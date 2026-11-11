"""Build short original sound effects for Samurai vs Zombies."""

import math
import os
import struct
import wave

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")


def write_wav(name, samples):
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        frames = bytearray()
        for sample in samples:
            clamped = max(-1.0, min(1.0, sample))
            frames += struct.pack("<h", int(clamped * 32767))
        handle.writeframes(frames)


def env(i, n, attack=0.01):
    t = i / max(1, n - 1)
    attack_n = max(1, int(attack * n))
    rise = min(1.0, i / attack_n)
    return rise * (1.0 - t) ** 1.4


def tone(freq, dur, vol=0.35, kind="sine", slide=0.0):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        f = freq + slide * t
        phase = 2.0 * math.pi * f * t
        if kind == "square":
            wave_v = 1.0 if math.sin(phase) >= 0 else -1.0
        elif kind == "noise":
            wave_v = math.sin(phase * 1.7) * math.sin(phase * 0.37 + 2.0)
        else:
            wave_v = math.sin(phase)
        out.append(wave_v * vol * env(i, n))
    return out


def mix(*tracks):
    length = max(len(track) for track in tracks)
    out = [0.0] * length
    for track in tracks:
        for i, sample in enumerate(track):
            out[i] += sample
    peak = max(1e-6, max(abs(sample) for sample in out))
    if peak > 0.95:
        scale = 0.95 / peak
        out = [sample * scale for sample in out]
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    write_wav("click", tone(740, 0.045, 0.3))
    write_wav("spawn", mix(tone(260, 0.12, 0.25), tone(520, 0.14, 0.18, slide=80)))
    write_wav("sword", tone(150, 0.09, 0.4, "square", -400))
    write_wav("arrow", tone(680, 0.07, 0.22, "sine", 200))
    write_wav("hit", tone(190, 0.08, 0.34, "square", -250))
    write_wav("explode", mix(tone(90, 0.28, 0.45, "square", -180), tone(50, 0.32, 0.25, "noise")))
    write_wav("heal", tone(560, 0.12, 0.22, "sine", 180))
    write_wav("buff", mix(tone(520, 0.1, 0.2), tone(780, 0.14, 0.16)))
    write_wav("blink", tone(420, 0.11, 0.24, "sine", 900))
    write_wav("castle", tone(80, 0.22, 0.4, "square", -80))
    write_wav("win", mix(tone(523, 0.16, 0.22), tone(659, 0.18, 0.18), tone(784, 0.28, 0.2)))
    write_wav("lose", mix(tone(311, 0.2, 0.24), tone(233, 0.28, 0.22, slide=-40), tone(174, 0.36, 0.18)))
    print("wrote sfx to", os.path.abspath(OUT))


if __name__ == "__main__":
    main()

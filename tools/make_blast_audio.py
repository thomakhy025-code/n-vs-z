"""Synthesize explosion, sword-impact, ice-wind, and ice-lock effects.

Does not touch shouted names or story narration.
"""

import math
import os
import struct
import wave

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "audio")
RATE = 44100


def write_wav(path, samples, rate=RATE):
    with wave.open(path, "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(rate)
        frames = bytearray()
        for sample in samples:
            clamped = max(-1.0, min(1.0, sample))
            frames += struct.pack("<h", int(clamped * 32767))
        handle.writeframes(frames)


def noise(n, seed):
    state = seed & 0x7FFFFFFF
    out = []
    i = 0
    while i < n:
        state = (1103515245 * state + 12345) & 0x7FFFFFFF
        out.append((state / 1073741823.0) - 1.0)
        i += 1
    return out


def lowpass(samples, cutoff, rate):
    rc = 1.0 / (2.0 * math.pi * max(1.0, cutoff))
    dt = 1.0 / rate
    a = dt / (rc + dt)
    out = []
    y = 0.0
    for sample in samples:
        y += a * (sample - y)
        out.append(y)
    return out


def highpass(samples, cutoff, rate):
    low = lowpass(samples, cutoff, rate)
    return [a - b for a, b in zip(samples, low)]


def normalize(samples, peak_target=0.92):
    peak = 1e-6
    for sample in samples:
        peak = max(peak, abs(sample))
    gain = peak_target / peak
    return [max(-1.0, min(1.0, sample * gain)) for sample in samples]


def bomb():
    n = int(RATE * 1.15)
    raw = noise(n, 17)
    grit = lowpass(raw, 900, RATE)
    air = highpass(raw, 1400, RATE)
    out = []
    phase = 0.0
    i = 0
    while i < n:
        t = i / float(RATE)
        hit = 0.0
        if t < 0.018:
            hit = air[i] * (1.0 - t / 0.018) * 1.35
        elif t < 0.05:
            hit = air[i] * (1.0 - (t - 0.018) / 0.032) * 0.35
        freq = 95.0 * math.exp(-t * 1.7) + 28.0
        phase += 2.0 * math.pi * freq / RATE
        rumble = math.sin(phase) * math.exp(-t * 1.15)
        body = grit[i] * math.exp(-t * 2.4) * 0.85
        crack = 0.0
        for when in (0.08, 0.16, 0.27):
            dt = t - when
            if 0.0 <= dt < 0.012:
                crack += air[i] * (1.0 - dt / 0.012) * 0.35
        out.append(math.tanh(hit * 1.1 + rumble * 0.95 + body * 0.7 + crack))
        i += 1
    return normalize(out)


def sword():
    n = int(RATE * 0.72)
    raw = noise(n, 29)
    hiss = highpass(raw, 1600, RATE)
    grit = lowpass(raw, 700, RATE)
    out = []
    i = 0
    while i < n:
        t = i / float(RATE)
        whoosh = 0.0
        if t < 0.09:
            whoosh = hiss[i] * math.sin(math.pi * t / 0.09) * 0.45
        impact = 0.0
        thump = 0.0
        if t >= 0.09:
            dt = t - 0.09
            if dt < 0.02:
                impact = hiss[i] * (1.0 - dt / 0.02) * 1.25
            thump = math.sin(2.0 * math.pi * 62.0 * dt) * math.exp(-dt * 7.0) * 1.05
            thump += grit[i] * math.exp(-dt * 3.5) * 0.55
        scrape = 0.0
        if 0.12 < t < 0.55:
            dt = t - 0.12
            scrape = grit[i] * (0.55 + 0.45 * math.sin(2.0 * math.pi * 28.0 * dt)) * math.exp(-dt * 2.2) * 0.4
        out.append(math.tanh(whoosh + impact + thump + scrape))
        i += 1
    return normalize(out)


def wind():
    n = int(RATE * 0.72)
    raw = noise(n, 41)
    air = highpass(lowpass(raw, 4200, RATE), 500, RATE)
    out = []
    i = 0
    while i < n:
        t = i / float(RATE)
        if t < 0.18:
            env = t / 0.18
        else:
            env = math.exp(-(t - 0.18) * 2.4)
        whistle = math.sin(2.0 * math.pi * (740.0 + 180.0 * math.sin(2.0 * math.pi * 3.0 * t)) * t)
        gust = 0.65 + 0.35 * math.sin(2.0 * math.pi * 7.0 * t)
        out.append((air[i] * 0.9 + whistle * 0.08) * env * gust)
        i += 1
    return normalize(out, 0.86)


def ice_lock():
    n = int(RATE * 0.58)
    raw = noise(n, 53)
    bright = highpass(raw, 1800, RATE)
    out = [0.0] * n
    hits = (0.0, 0.04, 0.09, 0.15, 0.23, 0.34, 0.46)
    tones = (2400.0, 3100.0, 1900.0, 3700.0, 2700.0, 4200.0, 2200.0)
    h = 0
    while h < len(hits):
        i0 = int(hits[h] * RATE)
        dur = int(0.07 * RATE)
        k = 0
        while k < dur and i0 + k < n:
            t = k / float(RATE)
            env = math.exp(-t * 28.0)
            crunch = bright[i0 + k] * env * 0.7
            ping = math.sin(2.0 * math.pi * tones[h] * t) * env * 0.55
            out[i0 + k] += crunch + ping
            k += 1
        h += 1
    return normalize(out)


def main():
    os.makedirs(OUT, exist_ok=True)
    made = {
        "fx_ex": bomb(),
        "fx_ls": sword(),
        "fz_wind": wind(),
        "fz_lock": ice_lock(),
    }
    for name, samples in made.items():
        path = os.path.join(OUT, name + ".wav")
        write_wav(path, samples)
        peak = max(abs(s) for s in samples)
        print("%s frames=%d dur=%.2fs peak=%.3f" % (name, len(samples), len(samples) / float(RATE), peak))


if __name__ == "__main__":
    main()

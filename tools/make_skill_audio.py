"""Shouted skill names via Windows SAPI, plus synthesized effect sounds."""

import math
import os
import random
import struct
import subprocess
import wave

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "audio")
RATE = 44100

LINES = [
    ("say_ex", "Explosion!"),
    ("say_ls", "Light smashing!"),
    ("say_fz", "Freezing!"),
    ("say_en", "Enhancement!"),
]


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


def read_wav(path):
    with wave.open(path, "rb") as handle:
        channels = handle.getnchannels()
        width = handle.getsampwidth()
        rate = handle.getframerate()
        count = handle.getnframes()
        raw = handle.readframes(count)
    if width == 2:
        values = struct.unpack("<" + "h" * (len(raw) // 2), raw)
        scale = 32768.0
    elif width == 1:
        values = struct.unpack("<" + "B" * len(raw), raw)
        scale = 128.0
        values = [v - 128 for v in values]
    else:
        raise RuntimeError("unsupported wav width %s" % width)
    if channels == 1:
        samples = [v / scale for v in values]
    else:
        samples = []
        i = 0
        while i < len(values):
            acc = 0.0
            c = 0
            while c < channels and i + c < len(values):
                acc += values[i + c]
                c += 1
            samples.append(acc / float(channels) / scale)
            i += channels
    return samples, rate


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


def normalize(samples, peak_target=0.94):
    peak = 1e-6
    for sample in samples:
        peak = max(peak, abs(sample))
    gain = peak_target / peak
    return [max(-1.0, min(1.0, sample * gain)) for sample in samples]


def trim(samples, rate, thresh=0.02):
    start = 0
    end = len(samples)
    while start < end and abs(samples[start]) < thresh:
        start += 1
    while end > start and abs(samples[end - 1]) < thresh:
        end -= 1
    pad = int(rate * 0.03)
    start = max(0, start - pad)
    end = min(len(samples), end + pad)
    if end - start < 8:
        return samples
    return samples[start:end]


def speed(samples, factor):
    if factor <= 1.001:
        return samples
    out = []
    pos = 0.0
    last = len(samples) - 1
    while pos < last:
        i = int(pos)
        frac = pos - i
        out.append(samples[i] * (1.0 - frac) + samples[i + 1] * frac)
        pos += factor
    return out


def shoutify(samples, rate):
    cleaned = trim(samples, rate, 0.015)
    dur = len(cleaned) / float(rate)
    factor = 1.0
    if dur > 1.25:
        factor = dur / 1.05
    sped = speed(cleaned, factor)
    driven = [math.tanh(sample * 1.55) for sample in sped]
    return normalize(driven, 0.98), rate


def sapi(text, dest):
    ps1 = os.path.join(OUT, "_say_once.ps1")
    safe = text.replace("'", "''")
    dest_ps = dest.replace("'", "''")
    script = """
Add-Type -AssemblyName System.Speech
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$names = @($s.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo.Name })
$pick = $names | Where-Object { $_ -match 'Zira' } | Select-Object -First 1
if (-not $pick) { $pick = $names | Select-Object -First 1 }
if (-not $pick) { throw 'No SAPI voice installed' }
$s.SelectVoice($pick)
$s.Rate = 1
$s.SetOutputToWaveFile('%s')
$ssml = @"
<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>
  <prosody pitch='high' volume='x-loud'><emphasis level='strong'>%s</emphasis></prosody>
</speak>
"@
try { $s.SpeakSsml($ssml) } catch { $s.Speak('%s') }
$s.SetOutputToNull()
$s.Dispose()
Write-Output $pick
""" % (dest_ps, safe, safe)
    with open(ps1, "w", encoding="utf-8") as handle:
        handle.write(script)
    voice = subprocess.check_output(
        ["powershell", "-NoProfile", "-File", ps1],
        text=True,
    ).strip()
    os.remove(ps1)
    return voice


def noise(n, seed):
    rng = random.Random(seed)
    return [rng.random() * 2.0 - 1.0 for _ in range(n)]


def bomb():
    n = int(RATE * 0.82)
    raw = noise(n, 11)
    body = lowpass(raw, 160, RATE)
    grit = lowpass(raw, 900, RATE)
    out = []
    phase = 0.0
    phase2 = 0.0
    hits = (0.11, 0.19, 0.31, 0.46)
    for i in range(n):
        t = i / RATE
        freq = 30.0 + 160.0 * math.exp(-t * 7.2)
        phase += 2.0 * math.pi * freq / RATE
        freq2 = 18.0 + 46.0 * math.exp(-t * 3.0)
        phase2 += 2.0 * math.pi * freq2 / RATE
        boom = math.sin(phase) * math.exp(-t * 2.5)
        sub = math.sin(phase2) * math.exp(-t * 1.5) * 0.75
        crack = 0.0
        if t < 0.012:
            crack = raw[i] * (1.0 - t / 0.012)
        elif t < 0.045:
            crack = raw[i] * 0.4 * (1.0 - (t - 0.012) / 0.033)
        debris = 0.0
        for hit in hits:
            dt = t - hit
            if 0.0 <= dt < 0.02:
                debris += raw[i] * (1.0 - dt / 0.02) * 0.28
        sample = (
            boom * 0.55
            + sub * 0.5
            + crack * 0.95
            + body[i] * math.exp(-t * 3.2) * 0.75
            + grit[i] * math.exp(-t * 8.0) * 0.3
            + debris
        )
        out.append(math.tanh(sample * 1.15))
    return normalize(out)


def ice():
    n = int(RATE * 0.74)
    raw = noise(n, 23)
    bright = highpass(raw, 1700, RATE)
    out = [0.0] * n
    for hit in (0.0, 0.045, 0.09, 0.15, 0.23, 0.3, 0.39, 0.5, 0.61):
        i0 = int(hit * RATE)
        dur = int(0.02 * RATE)
        k = 0
        while k < dur:
            i = i0 + k
            if i >= n:
                break
            env = (1.0 - k / float(dur)) ** 2
            out[i] += bright[i] * env * 0.9
            k += 1
    tones = (
        (2500, 0.02),
        (3200, 0.06),
        (1900, 0.11),
        (4100, 0.17),
        (2800, 0.25),
        (3600, 0.34),
        (2200, 0.43),
        (3900, 0.52),
    )
    for freq, start in tones:
        i0 = int(start * RATE)
        dur = int(0.1 * RATE)
        k = 0
        while k < dur:
            i = i0 + k
            if i >= n:
                break
            t = k / RATE
            env = math.exp(-t * 26.0)
            out[i] += math.sin(2.0 * math.pi * freq * (start + t)) * env * 0.24
            k += 1
    i = 0
    while i < n:
        t = i / RATE
        shimmer = math.sin(2.0 * math.pi * 1500 * t) * math.sin(2.0 * math.pi * 8.0 * t)
        env = math.exp(-t * 2.0) * min(1.0, t / 0.02)
        out[i] += shimmer * env * 0.09
        if t < 0.12:
            out[i] += raw[i] * (1.0 - t / 0.12) * 0.18
        i += 1
    return normalize(out)


def fire():
    n = int(RATE * 0.7)
    raw = noise(n, 41)
    low = lowpass(raw, 380, RATE)
    mid = highpass(lowpass(raw, 2200, RATE), 480, RATE)
    out = []
    i = 0
    while i < n:
        t = i / RATE
        if t < 0.16:
            whoosh = math.sin(math.pi * 0.5 * (t / 0.16))
        else:
            whoosh = math.exp(-(t - 0.16) * 2.8)
        freq = 240.0 + 980.0 * min(1.0, t / 0.22)
        sweep = math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 5.5) * 0.1
        sample = low[i] * whoosh * 0.6 + mid[i] * whoosh * 0.95 + sweep
        out.append(sample)
        i += 1
    rng = random.Random(7)
    i = 0
    while i < n:
        if rng.random() < 0.014:
            dur = int(0.009 * RATE)
            amp = 0.4 + rng.random() * 0.45
            k = 0
            while k < dur and i + k < n:
                env = 1.0 - k / float(dur)
                out[i + k] += (rng.random() * 2.0 - 1.0) * env * amp
                k += 1
            i += dur
        else:
            i += 1
    return normalize(out)


def sword():
    n = int(RATE * 0.78)
    raw = noise(n, 53)
    grit = lowpass(raw, 650, RATE)
    hiss = highpass(raw, 1800, RATE)
    out = []
    phase = 0.0
    hits = (0.08, 0.17, 0.29)
    i = 0
    while i < n:
        t = i / RATE
        freq = 1700.0 * math.exp(-t * 13.0) + 120.0
        phase += 2.0 * math.pi * freq / RATE
        slice_env = math.exp(-t * 9.0) * min(1.0, t / 0.004)
        slice_s = (math.sin(phase) * 0.4 + hiss[i] * 0.6) * slice_env
        impact = 0.0
        tear = 0.0
        if t > 0.05:
            dt = t - 0.05
            impact = math.sin(2.0 * math.pi * 68.0 * dt) * math.exp(-dt * 7.5) * 0.85
            impact += grit[i] * math.exp(-dt * 3.2) * 0.7
        if 0.07 < t < 0.58:
            dt = t - 0.07
            mod = 0.6 + 0.4 * math.sin(2.0 * math.pi * 36.0 * dt)
            tear = grit[i] * mod * math.exp(-dt * 2.0) * 0.6
        crack = 0.0
        for hit in hits:
            dt = t - hit
            if 0.0 <= dt < 0.018:
                crack += hiss[i] * (1.0 - dt / 0.018) * 0.6
        out.append(slice_s + impact + tear + crack)
        i += 1
    return normalize(out)


def main():
    os.makedirs(OUT, exist_ok=True)
    voice = ""
    for name, text in LINES:
        raw_path = os.path.join(OUT, "_raw_" + name + ".wav")
        voice = sapi(text, raw_path)
        samples, rate = read_wav(raw_path)
        print("  raw", name, "%.2fs" % (len(samples) / float(rate)))
        shouted, out_rate = shoutify(samples, rate)
        dest = os.path.join(OUT, name + ".wav")
        write_wav(dest, shouted, out_rate)
        os.remove(raw_path)
        print("%s voice=%s dur=%.2fs" % (name, voice, len(shouted) / float(out_rate)))
    effects = {
        "fx_ex": bomb(),
        "fx_ls": sword(),
        "fx_fz": ice(),
        "fx_en": fire(),
    }
    for name, samples in effects.items():
        dest = os.path.join(OUT, name + ".wav")
        write_wav(dest, samples, RATE)
        print("%s dur=%.2fs" % (name, len(samples) / float(RATE)))


if __name__ == "__main__":
    main()

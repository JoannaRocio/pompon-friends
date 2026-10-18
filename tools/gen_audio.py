"""Genera la musica y los sonidos de Pompon Friends (todo sintetizado, sin samples).

Uso:  python tools/gen_audio.py <carpeta_salida>
Crea WAV de musica (music_home.wav, music_play.wav, loops perfectos) y los efectos sfx_*.wav.
Despues se convierte la musica a OGG con ffmpeg (ver tools/README si hace falta).
"""
import math
import os
import random
import struct
import sys
import wave

SR = 32000
TWO_PI = 2.0 * math.pi
random.seed(7)


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def write_wav(path, left, right=None):
    right = right if right is not None else left
    peak = max(max(abs(x) for x in left), max(abs(x) for x in right), 1e-9)
    gain = 0.85 / peak
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for a, b in zip(left, right):
            frames += struct.pack("<hh", int(max(-1, min(1, a * gain)) * 32767),
                                  int(max(-1, min(1, b * gain)) * 32767))
        w.writeframes(bytes(frames))


# ----------------------------------------------------------------- musica

def add_note(buf, start_s, dur_s, freq, amp, kind, release=0.0):
    """Suma una nota al buffer circular (asi el loop queda sin cortes)."""
    n = len(buf)
    start = int(start_s * SR)
    total = int((dur_s + release) * SR)
    for i in range(total):
        t = i / SR
        if kind == "pad":
            att = min(1.0, t / 0.9)
            rel = 1.0 if t < dur_s else max(0.0, 1.0 - (t - dur_s) / max(release, 1e-6))
            trem = 1.0 + 0.12 * math.sin(TWO_PI * 0.23 * (start_s + t))
            env = att * rel * trem
            s = math.sin(TWO_PI * freq * t) + 0.55 * math.sin(TWO_PI * freq * 1.004 * t + 1.1)
            s += 0.18 * math.sin(TWO_PI * freq * 2 * t)
        elif kind == "bass":
            env = min(1.0, t / 0.012) * math.exp(-t * 1.9)
            s = math.sin(TWO_PI * freq * t) + 0.25 * math.sin(TWO_PI * freq * 2 * t)
        else:  # "bell": caja de musica / celesta
            env = min(1.0, t / 0.004) * math.exp(-t * 3.1)
            s = (math.sin(TWO_PI * freq * t) + 0.30 * math.sin(TWO_PI * freq * 2 * t)
                 + 0.12 * math.sin(TWO_PI * freq * 3.01 * t))
        buf[(start + i) % n] += amp * env * s


def add_brush(buf, start_s, amp):
    n = len(buf)
    start = int(start_s * SR)
    lp = 0.0
    for i in range(int(0.11 * SR)):
        t = i / SR
        x = random.uniform(-1, 1)
        lp += 0.35 * (x - lp)
        buf[(start + i) % n] += amp * (x - lp) * math.exp(-t * 28.0) * min(1.0, t / 0.004)


def reverb(dry):
    """Reverb tipo Schroeder sobre buffer circular -> (izq, der)."""
    n = len(dry)
    outs = []
    for delays in ([29.7, 37.1, 41.1, 43.7], [30.9, 36.3, 42.5, 45.1]):
        wet = [0.0] * n
        for d in delays:
            dl = int(d / 1000.0 * SR)
            fb = 0.80
            # dos pasadas sobre el buffer circular para llegar al estado estable
            buf = [0.0] * dl
            idx = 0
            damp = 0.0
            for p in range(2):
                for i in range(n):
                    y = buf[idx]
                    damp += 0.35 * (y - damp)
                    buf[idx] = dry[i] + damp * fb
                    idx += 1
                    if idx == dl:
                        idx = 0
                    if p == 1:
                        wet[i] += y * 0.25
        outs.append(wet)
    return outs


def lowpass(x, a):
    """Filtro de un polo circular: se hace una pasada previa para que el final empalme con el inicio."""
    y = 0.0
    for s in x:
        y += a * (s - y)
    out = []
    for s in x:
        y += a * (s - y)
        out.append(y)
    return out


def render_track(path, bpm, chords, bass_roots, melody, bass_pattern, brush=True, melody_amp=0.20):
    beat = 60.0 / bpm
    bar = beat * 4
    bars = len(chords)
    length = bars * bar
    n = int(length * SR)
    dry = [0.0] * n
    for b in range(bars):
        t0 = b * bar
        for m in chords[b]:
            add_note(dry, t0, bar * 1.02, mtof(m), 0.050, "pad", release=0.9)
        for slot in bass_pattern:
            add_note(dry, t0 + slot * beat * 0.5, beat * 1.6, mtof(bass_roots[b]), 0.17, "bass")
        for slot, midi in melody[b]:
            jitter = random.uniform(-0.012, 0.012)
            vel = random.uniform(0.8, 1.0)
            add_note(dry, max(0.0, t0 + slot * beat * 0.5 + jitter), 1.4, mtof(midi),
                     melody_amp * vel, "bell")
        if brush:
            add_brush(dry, t0 + beat * 1, 0.05)
            add_brush(dry, t0 + beat * 3, 0.05)
    left, right = reverb(dry)
    mix_l = [d + 0.9 * w for d, w in zip(dry, left)]
    mix_r = [d + 0.9 * w for d, w in zip(dry, right)]
    mix_l = lowpass(mix_l, 0.42)
    mix_r = lowpass(mix_r, 0.42)
    write_wav(path, mix_l, mix_r)
    print("ok", path, round(length, 1), "s")


def music(out):
    # Pista de la casa: Do mayor, calida y lenta.
    chords = [
        [60, 64, 67, 71], [57, 60, 64, 67], [53, 57, 60, 64], [55, 59, 62, 64],
        [60, 62, 64, 67], [59, 62, 64, 67], [53, 57, 60, 64], [55, 59, 62, 64],
    ]
    bass = [48, 45, 41, 43, 48, 47, 41, 43]
    mel = [
        [(0, 76), (2, 79), (4, 74), (6, 72)],
        [(0, 72), (3, 76), (4, 81), (7, 79)],
        [(0, 81), (2, 79), (4, 76), (6, 79)],
        [(0, 74), (2, 76), (4, 79), (7, 76)],
        [(0, 79), (3, 76), (4, 74), (6, 76)],
        [(0, 76), (2, 79), (4, 81), (5, 79)],
        [(0, 81), (3, 79), (4, 76), (6, 72)],
        [(0, 74), (2, 76), (4, 74), (6, 72)],
    ]
    render_track(os.path.join(out, "music_home.wav"), 70, chords, bass, mel, [0, 4])

    # Pista de minijuegos: Sol mayor, un poco mas alegre pero igual de suave.
    chords = [
        [55, 59, 62, 66], [52, 55, 59, 62], [60, 64, 67, 71], [57, 62, 66, 69],
        [55, 59, 62, 66], [52, 55, 59, 62], [60, 64, 67, 71], [57, 62, 66, 69],
    ]
    bass = [43, 40, 48, 50, 43, 40, 48, 50]
    mel = [
        [(0, 79), (1, 83), (3, 86), (4, 83), (6, 81)],
        [(0, 76), (2, 79), (3, 83), (5, 79), (7, 76)],
        [(0, 79), (2, 83), (4, 88), (6, 86)],
        [(0, 81), (2, 86), (3, 83), (5, 81), (6, 78)],
        [(0, 83), (1, 86), (3, 83), (4, 79), (6, 83)],
        [(0, 88), (2, 86), (4, 83), (5, 79), (7, 76)],
        [(0, 84), (2, 83), (4, 79), (6, 83)],
        [(0, 81), (2, 78), (4, 81), (6, 74)],
    ]
    render_track(os.path.join(out, "music_play.wav"), 88, chords, bass, mel, [0, 3, 4], melody_amp=0.18)


# -------------------------------------------------------------------- sfx

def tone(dur, f0, f1=None, decay=8.0, harm=0.0, attack=0.004, vib=0.0, amp=1.0):
    f1 = f1 if f1 is not None else f0
    n = int(dur * SR)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (i / n)
        f *= 1.0 + vib * math.sin(TWO_PI * 24 * t)
        phase += TWO_PI * f / SR
        env = min(1.0, t / attack) * math.exp(-t * decay)
        s = math.sin(phase) + harm * math.sin(2 * phase) + harm * 0.4 * math.sin(3 * phase)
        out.append(amp * env * s)
    return out


def noise_burst(dur, decay=40.0, cutoff=0.3, amp=1.0):
    n = int(dur * SR)
    out = []
    lp = 0.0
    for i in range(n):
        t = i / SR
        x = random.uniform(-1, 1)
        lp += cutoff * (x - lp)
        out.append(amp * lp * math.exp(-t * decay) * min(1.0, t / 0.002))
    return out


def mix(parts, total):
    out = [0.0] * int(total * SR)
    for offset, samples in parts:
        o = int(offset * SR)
        for i, s in enumerate(samples):
            if o + i < len(out):
                out[o + i] += s
    return out


def sfx(out):
    def save(name, samples):
        write_wav(os.path.join(out, "sfx_%s.wav" % name), samples)
        print("ok sfx_%s" % name)

    save("click", mix([(0, tone(0.09, 720, 520, decay=40, harm=0.2)), (0, noise_burst(0.012, 200, 0.6, 0.15))], 0.1))
    save("coin", mix([(0, tone(0.5, mtof(88), decay=7, harm=0.3)), (0.09, tone(0.7, mtof(95), decay=6, harm=0.3))], 0.8))
    save("success", mix([(i * 0.11, tone(0.7, mtof(m), decay=5, harm=0.3)) for i, m in enumerate([72, 76, 79, 84])], 1.2))
    save("fail", mix([(0, tone(0.35, mtof(67), decay=7, harm=0.1, amp=0.8)), (0.16, tone(0.5, mtof(62), decay=6, harm=0.1, amp=0.8))], 0.7))
    save("hatch", mix([(0, noise_burst(0.05, 50, 0.5, 0.8)), (0.16, noise_burst(0.05, 50, 0.5, 0.8)), (0.34, noise_burst(0.07, 40, 0.5, 1.0))]
                      + [(0.55 + i * 0.07, tone(0.6, mtof(m), decay=5, harm=0.25, amp=0.6)) for i, m in enumerate([79, 83, 86, 91, 95])], 1.4))
    save("eat", mix([(i * 0.17, noise_burst(0.1, 30, 0.25, 0.9)) for i in range(3)], 0.7))
    save("drink", mix([(i * 0.2, tone(0.17, 520 + i * 40, 280 + i * 20, decay=10, vib=0.04, amp=0.8)) for i in range(3)], 0.8))
    save("bath", mix([(random.uniform(0, 0.55), tone(0.08, random.uniform(900, 1700), decay=40, amp=0.5)) for _ in range(9)], 0.8))
    save("pet", mix([(0, tone(0.18, 560, 900, decay=9, harm=0.15, vib=0.03)), (0.12, tone(0.22, 700, 1050, decay=8, harm=0.15, vib=0.03))], 0.45))
    save("voice_a", tone(0.22, 620, 980, decay=8, harm=0.2, vib=0.04))
    save("voice_b", tone(0.26, 880, 700, decay=7, harm=0.2, vib=0.04))
    save("voice_c", mix([(0, tone(0.12, 700, 900, decay=12, harm=0.2)), (0.13, tone(0.16, 850, 1100, decay=10, harm=0.2))], 0.35))
    for i, m in enumerate([72, 76, 79, 81]):  # Do, Mi, Sol, La: tonos de Simon Dice
        save("simon%d" % i, tone(0.55, mtof(m), decay=5.5, harm=0.3, amp=0.9))


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out, exist_ok=True)
    sfx(out)
    music(out)

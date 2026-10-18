"""Genera solo los sonidos nuevos del trabajo en el periodico (sello y campanita).
Uso:  python tools/gen_sfx_job.py assets/audio
(No toca la musica ni los demas efectos.)"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_audio as g  # noqa: E402

out = sys.argv[1] if len(sys.argv) > 1 else "."
os.makedirs(out, exist_ok=True)

# sello: golpe grave y corto + toque de papel
stamp = g.mix([(0, g.tone(0.16, 160, 70, decay=22, harm=0.4)), (0, g.noise_burst(0.035, 110, 0.7, 0.7))], 0.2)
g.write_wav(os.path.join(out, "sfx_stamp.wav"), stamp)

# campanita de "ultima hora"
ding = g.mix([(0, g.tone(0.9, g.mtof(91), decay=4.0, harm=0.35)), (0.13, g.tone(0.9, g.mtof(96), decay=4.0, harm=0.3))], 1.1)
g.write_wav(os.path.join(out, "sfx_ding.wav"), ding)
print("ok sfx_stamp, sfx_ding")

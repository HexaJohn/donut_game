"""Mixes the trailer's sound and makes the final Steam video.

Run after test/trailer_test.dart has recorded video.mp4 and sounds.csv:

    TRAILER=/some/folder flutter test test/trailer_test.dart
    python tool/trailer_audio.py /some/folder

Lays every sound effect the game asked for at the moment it asked, over a
stretch of the in-game music, then encodes donut_trailer_1080p30.mp4: H.264
High at 12 Mbps, AAC 320 kbps stereo, 48 kHz, BT.709. Needs numpy and
ffmpeg on the PATH.
"""
import csv
import random
import subprocess
import sys
from pathlib import Path

import numpy as np

RATE = 48000
FPS = 30
ROOT = Path(__file__).resolve().parent.parent
SOUNDS = ROOT / 'assets' / 'sounds'
MUSIC = ROOT / 'assets' / 'music' / 'Oscuridad.mp3'

# Mirrors lib/audio/sfx.dart: (file, gain) per variation
BANK = {
    'shuffle': [('card-shuffle-1.mp3', 1.0)],
    'slide': [('card-slide-1.mp3', 0.67), ('card-slide-2.mp3', 1.0), ('card-slide-3.wav', 0.23)],
    'place': [('card-placed-1.wav', 1.0), ('card-placed-2.wav', 0.39), ('card-placed-3.wav', 1.0)],
    'cough': [('cough-1.mp3', 0.5), ('cough-2.mp3', 0.45), ('cough-3.mp3', 0.45), ('cough-4.mp3', 0.42)],
    'yourMove': [('alert-2.mp3', 1.0)],
    'yourTurn': [('alert-1.mp3', 1.0)],
    'gunshot': [('revolver-fired-1.mp3', 0.54), ('revolver-fired-2.mp3', 0.43),
                ('revolver-fired-3.mp3', 0.92), ('revolver-fired-4.mp3', 1.0)],
    'revolverLoaded': [('revolver-loaded-1.wav', 1.0)],
    'flashBang': [('flash-bang.mp3', 1.0)],
    'click': [('click-1.mp3', 0.8), ('click-2.mp3', 0.34), ('click-3.mp3', 1.0),
              ('click-4.mp3', 0.54), ('click-5.mp3', 0.64)],
}

# Sound effects sit over the music; these keep the busiest moments (a
# 30-card deal) from turning to mush
SFX_LEVEL = 2.2
MUSIC_LEVEL = 0.55
QUIET = {'cough': 0.0, 'click': 0.6, 'slide': 0.7}


def decode(path):
    """Any audio file as float32 stereo at RATE."""
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', str(path), '-f', 'f32le', '-ac', '2', '-ar', str(RATE), '-'],
        check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2).copy()


def loudest_stretch(music, seconds):
    """Start (in samples) of the most energetic stretch of the music."""
    hop = RATE // 2
    rms = np.array([np.sqrt(np.mean(music[i:i + hop] ** 2)) for i in range(0, len(music) - hop, hop)])
    span = int(seconds * 2)
    if span >= len(rms):
        return 0
    # Favour stretches that start loud too, so the trailer opens on energy
    scores = [rms[i:i + span].mean() + 0.5 * rms[i:i + 4].mean() for i in range(len(rms) - span)]
    return int(np.argmax(scores)) * hop


def main(folder):
    folder = Path(folder)
    edit = (folder / 'edit.txt').read_text().splitlines()
    frames = int(edit[0].split()[1])
    length = frames / FPS
    total = int(length * RATE) + RATE

    random.seed(7)
    clips = {}
    sfx = np.zeros((total, 2), dtype=np.float32)
    flashes = []
    with open(folder / 'sounds.csv') as f:
        for row in csv.DictReader(f):
            name, at, volume = row['sound'], float(row['time']), float(row['volume'])
            if name == 'flashBang':
                flashes.append(at)
            options = BANK.get(name)
            if not options:
                continue
            file, gain = random.choice(options)
            if file not in clips:
                clips[file] = decode(SOUNDS / file)
            clip = clips[file] * gain * volume * QUIET.get(name, 1.0)
            start = int(at * RATE)
            end = min(total, start + len(clip))
            sfx[start:end] += clip[:end - start]

    ring = decode(SOUNDS / 'ringing.mp3')
    for at in flashes:
        start = int((at + 0.15) * RATE)
        end = min(total, start + len(ring))
        sfx[start:end] += ring[:end - start] * 0.35

    music = decode(MUSIC)
    begin = loudest_stretch(music, length)
    bed = music[begin:begin + total]
    if len(bed) < total:
        bed = np.concatenate([bed, np.zeros((total - len(bed), 2), dtype=np.float32)])
    envelope = np.ones(total, dtype=np.float32)
    fade_in = int(0.08 * RATE)
    envelope[:fade_in] = np.linspace(0, 1, fade_in)
    # Out with the picture's fade to black
    fade_out = int(2.5 * RATE)
    stop = int(length * RATE)
    envelope[stop - fade_out:stop] *= np.linspace(1, 0, fade_out)
    envelope[stop:] = 0
    # The flashbang deafens the music for a moment, as in the game
    for at in flashes:
        a, b = int(at * RATE), int((at + 2.2) * RATE)
        duck = np.concatenate([np.full(int(0.6 * RATE), 0.12), np.linspace(0.12, 1, b - a - int(0.6 * RATE))])
        envelope[a:b] *= duck[:max(0, min(b, total) - a)]
    mix = bed * envelope[:, None] * MUSIC_LEVEL + sfx * SFX_LEVEL
    mix = np.tanh(mix * 1.1) / np.tanh(1.1)  # gentle limiting
    mix = mix[:stop]

    wav = folder / 'mix.wav'
    subprocess.run(
        ['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ac', '2', '-ar', str(RATE), '-i', '-', str(wav)],
        input=mix.astype(np.float32).tobytes(), check=True)

    out = folder / 'donut_trailer_1080p30.mp4'
    subprocess.run([
        'ffmpeg', '-v', 'error', '-y', '-i', str(folder / 'video.mp4'), '-i', str(wav),
        '-vf', 'scale=in_color_matrix=bt601:out_color_matrix=bt709:flags=lanczos,format=yuv420p',
        '-c:v', 'libx264', '-preset', 'slow', '-profile:v', 'high', '-level', '4.2',
        '-b:v', '12M', '-maxrate', '16M', '-bufsize', '24M', '-g', '60', '-r', str(FPS),
        '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709',
        '-af', 'loudnorm=I=-16:TP=-1.5:LRA=11', '-c:a', 'aac', '-b:a', '320k', '-ar', str(RATE), '-ac', '2',
        '-shortest', '-movflags', '+faststart', str(out),
    ], check=True)
    print(f'{out} ({length:.1f} s, music from {begin / RATE:.1f} s)')


if __name__ == '__main__':
    main(sys.argv[1])

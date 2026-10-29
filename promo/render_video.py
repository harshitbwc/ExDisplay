#!/usr/bin/env python3
"""Renders the Launch video reliably.

Chrome's headless renderer intermittently emits a garbled (tiled) frame, on the order of
1-2% of frames and in different places on every run. A clean frame is bit-identical across
runs, so we render the whole video as PNGs several times, keep for every frame the version
that at least two renders agree on, re-render any frame without agreement, and only then
encode. Usage: python3 render_video.py <out.mp4> <poster.jpg>
"""
import collections, hashlib, os, re, shutil, subprocess, sys

CHROME = os.environ.get("CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
COMP, FPS, PASSES, MAX_ROUNDS = "Launch", 30, 3, 6
POSTER_FRAME = 205
here = os.path.dirname(os.path.abspath(__file__))
work = os.path.join(here, "out", "consensus")


def remotion(out, *extra):
    cmd = ["npx", "remotion", "render", COMP, out, "--image-format=png", "--gl=angle",
           f"--browser-executable={CHROME}", *extra]
    subprocess.run(cmd, cwd=here, check=True, stdout=subprocess.DEVNULL)


def frames_in(d):
    out = {}
    for f in os.listdir(d):
        m = re.fullmatch(r"element-(\d+)\.png", f)
        if m:
            out[int(m.group(1))] = os.path.join(d, f)
    return out


def md5(path):
    return hashlib.md5(open(path, "rb").read()).hexdigest()


def total_frames():
    # Read the duration the composition declares (single source of truth is Root.tsx).
    src = open(os.path.join(here, "src", "Root.tsx")).read()
    return int(re.search(r'id="Launch"[\s\S]*?durationInFrames=\{(\d+)\}', src).group(1))


def main(out_mp4, poster):
    n = total_frames()
    shutil.rmtree(work, ignore_errors=True)
    votes = collections.defaultdict(lambda: collections.defaultdict(list))  # frame -> hash -> [paths]

    def collect(d):
        for i, p in frames_in(d).items():
            votes[i][md5(p)].append(p)

    for k in range(PASSES):
        d = os.path.join(work, f"pass{k}")
        print(f"pass {k + 1}/{PASSES}", flush=True)
        remotion(d, "--sequence", "--concurrency=4")
        collect(d)

    def winner(i):
        best = max(votes[i].items(), key=lambda kv: len(kv[1]), default=None)
        return best[1][0] if best and len(best[1]) >= 2 else None

    for rnd in range(MAX_ROUNDS):
        pending = [i for i in range(n) if winner(i) is None]
        disagreed = sum(1 for i in range(n) if len(votes[i]) > 1)
        print(f"round {rnd}: {disagreed} frames had disagreement, {len(pending)} unresolved", flush=True)
        if not pending:
            break
        for rep in range(2):  # two more renders of just the unresolved frames
            d = os.path.join(work, f"retry{rnd}_{rep}")
            remotion(d, f"--frames={','.join(map(str, pending))}", "--concurrency=1")
            collect(d)
    else:
        pending = [i for i in range(n) if winner(i) is None]
        if pending:
            sys.exit(f"could not get two matching renders for frames {pending}")

    final = os.path.join(work, "final")
    os.makedirs(final)
    for i in range(n):
        os.link(winner(i), os.path.join(final, f"f{i:04d}.png"))

    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-start_number", "0",
        "-i", os.path.join(final, "f%04d.png"),
        "-vf", "scale=out_color_matrix=bt709:out_range=tv,format=yuv420p",
        "-c:v", "libx264", "-preset", "slow", "-crf", "20", "-pix_fmt", "yuv420p",
        "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv",
        "-movflags", "+faststart", out_mp4], check=True)
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-i", os.path.join(final, f"f{POSTER_FRAME:04d}.png"),
        "-q:v", "2", poster], check=True)
    print("wrote", out_mp4, "and", poster)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2]))

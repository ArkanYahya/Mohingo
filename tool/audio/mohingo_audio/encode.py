"""WAV -> mono AAC-LC .m4a, with the ffmpeg binary that imageio-ffmpeg bundles, so no
system ffmpeg is needed on the authoring machine."""
import subprocess

import imageio_ffmpeg


def to_m4a(wav_path, m4a_path, bitrate: str = "32k") -> None:
    subprocess.run(
        [
            imageio_ffmpeg.get_ffmpeg_exe(),
            "-y", "-loglevel", "error",
            "-i", str(wav_path),
            "-ac", "1", "-c:a", "aac", "-b:a", bitrate,
            str(m4a_path),
        ],
        check=True,
    )

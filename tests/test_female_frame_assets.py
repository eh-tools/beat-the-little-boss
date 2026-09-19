from hashlib import sha256
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
FEMALE = ROOT / "assets" / "art" / "female_frames"
MALE = ROOT / "assets" / "art" / "male_frames"


def run() -> None:
    paths = [FEMALE / f"female_{index:02d}.png" for index in range(32)]
    assert all(path.is_file() for path in paths)
    images = [Image.open(path).convert("RGBA") for path in paths]
    assert all(image.size == (160, 180) and image.getbbox() for image in images)
    assert all(
        any(all(image.getpixel((x, y))[3] > 25 for x in (70, 80, 90)) for y in range(150, 180))
        for image in images[:28]
    )
    assert len({sha256(path.read_bytes()).hexdigest() for path in paths}) >= 20
    assert all(ImageChops.difference(images[0].convert("RGB"), image.convert("RGB")).getbbox() for image in images[16:28])
    male_hashes = {sha256((MALE / f"male_{index:02d}.png").read_bytes()).hexdigest() for index in range(32)}
    assert not male_hashes.intersection(sha256(path.read_bytes()).hexdigest() for path in paths)


if __name__ == "__main__":
    run()
    print("female frame asset contract passed")

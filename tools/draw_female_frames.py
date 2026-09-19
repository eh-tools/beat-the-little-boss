"""Original female leader frame art, aligned to the shared desk-pet frame contract."""
from pathlib import Path

from PIL import Image, ImageDraw


OUT = Path(__file__).resolve().parents[1] / "assets" / "art" / "female_frames"
REFERENCE = Path(__file__).resolve().parents[1] / "assets" / "art" / "female_style_reference.png"
SIZE = (160, 180)
INK = "#171827"
HAIR = "#25263c"
HAIR_LIT = "#4d4d70"
TEAL = "#28777d"
TEAL_LIT = "#49a09a"
TEAL_DARK = "#174d5c"
CREAM = "#f2e2bd"
SKIN = "#e9a17a"
SKIN_LIT = "#ffc39a"
SKIN_SHADE = "#bd6a67"
BRUISE = "#895477"
BLUE = "#78b5c7"
PANTS = "#293149"
WHITE = "#fff5d2"
COFFEE = "#6d4237"


def rectangle(draw: ImageDraw.ImageDraw, box, color, outline=INK, width=2) -> None:
    draw.rectangle(box, fill=color, outline=outline, width=width)


def polygon(draw: ImageDraw.ImageDraw, points, color, outline=INK, width=2) -> None:
    draw.polygon(points, fill=color)
    if outline:
        draw.line(points + [points[0]], fill=outline, width=width)


def hair(draw: ImageDraw.ImageDraw, stage: int, sway: int) -> None:
    left = 38 - sway
    right = 122 - sway
    polygon(draw, [(left, 88), (left - 4, 55), (45, 21), (69, 10), (95, 12), (116, 30), (right, 65), (116, 110), (103, 116), (99, 77), (58, 82), (54, 119), (40, 112)], HAIR)
    draw.line([(47, 57), (55, 32), (73, 21), (96, 24), (108, 43)], fill=HAIR_LIT, width=3)
    draw.line([(46, 85), (37, 104), (42, 116)], fill=HAIR_LIT, width=3)
    if stage >= 3:
        draw.line([(43, 30), (34, 17), (49, 20), (53, 7)], fill=INK, width=3)
        draw.line([(107, 28), (122, 12), (123, 28), (133, 22)], fill=INK, width=3)


def face(draw: ImageDraw.ImageDraw, stage: int, variant: int) -> None:
    polygon(draw, [(57, 41), (71, 28), (95, 30), (107, 43), (106, 71), (98, 84), (80, 91), (62, 80), (53, 66)], SKIN)
    polygon(draw, [(61, 44), (74, 34), (94, 35), (102, 46), (100, 61), (94, 71), (66, 70), (59, 60)], SKIN_LIT, None)
    # Eyebrows and glasses become progressively more severe.
    brow = 2 if stage == 0 else 3
    draw.line([(62, 50), (73, 47)], fill=INK, width=brow)
    draw.line([(88, 47), (100, 50)], fill=INK, width=brow)
    rectangle(draw, (57, 52, 76, 65), BLUE)
    rectangle(draw, (84, 52, 103, 65), BLUE)
    draw.line([(76, 58), (84, 58)], fill=INK, width=2)
    draw.rectangle((63, 56, 68, 58), fill=INK)
    draw.rectangle((92, 56, 97, 58), fill=INK)
    draw.line([(80, 57), (78, 66), (82, 67)], fill=SKIN_SHADE, width=2)
    if stage == 0:
        mouth = [(74, 76), (80, 78 + variant), (87, 75)]
    elif stage == 1:
        mouth = [(73, 77), (80, 74), (88, 77)]
    else:
        mouth = [(71, 76), (78, 81), (89, 78)]
    draw.line(mouth, fill=INK, width=2)
    if stage >= 1:
        polygon(draw, [(91, 66), (104, 64), (105, 73), (94, 76)], BRUISE, None)
    if stage >= 2:
        polygon(draw, [(58, 61), (70, 63), (67, 72), (57, 69)], "#76608e", None)
        draw.line([(58, 65), (68, 67)], fill=INK, width=2)
    if stage >= 3:
        draw.line([(94, 79), (98, 86)], fill=SKIN_SHADE, width=2)
        draw.line([(64, 73), (60, 80)], fill=SKIN_SHADE, width=2)


def jacket(draw: ImageDraw.ImageDraw, stage: int, hand_shift: int) -> None:
    # The 70/80/90 anchor columns remain solid through y=171.
    polygon(draw, [(54, 87), (68, 80), (80, 95), (93, 80), (109, 88), (115, 133), (108, 172), (52, 172), (46, 132)], TEAL)
    polygon(draw, [(58, 94), (73, 89), (80, 107), (69, 135), (55, 128)], TEAL_LIT, None)
    polygon(draw, [(103, 94), (88, 89), (80, 107), (92, 135), (108, 128)], TEAL_DARK, None)
    polygon(draw, [(71, 87), (80, 101), (89, 87), (87, 121), (80, 128), (73, 121)], CREAM)
    draw.line([(80, 107), (80, 168)], fill=TEAL_DARK, width=2)
    # Resting hands appear immediately above the desk front.
    rectangle(draw, (49 + hand_shift, 121, 65 + hand_shift, 132), SKIN)
    rectangle(draw, (95 - hand_shift, 121, 111 - hand_shift, 132), SKIN)
    if stage >= 2:
        polygon(draw, [(52, 141), (64, 145), (59, 153), (69, 159), (56, 163)], SKIN)
    if stage >= 3:
        draw.line([(102, 117), (111, 126), (105, 137)], fill=INK, width=2)
        draw.line([(57, 111), (51, 121), (55, 131)], fill=INK, width=2)


def coffee(draw: ImageDraw.ImageDraw, index: int) -> None:
    lift = [0, 4, 8, 12, 16, 19, 17][index - 4]
    cup_x = 105 - lift // 3
    cup_y = 118 - lift
    draw.line([(99, 126), (105, cup_y + 10)], fill=SKIN, width=7)
    rectangle(draw, (cup_x, cup_y, cup_x + 15, cup_y + 16), CREAM)
    draw.rectangle((cup_x + 2, cup_y + 3, cup_x + 12, cup_y + 7), fill=COFFEE)
    draw.arc((cup_x + 12, cup_y + 4, cup_x + 21, cup_y + 13), 270, 90, fill=INK, width=2)
    if lift >= 12:
        for x, y in [(cup_x + 4, cup_y - 5), (cup_x + 10, cup_y - 10)]:
            draw.rectangle((x, y, x + 2, y + 5), fill="#a7c4bd")


def seated(index: int, stage: int) -> Image.Image:
    image = Image.new("RGBA", SIZE)
    draw = ImageDraw.Draw(image)
    variant = index % 4
    sway = (-1, 0, 1, 0)[variant]
    hair(draw, stage, sway)
    face(draw, stage, variant)
    jacket(draw, stage, sway)
    if 4 <= index <= 10:
        coffee(draw, index)
    if stage >= 1:
        draw.rectangle((108, 127, 112, 137), fill="#f5c683", outline=INK)
    if stage >= 2:
        draw.line([(70, 139), (75, 148), (70, 155)], fill="#cc6f65", width=2)
    if stage >= 3:
        polygon(draw, [(82, 136), (91, 143), (86, 157), (95, 163), (84, 170)], SKIN)
    return image


def terminal(index: int) -> Image.Image:
    image = Image.new("RGBA", SIZE)
    draw = ImageDraw.Draw(image)
    shift = index - 28
    hair(draw, 3, shift - 1)
    face(draw, 3, shift)
    polygon(draw, [(55, 88), (70, 82), (80, 100), (92, 82), (108, 90), (111, 133), (98, 144), (61, 143), (49, 128)], TEAL)
    polygon(draw, [(70, 88), (80, 104), (90, 88), (87, 127), (80, 134), (73, 127)], CREAM)
    # Open palms are visible in front, and knees settle farther apart across the four frames.
    rectangle(draw, (47 - shift, 127, 64 - shift, 142), SKIN)
    rectangle(draw, (96 + shift, 127, 113 + shift, 142), SKIN)
    polygon(draw, [(61, 140), (78, 140), (84, 166), (55 - shift, 169), (49, 159)], PANTS)
    polygon(draw, [(82, 140), (99, 140), (111 + shift, 169), (78, 166)], PANTS)
    rectangle(draw, (51 - shift, 166, 83, 174), INK, None)
    rectangle(draw, (78, 166, 111 + shift, 174), INK, None)
    draw.line([(55, 99), (65, 110), (58, 121)], fill=INK, width=3)
    draw.line([(105, 100), (98, 111), (106, 120)], fill=INK, width=3)
    return image


def stylized_frame(index: int) -> Image.Image:
    """Crop the approved five-pose reference into desk-compatible native sprites."""
    source = Image.open(REFERENCE).convert("RGBA")
    if index < 11:
        cell = 0
    elif index < 20:
        cell = 1
    elif index < 24:
        cell = 2
    elif index < 28:
        cell = 3
    else:
        cell = 4
    center = [220, 650, 1084, 1518, 1950][cell]
    jitter = (index % 4) - 1
    if cell == 4:
        image = source.crop((center - 215 + jitter * 3, 115, center + 215 + jitter * 3, 660)).resize(SIZE, Image.Resampling.NEAREST)
    else:
        image = source.crop((center - 205 + jitter * 3, 140, center + 205 + jitter * 3, 600)).resize(SIZE, Image.Resampling.NEAREST)
    pixels = image.load()
    # The direction-preview included laptops. The actual runtime has its own
    # monitor and keyboard, so remove only their neutral-gray body below hands.
    if cell < 4:
        for y in range(126, 180):
            for x in range(36, 125):
                pixels[x, y] = (0, 0, 0, 0)
        for y in range(122, 180):
            for x in range(0, 47):
                pixels[x, y] = (0, 0, 0, 0)
    draw = ImageDraw.Draw(image)
    if cell < 4:
        # Rebuild only the jacket section obscured by the reference laptop.
        # The desk cabinet hides y>=136 at runtime; the opaque torso continues
        # underneath so scaling and hit testing keep their shared contract.
        polygon(draw, [(47, 124), (67, 116), (80, 130), (94, 116), (113, 124), (108, 171), (52, 171)], TEAL)
        polygon(draw, [(68, 118), (80, 132), (92, 118), (88, 153), (80, 161), (72, 153)], CREAM)
        draw.line([(80, 132), (80, 171)], fill=TEAL_DARK, width=2)
        if 4 <= index <= 10:
            coffee(draw, index)
    # Sub-pixel-free authored changes make each timing frame distinct without
    # breaking the approved silhouette or the central torso anchor.
    if 4 <= index <= 10:
        steam_x = 20 + (index - 4) * 2
        draw.rectangle((steam_x, 106 - (index % 3) * 4, steam_x + 1, 111 - (index % 3) * 4), fill="#bdd6ce")
    if 16 <= index < 28:
        draw.rectangle((112 + index % 3, 70 + index % 4, 114 + index % 3, 72 + index % 4), fill=BRUISE)
    return image


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for index in range(32):
        if index < 16:
            stage = 0
        elif index < 20:
            stage = 1
        elif index < 24:
            stage = 2
        elif index < 28:
            stage = 3
        else:
            stage = 4
        image = stylized_frame(index) if REFERENCE.is_file() else (terminal(index) if stage == 4 else seated(index, stage))
        image.save(OUT / f"female_{index:02d}.png")
    print("Wrote 32 female leader frames")


if __name__ == "__main__":
    main()

"""Original 1:1 pixel cutouts for the two office leaders. No external artwork."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'art'
OUT.mkdir(parents=True, exist_ok=True)
INK = '#29283f'
SKIN = '#e9a77c'
LIT = '#ffd4a0'
SHADE = '#bf745e'
TEAL = '#438b8b'

def canvas(w, h):
    im = Image.new('RGBA', (w, h))
    return im, ImageDraw.Draw(im)

def poly(d, points, fill, outline=INK):
    d.polygon(points, fill=fill)
    if outline:
        d.line(points + [points[0]], fill=outline, width=2)

def rect(d, box, fill, outline=None, width=1):
    d.rectangle(box, fill=fill, outline=outline, width=width)

def save(im, name):
    im.save(OUT / (name + '.png'))

for role in ('male', 'female'):
    for stage in range(5):
        im, d = canvas(64, 66)
        # Short, voluminous cut of hair behind the face.
        if role == 'female':
            poly(d, [(7,17),(12,7),(24,3),(44,4),(55,12),(59,26),(57,48),(49,56),(14,55),(5,43)], '#493b49')
            d.line([(10,31),(10,18),(16,11),(29,8),(44,10),(51,18)], fill='#796071', width=3)
        # Ears and a broad, square-rounded caricature face.
        for x in (4, 51):
            poly(d, [(x,29),(x+7,28),(x+8,42),(x+3,44),(x,39)], SKIN)
            rect(d, (x+3,33,x+5,38), SHADE)
        poly(d, [(13,15),(21,10),(42,10),(51,18),(53,44),(47,54),(38,59),(23,59),(13,53),(9,43),(9,26)], SKIN)
        poly(d, [(14,22),(20,15),(41,14),(48,20),(48,39),(42,48),(19,48),(13,40)], LIT, None)
        rect(d, (15,37,19,43), '#efb389')
        rect(d, (43,37,47,43), '#e5957b')
        if role == 'male':
            poly(d, [(10,29),(8,20),(13,13),(18,12),(17,24),(14,30)], '#50454c')
            poly(d, [(45,13),(51,17),(54,26),(50,33),(46,25)], '#50454c')
            d.line([(18,12),(23,8),(34,7),(41,10)], fill=INK, width=2)
            d.line([(21,12),(28,10),(36,11)], fill='#a16c56', width=1)
            d.line([(18,20),(26,18),(37,18),(42,20)], fill='#d39674', width=1)
        else:
            poly(d, [(10,28),(9,19),(15,10),(27,7),(43,9),(51,16),(52,27),(45,25),(39,16),(30,20),(20,22)], '#493b49')
            d.line([(15,17),(23,12),(36,12)], fill='#987481', width=2)
            d.line([(42,15),(47,19),(49,25)], fill='#705764', width=2)
            rect(d, (6,43,9,48), '#f5c86d', INK)
            rect(d, (54,43,57,48), '#f5c86d', INK)
            rect(d, (7,44,8,46), '#fff1be')
        # Independent expression frames permit real blinks without shrinking the face.
        if stage == 0:
            d.line([(16,29),(25,27)], fill=INK, width=2)
            d.line([(37,27),(46,29)], fill=INK, width=2)
            rect(d, (21,32,24,35), INK)
            rect(d, (38,32,41,35), INK)
            d.line([(24,49),(31,51),(39,48)], fill=INK, width=2)
            rect(d, (28,49,36,49), '#fff0d2')
        elif stage == 1:
            d.line([(16,27),(26,31)], fill=INK, width=2)
            d.line([(36,31),(46,27)], fill=INK, width=2)
            rect(d, (21,33,24,36), INK)
            rect(d, (38,33,41,36), INK)
            d.line([(26,50),(34,47),(39,49)], fill=INK, width=2)
        else:
            d.line([(16,30),(25,26)], fill=INK, width=2)
            d.line([(37,26),(46,30)], fill=INK, width=2)
            d.line([(18,34),(24,36),(19,38)], fill=INK, width=2)
            rect(d, (39,33,42,37), INK)
            poly(d, [(26,48),(34,46),(39,49),(37,53),(28,53)], '#805057')
            rect(d, (29,48,35,49), '#fff0d2')
        # Nose bridges and nostril set the central expression.
        d.line([(31,33),(30,40),(34,41)], fill=SHADE, width=2)
        rect(d, (29,39,32,40), '#f7bf91')
        if role == 'female':
            d.line([(12,32),(15,31),(27,31),(28,39),(16,40),(14,33)], fill=INK, width=2)
            d.line([(35,31),(47,31),(48,38),(36,40),(35,31)], fill=INK, width=2)
            d.line([(28,33),(34,33)], fill=INK, width=2)
            rect(d, (17,32,20,32), '#fff1dc')
            rect(d, (38,32,41,32), '#fff1dc')
        if stage >= 1:
            rect(d, (43,40,49,44), '#be7a88')
            rect(d, (45,41,49,43), '#956b89')
            d.line([(14,44),(17,42)], fill=SHADE, width=1)
        if stage >= 2:
            rect(d, (15,34,20,40), '#9c7999')
            d.line([(15,36),(23,37)], fill=INK, width=2)
            poly(d, [(39,43),(48,46),(47,50),(38,47)], '#f8d69e', '#ad8466')
            d.line([(42,44),(42,48)], fill='#c38f73', width=1)
            rect(d, (29,40,34,44), '#d88380')
        if stage >= 3:
            poly(d, [(16,15),(11,7),(20,11),(22,3),(26,11)], '#50454c' if role == 'male' else '#493b49')
            d.line([(36,10),(41,3),(41,12),(49,7),(48,17)], fill=INK, width=2)
            rect(d, (44,33,46,39), '#86c4cf')
            rect(d, (44,34,45,35), '#d0f5e8')
            d.line([(21,51),(24,54)], fill='#a65f71', width=2)
        if stage == 4:
            for x in (19, 42):
                rect(d, (x,39,x+2,47), '#85c8d8')
                rect(d, (x,40,x,44), '#d1f7ed')
            d.line([(26,51),(31,49),(36,51)], fill=INK, width=2)
        save(im, f'{role}_head_{stage}')
        # White shirt and ochre tie vs tailored teal suit and gold brooch.
        im, d = canvas(48, 47)
        poly(d, [(15,1),(32,1),(41,7),(45,34),(40,44),(7,44),(3,34),(7,7)], '#e8e6d5' if role == 'male' else '#397579')
        poly(d, [(10,8),(18,5),(29,5),(38,9),(37,32),(12,32)], '#fff4da' if role == 'male' else '#589e96', None)
        poly(d, [(15,2),(24,8),(32,2),(30,15),(18,15)], '#fff2d9')
        if role == 'male':
            poly(d, [(22,10),(26,10),(28,29),(24,35),(20,29)], '#c77855')
            d.line([(24,14),(25,27)], fill='#edb774', width=2)
            rect(d, (32,19,39,21), '#8c9a9c')
            rect(d, (34,17,35,21), '#b85f64')
            rect(d, (8,35,40,41), '#565367')
            rect(d, (8,36,40,38), '#353446')
            rect(d, (22,35,27,39), '#edbd72', INK)
        else:
            poly(d, [(14,4),(22,14),(18,25),(9,10)], '#72b4a7')
            poly(d, [(33,4),(25,15),(29,26),(40,10)], '#24565f')
            rect(d, (25,28,26,29), '#f7d28e')
            rect(d, (25,35,26,36), '#f7d28e')
            rect(d, (34,17,36,19), '#f7d28e')
        if stage >= 2:
            poly(d, [(7,24),(15,26),(10,30),(16,33),(7,34)], SKIN)
            d.line([(33,29),(36,25),(37,32)], fill=INK, width=1)
        if stage >= 3:
            poly(d, [(30,39),(34,32),(38,39),(40,35),(40,44),(30,44)], SKIN)
            d.line([(18,21),(15,26),(20,29)], fill=SHADE, width=2)
        if stage == 4:
            poly(d, [(17,10),(21,19),(15,21),(20,27),(13,25),(13,16)], SKIN)
        save(im, f'{role}_torso_{stage}')
    for part in ('arm','forearm','leg'):
        im, d = canvas(18, 26)
        color = '#ede9d5' if role == 'male' else '#438b8b'
        if part == 'leg':
            poly(d, [(3,1),(14,1),(14,18),(17,20),(17,24),(1,24),(1,20),(3,18)], '#55516a')
            rect(d, (5,4,7,17), '#797185')
            rect(d, (2,20,16,24), INK)
            rect(d, (3,20,9,20), '#817989')
        elif part == 'arm':
            poly(d, [(5,1),(12,1),(16,7),(14,22),(3,22),(1,9)], color)
            rect(d, (4,7,6,19), '#fff3dc' if role == 'male' else '#73b5a5')
            rect(d, (4,21,13,23), '#a9b9b3')
        else:
            poly(d, [(3,1),(13,1),(14,12),(16,16),(13,23),(5,24),(1,20),(2,14)], SKIN)
            rect(d, (4,4,7,18), LIT)
            d.line([(10,18),(12,20),(13,17)], fill=SHADE, width=1)
        save(im, f'{role}_{part}')

    # Bent trouser leg: upright thigh, rounded knee on the floor, shin folded back.
    im, d = canvas(28, 28)
    poly(d, [(13,1),(25,1),(25,17),(23,23),(7,25),(2,23),(2,18),(13,16)], '#55516a')
    rect(d, (16,3,19,14), '#797185')
    d.line([(17,17),(21,17),(22,20),(19,22)], fill='#a396a4', width=2)
    rect(d, (1,21,10,25), INK)
    rect(d, (3,21,8,22), '#817989')
    save(im, f'{role}_kneel_left')
    save(im.transpose(Image.Transpose.FLIP_LEFT_RIGHT), f'{role}_kneel_right')

for stage in range(5):
    im, d = canvas(118, 126)
    if stage < 4:
        poly(d, [(28,3),(85,3),(95,10),(96,63),(88,77),(26,77),(18,64),(18,13)], '#304958')
        poly(d, [(30,8),(81,8),(89,14),(88,59),(82,66),(31,66),(25,60),(25,16)], '#527c80')
        d.line([(31,12),(78,12),(85,18)], fill='#85a9a0', width=2)
        d.line([(29,24),(84,24)], fill='#365a63', width=2)
        d.line([(56,27),(56,62)], fill='#365a63', width=1)
        for x in (6, 99):
            rect(d, (x,57,x+12,63), '#516270', INK, 2)
            rect(d, (x+4,63,x+8,83), '#424453', INK)
        poly(d, [(23,72),(88,72),(95,82),(91,90),(21,90),(17,84)], '#3d5967')
        rect(d, (52,90,61,113), '#8d9599', INK, 2)
        d.line([(20,120),(56,110),(93,120)], fill=INK, width=5)
        d.line([(23,118),(56,109),(90,118)], fill='#8c9499', width=2)
        for x in (18, 54, 90):
            rect(d, (x,119,x+7,124), INK)
        if stage >= 3:
            d.line([(80,7),(74,24),(82,31),(73,49)], fill=INK, width=2)
            rect(d, (76,26,79,31), '#ad9f87')
    else:
        poly(d, [(6,107),(35,98),(62,115),(53,122),(17,120)], '#527c80')
        d.line([(13,108),(34,104),(52,115)], fill='#85a9a0', width=2)
        poly(d, [(75,109),(91,96),(111,112),(107,122),(89,120)], '#304958')
        d.line([(6,121),(40,117)], fill='#8d9599', width=3)
        rect(d, (7,120,13,124), INK)
    save(im, f'chair_{stage}')

for stage in range(5):
    im, d = canvas(150, 68)
    if stage < 4:
        poly(d, [(8,6),(140,6),(148,16),(148,23),(2,23),(2,16)], '#dcad70')
        d.line([(10,9),(137,9),(142,15)], fill='#ffdfa0', width=2)
        rect(d, (4,18,146,24), '#a46c50', INK, 2)
        rect(d, (10,25,20,64), '#986049', INK, 2)
        rect(d, (129,25,139,64), '#986049', INK, 2)
        rect(d, (13,26,16,60), '#c18b5b')
        rect(d, (22,25,127,55), '#c18b5b', INK, 2)
        rect(d, (25,27,124,29), '#dfac70')
        rect(d, (30,35,62,48), '#ac7855', '#d69e63')
        rect(d, (88,35,118,48), '#ac7855', '#d69e63')
        rect(d, (43,38,52,40), '#eac27c', INK)
        rect(d, (99,38,108,40), '#eac27c', INK)
        # Small brass office name plate with glyph-like engraving.
        poly(d, [(62,7),(91,7),(94,16),(59,16)], '#e9c487')
        for x, h in ((65,3),(69,4),(75,2),(80,4),(86,3)):
            rect(d, (x,10,x+1,10+h), '#866749')
        if stage >= 2:
            d.line([(109,23),(106,29),(111,34),(108,39)], fill='#734d49', width=1)
        if stage >= 3:
            d.line([(70,18),(65,26),(73,34),(68,41),(77,53)], fill=INK, width=2)
            d.line([(68,34),(61,36),(59,43)], fill=INK, width=1)
            poly(d, [(131,52),(137,49),(139,62),(133,60)], '#ecc08a')
    else:
        poly(d, [(1,52),(45,39),(68,51),(63,61),(4,63)], '#c18b5b')
        d.line([(6,54),(43,44),(60,53)], fill='#f1c88b', width=2)
        poly(d, [(91,43),(111,45),(142,55),(146,63),(89,62),(79,58)], '#c18b5b')
        d.line([(94,47),(134,57)], fill='#f1c88b', width=2)
        poly(d, [(21,56),(25,42),(32,44),(30,63)], '#986049')
        poly(d, [(126,58),(135,40),(141,43),(134,63)], '#986049')
        poly(d, [(58,63),(65,57),(71,64)], '#e9bd7d')
        rect(d, (110,64,116,66), '#a77454', INK)
    save(im, f'desk_{stage}')

im, d = canvas(42, 40)
poly(d, [(2,2),(36,2),(39,5),(39,29),(2,29)], '#414d61')
rect(d, (5,5,35,24), '#6ba4a5', INK)
rect(d, (7,7,33,9), '#a6cfbd')
rect(d, (8,12,18,21), '#477981')
for y in (12,16,20):
    rect(d, (21,y,31,y+1), '#c0dbbd')
rect(d, (17,30,23,34), '#747f88', INK)
poly(d, [(12,35),(28,35),(32,38),(8,38)], '#76838a')
rect(d, (33,27,34,27), '#cbe792')
save(im, 'monitor')
im, d = canvas(37, 10)
poly(d, [(4,1),(32,1),(36,8),(1,8)], '#abb7ac')
for y in (3,5):
    for x in range(6,31,4):
        rect(d, (x,y,x+1,y), '#596c74')
rect(d, (12,7,24,7), '#596c74')
save(im, 'keyboard')
im, d = canvas(23, 12)
poly(d, [(1,4),(18,1),(22,7),(4,10)], '#b87563')
poly(d, [(2,2),(17,0),(20,5),(4,8)], '#fff0cf')
for y in (3,5):
    d.line([(6,y),(15,y-1)], fill='#b0b9a8', width=1)
save(im, 'papers')
im, d = canvas(18, 19)
rect(d, (12,5,17,13), '#dce2ce', INK, 2)
poly(d, [(2,3),(13,3),(12,16),(4,16)], '#eee9cd')
rect(d, (4,5,10,7), '#75554b')
rect(d, (4,9,5,13), '#ffffe4')
rect(d, (7,10,10,12), '#d79069')
save(im, 'cup')
im, d = canvas(18, 9)
poly(d, [(1,3),(5,1),(14,1),(17,4),(14,8),(4,8)], '#789899')
rect(d, (5,3,13,5), '#425b69')
d.line([(8,1),(14,2)], fill='#f8e1b6', width=2)
rect(d, (14,2,16,3), '#ec8b60')
save(im, 'ashtray')
im, d = canvas(15, 6)
rect(d, (1,2,12,4), '#fff0cb', INK)
rect(d, (1,2,3,4), '#bb875f')
rect(d, (12,2,13,4), '#f09868')
save(im, 'cigarette')
im, d = canvas(25, 16)
poly(d, [(2,14),(4,7),(9,3),(17,3),(22,8),(23,14)], '#cc7b8b')
d.line([(6,8),(10,5),(16,5)], fill='#f6b2a9', width=2)
d.line([(11,0),(11,2)], fill=INK, width=1)
save(im, 'bump')
im, d = canvas(12, 8)
poly(d, [(1,2),(4,1),(9,2),(10,4),(8,6),(4,7),(1,5)], '#9d6077')
d.line([(4,2),(8,3),(9,4)], fill='#e59aaa', width=1)
save(im, 'chin')
im, d = canvas(48, 48)
poly(d, [(21,20),(28,20),(29,45),(21,45)], '#c08e62')
rect(d, (23,26,25,42), '#ffcf85')
poly(d, [(4,5),(10,2),(37,2),(44,7),(44,21),(38,25),(9,25),(4,20)], '#ce6b79')
rect(d, (10,4,36,7), '#ffbaa8')
rect(d, (7,8,12,20), '#e9858a')
rect(d, (35,7,40,20), '#9f536e')
rect(d, (16,8,30,20), '#efa18c')
d.line([(23,9),(21,14),(26,14),(23,19)], fill='#fff0bb', width=2)
save(im, 'hammer')
im, d = canvas(48, 48)
poly(d, [(8,12),(13,6),(28,4),(37,9),(40,19),(36,29),(31,34),(30,42),(13,42),(12,32),(7,28)], '#c56379')
poly(d, [(10,13),(15,8),(28,7),(33,11),(33,23),(18,27),(11,23)], '#ed8d91', None)
d.line([(14,12),(20,10),(27,10)], fill='#ffc6ae', width=3)
poly(d, [(29,22),(34,18),(40,21),(40,29),(34,34),(27,31)], '#db7a86')
rect(d, (13,34,30,41), '#75b4ab', INK, 2)
rect(d, (16,36,27,37), '#c5e2c1')
save(im, 'gloves')
print(f'Wrote {len(list(OUT.glob("*.png")))} original pixel-art cutouts to {OUT}')

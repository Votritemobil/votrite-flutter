"""Compose App Store screenshots: a captioned frame around each real app screen.

Input  : raw/*.png captured from the actual VotRite build (1290x2796)
Output : out/NN_name.png at 1290x2796, Apple's 6.7"/6.9" iPhone size
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
RAW, OUT = os.path.join(HERE, "raw"), os.path.join(HERE, "out")
os.makedirs(OUT, exist_ok=True)

W, H = 1290, 2796
NAVY = (11, 45, 94)
BLUE = (24, 101, 189)
SUB = (186, 214, 247)

BOLD = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
REG = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
CJK = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"

SHOTS = [
    ("03_ballots",        "Your election,\non your own phone",      "Pick your ballot and start"),
    ("04_pin",            "No account.\nNo password.",              "Just the PIN your election office gave you"),
    ("07_race_selected",  "One race at a time",                     "Large targets, clear labels, nothing buried"),
    ("11_review",         "Check everything\nbefore you cast",      "Tap any line to change it"),
    ("13_finish",         "Confirmed on screen",                    "You watch your ballot being recorded"),
    ("02_mode",           "Touch, or full\nvoice guidance",         "Choose how you vote before you start"),
    ("10_vi_settings",    "Built for voters who\ncan't see the screen", "High contrast, large text, adjustable speech"),
    ("09_proposition",    "Propositions in\nplain language",        "The question, then Yes or No"),
    ("01_language",       "English  ·  Espanol  ·  Chinese",        "Vote in the language you read"),
]


def background():
    """Vertical navy-to-blue gradient, built small and scaled up."""
    g = Image.new("RGB", (1, H))
    d = ImageDraw.Draw(g)
    for y in range(H):
        t = y / H
        d.point((0, y), fill=tuple(int(NAVY[i] + (BLUE[i] - NAVY[i]) * t) for i in range(3)))
    return g.resize((W, H))


def rounded(img, r):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], r, fill=255)
    out = Image.new("RGBA", img.size)
    out.paste(img, (0, 0), mask)
    return out


def fit_font(text, path, size, max_w):
    """Shrink until the widest line fits."""
    while size > 30:
        f = ImageFont.truetype(path, size)
        if max(f.getbbox(l)[2] - f.getbbox(l)[0] for l in text.split("\n")) <= max_w:
            return f
        size -= 2
    return ImageFont.truetype(path, size)


def compose(src, head, sub, dest):
    bg = background()
    d = ImageDraw.Draw(bg)

    margin = 90
    hf = fit_font(head, BOLD, 82, W - 2 * margin)
    lines = head.split("\n")
    lh = int(hf.size * 1.18)
    y = 130
    for l in lines:
        w = d.textlength(l, font=hf)
        d.text(((W - w) / 2, y), l, font=hf, fill=(255, 255, 255))
        y += lh

    sf = fit_font(sub, REG, 46, W - 2 * margin)
    y += 18
    w = d.textlength(sub, font=sf)
    d.text(((W - w) / 2, y), sub, font=sf, fill=SUB)
    y += int(sf.size * 1.5)

    # device: as wide as fits under the caption without touching the bottom
    top = max(y + 40, 560)
    avail_h = H - top - 90
    dw = min(960, int(avail_h * W / H))
    dh = int(dw * H / W)
    if top + dh > H - 90:
        dh = H - 90 - top
        dw = int(dh * W / H)

    shot = Image.open(os.path.join(RAW, src + ".png")).convert("RGB").resize((dw, dh), Image.LANCZOS)
    shot = rounded(shot, 42)

    # soft shadow under the device
    sh = Image.new("RGBA", (dw + 120, dh + 120), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([60, 66, dw + 60, dh + 60], 42, fill=(0, 0, 0, 120))
    sh = sh.filter(ImageFilter.GaussianBlur(26))
    x = (W - dw) // 2
    bg.paste(sh, (x - 60, top - 60), sh)
    bg.paste(shot, (x, top), shot)

    bg.save(os.path.join(OUT, dest), "PNG")
    return dest, dw, dh


if __name__ == "__main__":
    for i, (src, head, sub) in enumerate(SHOTS, 1):
        print(compose(src, head, sub, f"{i:02d}_{src.split('_', 1)[1]}.png"))

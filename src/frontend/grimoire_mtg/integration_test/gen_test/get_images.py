import os
import random
import requests
from PIL import Image
from io import BytesIO
import re
import sys
import shutil

"""
script usage:
1. run from main folder of repo (lazy i know)

2. Format: Script_name destination_name type num_cards num_backgrounds

default destination is test

3. type:
- only_card -> no background
- hd -> full hd with background
-  d -> 800x600
- mono_bg -> white background

default type is hd


default num_cards is 200

default num_backgorunds is 50
"""



OUTPUT_DIR = "src/frontend/grimoire_mtg/assets/" + ( sys.argv[1] if len(sys.argv) >= 2 else "test" )
CARD_DIR = os.path.join(OUTPUT_DIR, "cards")
BG_DIR = os.path.join(OUTPUT_DIR, "backgrounds")
FINAL_DIR = OUTPUT_DIR

QUALITY = sys.argv[2] if len(sys.argv) >= 3 else "hd"

NUM_CARDS = int(sys.argv[3]) if len(sys.argv) >= 4 else 200
NUM_BACKGROUNDS = int(sys.argv[4]) if len(sys.argv) >= 5 else 50

HEADERS = {
    "User-Agent": "MTG-OCR-Dataset-Generator/4.0"
}
if os.path.exists(OUTPUT_DIR):
    shutil.rmtree(OUTPUT_DIR)

os.makedirs(FINAL_DIR , exist_ok=True)
os.makedirs(CARD_DIR, exist_ok=True)
os.makedirs(BG_DIR, exist_ok=True)


def download_image(url):
    r = requests.get(url, headers=HEADERS, timeout=15)
    r.raise_for_status()
    return Image.open(BytesIO(r.content))


def sanitize_filename(name):
    name = name.lower()
    name = re.sub(r"[^a-z0-9]+", "_", name)
    return name.strip("_")


# ✅ FILTERED BULK API APPROACH
def fetch_cards_bulk(n):
    print("Fetching bulk card data from Scryfall...")

    bulk_data = requests.get("https://api.scryfall.com/bulk-data", headers=HEADERS).json()
    default_cards = next(x for x in bulk_data["data"] if x["type"] == "default_cards")
    download_uri = default_cards["download_uri"]

    print("Downloading full card dataset...")
    data = requests.get(download_uri, headers=HEADERS).json()

    print(f"Total cards available: {len(data)}")

    random.shuffle(data)

    paths = []
    used_names = set()

    for card in data:
        if len(paths) >= n:
            break

        try:
            # ✅ FILTERS
            if card.get("lang") != "en":
                continue

            if card.get("digital") is True:
                continue

            if card.get("layout") not in ["normal", "transform", "modal_dfc"]:
                continue

            if card.get("set_type") in ["token", "memorabilia"]:
                continue

            # must have image
            if "image_uris" not in card and "card_faces" not in card:
                continue

            card_name = card.get("name", "unknown_card")
            safe_name = sanitize_filename(card_name)

            base_name = safe_name
            counter = 1
            while safe_name in used_names:
                safe_name = f"{base_name}_{counter}"
                counter += 1

            # image selection
            if "image_uris" in card:
                url = card["image_uris"].get("png") or card["image_uris"].get("large")
            else:
                url = card["card_faces"][0]["image_uris"].get("png")

            img = download_image(url).convert("RGBA")

            path = os.path.join(CARD_DIR, f"{safe_name}.png")
            img.save(path)

            used_names.add(safe_name)
            paths.append(path)

            if len(paths) % 20 == 0:
                print(f"Downloaded {len(paths)}/{n} cards")

        except Exception as e:
            print("Skip card:", e)

    print(f"Finished: {len(paths)} cards")
    return paths


def fetch_backgrounds(n):
    print("Downloading random backgrounds...")
    paths = []

    main_url = "https://picsum.photos/1080/1920?random="

    if QUALITY == "ld":
        main_url = "https://picsum.photos/800/600?random="

    for i in range(n):
        try:
            url = main_url + str(i)
            img = download_image(url).convert("RGB")

            path = os.path.join(BG_DIR, f"bg_{i}.jpg")
            img.save(path, "JPEG")
            paths.append(path)

        except Exception as e:
            print("Error fetching background:", e)

    return paths


def compose_images(cards, bgs):
    print("Composing final images...")
    if len(bgs) == 0:
        try:
            card = Image.open(card_path).convert("RGBA")
            base_name = os.path.splitext(os.path.basename(card_path))[0]
            out_path = os.path.join(FINAL_DIR, f"{base_name}.png")

            card.convert("RGB").save(out_path)

            if i % 10 == 0:
                print(f"Generated {i} images...")

        except Exception as e:
            print("Error composing image:", e)
        return

    for i, card_path in enumerate(cards):
        try:
            bg_path = random.choice(bgs)

            bg = Image.open(bg_path).convert("RGBA")
            card = Image.open(card_path).convert("RGBA")

            scale = random.uniform(0.9, 1.1)
            card = card.resize((int(card.width * scale), int(card.height * scale)))

            angle = random.uniform(-15, 15)
            card = card.rotate(angle, expand=True)

            max_x = max(0, bg.width - card.width)
            max_y = max(0, bg.height - card.height)

            x = random.randint(0, max_x)
            y = random.randint(0, max_y)

            bg.paste(card, (x, y), card)

            base_name = os.path.splitext(os.path.basename(card_path))[0]
            out_path = os.path.join(FINAL_DIR, f"{base_name}.png")

            bg.convert("RGB").save(out_path)

            if i % 10 == 0:
                print(f"Generated {i} images...")

        except Exception as e:
            print("Error composing image:", e)


if __name__ == "__main__":
    cards = fetch_cards_bulk(NUM_CARDS)
    bgs = []
    if QUALITY != "only_card" and QUALITY != "mono_bg":
        bgs = fetch_backgrounds(NUM_BACKGROUNDS)
    if QUALITY == "mono_bg":
        img = download_image("https://placehold.co/1080x1920/FFFFFF/FFFFFF").convert("RGB")
        path = os.path.join(BG_DIR, f"bg_{0}.jpg")
        img.save(path, "JPEG")
        bgs.append(path)
    compose_images(cards, bgs)
    shutil.rmtree(CARD_DIR)
    shutil.rmtree(BG_DIR)
    print("Done!")
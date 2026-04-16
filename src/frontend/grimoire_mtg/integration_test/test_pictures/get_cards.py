import os
import random
import requests
from PIL import Image
from io import BytesIO
import re

OUTPUT_DIR = "output"
CARD_DIR = os.path.join(OUTPUT_DIR, "cards")
BG_DIR = os.path.join(OUTPUT_DIR, "backgrounds")
FINAL_DIR = os.path.join(OUTPUT_DIR, "final")

NUM_CARDS = 200
NUM_BACKGROUNDS = 50

HEADERS = {
    "User-Agent": "MTG-OCR-Dataset-Generator/4.0"
}

os.makedirs(CARD_DIR, exist_ok=True)
os.makedirs(BG_DIR, exist_ok=True)
os.makedirs(FINAL_DIR, exist_ok=True)


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

            path = os.path.join(CARD_DIR, f"{safe_name}_final.png")
            img.save(path)

            used_names.add(safe_name)
            paths.append(path)

            if len(paths) % 20 == 0:
                print(f"Downloaded {len(paths)}/{n} cards")

        except Exception as e:
            print("Skip card:", e)

    print(f"Finished: {len(paths)} cards")
    return paths


if __name__ == "__main__":
    fetch_cards_bulk(NUM_CARDS)
    print("Done!")
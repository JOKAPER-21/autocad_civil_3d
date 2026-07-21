"""
main.py

Entry point for the X Marker Detector.

Workflow:
    Read Image
        ↓
    Call Detector
        ↓
    Show Result
"""

from pathlib import Path
import cv2

from detector import detect_x_markers
from visualize import show_result


def main():
    # -------------------------------------------------
    # Image Path
    # -------------------------------------------------
    image_path = Path("../images/sample.jpg")

    if not image_path.exists():
        print(f"[ERROR] Image not found:\n{DJI_20260408101416_0011_V.JPG}")
        return

    # -------------------------------------------------
    # Read Image
    # -------------------------------------------------
    image = cv2.imread(str(image_path))

    if image is None:
        print("[ERROR] Unable to read image.")
        return

    print(f"[INFO] Loaded: {image_path.name}")

    # -------------------------------------------------
    # Detect X Markers
    # -------------------------------------------------
    markers = detect_x_markers(image)

    print(f"[INFO] Markers Found: {len(markers)}")

    # -------------------------------------------------
    # Display Result
    # -------------------------------------------------
    show_result(image, markers)


if __name__ == "__main__":
    main()
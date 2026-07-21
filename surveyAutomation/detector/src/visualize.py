"""
visualize.py
"""

import cv2


def show_result(image, markers):
    """
    Display image and draw detected markers.
    """

    output = image.copy()

    for marker in markers:
        x = marker["x"]
        y = marker["y"]

        cv2.circle(output, (x, y), 8, (0, 0, 255), 2)

    cv2.imshow("X Marker Detector", output)
    cv2.waitKey(0)
    cv2.destroyAllWindows()
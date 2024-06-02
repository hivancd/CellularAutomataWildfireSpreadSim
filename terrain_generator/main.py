from PIL import Image
import numpy as np
import matplotlib.pyplot as plt


def cos_similarity(v1, v2):
    dot_product = 0
    norm_v1 = 0
    norm_v2 = 0
    for i in range(len(v1)):
        dot_product += v1[i] * v2[i]
        norm_v1 += v1[i] ** 2
        norm_v2 += v2[i] ** 2
    return dot_product / ((norm_v1 * norm_v2) ** 0.5)


def distance(v1, v2):
    return sum([(v1[i] - v2[i]) ** 2 for i in range(len(v1))]) ** 0.5


def get_base_color(pixel):
    base_colors = [
        (89, 93, 66),
        (30, 144, 235),
        (57, 102, 21),
    ]
    pixel = np.array(pixel, dtype=np.float32) / 255
    max_similarity = 0
    closest_color = 0
    for color, i in zip(base_colors, range(len(base_colors))):
        color = np.array(color, dtype=np.float32) / 255
        similarity = cos_similarity(pixel, color) - distance(pixel, color)
        # print("similarity:", "i", i, ", ", similarity)
        if similarity > max_similarity:
            max_similarity = similarity
            # print("Max:", max_similarity)
            closest_color = i
    return closest_color


im = Image.open("map1.ppm")  # Can be many different formats.
matrix_result = np.zeros((im.size[0], im.size[1]))
array_result = []
for j in range(0, im.size[1]):
    for i in range(0, im.size[0]):
        matrix_result[i][j] = get_base_color(im.getpixel((i, j)))
        array_result.append(get_base_color(im.getpixel((i, j))))
im.save("map1.png")
file = open("map.txt", "w")

for line in array_result:
    file.write(str(line))
plt.imsave("map.png", matrix_result, cmap="tab20")

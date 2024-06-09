import time
import sys
import os

from modules.short_class_import import BoardBox, Seed
from modules.decisional import generate_box
from modules.encyclopedia_functions import encyclopedia_creation
from modules.image_creation import write_image_header, write_image_body
from modules.trees_generation import generate_trees
from modules.utilities import is_integer, print_progress

from PIL import Image


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

def get_base_color_i(pixel):
    max=-1
    for i in range(3):
        if pixel[i]>max:
            max = pixel[i]
            closest_color=i+1
    if closest_color==2:
        closest_color=3
    elif closest_color==3:
        closest_color=2

    return closest_color

def get_base_color(pixel):
    base_colors = [
        (89, 93, 66),  # ground
        (30, 144, 235),  # water
        (57, 102, 21),  # forest
        (160, 173, 120),  # grass
        (128, 168, 104),  # grass
    ]
    pixel = [pixel[0] / 255, pixel[1] / 255, pixel[2] / 255]
    max_similarity = 0
    closest_color = 0
    for color, i in zip(base_colors, range(len(base_colors))):
        color = [color[0] / 255, color[1] / 255, color[2] / 255]
        similarity = cos_similarity(pixel, color) - distance(pixel, color)
        if similarity > max_similarity:
            max_similarity = similarity
            closest_color = i + 1
    return closest_color


def create_map_ppm(filename, w, h, seed):

    print_progress_opt = "idlelib" not in sys.modules

    if seed == None:
        seed = Seed()

    print("Seed of the map : " + str(seed) + "\n")
    encyclopedia = encyclopedia_creation()

    destination_file = open(filename + ".ppm", "w")
    write_image_header(destination_file, h, w, str(seed))

    for line_number in range(h):  # L'image se crée ligne par ligne

        chunk = BoardBox.create_empty_board(w, 1)

        for column_number in range(w):

            chunk.set_element(
                value=generate_box(encyclopedia, column_number, line_number, seed),
                x=column_number,
                y=0,
            )

        write_image_body(destination_file, chunk)

        if print_progress_opt:
            print_progress("Creation of the map : ", (line_number + 1) / h)

    destination_file.close()
    print("")
    print("Done")


def create_map_txt(f_name):
    im = Image.open(f_name + ".ppm")  # Can be many different formats.
    im.save("map.png")
    array_result = []
    for j in range(0, im.size[1]):
        for i in range(0, im.size[0]):
            array_result.append(get_base_color(im.getpixel((i, j))))

    file = open(f_name + ".txt", "w")

    for line in array_result:
        file.write(str(line))


def create_map(w, h, seed=None):
    create_map_ppm("map", w, h, seed)
    create_map_txt("map")

if __name__=="__main__":
    # im = Image.open("./CellularAutomataWildfireSpreadSim/terrain_generator/Isla_de_la_Juventud.jpg")  # Can be many different formats.
    # array_result = []
    # for i in [int(h*(922/256))for h in range(256)]:
    #     for j in [int(h*(922/256))for h in range(256)]:
    #         array_result.append(get_base_color_i(im.getpixel((i, j))))

    # file = open("IslaJuventud" + ".txt", "w")

    # for line in array_result:
    #     file.write(str(line))

    x = int(sys.argv[1])
    y = int(sys.argv[2])
    create_map(x, y)
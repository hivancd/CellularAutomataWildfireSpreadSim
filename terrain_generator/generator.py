import time
import sys
import os

from modules.short_class_import import BoardBox, Seed

from modules.decisional import generate_box
from modules.encyclopedia_functions import encyclopedia_creation
from modules.image_creation import write_image_header, write_image_body
from modules.trees_generation import generate_trees
from modules.utilities import is_integer, print_progress

def create_map(filename,w,h, seed=None):
    
    print_progress_opt = ("idlelib" not in sys.modules)
    
    if seed==None:
        seed = Seed()
    
    print("Seed of the map : " + str(seed) + "\n")
    encyclopedia = encyclopedia_creation()

    destination_file = open(filename+".ppm", "w")
    write_image_header(destination_file, h, w, str(seed))
    
    for line_number in range(h):    # L'image se crée ligne par ligne

        chunk = BoardBox.create_empty_board(w, 1)

        for column_number in range(w):

            chunk.set_element(
                value=generate_box(
                    encyclopedia,
                    column_number,
                    line_number,
                    seed
                ),
                x=column_number,
                y=0
            )

        write_image_body(destination_file, chunk)

        if print_progress_opt:
            print_progress(
                "Creation of the map : ", (line_number + 1) / h)

    destination_file.close()
    print("")
    print("Done")
    
os.system("mkdir maps")
for i in range(5):
    create_map("./maps/map"+str(i),256,256)
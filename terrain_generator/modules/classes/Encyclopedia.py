# ==========================================================
# INFORMATIONS SUR CE PACKAGE :
# -----------------------------
# UTILITÉ DE SON CONTENU :
# Définir la classe Encyclopedia
# -----------------------------
# CONTENU :
# + __slots__
# + HINTS
# + __init__()
# + GETTERS
# + SETTERS
# + get_color()
# + get_hexadecimal()
# + set_biome()
# + __str__()
# ==========================================================

from typing import Dict, List

from modules.classes.Tree import Tree
from modules.classes.Biome import Biome

from modules.settings import DEBUG_MOD
from modules.utilities import check_attribute_type_set


class Encyclopedia:
    ###############################################################
    ########################## __SLOTS__ ##########################
    ###############################################################
    __slots__ = (
        "_name",
        "_biomes"
    )

    ###############################################################
    ############################ HINTS ############################
    ###############################################################
    _name: str
    _biomes: Dict[str, Biome]

    ###############################################################
    ########################## __INIT__ ###########################
    ###############################################################
    def __init__(self, name: str, biomes: Dict[str, Biome]) -> None:
        # =============================
        # INFORMATIONS :
        # -----------------------------
        # UTILITÉ :
        # Crée un objet Encyclopedia, caractérisé par :
        # - son nom
        # - les Biomes qu'il répertorie
        # =============================
        self.set_name(name)
        self.set_biomes(biomes)

    ###############################################################
    ########################### GETTERS ###########################
    ###############################################################
    def get_name(self) -> str:
        return self._name

    def get_biomes(self) -> Dict[str, Biome]:
        return self._biomes

    ###############################################################
    ########################### SETTERS ###########################
    ###############################################################
    def set_name(self, name: str) -> None:
        if DEBUG_MOD:
            check_attribute_type_set(
                attribute_to_check=name,
                type_to_check=str,
                name_of_attribute_to_check="_name",
                object_destination=self
            )
        self._name = name

    def set_biomes(self, biomes: Dict[str, Biome]):
        if DEBUG_MOD:
            check_attribute_type_set(
                attribute_to_check=biomes,
                type_to_check=dict,
                name_of_attribute_to_check="_biomes",
                object_destination=self
            )
            # Vérification que tous les éléments de biomes sont instance de Biome
            iterator = iter(biomes)
            value = next(iterator, None)
            while value is not None and isinstance(biomes[value], Biome):
                value = next(iterator, None)

            if value is not None:
                raise TypeError(
                    "Error: impossible to set _biomes for a " + type(self).__name__ + ":" +
                    "\n_biomes must be a Dict[str, Biome] but at least one item is a " + type(value).__name__ + "."
                )
        self._biomes = biomes

    ###############################################################
    ########################### GET_BIOME #########################
    ###############################################################
    def get_biome(self, name: str) -> Biome:
        # =============================
        # INFORMATIONS :
        # -----------------------------
        # UTILITÉ :
        # Renvoie le biome correspondant
        # =============================
        if DEBUG_MOD:
            if isinstance(name, str):
                try:
                    self.get_biomes()[name]
                except KeyError:
                    raise KeyError(
                        "Error: impossible to get a biome from a " + type(self).__name__ + "._biomes: " +
                        "\nno biome machs with the given name (" + name + ")."
                    )
            else:
                raise TypeError(
                    "Error: impossible to get a biome from a " + type(self).__name__ + "._biomes: " +
                    "\nkey must be a str, but a " + type(name).__name__ + " is given."
                )
        return self.get_biomes()[name]

    ###############################################################
    ########################### SET_BIOME #########################
    ###############################################################
    def set_biome(self, biome: Biome, biome_name: str) -> None:
        if DEBUG_MOD:
            check_attribute_type_set(
                attribute_to_check=biome,
                type_to_check=Biome,
                name_of_attribute_to_check="_biome",
                object_destination=self
            )
        self.get_biomes()[biome_name] = biome

    ###############################################################
    ########################### GET_TREES #########################
    ###############################################################
    def get_trees(self) -> List[Tree]:
        # =============================
        # INFORMATIONS :
        # -----------------------------
        # UTILITÉ :
        # Renvoie une liste de tous les arbres présents dans l'encyclopédie
        # =============================
        trees = []
        for biome in self.get_biomes().values():

            for tree in biome.get_trees():
                trees.append(tree)

        return trees

    ###############################################################
    ################### GET_MAX_HEIGHT_OF_TREES ###################
    ###############################################################
    def get_max_height_of_trees(self) -> int:
        # =============================
        # INFORMATIONS :
        # -----------------------------
        # UTILITÉ :
        # Renvoie la hauteur de l'arbre le plus haut de l'encyclopédie
        # =============================
        max_height = 0

        for tree in self.get_trees():

            if tree.get_height() > max_height:
                max_height = tree.get_height()

        return max_height

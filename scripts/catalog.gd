class_name Catalog
extends RefCounted
## Catalogo de items. Cada item se dibuja por codigo (ver PomponView e ItemArt).

const CATEGORY_LABELS := {
	"hat": "Gorro", "glasses": "Lentes", "shirt": "Ropa",
	"floor": "Piso", "wall": "Pared", "furniture": "Mueble", "deco": "Decoración",
	"bowl_food": "Tazón de comida", "bowl_water": "Tazón de agua",
}
const BOWLS := ["bowl_food", "bowl_water"]   # se usan al comer y beber (reemplazan a los feos de siempre)
const WEARABLE := ["hat", "glasses", "shirt"]
const PLACEABLE := ["furniture", "deco"]   # se colocan y mueven en el cuarto
const SHOP_SIZE := 18   # 8 muebles y adornos, 5 de ropa, 3 paredes o pisos y 2 tazones (SHOP_GROUPS)

# Nivel (dia de vida del Pompon) en el que se desbloquea cada item. Lo que no aparece aqui ya esta
# disponible desde el nivel 1. Las etapas empiezan en los niveles 1, 8, 22 y 52.
const UNLOCK := {
	# gorros
	"hat_bow": 1, "hat_beanie": 2, "hat_cap": 3, "hat_party": 5, "hat_beret": 7, "hat_flower": 8, "hat_straw": 10,
	"hat_ears": 13, "hat_chef": 14, "hat_witch": 26, "hat_halo": 40, "hat_crown": 52,
	# lentes
	"glasses_round": 1, "glasses_sun": 4, "glasses_heart": 9, "glasses_cat": 15, "glasses_pixel": 18,
	"glasses_star": 22, "glasses_rainbow": 35,
	# ropa
	"shirt_red": 1, "shirt_sweater": 2, "shirt_dress": 3, "shirt_star": 5, "shirt_hoodie": 6, "shirt_green": 9,
	"shirt_scarf": 11, "shirt_pajama": 12, "shirt_overalls": 16, "shirt_cape": 20, "shirt_tutu": 22,
	"shirt_raincoat": 28, "shirt_sailor": 32, "shirt_tux": 52,
	# paredes y pisos
	"wall_stars": 1, "wall_blue": 3, "wall_peach": 5, "wall_mint": 7, "wall_clouds": 8, "wall_lilac": 10,
	"wall_hearts": 16, "wall_space": 34,
	"floor_wood": 1, "floor_pink": 4, "floor_mint": 7, "floor_checker": 12, "floor_grass": 14, "floor_carpet": 26,
	# muebles y decoracion
	"furn_plant": 2, "furn_lamp": 3, "furn_teddy": 4, "furn_table": 6, "furn_toybox": 8, "furn_bookshelf": 10,
	"furn_beanbag": 11, "furn_sofa": 12, "furn_globe": 19, "furn_fireplace": 24, "furn_aquarium": 30, "furn_piano": 45,
	"deco_clock": 2, "deco_picture": 4, "deco_window": 6, "deco_rainbow": 7, "deco_garland": 9, "deco_shelf": 13,
	"deco_balloons": 15, "deco_moon": 18,
	# tazones
	"bowl_food_pink": 2, "bowl_water_blue": 2, "bowl_food_mint": 5, "bowl_water_lilac": 6, "bowl_food_star": 10,
	"bowl_water_heart": 12, "bowl_water_fish": 20, "bowl_food_gold": 30,
	# estantes, muebles con superficie y adornos para ponerles encima
	"toy_blocks": 3, "toy_books": 4, "furn_stool": 5, "toy_vase": 6, "furn_dresser": 7, "deco_shelf_long": 8,
	"toy_cactus": 9, "toy_cake": 11, "toy_frame": 13, "furn_desk": 15, "toy_musicbox": 17, "toy_robot": 21,
	"furn_wardrobe": 23, "deco_shelf_cloud": 27, "toy_trophy": 33,
	# decoracion nueva (16/11/2026): muebles por habitacion, alfombras, cosas para colgar y adornos chicos
	"furn_cushions": 1, "rug_round": 1, "toy_alarm": 1, "furn_chair": 2, "furn_nightstand": 2, "toy_lamp": 2,
	"deco_stars": 2, "wall_yellow": 2, "furn_flowers": 3, "deco_mirror": 3, "toy_duck": 3, "floor_lilac": 3,
	"furn_armchair": 4, "deco_plant_hanging": 4, "wall_flowers": 4, "rug_stripes": 5, "toy_teacup": 5,
	"furn_tree": 6, "deco_cloud": 6, "floor_dark": 6, "toy_dino": 7, "deco_board": 8, "toy_fruit": 8,
	"furn_sofa_mint": 8, "furn_tent": 9, "wall_brick": 9, "floor_tiles": 9, "furn_bench": 10, "toy_candles": 10,
	"furn_beanbag_blue": 10, "rug_star": 11, "wall_wood": 11, "furn_easel": 12, "furn_toybox_pink": 13,
	"furn_stove": 14, "furn_fridge": 14, "wall_tiles": 14, "toy_snowglobe": 14, "furn_slide": 16,
	"furn_dresser_mint": 16, "rug_cloud": 17, "deco_map": 19, "furn_fountain": 20, "floor_stones": 20,
	"furn_telescope": 24, "floor_starry": 30,
	# especiales (caros, para ahorrar; siempre a la vista en "Especial")
	"deco_garland_lights": 9, "furn_lamp_stars": 12, "deco_window_magic": 15, "floor_cloud": 18, "furn_sofa_royal": 20,
	"wall_rainbow": 20, "glasses_star_gold": 22, "furn_bed_cloud": 22, "furn_fireplace_crystal": 24,
	"shirt_dress_princess": 25, "bowl_food_diamond": 25, "bowl_water_crystal": 25, "hat_wizard": 26,
	"hat_crown_diamond": 30, "furn_aquarium_rainbow": 30, "floor_gold": 30, "shirt_cape_royal": 35,
	"wall_galaxy": 40, "hat_halo_gold": 42, "furn_piano_gold": 45, "shirt_tux_gold": 52,
}

# Adornos chicos: se pueden apoyar sobre una superficie (mesa, estante, comoda...).
const SMALL := ["furn_plant", "furn_teddy", "furn_globe", "furn_aquarium", "toy_blocks", "toy_books", "toy_vase",
	"toy_cactus", "toy_cake", "toy_frame", "toy_musicbox", "toy_robot", "toy_trophy", "toy_lamp", "toy_alarm",
	"toy_teacup", "toy_dino", "toy_candles", "toy_duck", "toy_snowglobe", "toy_fruit"]

# Alfombras: van en el piso, debajo de todo (se dibujan primero y no tapan los muebles).
const RUGS := ["rug_round", "rug_stripes", "rug_star", "rug_cloud"]

# Superficies donde apoyar cosas: "dy" = altura de la tapa respecto del centro del mueble (px, negativo = arriba)
# y "hw" = mitad del ancho util.
const SURFACES := {
	"furn_table": {"dy": -4.0, "hw": 58.0},
	"furn_bookshelf": {"dy": -95.0, "hw": 55.0},
	"furn_toybox": {"dy": -27.0, "hw": 48.0},
	"furn_piano": {"dy": -75.0, "hw": 80.0},
	"furn_fireplace": {"dy": -77.0, "hw": 80.0},
	"furn_dresser": {"dy": -45.0, "hw": 82.0},
	"furn_desk": {"dy": -25.0, "hw": 96.0},
	"furn_wardrobe": {"dy": -105.0, "hw": 56.0},
	"furn_stool": {"dy": -20.0, "hw": 30.0},
	"furn_nightstand": {"dy": -26.0, "hw": 42.0},
	"furn_stove": {"dy": -40.0, "hw": 70.0},
	"deco_shelf": {"dy": 3.0, "hw": 70.0},
	"deco_shelf_long": {"dy": 5.0, "hw": 116.0},
	"deco_shelf_cloud": {"dy": 2.0, "hw": 86.0},
}

const ITEMS := [
	# --- gorros
	{"id": "hat_beanie", "name": "Gorro de lana", "category": "hat", "price": 12, "color": "ff8fb1"},
	{"id": "hat_cap", "name": "Gorra azul", "category": "hat", "price": 10, "color": "5b8def"},
	{"id": "hat_bow", "name": "Moño rosa", "category": "hat", "price": 8, "color": "ff5e9c"},
	{"id": "hat_crown", "name": "Corona", "category": "hat", "price": 30, "color": "ffd33d"},
	{"id": "hat_party", "name": "Gorro de fiesta", "category": "hat", "price": 14, "color": "b388f5"},
	{"id": "hat_flower", "name": "Corona de flores", "category": "hat", "price": 16, "color": "ff9ecb"},
	{"id": "hat_straw", "name": "Sombrero de paja", "category": "hat", "price": 15, "color": "f2d18b"},
	{"id": "hat_chef", "name": "Gorro de chef", "category": "hat", "price": 14, "color": "f6f6f6"},
	# --- lentes
	{"id": "glasses_round", "name": "Lentes redondos", "category": "glasses", "price": 9, "color": "5a3b2e"},
	{"id": "glasses_sun", "name": "Lentes de sol", "category": "glasses", "price": 14, "color": "222222"},
	{"id": "glasses_star", "name": "Lentes estrella", "category": "glasses", "price": 18, "color": "e84393"},
	{"id": "glasses_heart", "name": "Lentes de corazón", "category": "glasses", "price": 16, "color": "ff4f7b"},
	{"id": "glasses_cat", "name": "Lentes de gato", "category": "glasses", "price": 14, "color": "7b4bb8"},
	# --- ropa
	{"id": "shirt_red", "name": "Remera roja", "category": "shirt", "price": 10, "color": "e74c3c"},
	{"id": "shirt_hoodie", "name": "Buzo azul", "category": "shirt", "price": 16, "color": "34609e"},
	{"id": "shirt_dress", "name": "Vestido rosa", "category": "shirt", "price": 16, "color": "ff9ecb"},
	{"id": "shirt_sweater", "name": "Sweater celeste", "category": "shirt", "price": 14, "color": "8ecae6"},
	{"id": "shirt_green", "name": "Campera verde", "category": "shirt", "price": 14, "color": "5fbf6a"},
	{"id": "shirt_overalls", "name": "Jardinero", "category": "shirt", "price": 18, "color": "4a7fc1"},
	{"id": "shirt_pajama", "name": "Piyama", "category": "shirt", "price": 16, "color": "b7a7e8"},
	{"id": "shirt_raincoat", "name": "Piloto amarillo", "category": "shirt", "price": 18, "color": "ffd54a"},
	{"id": "shirt_tutu", "name": "Tutú", "category": "shirt", "price": 20, "color": "ff8fc8"},
	{"id": "shirt_scarf", "name": "Bufanda", "category": "shirt", "price": 12, "color": "f28c6b"},
	# --- nuevos (se desbloquean al subir de nivel)
	{"id": "hat_beret", "name": "Boina", "category": "hat", "price": 14, "color": "e0609e"},
	{"id": "hat_ears", "name": "Diadema de gatito", "category": "hat", "price": 16, "color": "7a63a0"},
	{"id": "hat_witch", "name": "Sombrero de bruja", "category": "hat", "price": 24, "color": "6c4ba6"},
	{"id": "hat_halo", "name": "Aureola", "category": "hat", "price": 28, "color": "ffd966"},
	{"id": "glasses_pixel", "name": "Lentes pixelados", "category": "glasses", "price": 16, "color": "222233"},
	{"id": "glasses_rainbow", "name": "Lentes arcoíris", "category": "glasses", "price": 22, "color": "ff7aa8"},
	{"id": "shirt_star", "name": "Remera de estrellas", "category": "shirt", "price": 14, "color": "5b8def"},
	{"id": "shirt_cape", "name": "Capa de superhéroe", "category": "shirt", "price": 22, "color": "e5484d"},
	{"id": "shirt_sailor", "name": "Marinero", "category": "shirt", "price": 18, "color": "4a7fc1"},
	{"id": "shirt_tux", "name": "Smoking", "category": "shirt", "price": 30, "color": "3a3a4a"},
	{"id": "furn_teddy", "name": "Osito de peluche", "category": "furniture", "price": 20, "color": "d9a46a"},
	{"id": "furn_beanbag", "name": "Puff", "category": "furniture", "price": 24, "color": "ff9ecb"},
	{"id": "furn_globe", "name": "Globo terráqueo", "category": "furniture", "price": 26, "color": "5bb8f5"},
	{"id": "furn_aquarium", "name": "Pecera", "category": "furniture", "price": 36, "color": "8ecae6"},
	{"id": "furn_piano", "name": "Piano", "category": "furniture", "price": 50, "color": "5b4a6a"},
	{"id": "deco_rainbow", "name": "Arcoíris", "category": "deco", "price": 20, "color": "ff9ecb"},
	{"id": "deco_balloons", "name": "Globos", "category": "deco", "price": 18, "color": "ff7aa8"},
	{"id": "wall_clouds", "name": "Pared de nubes", "category": "wall", "price": 24, "color": "d6ecff", "pattern": "clouds"},
	{"id": "wall_hearts", "name": "Pared de corazones", "category": "wall", "price": 24, "color": "ffe0ea", "pattern": "hearts"},
	{"id": "wall_space", "name": "Pared del espacio", "category": "wall", "price": 30, "color": "2d2f5e", "pattern": "space"},
	{"id": "floor_grass", "name": "Piso de pasto", "category": "floor", "price": 22, "color": "bfe6a0", "pattern": "grass"},
	{"id": "floor_carpet", "name": "Alfombrado rosa", "category": "floor", "price": 24, "color": "f6c0d8", "pattern": "carpet"},
	# --- tazones (reemplazan a los feos de siempre)
	{"id": "bowl_food_pink", "name": "Tazón rosa de lunares", "category": "bowl_food", "price": 14, "color": "ffb3cc"},
	{"id": "bowl_food_star", "name": "Tazón de estrellas", "category": "bowl_food", "price": 18, "color": "ffe27a"},
	{"id": "bowl_food_mint", "name": "Tazón menta con huellita", "category": "bowl_food", "price": 14, "color": "9be3d0"},
	{"id": "bowl_food_gold", "name": "Tazón dorado", "category": "bowl_food", "price": 28, "color": "ffd34d"},
	{"id": "bowl_water_blue", "name": "Tazón celeste con olas", "category": "bowl_water", "price": 14, "color": "8ecae6"},
	{"id": "bowl_water_heart", "name": "Tazón de corazón", "category": "bowl_water", "price": 18, "color": "ff9ecb"},
	{"id": "bowl_water_lilac", "name": "Tazón lila", "category": "bowl_water", "price": 14, "color": "d2b8f0"},
	{"id": "bowl_water_fish", "name": "Tazón de pececito", "category": "bowl_water", "price": 22, "color": "7fd0f0"},
	# --- paredes y pisos
	{"id": "wall_stars", "name": "Pared de estrellas", "category": "wall", "price": 22, "color": "fff2c9", "pattern": "stars"},
	{"id": "wall_blue", "name": "Pared celeste", "category": "wall", "price": 22, "color": "cfe8f7", "pattern": "stripes"},
	{"id": "wall_lilac", "name": "Pared lila", "category": "wall", "price": 22, "color": "e3d4f5", "pattern": "dots"},
	{"id": "wall_peach", "name": "Pared durazno", "category": "wall", "price": 22, "color": "ffe0cc", "pattern": "stripes"},
	{"id": "wall_mint", "name": "Pared menta", "category": "wall", "price": 22, "color": "d6f0e2", "pattern": "plain"},
	{"id": "floor_wood", "name": "Piso de madera", "category": "floor", "price": 20, "color": "e8c9a0", "pattern": "planks"},
	{"id": "floor_pink", "name": "Piso rosa", "category": "floor", "price": 20, "color": "f7c6d4", "pattern": "planks"},
	{"id": "floor_mint", "name": "Piso menta", "category": "floor", "price": 20, "color": "bfe8d2", "pattern": "planks"},
	{"id": "floor_checker", "name": "Piso ajedrez", "category": "floor", "price": 26, "color": "f4e4d0", "pattern": "checker"},
	# --- muebles clave de cada especie (el Pompon los necesita para estar comodo)
	{"id": "furn_bed", "name": "Cama amplia", "category": "furniture", "price": 40, "color": "b5838d", "species": "Canino"},
	{"id": "furn_scratcher", "name": "Rascador", "category": "furniture", "price": 35, "color": "a98467", "species": "Felino"},
	{"id": "furn_tunnel", "name": "Túnel", "category": "furniture", "price": 35, "color": "9c6644", "species": "Conejo"},
	{"id": "furn_swing", "name": "Columpio", "category": "furniture", "price": 38, "color": "d4a373", "species": "Ave"},
	{"id": "furn_wheel", "name": "Rueda de ejercicio", "category": "furniture", "price": 38, "color": "adb5bd", "species": "Raton"},
	{"id": "furn_cushion", "name": "Cojín térmico", "category": "furniture", "price": 32, "color": "e76f51", "species": "Dragon"},
	{"id": "furn_heat", "name": "Lámpara de calor", "category": "furniture", "price": 36, "color": "f4a261", "species": "Reptil"},
	# --- muebles para decorar
	{"id": "furn_crib", "name": "Cuna", "category": "furniture", "price": 50, "color": "ffc9dc"},
	{"id": "furn_sofa", "name": "Sofá", "category": "furniture", "price": 45, "color": "e8a0bf"},
	{"id": "furn_plant", "name": "Planta", "category": "furniture", "price": 18, "color": "6bbf7a"},
	{"id": "furn_bookshelf", "name": "Biblioteca", "category": "furniture", "price": 40, "color": "b98a62"},
	{"id": "furn_table", "name": "Mesita de té", "category": "furniture", "price": 30, "color": "e6b88a"},
	{"id": "furn_lamp", "name": "Lámpara de pie", "category": "furniture", "price": 25, "color": "f6d17a"},
	{"id": "furn_fireplace", "name": "Chimenea", "category": "furniture", "price": 60, "color": "c97b63"},
	{"id": "furn_toybox", "name": "Baúl de juguetes", "category": "furniture", "price": 28, "color": "7fb5e8"},
	# --- decoracion de pared
	{"id": "deco_window", "name": "Ventana", "category": "deco", "price": 30, "color": "bfe3f5"},
	{"id": "deco_picture", "name": "Cuadro", "category": "deco", "price": 18, "color": "f5c26b"},
	{"id": "deco_clock", "name": "Reloj", "category": "deco", "price": 16, "color": "f2f2f2"},
	{"id": "deco_shelf", "name": "Estante", "category": "deco", "price": 24, "color": "c9a27a"},
	{"id": "deco_garland", "name": "Guirnalda", "category": "deco", "price": 20, "color": "ff9ecb"},
	{"id": "deco_moon", "name": "Luna y estrellas", "category": "deco", "price": 22, "color": "ffe08a"},
	# --- estantes y muebles con superficie
	{"id": "deco_shelf_long", "name": "Estante largo", "category": "deco", "price": 30, "color": "d9a679"},
	{"id": "deco_shelf_cloud", "name": "Estante nube", "category": "deco", "price": 34, "color": "e4f1ff"},
	{"id": "furn_stool", "name": "Banquito", "category": "furniture", "price": 16, "color": "ffb3a0"},
	{"id": "furn_dresser", "name": "Cómoda", "category": "furniture", "price": 38, "color": "f2c58f"},
	{"id": "furn_desk", "name": "Escritorio", "category": "furniture", "price": 44, "color": "9ed0e6"},
	{"id": "furn_wardrobe", "name": "Armario", "category": "furniture", "price": 52, "color": "c9b3f0"},
	# --- adornos para apoyar encima
	{"id": "toy_blocks", "name": "Cubos de juguete", "category": "furniture", "price": 10, "color": "ff9ecb"},
	{"id": "toy_books", "name": "Pila de libros", "category": "furniture", "price": 10, "color": "8ecae6"},
	{"id": "toy_vase", "name": "Jarrón con flores", "category": "furniture", "price": 14, "color": "9fd8f0"},
	{"id": "toy_cactus", "name": "Cactus", "category": "furniture", "price": 12, "color": "7bc98a"},
	{"id": "toy_cake", "name": "Tarta", "category": "furniture", "price": 16, "color": "ffd1e3"},
	{"id": "toy_frame", "name": "Portarretrato", "category": "furniture", "price": 14, "color": "ffd27a"},
	{"id": "toy_musicbox", "name": "Caja musical", "category": "furniture", "price": 20, "color": "d2b8f0"},
	{"id": "toy_robot", "name": "Robot de juguete", "category": "furniture", "price": 22, "color": "9fb4c9"},
	{"id": "toy_trophy", "name": "Copa", "category": "furniture", "price": 26, "color": "ffd34d"},
	# --- decoracion nueva (16/11/2026)
	{"id": "furn_chair", "name": "Silla", "category": "furniture", "price": 14, "color": "f7a8b8"},
	{"id": "furn_armchair", "name": "Sillón", "category": "furniture", "price": 32, "color": "f4a261"},
	{"id": "furn_cushions", "name": "Almohadones", "category": "furniture", "price": 16, "color": "b388f5"},
	{"id": "furn_nightstand", "name": "Mesita de luz", "category": "furniture", "price": 18, "color": "f2c58f"},
	{"id": "furn_tent", "name": "Tipi", "category": "furniture", "price": 42, "color": "fff1d6"},
	{"id": "furn_stove", "name": "Cocinita", "category": "furniture", "price": 46, "color": "9be3d0"},
	{"id": "furn_fridge", "name": "Heladera", "category": "furniture", "price": 40, "color": "ffd1e3"},
	{"id": "furn_telescope", "name": "Telescopio", "category": "furniture", "price": 48, "color": "5b8def"},
	{"id": "furn_fountain", "name": "Fuente", "category": "furniture", "price": 55, "color": "d8d2e8"},
	{"id": "furn_bench", "name": "Banco de plaza", "category": "furniture", "price": 30, "color": "7bc98a"},
	{"id": "furn_tree", "name": "Arbolito", "category": "furniture", "price": 34, "color": "6bbf7a"},
	{"id": "furn_flowers", "name": "Cantero de flores", "category": "furniture", "price": 22, "color": "c9985f"},
	{"id": "furn_easel", "name": "Atril de pintura", "category": "furniture", "price": 30, "color": "d8a56f"},
	{"id": "furn_slide", "name": "Tobogán", "category": "furniture", "price": 50, "color": "ff9ecb"},
	{"id": "furn_sofa_mint", "name": "Sofá menta", "category": "furniture", "price": 45, "color": "9fd8c4", "base": "furn_sofa"},
	{"id": "furn_beanbag_blue", "name": "Puff celeste", "category": "furniture", "price": 24, "color": "8ecae6", "base": "furn_beanbag"},
	{"id": "furn_toybox_pink", "name": "Baúl rosa", "category": "furniture", "price": 28, "color": "ffadc9", "base": "furn_toybox"},
	{"id": "furn_dresser_mint", "name": "Cómoda menta", "category": "furniture", "price": 38, "color": "a8dfc9", "base": "furn_dresser"},
	{"id": "rug_round", "name": "Alfombra redonda", "category": "furniture", "price": 18, "color": "ffc2d9", "rug": true},
	{"id": "rug_stripes", "name": "Alfombra a rayas", "category": "furniture", "price": 22, "color": "8ecae6", "rug": true},
	{"id": "rug_star", "name": "Alfombra estrella", "category": "furniture", "price": 28, "color": "ffd966", "rug": true},
	{"id": "rug_cloud", "name": "Alfombra nube", "category": "furniture", "price": 26, "color": "eaf4ff", "rug": true},
	{"id": "deco_mirror", "name": "Espejo", "category": "deco", "price": 22, "color": "f5c26b"},
	{"id": "deco_plant_hanging", "name": "Maceta colgante", "category": "deco", "price": 20, "color": "e0885c"},
	{"id": "deco_stars", "name": "Estrellas brillantes", "category": "deco", "price": 18, "color": "ffe066"},
	{"id": "deco_board", "name": "Pizarrón", "category": "deco", "price": 26, "color": "3f6b5a"},
	{"id": "deco_map", "name": "Mapa del mundo", "category": "deco", "price": 28, "color": "bfe3f5"},
	{"id": "deco_cloud", "name": "Nube colgante", "category": "deco", "price": 20, "color": "ffffff"},
	{"id": "toy_lamp", "name": "Velador", "category": "furniture", "price": 16, "color": "ffd1a8"},
	{"id": "toy_alarm", "name": "Despertador", "category": "furniture", "price": 12, "color": "ff7aa8"},
	{"id": "toy_teacup", "name": "Juego de té", "category": "furniture", "price": 14, "color": "fff6f9"},
	{"id": "toy_dino", "name": "Dinosaurio de juguete", "category": "furniture", "price": 18, "color": "7bd389"},
	{"id": "toy_candles", "name": "Velas", "category": "furniture", "price": 12, "color": "fff1d6"},
	{"id": "toy_duck", "name": "Patito de goma", "category": "furniture", "price": 10, "color": "ffd93d"},
	{"id": "toy_snowglobe", "name": "Bola de nieve", "category": "furniture", "price": 20, "color": "cfefff"},
	{"id": "toy_fruit", "name": "Frutero", "category": "furniture", "price": 12, "color": "e6b88a"},
	{"id": "wall_yellow", "name": "Pared amarilla", "category": "wall", "price": 20, "color": "fff4c2", "pattern": "dots"},
	{"id": "wall_flowers", "name": "Pared de flores", "category": "wall", "price": 24, "color": "fff0f4", "pattern": "flowers"},
	{"id": "wall_brick", "name": "Pared de ladrillos", "category": "wall", "price": 24, "color": "f2c4a8", "pattern": "brick"},
	{"id": "wall_wood", "name": "Pared de madera", "category": "wall", "price": 26, "color": "ecd2ac", "pattern": "panels"},
	{"id": "wall_tiles", "name": "Pared de azulejos", "category": "wall", "price": 24, "color": "e6f4fb", "pattern": "tiles"},
	{"id": "floor_lilac", "name": "Piso lila", "category": "floor", "price": 20, "color": "e3d4f5", "pattern": "planks"},
	{"id": "floor_dark", "name": "Piso de madera oscura", "category": "floor", "price": 22, "color": "b98a62", "pattern": "planks"},
	{"id": "floor_tiles", "name": "Piso de baldosas", "category": "floor", "price": 24, "color": "eef3f7", "pattern": "tiles"},
	{"id": "floor_stones", "name": "Piso de piedras", "category": "floor", "price": 24, "color": "cfe6b8", "pattern": "stones"},
	{"id": "floor_starry", "name": "Alfombrado de estrellas", "category": "floor", "price": 28, "color": "3b3d78", "pattern": "starry"},
	# --- especiales: caros y con brillo. "base" = usa el dibujo de ese item con su propio color.
	{"id": "hat_crown_diamond", "name": "Corona de diamantes", "category": "hat", "price": 1200, "color": "bfe9ff", "base": "hat_crown", "special": true},
	{"id": "hat_halo_gold", "name": "Aureola dorada", "category": "hat", "price": 900, "color": "ffcc33", "base": "hat_halo", "special": true},
	{"id": "hat_wizard", "name": "Sombrero de mago", "category": "hat", "price": 800, "color": "3f51b5", "base": "hat_witch", "special": true},
	{"id": "glasses_star_gold", "name": "Lentes de estrellas doradas", "category": "glasses", "price": 600, "color": "ffcc33", "base": "glasses_star", "special": true},
	{"id": "shirt_dress_princess", "name": "Vestido de princesa", "category": "shirt", "price": 1200, "color": "c77dff", "base": "shirt_dress", "special": true},
	{"id": "shirt_cape_royal", "name": "Capa real", "category": "shirt", "price": 1500, "color": "7b2cbf", "base": "shirt_cape", "special": true},
	{"id": "shirt_tux_gold", "name": "Smoking dorado", "category": "shirt", "price": 2000, "color": "c9a227", "base": "shirt_tux", "special": true},
	{"id": "furn_bed_cloud", "name": "Cama de nube", "category": "furniture", "price": 1800, "color": "e3f2fd", "special": true, "bed": true},
	{"id": "furn_piano_gold", "name": "Piano de cola dorado", "category": "furniture", "price": 2500, "color": "e9c46a", "base": "furn_piano", "special": true},
	{"id": "furn_sofa_royal", "name": "Sofá real", "category": "furniture", "price": 1300, "color": "b5179e", "base": "furn_sofa", "special": true},
	{"id": "furn_fireplace_crystal", "name": "Chimenea de cristal", "category": "furniture", "price": 1500, "color": "a8dadc", "base": "furn_fireplace", "special": true},
	{"id": "furn_lamp_stars", "name": "Lámpara de estrellas", "category": "furniture", "price": 700, "color": "b39ddb", "base": "furn_lamp", "special": true},
	{"id": "furn_aquarium_rainbow", "name": "Acuario de colores", "category": "furniture", "price": 900, "color": "ff9ecb", "base": "furn_aquarium", "special": true},
	{"id": "deco_window_magic", "name": "Ventana mágica", "category": "deco", "price": 800, "color": "c3b1e1", "base": "deco_window", "special": true},
	{"id": "deco_garland_lights", "name": "Guirnalda de luces", "category": "deco", "price": 500, "color": "ffe066", "base": "deco_garland", "special": true},
	{"id": "wall_rainbow", "name": "Pared arcoíris", "category": "wall", "price": 900, "color": "fff6e5", "pattern": "rainbow", "special": true},
	{"id": "wall_galaxy", "name": "Pared galaxia", "category": "wall", "price": 1100, "color": "1a1446", "pattern": "space", "special": true},
	{"id": "floor_gold", "name": "Piso dorado", "category": "floor", "price": 800, "color": "e9c46a", "pattern": "planks", "special": true},
	{"id": "floor_cloud", "name": "Piso de nubes", "category": "floor", "price": 700, "color": "e3f2fd", "pattern": "carpet", "special": true},
	{"id": "bowl_food_diamond", "name": "Tazón de diamante", "category": "bowl_food", "price": 600, "color": "cfefff", "special": true},
	{"id": "bowl_water_crystal", "name": "Tazón de cristal", "category": "bowl_water", "price": 600, "color": "e0d7ff", "special": true},
]


## Nombre del item en el idioma actual (los dibujos de pixel art: "Dibujo de ...").
static func item_name(id: String) -> String:
	var it := get_item(id)
	if it.is_empty():
		return id
	if it.get("art", false):
		return str(it["name"])
	return T.data("item", id, str(it["name"]))


## Nombre de una categoria en el idioma actual ("Gorro", "Pared"...).
static func category_name(cat: String) -> String:
	return T.s(CATEGORY_LABELS.get(cat, cat))


## Dibujo que usa el item (los especiales reutilizan el de otro item con su propio color).
static func shape_of(id: String) -> String:
	return str(get_item(id).get("base", id))


## Especiales: caros, con brillo y siempre a la vista en la tienda (no rotan).
static func is_special(id: String) -> bool:
	return bool(get_item(id).get("special", false))


## Camas donde puede dormir un Pompon grande de noche.
static func is_bed(id: String) -> bool:
	return id == "furn_bed" or bool(get_item(id).get("bed", false))


## Todos los especiales, de mas barato a mas caro.
static func specials() -> Array:
	var out := ITEMS.filter(func(it): return it.get("special", false))
	out.sort_custom(func(a, b): return int(a["price"]) < int(b["price"]))
	return out


## Nivel del Pompon (dia de vida) que hace falta para comprar el item.
static func unlock_level(id: String) -> int:
	return int(UNLOCK.get(id, 1))


static func is_unlocked(id: String, level: int) -> bool:
	return level >= unlock_level(id)


## Los proximos items que se van a desbloquear (de menor a mayor nivel), para mostrarlos con candado.
static func locked_items(level: int, limit := 6) -> Array:
	var out := []
	for it in ITEMS:
		if not is_unlocked(it["id"], level) and not it.get("special", false):
			out.append(it)
	out.sort_custom(func(a, b): return unlock_level(a["id"]) < unlock_level(b["id"]))
	return out.slice(0, limit)


static func is_small(id: String) -> bool:
	return SMALL.has(id) or SMALL.has(shape_of(id))


## Superficie del item ({"dy", "hw"}) o {} si no se puede apoyar nada encima.
static func surface_of(id: String) -> Dictionary:
	return SURFACES.get(id, SURFACES.get(shape_of(id), {}))


## Alfombra: va en el piso, debajo de los muebles.
static func is_rug(id: String) -> bool:
	return RUGS.has(id) or RUGS.has(shape_of(id))


## Se puede dar vuelta en el cuarto (lo que tiene letras o numeros quedaria al reves).
static func can_flip(id: String) -> bool:
	return is_placeable(id) and not shape_of(id) in ["deco_board", "deco_clock"] and not PixelArt.is_art(id)


static func is_placeable(id: String) -> bool:
	return get_item(id).get("category", "") in PLACEABLE


## Mueble tipico de cada especie (rascador, tunel...). Ya no es obligatorio: solo decora los cuartos
## de los vecinos. La comodidad ahora sale de usar los muebles (ver PomponPlay).
static func required_furniture(species: String) -> Dictionary:
	if species == "":
		return {}
	for it in ITEMS:
		if it.get("species", "") == species:
			return it
	return {}


## `placed_ids`: ids de los muebles que estan colocados en el cuarto.
static func has_required_furniture(species: String, placed_ids: Array) -> bool:
	var req := required_furniture(species)
	return req.is_empty() or placed_ids.has(req["id"])


static func get_item(id: String) -> Dictionary:
	if PixelArt.is_art(id):   # dibujo de pixel art: un cuadro para la pared
		if not PixelArt.cache.has(id):
			return {}
		return {"id": id, "name": PixelArt.name_of(id), "category": "deco", "price": 0, "color": "c99560", "art": true}
	for it in ITEMS:
		if it["id"] == id:
			return it
	return {}


static func color_of(id: String) -> Color:
	var it := get_item(id)
	return Color.html(it["color"]) if not it.is_empty() else Color.WHITE


## Cuantos items de cada grupo trae la tienda del dia (asi cada solapa tiene opciones para elegir).
const SHOP_GROUPS := [
	{"cats": ["furniture", "deco"], "n": 8},
	{"cats": ["hat", "glasses", "shirt"], "n": 5},
	{"cats": ["wall", "floor"], "n": 3},
	{"cats": ["bowl_food", "bowl_water"], "n": 2},
]


## Los items de hoy (SHOP_SIZE): cambian cada 24 h, repartidos por grupo (SHOP_GROUPS). Prefiere items
## que aun no tienes; si a un grupo le faltan, se completa con los de otros.
## (`_species` ya no se usa: antes forzaba el mueble clave de la especie.)
static func daily_shop(unix_time: int, _species := "", owned: Array = [], must_include: Array = [], level := 9999) -> Array:
	var day := unix_time / 86400
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 2654435761
	var pool := []
	for it in ITEMS:
		if not owned.has(it["id"]) and is_unlocked(it["id"], level) and not it.get("special", false):
			pool.append(it)
	if pool.size() < SHOP_SIZE:  # casi lo tienes todo: se rellena con repetidos
		for it in ITEMS:
			if owned.has(it["id"]) and is_unlocked(it["id"], level) and pool.size() < SHOP_SIZE and not it.get("special", false):
				pool.append(it)
	var picked := []
	for g in SHOP_GROUPS:
		var group_pool := pool.filter(func(it): return it["category"] in g["cats"])
		var n := 0
		while n < int(g["n"]) and not group_pool.is_empty():
			var it: Dictionary = group_pool.pop_at(rng.randi() % group_pool.size())
			picked.append(it)
			pool.erase(it)
			n += 1
	while picked.size() < SHOP_SIZE and not pool.is_empty():
		picked.append(pool.pop_at(rng.randi() % pool.size()))
	# lo imprescindible (por ejemplo la cuna del huevo) va siempre primero en la lista
	for i in range(must_include.size() - 1, -1, -1):
		var pinned := get_item(must_include[i])
		if pinned.is_empty() or owned.has(pinned["id"]):
			continue
		if picked.has(pinned):
			picked.erase(pinned)
		else:
			for j in range(picked.size() - 1, -1, -1):
				if not must_include.has(picked[j]["id"]) and picked[j]["category"] == pinned["category"]:
					picked.remove_at(j)
					break
			if picked.size() >= SHOP_SIZE:
				picked.remove_at(picked.size() - 1)
		picked.insert(0, pinned)
	return picked


static func seconds_until_refresh(unix_time: int) -> int:
	return 86400 - unix_time % 86400

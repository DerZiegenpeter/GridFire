@tool
extends Sprite2D
class_name TerrainGenerator

@export var map_size: Vector2i = Vector2i(2048, 2048)
@export var noise_seed: int = 1337
@export var frequency: float = 0.0035
@export var octaves: int = 5
@export var lacunarity: float = 2.0
@export var gain: float = 0.55

@export var min_height_m: float = 80.0
@export var max_height_m: float = 420.0

var noise: FastNoiseLite

var terrain_texture: ImageTexture

func _ready() -> void:
    generate_terrain()  # jetzt auch im Editor (@tool) sichtbar

func generate_terrain() -> void:
    noise = FastNoiseLite.new()
    noise.seed = noise_seed
    noise.frequency = frequency
    noise.fractal_octaves = octaves
    noise.fractal_lacunarity = lacunarity
    noise.fractal_gain = gain
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

    var img := Image.create(map_size.x, map_size.y, false, Image.FORMAT_RGB8)

    for y in map_size.y:
        for x in map_size.x:
            var noise_value: float = noise.get_noise_2d(x, y)
            var h: float = noise_value * 0.5 + 0.5

            var color: Color
            if h < 0.22:
                color = Color(0.02, 0.15, 0.02)
            elif h < 0.40:
                color = Color(0.08, 0.28, 0.06)
            elif h < 0.60:
                color = Color(0.18, 0.38, 0.10)
            else:
                color = Color(0.32, 0.48, 0.15)

            img.set_pixel(x, y, color)

    terrain_texture = ImageTexture.create_from_image(img)
    
    # FIX: Da das Script jetzt am TerrainSprite (Sprite2D) hängt, wenden wir die Textur direkt auf uns selbst an
    self.texture = terrain_texture
    self.position = Vector2.ZERO
    self.centered = true

func get_height_meters(world_pos: Vector2) -> float:
    if not noise:
        return 0.0
    var noise_value: float = noise.get_noise_2d(world_pos.x, world_pos.y)
    var h: float = noise_value * 0.5 + 0.5
    return lerp(min_height_m, max_height_m, h)
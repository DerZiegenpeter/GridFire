extends Node2D

@export var map_size: Vector2i = Vector2i(2048, 2048)
@export var meters_per_pixel: float = 5.0
@export var major_grid_meters: int = 1000
@export var minor_grid_meters: int = 200
@export var contour_step_meters: int = 50

@export var utm_easting_base: float = 512000.0
@export var utm_northing_base: float = 5480000.0
@export var utm_zone: String = "32U"

@export var terrain_generator_path: NodePath

var terrain_generator: TerrainGenerator

var label_font: Font

func _ready() -> void:
    label_font = ThemeDB.fallback_font
    if terrain_generator_path:
        terrain_generator = get_node(terrain_generator_path) as TerrainGenerator

func _draw() -> void:
    var major_px := int(major_grid_meters / meters_per_pixel)
    var minor_px := int(minor_grid_meters / meters_per_pixel)

    # Minor lines (subtle)
    for x in range(0, map_size.x + 1, minor_px):
        if x % major_px != 0:
            draw_line(Vector2(x, 0), Vector2(x, map_size.y), Color(0.0, 0.7, 0.35, 0.4), 1.0)

    for y in range(0, map_size.y + 1, minor_px):
        if y % major_px != 0:
            draw_line(Vector2(0, y), Vector2(map_size.x, y), Color(0.0, 0.7, 0.35, 0.4), 1.0)

    # Major lines (strong)
    for x in range(0, map_size.x + 1, major_px):
        draw_line(Vector2(x, 0), Vector2(x, map_size.y), Color(0.0, 1.0, 0.55, 0.95), 2.8)
        if x > 0:
            var east := int(utm_easting_base + x * meters_per_pixel)
            draw_string(label_font, Vector2(x + 5, 17), str(east / 1000), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.4, 1.0, 0.7))

    for y in range(0, map_size.y + 1, major_px):
        draw_line(Vector2(0, y), Vector2(map_size.x, y), Color(0.0, 1.0, 0.55, 0.95), 2.8)
        if y > 0:
            var north := int(utm_northing_base + (map_size.y - y) * meters_per_pixel)
            draw_string(label_font, Vector2(5, y + 13), str(north / 1000), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.4, 1.0, 0.7))

    # Contour dots (more visible)
    if terrain_generator:
        var step := int(contour_step_meters / meters_per_pixel)
        for x in range(0, map_size.x, step):
            for y in range(0, map_size.y, step):
                var h: float = terrain_generator.get_height_meters(Vector2(x, y))
                if int(h) % 50 == 0 and int(h) > 100:
                    draw_circle(Vector2(x, y), 2.2, Color(1.0, 0.85, 0.2, 0.85))

func world_to_utm_string(world_pos: Vector2) -> String:
    var east := int(utm_easting_base + world_pos.x * meters_per_pixel)
    var north := int(utm_northing_base + (map_size.y - world_pos.y) * meters_per_pixel)
    return "%s %06d %07d" % [utm_zone, east, north]
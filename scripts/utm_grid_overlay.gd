extends Node2D

@export var map_size: Vector2i = Vector2i(2048, 2048)
@export var meters_per_pixel: float = 5.0
@export var major_grid_meters: int = 1000
@export var minor_grid_meters: int = 200
@export var contour_interval_m: int = 50

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

    # === Minor Grid Lines (subtle) ===
    for x in range(0, map_size.x + 1, minor_px):
        if x % major_px != 0:
            draw_line(Vector2(x, 0), Vector2(x, map_size.y), Color(0.0, 0.65, 0.3, 0.35), 1.0)

    for y in range(0, map_size.y + 1, minor_px):
        if y % major_px != 0:
            draw_line(Vector2(0, y), Vector2(map_size.x, y), Color(0.0, 0.65, 0.3, 0.35), 1.0)

    # === Major Grid Lines (strong, military style) ===
    for x in range(0, map_size.x + 1, major_px):
        draw_line(Vector2(x, 0), Vector2(x, map_size.y), Color(0.0, 0.95, 0.5, 0.95), 3.0)
        if x > 0:
            var east := int(utm_easting_base + x * meters_per_pixel)
            # Label with slight background for readability
            draw_string(label_font, Vector2(x + 6, 16), str(east / 1000), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.3, 1.0, 0.6))

    for y in range(0, map_size.y + 1, major_px):
        draw_line(Vector2(0, y), Vector2(map_size.x, y), Color(0.0, 0.95, 0.5, 0.95), 3.0)
        if y > 0:
            var north := int(utm_northing_base + (map_size.y - y) * meters_per_pixel)
            draw_string(label_font, Vector2(6, y + 12), str(north / 1000), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.3, 1.0, 0.6))

    # === Contour Lines (Höhenlinien) - more visible ===
    if terrain_generator:
        var step := int(contour_interval_m / meters_per_pixel)
        for x in range(0, map_size.x, step):
            for y in range(0, map_size.y, step):
                var h := terrain_generator.get_height_meters(Vector2(x, y))
                # Draw small cross / plus at contour levels for better visibility
                if int(h) % contour_interval_m == 0 and int(h) > 80:
                    var pos := Vector2(x, y)
                    draw_line(pos - Vector2(4, 0), pos + Vector2(4, 0), Color(1.0, 0.9, 0.3, 0.9), 1.8)
                    draw_line(pos - Vector2(0, 4), pos + Vector2(0, 4), Color(1.0, 0.9, 0.3, 0.9), 1.8)

func world_to_utm_string(world_pos: Vector2) -> String:
    var east := int(utm_easting_base + world_pos.x * meters_per_pixel)
    var north := int(utm_northing_base + (map_size.y - world_pos.y) * meters_per_pixel)
    return "%s %06d %07d" % [utm_zone, east, north]
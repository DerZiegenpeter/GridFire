extends Node2D

@export var map_size: Vector2i = Vector2i(2000, 2000)
@export var meters_per_pixel: float = 5.0
@export var major_grid_meters: int = 1000
@export var minor_grid_meters: int = 200

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
	# Einmal zeichnen, danach nur bei Bedarf
	queue_redraw()

func _draw() -> void:
	var major_px := int(major_grid_meters / meters_per_pixel)
	var minor_px := int(minor_grid_meters / meters_per_pixel)

	# Linienbreite unabhängig vom Zoom (immer gleich dünn auf dem Bildschirm)
	var cam := get_viewport().get_camera_2d()
	var z: float = cam.zoom.x if cam else 1.0
	var major_w: float = 2.2 / z
	var minor_w: float = 1.0 / z

	# Minor Grid
	for x in range(0, map_size.x + 1, minor_px):
		if x % major_px != 0:
			draw_line(Vector2(x, 0), Vector2(x, map_size.y), Color(0.0, 0.6, 0.3, 0.28), minor_w)

	for y in range(0, map_size.y + 1, minor_px):
		if y % major_px != 0:
			draw_line(Vector2(0, y), Vector2(map_size.x, y), Color(0.0, 0.6, 0.3, 0.28), minor_w)

	# Major Grid
	for x in range(0, map_size.x + 1, major_px):
		draw_line(Vector2(x, 0), Vector2(x, map_size.y), Color(0.0, 0.95, 0.5, 0.9), major_w)
		if x > 0:
			var east := int(utm_easting_base + x * meters_per_pixel)
			draw_string(label_font, Vector2(x + 6, 16), str(east / 1000), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.3, 1.0, 0.6))

	for y in range(0, map_size.y + 1, major_px):
		draw_line(Vector2(0, y), Vector2(map_size.x, y), Color(0.0, 0.95, 0.5, 0.9), major_w)
		if y > 0:
			var north := int(utm_northing_base + (map_size.y - y) * meters_per_pixel)
			draw_string(label_font, Vector2(6, y + 12), str(north / 1000), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.3, 1.0, 0.6))

func world_to_utm_string(world_pos: Vector2) -> String:
	var east := int(utm_easting_base + world_pos.x * meters_per_pixel)
	var north := int(utm_northing_base + (map_size.y - world_pos.y) * meters_per_pixel)
	return "%s %06d %07d" % [utm_zone, east, north]

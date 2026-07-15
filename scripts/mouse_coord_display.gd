extends Label

@export var grid_overlay_path: NodePath = "../../../World/GridOverlay"
@export var terrain_sprite_path: NodePath = "../../../World/TerrainSprite"

@export var map_size: Vector2i = Vector2i(2048, 2048)

var grid_overlay: Node2D
var terrain_sprite: Sprite2D

func _ready() -> void:
	grid_overlay = get_node_or_null(grid_overlay_path)
	terrain_sprite = get_node_or_null(terrain_sprite_path)

	text = "GRID 32U 512000 5480000   H: ---m"
	add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	add_theme_font_size_override("font_size", 22)

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam or not grid_overlay:
		return

	var world_pos := cam.get_global_mouse_position()

	# Clamp to map bounds
	world_pos.x = clamp(world_pos.x, 0, map_size.x)
	world_pos.y = clamp(world_pos.y, 0, map_size.y)

	var utm_text := ""
	if grid_overlay.has_method("world_to_utm_string"):
		utm_text = grid_overlay.world_to_utm_string(world_pos)

	var height_text := "   H: ---m"
	if terrain_sprite and terrain_sprite.has_method("get_height_meters"):
		var h: float = terrain_generator.get_height_meters(Vector2(x, y))
		height_text = "   H: %dm" % int(round(h))

	text = utm_text + height_text

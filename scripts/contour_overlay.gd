extends Node2D
class_name ContourOverlay

@export var map_size: Vector2i = Vector2i(2000, 2000)
@export var terrain_path: NodePath = NodePath("../TerrainSprite")

@export var contour_interval: float = 25.0
@export var index_interval: float = 100.0
@export var sample_step: int = 12

@export var normal_color: Color = Color(0.10, 0.20, 0.08, 0.75)
@export var index_color: Color = Color(0.06, 0.13, 0.05, 0.95)

# Gewünschte Dicke auf dem Bildschirm in Pixeln
@export var normal_screen_width: float = 1.1
@export var index_screen_width: float = 2.0

var terrain: TerrainGenerator
var contour_lines: Array[PackedVector2Array] = []
var is_index: Array[bool] = []
var generated := false

func _ready() -> void:
	if terrain_path:
		terrain = get_node_or_null(terrain_path) as TerrainGenerator
	await get_tree().process_frame
	await get_tree().process_frame
	_generate_contours()
	generated = true
	queue_redraw()

func _process(_delta: float) -> void:
	if generated:
		queue_redraw()   # nötig für konstante Bildschirm-Dicke beim Zoomen

func _generate_contours() -> void:
	if not terrain or terrain.heights.is_empty():
		return

	contour_lines.clear()
	is_index.clear()

	var min_h: float = terrain.min_height_m
	var max_h: float = terrain.max_height_m

	var levels: Array[float] = []
	var h: float = ceilf(min_h / contour_interval) * contour_interval
	while h <= max_h:
		levels.append(h)
		h += contour_interval

	for level in levels:
		var is_idx: bool = (int(round(level)) % int(index_interval) == 0)
		_extract_isolines(level, is_idx)

func _extract_isolines(level: float, is_idx: bool) -> void:
	var step: int = sample_step
	var w: int = map_size.x
	var height: int = map_size.y

	for y in range(0, height - step, step):
		for x in range(0, w - step, step):
			var h00: float = terrain.get_height_meters(Vector2(x, y))
			var h10: float = terrain.get_height_meters(Vector2(x + step, y))
			var h01: float = terrain.get_height_meters(Vector2(x, y + step))
			var h11: float = terrain.get_height_meters(Vector2(x + step, y + step))

			var points: Array[Vector2] = []
			_check_edge(Vector2(x, y), h00, Vector2(x + step, y), h10, level, points)
			_check_edge(Vector2(x + step, y), h10, Vector2(x + step, y + step), h11, level, points)
			_check_edge(Vector2(x + step, y + step), h11, Vector2(x, y + step), h01, level, points)
			_check_edge(Vector2(x, y + step), h01, Vector2(x, y), h00, level, points)

			if points.size() >= 2:
				var poly := PackedVector2Array([points[0], points[1]])
				contour_lines.append(poly)
				is_index.append(is_idx)

func _check_edge(p1: Vector2, h1: float, p2: Vector2, h2: float, level: float, points: Array[Vector2]) -> void:
	if (h1 < level and h2 >= level) or (h1 >= level and h2 < level):
		var t: float = (level - h1) / (h2 - h1 + 0.00001)
		points.append(p1.lerp(p2, clamp(t, 0.0, 1.0)))

func _draw() -> void:
	if not generated:
		return

	var cam := get_viewport().get_camera_2d()
	var z: float = maxf(cam.zoom.x, 0.01) if cam else 1.0

	var normal_w: float = normal_screen_width / z
	var index_w: float = index_screen_width / z

	for i in contour_lines.size():
		var poly: PackedVector2Array = contour_lines[i]
		if poly.size() < 2:
			continue
		var col: Color = index_color if is_index[i] else normal_color
		var width: float = index_w if is_index[i] else normal_w
		draw_polyline(poly, col, width, true)

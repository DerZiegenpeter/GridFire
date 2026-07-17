extends Node2D
class_name ContourOverlay

@export var map_size: Vector2i = Vector2i(2000, 2000)
@export var terrain_path: NodePath = NodePath("../TerrainSprite")

@export var contour_interval: float = 25.0
@export var index_interval: float = 100.0
@export var sample_step: int = 14          # höher = deutlich schneller + weniger Lag

@export var normal_color: Color = Color(0.12, 0.22, 0.10, 0.65)
@export var index_color: Color = Color(0.08, 0.15, 0.06, 0.90)
@export var normal_width: float = 1.1
@export var index_width: float = 2.2

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
		var is_idx := (int(round(level)) % int(index_interval) == 0)
		_extract_isolines(level, is_idx)

func _extract_isolines(level: float, is_idx: bool) -> void:
	var step := sample_step
	var w := map_size.x
	var height := map_size.y

	for y in range(0, height - step, step):
		for x in range(0, w - step, step):
			var h00 := terrain.get_height_meters(Vector2(x, y))
			var h10 := terrain.get_height_meters(Vector2(x + step, y))
			var h01 := terrain.get_height_meters(Vector2(x, y + step))
			var h11 := terrain.get_height_meters(Vector2(x + step, y + step))

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
		var t := (level - h1) / (h2 - h1 + 0.00001)
		points.append(p1.lerp(p2, clamp(t, 0.0, 1.0)))

func _draw() -> void:
	if not generated:
		return
	for i in contour_lines.size():
		var poly: PackedVector2Array = contour_lines[i]
		if poly.size() < 2:
			continue
		var col := index_color if is_index[i] else normal_color
		var width := index_width if is_index[i] else normal_width
		draw_polyline(poly, col, width, true)

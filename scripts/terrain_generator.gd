@tool
extends Sprite2D
class_name TerrainGenerator

@export var map_size: Vector2i = Vector2i(2000, 2000)
@export var noise_seed: int = 1337

# Noise settings
@export var frequency: float = 0.0016
@export var octaves: int = 5
@export var lacunarity: float = 2.2
@export var gain: float = 0.48
@export var warp_strength: float = 45.0
@export var ridge_strength: float = 0.55

@export var min_height_m: float = 90.0
@export var max_height_m: float = 420.0

# Erosion (kept light for performance)
@export var erosion_iterations: int = 6
@export var talus_angle: float = 0.035
@export var erosion_strength: float = 0.35

# Hillshade
@export var light_direction: Vector3 = Vector3(-0.6, -0.45, 0.65)
@export var ambient: float = 0.38
@export var diffuse_strength: float = 0.72

var noise: FastNoiseLite
var warp_noise: FastNoiseLite
var ridge_noise: FastNoiseLite

var heights: PackedFloat32Array = PackedFloat32Array()
var terrain_texture: ImageTexture

func _ready() -> void:
	generate_terrain()

func generate_terrain() -> void:
	_init_noises()
	_generate_base_heights()
	_apply_thermal_erosion()
	_build_shaded_texture()

	self.texture = terrain_texture
	self.position = Vector2.ZERO
	self.centered = false

func _init_noises() -> void:
	noise = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	noise.fractal_lacunarity = lacunarity
	noise.fractal_gain = gain
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM

	warp_noise = FastNoiseLite.new()
	warp_noise.seed = noise_seed + 17
	warp_noise.frequency = frequency * 0.7
	warp_noise.fractal_octaves = 3
	warp_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	ridge_noise = FastNoiseLite.new()
	ridge_noise.seed = noise_seed + 91
	ridge_noise.frequency = frequency * 1.4
	ridge_noise.fractal_octaves = 4
	ridge_noise.fractal_lacunarity = 2.3
	ridge_noise.fractal_gain = 0.5
	ridge_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ridge_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED

func _generate_base_heights() -> void:
	var w: int = map_size.x
	var h: int = map_size.y
	heights.resize(w * h)

	for y in h:
		for x in w:
			var wx: float = warp_noise.get_noise_2d(x, y) * warp_strength
			var wy: float = warp_noise.get_noise_2d(x + 500, y + 300) * warp_strength

			var n1: float = noise.get_noise_2d(x + wx, y + wy)
			var n2: float = ridge_noise.get_noise_2d(x * 0.85 + wx * 0.4, y * 0.85 + wy * 0.4)

			var val: float = n1 * 0.65 + n2 * ridge_strength
			val = clamp(val * 0.5 + 0.5, 0.0, 1.0)

			var dx: float = (x / float(w) - 0.5) * 2.0
			var dy: float = (y / float(h) - 0.5) * 2.0
			var dist: float = sqrt(dx * dx + dy * dy)
			val = lerp(val, val * 0.75 + 0.15, clamp(dist * 0.6, 0.0, 1.0))

			heights[y * w + x] = lerp(min_height_m, max_height_m, val)

func _apply_thermal_erosion() -> void:
	var w: int = map_size.x
	var h: int = map_size.y
	# Only 4 directions = much faster
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1)
	]

	for iter in erosion_iterations:
		var delta := PackedFloat32Array()
		delta.resize(w * h)
		delta.fill(0.0)

		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var idx: int = y * w + x
				var h0: float = heights[idx]

				var max_diff: float = 0.0
				var best_dir: Vector2i = Vector2i.ZERO

				for d in dirs:
					var nx: int = x + d.x
					var ny: int = y + d.y
					var h1: float = heights[ny * w + nx]
					var diff: float = h0 - h1
					if diff > max_diff:
						max_diff = diff
						best_dir = d

				if max_diff > talus_angle:
					var amount: float = (max_diff - talus_angle) * erosion_strength
					delta[idx] -= amount
					var nidx: int = (y + best_dir.y) * w + (x + best_dir.x)
					delta[nidx] += amount

		for i in heights.size():
			heights[i] += delta[i]

func _build_shaded_texture() -> void:
	var w: int = map_size.x
	var h: int = map_size.y
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)

	var light: Vector3 = light_direction.normalized()

	var col_low: Color = Color(0.82, 0.88, 0.76)
	var col_mid: Color = Color(0.74, 0.82, 0.66)
	var col_high: Color = Color(0.68, 0.76, 0.58)
	var col_peak: Color = Color(0.78, 0.80, 0.72)

	for y in h:
		for x in w:
			var height: float = _get_height_raw(x, y)
			var t: float = inverse_lerp(min_height_m, max_height_m, height)
			t = clamp(t, 0.0, 1.0)

			var base: Color
			if t < 0.45:
				base = col_low.lerp(col_mid, t / 0.45)
			elif t < 0.75:
				base = col_mid.lerp(col_high, (t - 0.45) / 0.30)
			else:
				base = col_high.lerp(col_peak, (t - 0.75) / 0.25)

			var hl: float = _get_height_raw(maxi(x - 1, 0), y)
			var hr: float = _get_height_raw(mini(x + 1, w - 1), y)
			var hu: float = _get_height_raw(x, maxi(y - 1, 0))
			var hd: float = _get_height_raw(x, mini(y + 1, h - 1))

			var dzx: float = (hr - hl) / 2.0
			var dzy: float = (hd - hu) / 2.0
			var normal: Vector3 = Vector3(-dzx, -dzy, 8.0).normalized()

			var ndotl: float = clamp(normal.dot(light), 0.0, 1.0)
			var shade: float = ambient + diffuse_strength * ndotl
			shade = pow(shade, 0.92)

			var final_col: Color = base * shade
			img.set_pixel(x, y, final_col)

	terrain_texture = ImageTexture.create_from_image(img)

func _get_height_raw(x: int, y: int) -> float:
	if heights.is_empty():
		return min_height_m
	x = clampi(x, 0, map_size.x - 1)
	y = clampi(y, 0, map_size.y - 1)
	return heights[y * map_size.x + x]

func get_height_meters(world_pos: Vector2) -> float:
	if heights.is_empty():
		return 0.0

	var x: float = world_pos.x
	var y: float = world_pos.y

	var x0: int = int(floor(x))
	var y0: int = int(floor(y))
	var x1: int = x0 + 1
	var y1: int = y0 + 1

	var sx: float = x - x0
	var sy: float = y - y0

	var h00: float = _get_height_raw(x0, y0)
	var h10: float = _get_height_raw(x1, y0)
	var h01: float = _get_height_raw(x0, y1)
	var h11: float = _get_height_raw(x1, y1)

	var h0: float = lerp(h00, h10, sx)
	var h1: float = lerp(h01, h11, sx)
	return lerp(h0, h1, sy)

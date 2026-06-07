class_name Cube

## Hex math yay
## via https://www.redblobgames.com/grids/hexagons/

@export var q: int
@export var r: int
@export var s: int

func _init(cq: int = 0, cr: int = 0, cs: int = 0) -> void:
	q = cq
	r = cr
	s = cs

func to_axial() -> Vector2i:
	return Vector2i(q, r)

static func from_axial(coords: Vector2i) -> Cube:
	return Cube.new(coords.x, coords.y, (-coords.x - coords.y))

## [param a], [param b] can be Vector3, Vector3i, or Cube.
## Note results returned are always Vector3 (floating point).
static func clerp(a, b, t: float) -> Vector3: ## Fractional
	var c: Vector3
	var d: Vector3
	
	if a is Cube:
		c = Vector3(a.q, a.r, a.s)
	elif a is Vector3:
		c = a
	elif a is Vector3i:
		c = Vector3(a)
	else:
		push_error("Why")
	
	if b is Cube:
		d = Vector3(b.q, b.r, b.s)
	elif b is Vector3:
		d = b
	elif b is Vector3i:
		d = Vector3(b)
	else:
		push_error("Why")
	
	return Vector3(
		lerp(c.x, d.x, t),
		lerp(c.y, d.y, t),
		lerp(c.z, d.z, t)
	)

static func sum(a: Cube, b: Cube) -> Cube:
	return Cube.new(a.q + b.q, a.r + b.r, a.s + b.s)

static func subtract(a: Cube, b: Cube) -> Cube:
	return Cube.new(a.q - b.q, a.r - b.r, a.s - b.s)

static func distance(a: Cube, b: Cube) -> int:
	var vec = subtract(a, b)
	return max(abs(vec.q), abs(vec.r), abs(vec.s))
	
static func cround(fq: float, fr: float, fs: float) -> Cube:
	var _cube: Cube = Cube.new(
		roundi(fq),
		roundi(fr),
		roundi(fs)
	)

	var q_diff: float = absf(_cube.q - fq)
	var r_diff: float = absf(_cube.r - fr)
	var s_diff: float = absf(_cube.s - fs)

	if q_diff > r_diff and q_diff > s_diff:
		_cube.q = -_cube.r - _cube.s
	elif r_diff > s_diff:
		_cube.r = -_cube.q - _cube.s
	else:
		_cube.s = -_cube.q - _cube.r

	return _cube

## Result is inclusive of [param a], exclusive of [param b].
static func get_inline(a: Cube, b: Cube) -> Array[Cube]:
	var n: int = Cube.distance(a, b)
	
	var epsilon := Vector3(1e-6, 2e-6, -3e-6)
	var af: Vector3 = epsilon + Vector3(
		a.q,
		a.r,
		a.s
	)
	
	var results: Array[Cube] = []
	for i in n:
		var lerped: Vector3 = clerp(af, b, 1.0/n * i)
		results.append(cround(lerped.x, lerped.y, lerped.z))
	return results

## Result is inclusive of [param a], exclusive of [param b].
static func get_inline_tiles(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var results: Array[Cube] = get_inline(Cube.from_axial(a), Cube.from_axial(b))
	var axial_results: Array[Vector2i] = []
	for cube: Cube in results:
		axial_results.append(cube.to_axial())
	return axial_results

## If these two tiles share an axis direction (flat sides), returns true.
## Returns false if these tiles are at all diagonal from each other (through points).
static func is_in_row(a: Vector2i, b: Vector2i) -> bool:
	var ac := Cube.from_axial(a)
	var bc := Cube.from_axial(b)
	if ac.q == bc.q:
		return true
	if ac.r == bc.r:
		return true
	if ac.s == bc.s:
		return true
	return false
	

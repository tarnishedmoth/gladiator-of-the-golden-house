class_name Facing

enum Cardinal {
	NORTH = 0,
	NORTHEAST = 1,
	SOUTHEAST = 2,
	SOUTH = 3,
	SOUTHWEST = 4,
	NORTHWEST = 5,
}

enum Relative{
	FRONT = 0,
	FRONT_RIGHT = 1,
	BACK_RIGHT = 2,
	BACK = 3,
	BACK_LEFT = 4,
	FRONT_LEFT = 5
}

const DIRECTIONS = [
	Vector2i(0, -1),   # 0 = NORTH
	Vector2i(1, -1),   # 1 = NORTHEAST
	Vector2i(1, 0),    # 2 = SOUTHEAST
	Vector2i(0, 1),    # 3 = SOUTH
	Vector2i(-1, 1),   # 4 = SOUTHWEST
	Vector2i(-1, 0),   # 5 = NORTHWEST
]

static func get_direction_from_facing(facing: int, relative: int) -> Vector2i:
	return DIRECTIONS[(facing + relative) % 6]

static func rotate_hex(unit_facing: Cardinal, hex_coords: Vector2i):
	var q = hex_coords.x
	var r = hex_coords.y
	for i in unit_facing:
		var old_q = q
		q = -r
		r = old_q + r
	return Vector2i(q, r)

static func rotate_hex_array(unit_facing: Cardinal, pattern: Array[Vector2i]) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for entry in pattern:
		targets.append(rotate_hex(unit_facing, entry))
	return targets


static func get_target_cells(pos: Vector2i, facing: Cardinal, pattern: Array[Vector2i]) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for entry in pattern:
		targets.append(pos + rotate_hex(facing, entry))
	return targets

## Returns a cardinal direction from "a" pointing to "b".
static func get_direction_to_coordinate(a: Vector2i, b: Vector2i) -> Cardinal:
	## We have to convert to floating point to use these methods
	var dir = Vector2(a).direction_to(Vector2(b))
	var diri = Vector2i(dir.sign())
	## TODO FIXME figure out why this isn't exactly working correctly
	## Perhaps use Vector2.angle_to() / Vector2.angle_to_point()
	return DIRECTIONS.find(dir) as Cardinal

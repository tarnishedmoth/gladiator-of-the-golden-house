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
	BACK_LEFt = 4,
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

static func get_target_cells(pos: Vector2i, facing: int, possible_target_pattern: Array) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []	
	for entry in possible_target_pattern:
		var dir = get_direction_from_facing(facing, entry[0])
		targets.append(pos + dir * entry[1])			
	return targets

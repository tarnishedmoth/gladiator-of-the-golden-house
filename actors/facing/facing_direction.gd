class_name Facing

enum Cardinal {
	NORTH = 0,
	NORTHEAST = 1,
	SOUTHEAST = 2,
	SOUTH = 3,
	SOUTHWEST = 4,
	NORTHWEST = 5,
}

static func rotate(pattern: DirectionPattern, center: Cardinal) -> DirectionPattern:
	## There is no way this is an efficient method
	var array = [
		pattern.twelve,
		pattern.two,
		pattern.four,
		pattern.six,
		pattern.eight,
		pattern.ten
	]
	
	for shifts in center:
		var front = array.pop_front()
		array.push_back(front)
		
	var rotated: DirectionPattern = DirectionPattern.new()
	rotated.twelve = array[0]
	rotated.two = array[1]
	rotated.four = array[2]
	rotated.six = array[3]
	rotated.eight = array[4]
	rotated.ten = array[5]
	
	return rotated

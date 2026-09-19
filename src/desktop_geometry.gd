extends RefCounted
## Physical desktop coordinates, including negative origins on secondary monitors.

static func fit_position(point: Vector2i, size: Vector2i, screens: Array[Rect2i]) -> Vector2i:
	if screens.is_empty():
		return point
	var chosen := screens[0]
	var best_distance := INF
	var center := Vector2(point) + Vector2(size) / 2.0
	for screen in screens:
		var distance := center.distance_squared_to(Vector2(screen.get_center()))
		if screen.has_point(Vector2i(center)):
			chosen = screen
			break
		if distance < best_distance:
			best_distance = distance
			chosen = screen
	return Vector2i(
		clampi(point.x, chosen.position.x, maxi(chosen.position.x, chosen.end.x - size.x)),
		clampi(point.y, chosen.position.y, maxi(chosen.position.y, chosen.end.y - size.y)))

static func work_areas() -> Array[Rect2i]:
	var areas: Array[Rect2i] = []
	for index in DisplayServer.get_screen_count():
		areas.append(DisplayServer.screen_get_usable_rect(index))
	return areas

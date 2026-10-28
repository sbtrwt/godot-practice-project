extends Node2D
## Asset-independent arena presentation layer for the prototype map.

const PLATFORM_COLOR := Color("#625b50")
const PLATFORM_EDGE := Color("#7fb477")
const ROCK_COLOR := Color("#aaa69a")
const SKY_COLOR := Color("#b8d6db")


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), SKY_COLOR)
	_draw_hills()
	_draw_island(Rect2(40.0, 490.0, 390.0, 150.0))
	_draw_island(Rect2(455.0, 390.0, 300.0, 120.0))
	_draw_island(Rect2(805.0, 500.0, 420.0, 145.0))
	_draw_island(Rect2(180.0, 245.0, 280.0, 95.0))
	_draw_island(Rect2(720.0, 210.0, 350.0, 105.0))
	_draw_rocks(Vector2(150.0, 550.0), 5)
	_draw_rocks(Vector2(580.0, 440.0), 4)
	_draw_rocks(Vector2(1010.0, 555.0), 6)
	_draw_palm(Vector2(910.0, 205.0))
	_draw_palm(Vector2(330.0, 238.0))


func _draw_hills() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 390.0), Vector2(180.0, 310.0), Vector2(340.0, 380.0),
		Vector2(530.0, 285.0), Vector2(760.0, 370.0), Vector2(980.0, 290.0),
		Vector2(1280.0, 360.0), Vector2(1280.0, 520.0), Vector2(0.0, 520.0),
	]), Color("#91b68e"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 455.0), Vector2(210.0, 385.0), Vector2(410.0, 450.0),
		Vector2(650.0, 370.0), Vector2(900.0, 455.0), Vector2(1110.0, 380.0),
		Vector2(1280.0, 430.0), Vector2(1280.0, 540.0), Vector2(0.0, 540.0),
	]), Color("#7fa77b"))


func _draw_island(rect: Rect2) -> void:
	var top := rect.position
	var right := rect.position + Vector2(rect.size.x, 0.0)
	var bottom_right := rect.position + rect.size
	var bottom_left := rect.position + Vector2(0.0, rect.size.y)
	draw_colored_polygon(PackedVector2Array([
		top + Vector2(18.0, 0.0), right - Vector2(18.0, 0.0),
		bottom_right - Vector2(30.0, 0.0), bottom_left + Vector2(30.0, 0.0),
	]), PLATFORM_COLOR)
	draw_line(top + Vector2(18.0, 0.0), right - Vector2(18.0, 0.0), PLATFORM_EDGE, 10.0)
	draw_line(bottom_left + Vector2(30.0, 0.0), bottom_right - Vector2(30.0, 0.0), Color("#393832"), 3.0)


func _draw_rocks(origin: Vector2, count: int) -> void:
	for index: int in count:
		var offset := Vector2(float(index) * 28.0, -float((index * 13) % 22))
		draw_colored_polygon(PackedVector2Array([
			origin + offset + Vector2(-12.0, 8.0), origin + offset + Vector2(-4.0, -12.0),
			origin + offset + Vector2(12.0, -8.0), origin + offset + Vector2(15.0, 10.0),
		]), ROCK_COLOR)


func _draw_palm(base: Vector2) -> void:
	draw_line(base, base + Vector2(0.0, -70.0), Color("#67523c"), 8.0)
	var frond_angles := PackedFloat32Array([-2.7, -2.1, -1.55, -1.0, -0.45])
	for angle: float in frond_angles:
		var tip: Vector2 = base + Vector2(cos(angle), sin(angle)) * 44.0 + Vector2(0.0, -70.0)
		draw_line(base + Vector2(0.0, -70.0), tip, Color("#477e4d"), 10.0)

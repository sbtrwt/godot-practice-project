extends Control
## Touch-friendly action buttons feeding the same InputMap as desktop controls.

@onready var _left: Button = $Movement/Left
@onready var _right: Button = $Movement/Right
@onready var _up: Button = $Movement/Up
@onready var _down: Button = $Movement/Down
@onready var _fire: Button = $Fire


func _ready() -> void:
	_bind_button(_left, &"move_left")
	_bind_button(_right, &"move_right")
	_bind_button(_up, &"move_up")
	_bind_button(_down, &"move_down")
	_bind_button(_fire, &"fire")


func _bind_button(button: Button, action: StringName) -> void:
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))

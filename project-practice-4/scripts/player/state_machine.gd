class_name StateMachine
extends RefCounted

var current_state: PlayerState
var states: Dictionary = {}

func add_state(state_name: String, state: PlayerState) -> void:
	states[state_name] = state

func change_state(state_name: String) -> void:
	if not states.has(state_name):
		push_error("Unknown player state: " + state_name)
		return

	var next_state: PlayerState = states[state_name]
	if current_state == next_state:
		return

	if current_state != null:
		current_state.exit()

	current_state = next_state
	current_state.enter()

func update(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)

func physics_update(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)

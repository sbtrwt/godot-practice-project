extends Control
## Presentation-only match HUD. It consumes the MatchViewModel and owns no rules.

@onready var _state_label: Label = $State
@onready var _timer_label: Label = $Timer
@onready var _score_label: Label = $Score
@onready var _return_button: Button = $ReturnButton
@onready var _kill_feed_label: Label = $KillFeed
@onready var _results_label: Label = $Results
@onready var _view_model: Node = $ViewModel


func _ready() -> void:
	Signal(_view_model, &"state_changed").connect(_on_state_changed)
	Signal(_view_model, &"timer_changed").connect(_on_timer_changed)
	Signal(_view_model, &"score_changed").connect(_on_score_changed)
	Signal(_view_model, &"kill_feed_changed").connect(_on_kill_feed_changed)
	Signal(_view_model, &"results_changed").connect(_on_results_changed)
	_return_button.pressed.connect(_on_return_button_pressed)


func _on_state_changed(state: StringName, can_return_to_lobby: bool) -> void:
	_state_label.text = str(state).to_upper()
	_return_button.visible = can_return_to_lobby


func _on_timer_changed(text: String) -> void:
	_timer_label.text = text


func _on_score_changed(text: String) -> void:
	_score_label.text = text


func _on_kill_feed_changed(text: String) -> void:
	_kill_feed_label.text = text


func _on_results_changed(text: String) -> void:
	_results_label.text = text
	_results_label.visible = not text.is_empty()


func _on_return_button_pressed() -> void:
	_view_model.call("return_to_lobby")

extends Node

enum GameState { TITLE, PLAYING, GAME_OVER }
var current_state: GameState = GameState.TITLE
var score: int = 0

var world_scene = preload("res://Scenes/Game/World.tscn")
var title_scene = preload("res://Scenes/UI/TitleScreen.tscn")
var game_over_scene = preload("res://Scenes/UI/GameOverScreen.tscn")

var current_world: Node = null
var current_ui: Control = null


func _ready():
	call_deferred("change_state", GameState.TITLE)


func change_state(new_state: GameState):
	current_state = new_state

	if current_ui:
		current_ui.queue_free()
	if current_world and new_state != GameState.GAME_OVER:
		if current_world.game_over.is_connected(_on_game_over):
			current_world.game_over.disconnect(_on_game_over)
		current_world.queue_free()
		current_world = null

	match current_state:
		GameState.TITLE:
			current_ui = title_scene.instantiate()
			add_child(current_ui)
			current_ui.get_node("StartButton").pressed.connect(_on_start_pressed)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameState.PLAYING:
			score = 0
			current_world = world_scene.instantiate()
			add_child(current_world)
			current_world.game_over.connect(_on_game_over)
			current_world.score_changed.connect(_on_score_changed)

			# We don't need to capture the mouse anymore since we have a fixed camera
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameState.GAME_OVER:
			current_ui = game_over_scene.instantiate()
			add_child(current_ui)
			current_ui.get_node("VBoxContainer/ScoreLabel").text = "Score: " + str(score)
			current_ui.get_node("VBoxContainer/RetryButton").pressed.connect(_on_retry_pressed)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_start_pressed():
	change_state(GameState.PLAYING)


func _on_retry_pressed():
	if current_world:
		if current_world.game_over.is_connected(_on_game_over):
			current_world.game_over.disconnect(_on_game_over)
		current_world.queue_free()
		current_world = null
	change_state(GameState.PLAYING)


func _on_game_over():
	if current_state == GameState.PLAYING:
		change_state(GameState.GAME_OVER)


func _on_score_changed(new_score):
	score = new_score
	# Update HUD if exists


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

extends Node3D

signal game_over
signal score_changed(new_score)

var score: int = 0
var max_enemies = 40
var current_enemies = 0

var enemy_scene = preload("res://Scenes/Entities/Enemy.tscn")
var coin_scene = preload("res://Scenes/Entities/Coin.tscn")
var player_scene = preload("res://Scenes/Entities/Player.tscn")

var player: Node3D
@onready var floor_node = $Floor

var debug_btn: Button
var is_debug_sphere_on = true

func _ready():
	# Spawn player
	player = player_scene.instantiate()
	player.position = Vector3(0, 2, 0)
	add_child(player)
	
	# Spawn initial coins and enemies
	for i in range(5):
		spawn_coin()
	for i in range(3):
		_on_enemy_spawn_timer()
		
	# Start spawn timers
	var enemy_timer = Timer.new()
	enemy_timer.wait_time = 1.5
	enemy_timer.autostart = true
	enemy_timer.timeout.connect(_on_enemy_spawn_timer)
	add_child(enemy_timer)
	
	var coin_timer = Timer.new()
	coin_timer.wait_time = 2.0
	coin_timer.autostart = true
	coin_timer.timeout.connect(spawn_coin)
	add_child(coin_timer)
	
	# Cleanup timer
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 5.0
	cleanup_timer.autostart = true
	cleanup_timer.timeout.connect(_cleanup_distant_objects)
	add_child(cleanup_timer)

	if OS.is_debug_build():
		var canvas = CanvasLayer.new()
		canvas.layer = 100 # Ensure it renders on top
		add_child(canvas)
		debug_btn = Button.new()
		
		# Better layout system for responsive fullscreen UI
		debug_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		debug_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		debug_btn.offset_right = -20
		debug_btn.offset_top = 20
		
		debug_btn.pressed.connect(_on_debug_toggle)
		canvas.add_child(debug_btn)
		_update_debug_btn_visuals()
		
		# Sync initial state for all entities
		get_tree().call_group("player", "toggle_debug", is_debug_sphere_on)
		get_tree().call_group("enemy", "toggle_debug", is_debug_sphere_on)
		get_tree().call_group("chick", "toggle_debug", is_debug_sphere_on)
		get_tree().call_group("egg", "toggle_debug", is_debug_sphere_on)

func _update_debug_btn_visuals():
	if is_debug_sphere_on:
		debug_btn.text = "Debug Sphere: ON"
		debug_btn.modulate = Color(0.5, 1.0, 0.5) # Light Green
	else:
		debug_btn.text = "Debug Sphere: OFF"
		debug_btn.modulate = Color(1.0, 0.6, 0.6) # Light Red

func _on_debug_toggle():
	is_debug_sphere_on = not is_debug_sphere_on
	_update_debug_btn_visuals()
	
	get_tree().call_group("player", "toggle_debug", is_debug_sphere_on)
	get_tree().call_group("enemy", "toggle_debug", is_debug_sphere_on)
	get_tree().call_group("chick", "toggle_debug", is_debug_sphere_on)
	get_tree().call_group("egg", "toggle_debug", is_debug_sphere_on)

func _process(_delta):
	if is_instance_valid(player):
		# Move floor smoothly to follow player without snapping to prevent shadow flicker
		floor_node.global_position = Vector3(player.global_position.x, -0.5, player.global_position.z)

func get_random_position() -> Vector3:
	if not is_instance_valid(player):
		return Vector3(0, 0.0, 0)
	
	var angle = randf() * TAU
	var dist = randf_range(15.0, 35.0)
	var pos = player.global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	pos.y = 0.0
	return pos

func spawn_coin():
	var coin = coin_scene.instantiate()
	coin.position = get_random_position()
	add_child(coin)

func _on_enemy_spawn_timer():
	if current_enemies >= max_enemies:
		return
	if not is_instance_valid(player):
		return
		
	var enemy = enemy_scene.instantiate()
	enemy.position = get_random_position()
	add_child(enemy)
	if enemy.has_method("toggle_debug"):
		enemy.toggle_debug(is_debug_sphere_on)
	current_enemies += 1

func _cleanup_distant_objects():
	if not is_instance_valid(player):
		return
		
	var max_dist = 80.0
	var player_pos = player.global_position
	
	for child in get_children():
		if child.is_in_group("enemy") or child.is_in_group("coin"):
			if child.global_position.distance_to(player_pos) > max_dist:
				if child.is_in_group("enemy"):
					current_enemies -= 1
				child.queue_free()

func add_score(amount: int):
	score += amount
	score_changed.emit(score)

func trigger_game_over():
	game_over.emit()

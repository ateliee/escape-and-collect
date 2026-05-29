extends Node3D

signal game_over
signal score_changed(new_score)

var score: int = 0
var max_enemies = 10
var current_enemies = 0

var enemy_scene = preload("res://Scenes/Entities/Enemy.tscn")
var coin_scene = preload("res://Scenes/Entities/Coin.tscn")
var player_scene = preload("res://Scenes/Entities/Player.tscn")

@onready var nav_region = $NavigationRegion3D

func _ready():
	# Bake navigation mesh at runtime so enemies can navigate
	nav_region.bake_navigation_mesh(true)
	
	# Wait for baking to finish
	await get_tree().create_timer(0.5).timeout
	
	# Spawn player
	var player = player_scene.instantiate()
	player.position = Vector3(0, 2, 0)
	add_child(player)
	
	# Spawn initial coins
	for i in range(5):
		spawn_coin()
		
	# Start spawn timers
	var enemy_timer = Timer.new()
	enemy_timer.wait_time = 5.0
	enemy_timer.autostart = true
	enemy_timer.timeout.connect(_on_enemy_spawn_timer)
	add_child(enemy_timer)
	
	var coin_timer = Timer.new()
	coin_timer.wait_time = 3.0
	coin_timer.autostart = true
	coin_timer.timeout.connect(spawn_coin)
	add_child(coin_timer)

func get_random_position() -> Vector3:
	return Vector3(randf_range(-18, 18), 2.0, randf_range(-18, 18))

func spawn_coin():
	var coin = coin_scene.instantiate()
	coin.position = get_random_position()
	add_child(coin)

func _on_enemy_spawn_timer():
	if current_enemies >= max_enemies:
		return
	var enemy = enemy_scene.instantiate()
	# Spawn enemy away from center
	var pos = get_random_position()
	while pos.length() < 10.0:
		pos = get_random_position()
	enemy.position = pos
	add_child(enemy)
	current_enemies += 1

func add_score(amount: int):
	score += amount
	score_changed.emit(score)

func trigger_game_over():
	game_over.emit()

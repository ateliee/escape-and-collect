extends CharacterBody3D

const SPEED = 5.0
var player: Node3D = null
var offset_dir = Vector3.ZERO
var time_passed = 0.0
@onready var model = $ModelRoot

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	# Random offset so chicks don't perfectly overlap
	var angle = randf() * TAU
	offset_dir = Vector3(cos(angle), 0, sin(angle)) * randf_range(1.0, 2.5)

func _physics_process(delta):
	if not is_instance_valid(player):
		return
		
	# Gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	var target_pos = player.global_position + offset_dir
	target_pos.y = global_position.y
	
	var dir = target_pos - global_position
	dir.y = 0
	
	if dir.length() > 0.5:
		dir = dir.normalized()
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		
		# Rotate the whole CharacterBody3D to face movement direction
		var look_target_pos = global_position + Vector3(velocity.x, 0, velocity.z)
		if look_target_pos.distance_to(global_position) > 0.1:
			var look_dir = atan2(-velocity.x, -velocity.z)
			rotation.y = lerp_angle(rotation.y, look_dir, 15 * delta)
		
		# Hop animation on the model
		time_passed += delta * 20.0
		model.position.y = abs(sin(time_passed * 0.5)) * 0.2
		model.rotation.z = sin(time_passed) * 0.1
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		model.position.y = lerp(model.position.y, 0.0, 15 * delta)
		model.rotation.z = lerp(model.rotation.z, 0.0, 15 * delta)

	move_and_slide()

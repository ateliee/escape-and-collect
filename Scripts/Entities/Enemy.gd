extends CharacterBody3D

const SPEED = 3.0

@onready var model = $ModelRoot

var player: Node3D = null

func _ready():
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# (Removed hardcoded scale)

var time_passed: float = 0.0

func _physics_process(delta):
	if not is_instance_valid(player):
		return
		
	# Add gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	# Direct pursuit towards player
	var dir = (player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED

	# Rotate to face movement and animate
	if velocity.length_squared() > 0.1:
		var look_dir = atan2(-velocity.x, -velocity.z)
		model.rotation.y = lerp_angle(model.rotation.y, look_dir, 10 * delta)
		
		# Procedural hopping/wobbling animation
		time_passed += delta * 15.0
		model.position.y = abs(sin(time_passed * 0.5)) * 0.3
		model.rotation.z = sin(time_passed) * 0.15
	else:
		model.position.y = lerp(model.position.y, 0.0, 10 * delta)
		model.rotation.z = lerp(model.rotation.z, 0.0, 10 * delta)

	move_and_slide()
	
	# Check for collisions with player (Removed game over logic)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		# if collider and collider.is_in_group("player"):
		# 	if collider.has_method("die"):
		# 		collider.die()

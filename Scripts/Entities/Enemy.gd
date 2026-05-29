extends CharacterBody3D

const SPEED = 3.0

@onready var model = $ModelRoot

var player: Node3D = null

func _ready():
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# Make enemy look a bit different by coloring it red if possible, or just scale it slightly
	model.scale = Vector3(1.1, 1.1, 1.1)

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

	# Rotate to face movement
	if velocity.length_squared() > 0.1:
		var look_dir = atan2(-velocity.x, -velocity.z)
		model.rotation.y = lerp_angle(model.rotation.y, look_dir, 10 * delta)

	move_and_slide()
	
	# Check for collisions with player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_method("die"):
				collider.die()

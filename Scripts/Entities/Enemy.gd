extends CharacterBody3D

const SPEED = 4.5

@onready var nav_agent = $NavigationAgent3D
@onready var model = $ModelRoot

var player: Node3D = null

func _ready():
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# We'll use a slightly red/darker material for the enemy, but for now we just use the model
	# You can change the model scale or add a red outline later

func _physics_process(delta):
	if not is_instance_valid(player):
		return
		
	# Add gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	# Update navigation target
	nav_agent.target_position = player.global_position
	
	if nav_agent.is_navigation_finished():
		return

	var current_agent_position = global_position
	var next_path_position = nav_agent.get_next_path_position()
	var new_velocity = (next_path_position - current_agent_position).normalized() * SPEED
	
	velocity.x = new_velocity.x
	velocity.z = new_velocity.z

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

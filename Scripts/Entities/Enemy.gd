extends CharacterBody3D

const SPEED = 3.0

var player: Node3D = null
var time_passed: float = 0.0
var state_timer: float = 0.0
var wander_dir: Vector3 = Vector3.ZERO
var is_wandering: bool = false

@onready var model = $ModelRoot


func _ready():
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# Setup eat hitbox
	var eat_area = Area3D.new()
	eat_area.collision_layer = 0
	eat_area.collision_mask = 16  # Layer 5 (Chicks)
	var eat_shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.2  # Eat radius
	eat_shape.shape = sphere
	eat_area.add_child(eat_shape)
	add_child(eat_area)
	eat_area.body_entered.connect(_on_eat_area_entered)

	# Setup vision visualizer
	var vision_mesh = MeshInstance3D.new()
	vision_mesh.name = "VisionMesh"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 15.0
	sphere_mesh.height = 30.0
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.8, 0.8, 0.8, 0.15)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere_mesh.material = mat
	vision_mesh.mesh = sphere_mesh
	vision_mesh.visible = false
	add_child(vision_mesh)


func _on_eat_area_entered(body: Node3D):
	if body.is_in_group("chick"):
		var effect = preload("res://Scenes/Entities/EggHatchEffect.tscn").instantiate()
		effect.position = body.global_position
		get_parent().call_deferred("add_child", effect)
		body.queue_free()

	# (Removed hardcoded scale)


func _physics_process(delta):
	if not is_instance_valid(player):
		return

	# Add gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	# Find closest valid target within vision range (Chicks only)
	var targets = get_tree().get_nodes_in_group("chick")

	var closest_target = null
	var closest_dist = 15.0  # Vision radius

	for t in targets:
		if not is_instance_valid(t):
			continue
		var dist = global_position.distance_to(t.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_target = t

	# Pursuit towards target if found
	if closest_target:
		var dir = closest_target.global_position - global_position
		dir.y = 0
		if dir.length() > 0.1:
			dir = dir.normalized()
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	else:
		state_timer -= delta
		if state_timer <= 0:
			if randf() > 0.5:
				# Wander around
				is_wandering = true
				state_timer = randf_range(2.0, 5.0)
				var angle = randf() * TAU
				wander_dir = Vector3(cos(angle), 0, sin(angle))
			else:
				# Stand still
				is_wandering = false
				state_timer = randf_range(2.0, 4.0)

		if is_wandering:
			velocity.x = wander_dir.x * (SPEED * 0.4)
			velocity.z = wander_dir.z * (SPEED * 0.4)
		else:
			# Decelerate if standing still
			velocity.x = move_toward(velocity.x, 0, SPEED * 5.0 * delta)
			velocity.z = move_toward(velocity.z, 0, SPEED * 5.0 * delta)

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


func toggle_debug(show: bool):
	if has_node("DebugMesh"):
		$DebugMesh.visible = show
	if has_node("VisionMesh"):
		$VisionMesh.visible = show

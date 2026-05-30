extends CharacterBody3D

const SPEED = 4.0
var player: Node3D = null
var offset_dir = Vector3.ZERO
var current_state: String = "follow"
var time_passed = 0.0

@onready var model = $ModelRoot


func _ready():
	collision_layer = 16

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# Random offset so chicks don't perfectly overlap
	var angle = randf() * TAU
	offset_dir = Vector3(cos(angle), 0, sin(angle)) * randf_range(1.0, 2.5)

	# Setup alert visualizer
	var vision_mesh = MeshInstance3D.new()
	vision_mesh.name = "VisionMesh"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 10.0
	sphere_mesh.height = 20.0
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.5, 0.0, 0.15)  # Orange for alert
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere_mesh.material = mat
	vision_mesh.mesh = sphere_mesh
	vision_mesh.visible = false
	add_child(vision_mesh)


func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	# 1. State check
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest_enemy = null
	# Hysteresis: If already fleeing, keep fleeing until enemy is > 15m away
	var closest_enemy_dist = 15.0 if current_state == "flee" else 10.0

	for e in enemies:
		if not is_instance_valid(e):
			continue
		var dist = global_position.distance_to(e.global_position)
		if dist < closest_enemy_dist:
			closest_enemy_dist = dist
			closest_enemy = e

	if closest_enemy:
		current_state = "flee"
	else:
		if current_state == "flee":
			# Once safe from enemy, become lost and stand still
			current_state = "lost"

		if is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if current_state == "lost":
				# Player must come close to rescue the chick
				if dist < 8.0:
					current_state = "follow"
			elif current_state == "follow":
				# Lose the chick if player runs too far away
				if dist > 30.0:
					current_state = "lost"

	# 2. Movement logic based on state
	var target_vel_x = 0.0
	var target_vel_z = 0.0
	var look_dir = rotation.y
	var is_moving = false

	if current_state == "flee":
		var dir = global_position - closest_enemy.global_position
		dir.y = 0
		if dir.length() > 0.1:
			dir = dir.normalized()
			target_vel_x = dir.x * (SPEED * 1.5)
			target_vel_z = dir.z * (SPEED * 1.5)
			is_moving = true
			look_dir = atan2(-dir.x, -dir.z)

	elif current_state == "follow":
		# Calculate dynamic triangular formation
		var all_chicks = get_tree().get_nodes_in_group("chick")
		var followers = []
		for c in all_chicks:
			if c.get("current_state") == "follow":
				followers.append(c)

		var index = followers.find(self)
		if index == -1:
			index = 0

		var row = int(floor((sqrt(8 * index + 1) - 1) / 2.0))
		var first_in_row = (row * (row + 1)) / 2
		var col = index - first_in_row

		var spacing_x = 1.0
		var spacing_z = 1.0
		var local_x = (col - (row / 2.0)) * spacing_x
		var local_z = (row + 1.5) * spacing_z

		var player_basis = player.global_transform.basis
		var formation_offset = player_basis.x * local_x + player_basis.z * local_z

		var target_pos = player.global_position + formation_offset
		var dir = target_pos - global_position
		dir.y = 0
		var dist = dir.length()

		if dist > 0.2:
			dir = dir.normalized()
			var catchup_speed = SPEED + (dist * 0.4)
			target_vel_x = dir.x * catchup_speed
			target_vel_z = dir.z * catchup_speed
			is_moving = true
			look_dir = atan2(-dir.x, -dir.z)

	# Apply velocity
	if is_moving:
		velocity.x = target_vel_x
		velocity.z = target_vel_z
		rotation.y = lerp_angle(rotation.y, look_dir, 15 * delta)

		time_passed += delta * 20.0
		model.position.y = abs(sin(time_passed * 0.5)) * 0.2
		model.rotation.z = sin(time_passed) * 0.1
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		model.position.y = lerp(model.position.y, 0.0, 15 * delta)
		model.rotation.z = lerp(model.rotation.z, 0.0, 15 * delta)

	move_and_slide()


func toggle_debug(show: bool):
	if has_node("DebugMesh"):
		$DebugMesh.visible = show
	if has_node("VisionMesh"):
		$VisionMesh.visible = show

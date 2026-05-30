extends RigidBody3D

const MOVE_FORCE = 30.0
const DASH_FORCE_MULTIPLIER = 2.5
const MAX_SPEED = 6.0
const DASH_MAX_SPEED = 12.0
const JUMP_IMPULSE = 25.0
const DASH_DURATION = 0.3
const DASH_COOLDOWN = 1.0

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var throw_cooldown = 0.0

@onready var spring_arm = $SpringArm3D
func _ready():
	# Ensure camera is top down and detached from torso rotation
	spring_arm.top_level = true
	spring_arm.rotation_degrees = Vector3(-45, 0, 0)
	spring_arm.spring_length = 15.0
	
	# Force maximized mode as requested (large but not a separate macOS space)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	
	# Register action_throw if it hasn't been loaded from project.godot yet
	if not InputMap.has_action("action_throw"):
		InputMap.add_action("action_throw")
		var ev1 = InputEventKey.new()
		ev1.physical_keycode = KEY_E
		InputMap.action_add_event("action_throw", ev1)
		var ev2 = InputEventMouseButton.new()
		ev2.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("action_throw", ev2)

func _physics_process(delta):
	# Handle dash timers
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	elif Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN

	var force_mult = DASH_FORCE_MULTIPLIER if is_dashing else 1.0
	var speed_limit = DASH_MAX_SPEED if is_dashing else MAX_SPEED

	# Tank controls logic
	var turn_input = Input.get_axis("move_right", "move_left") # Left turns positive (CCW), Right turns negative (CW)
	var forward_input = Input.get_axis("move_forward", "move_back") # W is -1, S is 1
	
	# Steer left/right
	if abs(turn_input) > 0.1:
		angular_velocity.y = turn_input * 2.5
	else:
		angular_velocity.y = move_toward(angular_velocity.y, 0.0, 15.0 * delta)
		
	# Move forward/back
	if abs(forward_input) > 0.1:
		var forward_dir = -global_transform.basis.z # Player's facing direction
		forward_dir.y = 0
		forward_dir = forward_dir.normalized()
		
		var current_horiz_vel = Vector3(linear_velocity.x, 0, linear_velocity.z)
		if current_horiz_vel.length() < speed_limit:
			apply_central_force(forward_dir * -forward_input * MOVE_FORCE * force_mult * mass)

	# Handle throw cooldown
	if throw_cooldown > 0:
		throw_cooldown -= delta
		
	# Throwing logic (fallback to key check if action map fails)
	if (Input.is_action_just_pressed("action_throw") or Input.is_key_pressed(KEY_E) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and throw_cooldown <= 0:
		throw_egg()
		throw_cooldown = 0.1

func throw_egg():
	var egg_scene = preload("res://Scenes/Entities/Egg.tscn")
	var egg = egg_scene.instantiate()
	
	# Spawn egg slightly in front and above
	var throw_dir = -global_transform.basis.z
	var look_rot = rotation.y
	throw_dir = Vector3(sin(look_rot), 0, cos(look_rot)).normalized()
	
	# Set position BEFORE adding to tree to avoid physics state errors
	egg.position = global_position + Vector3(0, 1.0, 0) + throw_dir * 0.5
	
	var throw_force = 6.0
	throw_dir.y = 1.0 # arc upwards
	egg.linear_velocity = throw_dir.normalized() * throw_force
	
	if egg.has_method("toggle_debug"):
		egg.toggle_debug(is_debug_on)
	get_parent().call_deferred("add_child", egg)
	
func _process(delta):
	# Update camera position in _process for smooth rendering, preserving the Y offset
	spring_arm.global_position = self.global_position + Vector3(0, 1.5, 0)
	
	# Smoothly rotate the camera to follow the player's facing direction
	if linear_velocity.length_squared() > 0.5:
		spring_arm.rotation.y = lerp_angle(spring_arm.rotation.y, rotation.y, 2.0 * delta)
		
	# Simple procedural run animation for the chicken model
	if get_node_or_null("ModelRoot"):
		var model = $ModelRoot
		if linear_velocity.length_squared() > 0.5:
			var time_passed = Time.get_ticks_msec() / 1000.0 * 15.0
			model.position.y = abs(sin(time_passed * 0.5)) * 0.3
			model.rotation.z = sin(time_passed) * 0.15
		else:
			model.position.y = lerp(model.position.y, 0.0, 10 * delta)
			model.rotation.z = lerp(model.rotation.z, 0.0, 10 * delta)

func die():
	var world = get_parent()
	if world.has_method("trigger_game_over"):
		world.trigger_game_over()

var is_debug_on = true
func toggle_debug(show: bool):
	is_debug_on = show
	if has_node("DebugMesh"):
		$DebugMesh.visible = show

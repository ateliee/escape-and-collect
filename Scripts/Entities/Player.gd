extends CharacterBody3D

const SPEED = 5.0
const DASH_SPEED = 15.0
const JUMP_VELOCITY = 6.0
const DASH_DURATION = 0.3
const DASH_COOLDOWN = 1.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0

@onready var spring_arm = $SpringArm3D
@onready var model = $ModelRoot # We'll put the glb instance here

func _ready():
	# Configure spring arm for 3rd person
	pass

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.005)
		spring_arm.rotate_x(-event.relative.y * 0.005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle dash
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

	var current_speed = DASH_SPEED if is_dashing else SPEED

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		# Rotate model to face movement direction
		var look_dir = atan2(-velocity.x, -velocity.z)
		model.rotation.y = lerp_angle(model.rotation.y, look_dir - rotation.y, 10 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

# Called by enemy when touching player
func die():
	# Inform world
	var world = get_parent()
	if world.has_method("trigger_game_over"):
		world.trigger_game_over()

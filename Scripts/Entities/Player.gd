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

@onready var spring_arm = $SpringArm3D
var limbs = []

func _ready():
	# Ensure camera is top down and detached from torso rotation
	spring_arm.top_level = true
	spring_arm.rotation_degrees = Vector3(-45, 0, 0)
	spring_arm.spring_length = 7.0
	
	# Delay ragdoll generation slightly to ensure world is ready
	call_deferred("_setup_ragdoll")

func _setup_ragdoll():
	# Create limbs
	# Head
	create_limb("Head", Vector3(0, 1.2, 0), true)
	# Left Arm
	create_limb("ArmL", Vector3(-0.6, 0.6, 0), false)
	# Right Arm
	create_limb("ArmR", Vector3(0.6, 0.6, 0), false)
	# Left Leg
	create_limb("LegL", Vector3(-0.3, -0.7, 0), false)
	# Right Leg
	create_limb("LegR", Vector3(0.3, -0.7, 0), false)

func create_limb(limb_name: String, offset: Vector3, is_head: bool):
	var rb = RigidBody3D.new()
	rb.name = limb_name
	rb.collision_layer = 0 # Don't collide with enemies directly
	rb.collision_mask = 1 # Collide with floor
	rb.mass = 0.5
	
	var mesh_inst = MeshInstance3D.new()
	var col = CollisionShape3D.new()
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 0.9)
	
	var phys_mat = PhysicsMaterial.new()
	phys_mat.friction = 0.0
	rb.physics_material_override = phys_mat
	
	if is_head:
		var sphere = SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.6
		sphere.material = mat
		mesh_inst.mesh = sphere
		var shape = SphereShape3D.new()
		shape.radius = 0.3
		col.shape = shape
	else:
		var is_leg = "Leg" in limb_name
		if is_leg:
			var cap = CapsuleMesh.new()
			cap.radius = 0.15
			cap.height = 0.6
			cap.material = mat
			mesh_inst.mesh = cap
			var shape = CapsuleShape3D.new()
			shape.radius = 0.15
			shape.height = 0.6
			col.shape = shape
		else:
			var box = BoxMesh.new()
			box.size = Vector3(0.2, 0.7, 0.2)
			box.material = mat
			mesh_inst.mesh = box
			var shape = BoxShape3D.new()
			shape.size = box.size
			col.shape = shape
		
	rb.add_child(mesh_inst)
	rb.add_child(col)
	
	get_parent().add_child(rb)
	rb.global_position = self.global_position + offset
	limbs.append(rb)
	
	var joint = PinJoint3D.new()
	get_parent().add_child(joint)
	# Place joint between torso and limb
	if is_head:
		joint.global_position = self.global_position + Vector3(0, 1.0, 0)
	elif "Arm" in limb_name:
		# Arm joints closer to shoulders
		joint.global_position = self.global_position + Vector3(offset.x * 0.7, 0.8, 0)
	elif "Leg" in limb_name:
		# Leg joints closer to hips
		joint.global_position = self.global_position + Vector3(offset.x * 0.7, 0.1, 0)
		
	joint.node_a = self.get_path()
	joint.node_b = rb.get_path()

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

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = Vector3.ZERO
	
	if input_dir.length() > 0:
		var cam_basis = spring_arm.global_transform.basis
		var cam_forward = -cam_basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		
		var cam_right = cam_basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()
		
		direction = (cam_right * input_dir.x - cam_forward * input_dir.y).normalized()
	
	# Apply force for movement
	if direction.length() > 0:
		var current_horiz_vel = Vector3(linear_velocity.x, 0, linear_velocity.z)
		if current_horiz_vel.length() < speed_limit:
			apply_central_force(direction * MOVE_FORCE * force_mult * mass)
			
		# Rotate visual facing towards movement using angular velocity
		var target_angle = atan2(-direction.x, -direction.z)
		var angle_diff = wrapf(target_angle - rotation.y, -PI, PI)
		angular_velocity.y = angle_diff * 10.0

	# Handle jump (check if on floor is tricky for RigidBody, using raycast or contact points is better)
	# For simplicity, we just allow jump if Y velocity is close to 0 and we are near Y=0.5
	if Input.is_action_just_pressed("jump") and abs(linear_velocity.y) < 0.1 and global_position.y < 1.0:
		apply_central_impulse(Vector3.UP * JUMP_IMPULSE)

func _process(delta):
	# Update camera position in _process for smooth rendering, preserving the Y offset
	spring_arm.global_position = self.global_position + Vector3(0, 1.5, 0)
	
	# Smoothly rotate the camera to follow the player's facing direction
	# Only do this if the player is actually moving/facing a clear direction
	if linear_velocity.length_squared() > 0.5:
		spring_arm.rotation.y = lerp_angle(spring_arm.rotation.y, rotation.y, 2.0 * delta)

func die():
	var world = get_parent()
	if world.has_method("trigger_game_over"):
		world.trigger_game_over()

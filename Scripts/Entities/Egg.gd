extends RigidBody3D

var chick_scene = preload("res://Scenes/Entities/Chick.tscn")
var hatched = false

var can_hatch = false

func _ready():
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
	
	# Fallback timer in case it never hits anything
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(hatch)
	add_child(timer)
	timer.start()
	
	# Prevent instant hatching from spawning too close to the floor
	var delay = Timer.new()
	delay.wait_time = 0.2
	delay.one_shot = true
	delay.timeout.connect(func(): can_hatch = true)
	add_child(delay)
	delay.start()

func _on_body_entered(_body):
	if can_hatch:
		hatch()

func hatch():
	if hatched:
		return
	hatched = true
	
	var chick = chick_scene.instantiate()
	get_parent().call_deferred("add_child", chick)
	chick.global_position = global_position
	
	# Spawn particle or effect here if desired
	
	queue_free()

func toggle_debug(show: bool):
	if has_node("DebugMesh"):
		$DebugMesh.visible = show

extends Area3D

const ROTATION_SPEED = 2.0


func _process(delta):
	rotate_y(ROTATION_SPEED * delta)


func _on_body_entered(body):
	if body.is_in_group("player"):
		var world = get_tree().get_first_node_in_group("world")
		if world and world.has_method("add_score"):
			world.add_score(1)
		queue_free()

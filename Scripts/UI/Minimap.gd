extends Control

var map_scale: float = 2.0 # World distance to minimap pixels
var map_radius: float = 150.0 # Visual radius of the minimap
var player: Node3D = null

func _ready():
	custom_minimum_size = Vector2(map_radius * 2, map_radius * 2)

func _process(_delta):
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			
	# Redraw every frame
	queue_redraw()

func _draw():
	# Draw background (circular white area)
	var center = Vector2(map_radius, map_radius)
	draw_circle(center, map_radius, Color(1, 1, 1, 0.7))
	
	if not is_instance_valid(player):
		return
		
	# Draw player at center (Red)
	draw_circle(center, 8.0, Color(1, 0, 0, 1))
	
	# Draw enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
			
		var offset = enemy.global_position - player.global_position
		var map_pos = Vector2(offset.x, offset.z) * map_scale
		
		# Only draw if within the minimap circle
		if map_pos.length() <= map_radius:
			draw_circle(center + map_pos, 6.0, Color(0, 0, 1, 1)) # Blue dot

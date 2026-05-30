extends SceneTree
func _init():
    var scene = preload("res://Assets/Models/dog.glb")
    var dog = scene.instantiate()
    var mesh_inst = dog.get_node("Cube_Cube_001") as MeshInstance3D
    var aabb = mesh_inst.get_aabb()
    print("AABB Position: ", aabb.position)
    print("AABB Size: ", aabb.size)
    print("Center: ", aabb.position + aabb.size / 2.0)
    quit()

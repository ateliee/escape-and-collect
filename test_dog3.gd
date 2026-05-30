extends SceneTree
func _init():
    var scene = preload("res://Assets/Models/dog.glb")
    var dog = scene.instantiate()
    var mesh_inst = dog.get_node("Cube_Cube_001") as MeshInstance3D
    print("Mesh local transform: ", mesh_inst.transform)
    print("Mesh position: ", mesh_inst.position)
    quit()

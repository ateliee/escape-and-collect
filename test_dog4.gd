extends SceneTree
func _init():
    var scene = preload("res://Assets/Models/dog.glb")
    var dog = scene.instantiate()
    dog.transform = Transform3D(Basis(Vector3(0, 1, 0), -PI/2), Vector3(-0.716, 3.401, 1.182))
    var mesh_inst = dog.get_node("Cube_Cube_001") as MeshInstance3D
    var aabb = mesh_inst.get_aabb()
    
    # Calculate AABB in parent space
    var xform = dog.transform * mesh_inst.transform
    var min_p = xform * aabb.position
    var max_p = xform * (aabb.position + aabb.size)
    print("New Min: ", min_p)
    print("New Max: ", max_p)
    var center = (min_p + max_p) / 2.0
    print("New Center: ", center)
    quit()

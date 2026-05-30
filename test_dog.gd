extends SceneTree
func _init():
    var scene = preload("res://Assets/Models/dog.glb")
    var dog = scene.instantiate()
    print("Dog loaded, type: ", dog.get_class())
    for child in dog.get_children():
        print("Child: ", child.name, " type: ", child.get_class())
        if child is MeshInstance3D:
            var aabb = child.get_aabb()
            print("Mesh AABB size: ", aabb.size)
    quit()

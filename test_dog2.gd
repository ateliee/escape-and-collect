extends SceneTree
func _init():
    var scene = preload("res://Assets/Models/dog.glb")
    var dog = scene.instantiate()
    var mesh_inst = dog.get_node("Cube_Cube_001") as MeshInstance3D
    var mesh = mesh_inst.mesh
    var mat = mesh.surface_get_material(0)
    print("Material: ", mat)
    if mat and mat is BaseMaterial3D:
        print("Transparency mode: ", mat.transparency)
        print("Albedo color: ", mat.albedo_color)
        print("Texture: ", mat.albedo_texture)
    quit()

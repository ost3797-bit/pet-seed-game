extends SceneTree
func _init():
    var joystick_scene = preload("res://addons/virtual_joystick/virtual_joystick_scene.tscn")
    var joystick = joystick_scene.instantiate()
    joystick.scale = Vector2(0.8, 0.8)
    joystick.position = Vector2(40, 450)
    print("Before add_child: position=", joystick.position, " scale=", joystick.scale)
    var root = Node2D.new()
    root.add_child(joystick)
    print("After add_child: position=", joystick.position, " scale=", joystick.scale)
    quit()

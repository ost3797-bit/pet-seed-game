extends SceneTree
func _init():
	var f = FileAccess.open('res://keys.txt', FileAccess.WRITE)
	f.store_line('KEY_LEFT: ' + str(KEY_LEFT))
	f.store_line('KEY_UP: ' + str(KEY_UP))
	f.store_line('KEY_RIGHT: ' + str(KEY_RIGHT))
	f.store_line('KEY_DOWN: ' + str(KEY_DOWN))
	f.close()
	quit()

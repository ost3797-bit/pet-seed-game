extends SceneTree
func _init():
	for action in InputMap.get_actions():
		print(action, ' : ', InputMap.action_get_events(action))
	quit()

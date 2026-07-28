extends SceneTree
func _init():
	var actions = {'interact': [KEY_SPACE], 'move_left': [KEY_LEFT, KEY_A], 'move_right': [KEY_RIGHT, KEY_D], 'move_up': [KEY_UP, KEY_W], 'move_down': [KEY_DOWN, KEY_S]}
	for a in actions:
		if not InputMap.has_action(a): InputMap.add_action(a)
		InputMap.action_erase_events(a)
		for k in actions[a]:
			var ev = InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(a, ev)
		ProjectSettings.set_setting('input/' + a, InputMap.action_get_events(a))
	ProjectSettings.save()
	print('Inputs fixed and saved')
	quit()

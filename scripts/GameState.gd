extends Node

const SAVE_PATH := "user://savegame.save"

var player_name := "새싹이"
var seed_type := "sky_seed"
var character_style_id := 0
var current_quest: StringName = &"water"
var water_cleared := false
var temp_cleared := false
var air_cleared := false
var temp_phase_id := 0  # 0: 시작(씨앗대화), 1: 목수대화(퍼즐진입), 2: 그늘막 획득완료(햇빛막기진입)
var air_phase_id := 0   # 0: 시작(씨앗대화), 1: 마법사대화(분류미니게임), 2: 마법봉완성(공기정화진입)
var just_cleared_temp := false
var just_cleared_air := false



func _ready() -> void:
	_init_fallback_fonts()
	_register_input_actions()


func _init_fallback_fonts() -> void:
	if ResourceLoader.exists("res://assets/fonts/korean.ttf"):
		var korean_font := load("res://assets/fonts/korean.ttf") as FontFile
		if korean_font != null:
			if ResourceLoader.exists("res://assets/fonts/emoji.ttf"):
				var emoji_font := load("res://assets/fonts/emoji.ttf") as FontFile
				if emoji_font != null:
					korean_font.fallbacks = [emoji_font]
			ThemeDB.fallback_font = korean_font


func _register_input_actions() -> void:
	var key_sets := {
		&"move_left": [KEY_A, KEY_LEFT],
		&"move_right": [KEY_D, KEY_RIGHT],
		&"move_up": [KEY_W, KEY_UP],
		&"move_down": [KEY_S, KEY_DOWN],
		&"interact": [KEY_SPACE, KEY_ENTER]
	}
	for action: StringName in key_sets:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode: Key in key_sets[action]:
			var event := InputEventKey.new()
			event.keycode = keycode
			InputMap.action_add_event(action, event)


func new_game(new_name: String, new_seed_type: String, new_style_id: int) -> void:
	player_name = new_name.strip_edges()
	if player_name.is_empty():
		player_name = "새싹이"
	seed_type = new_seed_type
	character_style_id = new_style_id
	water_cleared = false
	temp_cleared = false
	air_cleared = false
	temp_phase_id = 0
	air_phase_id = 0
	just_cleared_temp = false
	just_cleared_air = false
	update_current_quest()
	save_game()


func jump_to_air_quest() -> void:
	water_cleared = true
	temp_cleared = true
	air_cleared = false
	temp_phase_id = 0
	air_phase_id = 1      # 마법사 NPC 옆에서 바로 미니게임을 진행할 수 있도록 1단계 설정
	just_cleared_temp = false
	just_cleared_air = false
	update_current_quest()
	save_game()


func complete_quest(quest_name: StringName) -> void:
	match quest_name:
		&"water": water_cleared = true
		&"temp":
			temp_cleared = true
			temp_phase_id = 0
		&"air":
			air_cleared = true
			air_phase_id = 0
			just_cleared_air = true
	update_current_quest()
	save_game()


func update_current_quest() -> void:
	if not water_cleared:
		current_quest = &"water"
	elif not temp_cleared:
		current_quest = &"temp"
	elif not air_cleared:
		current_quest = &"air"
	else:
		current_quest = &"complete"


func is_all_clear() -> bool:
	return water_cleared and temp_cleared and air_cleared


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var data := {
		"player_name": player_name,
		"seed_type": seed_type,
		"character_style_id": character_style_id,
		"water_cleared": water_cleared,
		"temp_cleared": temp_cleared,
		"air_cleared": air_cleared,
		"temp_phase_id": temp_phase_id,
		"air_phase_id": air_phase_id
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true


func load_game() -> bool:
	if not has_save_file():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	player_name = str(data.get("player_name", "새싹이"))
	seed_type = str(data.get("seed_type", "sky_seed"))
	character_style_id = int(data.get("character_style_id", 0))
	water_cleared = bool(data.get("water_cleared", false))
	temp_cleared = bool(data.get("temp_cleared", false))
	air_cleared = bool(data.get("air_cleared", false))
	temp_phase_id = int(data.get("temp_phase_id", 0))
	air_phase_id = int(data.get("air_phase_id", 0))
	update_current_quest()
	return true

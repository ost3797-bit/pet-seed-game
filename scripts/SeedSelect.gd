extends Control

var selected_seed_type := "seed_1"
var seed1_button: Button
var seed2_button: Button
var seed3_button: Button


func _ready() -> void:
	_make_background()
	
	# 1. 씨앗 선택 버튼 컨테이너 (라벨 삭제 전 원래 위치를 고려하여 배경화면 영역인 Y=235 위치에 배치)
	var choices := HBoxContainer.new()
	choices.position = Vector2(185, 235)
	choices.size = Vector2(920, 250)
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation", 24)
	add_child(choices)
	
	seed1_button = _choice_button("씨앗 1\n(초록 씨앗)", "res://assets/seed/seed1.png")
	seed2_button = _choice_button("씨앗 2\n(노랑 씨앗)", "res://assets/seed/seed2.png")
	seed3_button = _choice_button("씨앗 3\n(파랑 씨앗)", "res://assets/seed/seed3.png")
	seed1_button.pressed.connect(func(): _select_seed("seed_1"))
	seed2_button.pressed.connect(func(): _select_seed("seed_2"))
	seed3_button.pressed.connect(func(): _select_seed("seed_3"))
	choices.add_child(seed1_button)
	choices.add_child(seed2_button)
	choices.add_child(seed3_button)
	
	# 2. 하단 시작/뒤로가기 버튼 컨테이너 (CharacterSelect.tscn과 동일한 하단 Y=515 위치에 분리 배치)
	var bottom_box := VBoxContainer.new()
	bottom_box.position = Vector2(280, 560)
	bottom_box.size = Vector2(720, 180)
	bottom_box.add_theme_constant_override("separation", 14)
	add_child(bottom_box)
	
	var start := _button("", 30)
	start.pressed.connect(_start_game)
	bottom_box.add_child(start)
	
	var back := _button("", 22)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn"))
	bottom_box.add_child(back)
	
	_select_seed("seed_1")


func _select_seed(type: String) -> void:
	selected_seed_type = type
	match type:
		"seed_1":
			seed1_button.text = "씨앗 1\n선택됨 ✓"
			seed2_button.text = "씨앗 2\n(노랑 씨앗)"
			seed3_button.text = "씨앗 3\n(파랑 씨앗)"
		"seed_2":
			seed1_button.text = "씨앗 1\n(초록 씨앗)"
			seed2_button.text = "씨앗 2\n선택됨 ✓"
			seed3_button.text = "씨앗 3\n(파랑 씨앗)"
		"seed_3":
			seed1_button.text = "씨앗 1\n(초록 씨앗)"
			seed2_button.text = "씨앗 2\n(노랑 씨앗)"
			seed3_button.text = "씨앗 3\n선택됨 ✓"


func _start_game() -> void:
	GameState.new_game(GameState.player_name, selected_seed_type, GameState.character_style_id)
	get_tree().change_scene_to_file("res://scenes/MainField.tscn")


func _make_background() -> void:
	# seed_select_bg.png 이미지를 전체화면 배경으로 사용
	var bg := TextureRect.new()
	bg.texture = load("res://assets/select/seed_select_bg.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)


func _choice_button(caption: String, icon_path: String) -> Button:
	var button := Button.new()
	button.text = caption
	if ResourceLoader.exists(icon_path):
		button.icon = load(icon_path)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.expand_icon = true
	button.custom_minimum_size = Vector2(280, 240)
	button.add_theme_font_size_override("font_size", 25)
	return button


func _label(text_value: String, font_size: int) -> Label:
	var node := Label.new()
	node.text = text_value
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	return node


func _button(text_value: String, font_size: int) -> Button:
	var node := Button.new()
	node.text = text_value
	node.custom_minimum_size = Vector2(720, 66)
	node.flat = true
	node.modulate = Color(1.0, 1.0, 1.0, 0.0)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size", font_size)
	return node


func _spacer(height: float) -> Control:
	var node := Control.new()
	node.custom_minimum_size.y = height
	return node

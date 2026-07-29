extends Control

var notice: Label
var load_button: TextureButton


func _ready() -> void:
	_make_background()
	
	# 버튼 2개를 담는 세로 컨테이너 (화면 중앙 하단에 가지런히 배치)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(280, 300)
	# 1280x720 화면에서 가로 중앙(x = 500), 세로 위치(y = 350)에 반듯하게 위치
	box.position = Vector2(500, 350)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16) # 버튼 사이의 간격을 16으로 설정
	add_child(box)
	
	# 1. 새 게임 버튼 (크기: 280x140으로 아담하게 동일)
	var new_button := _texture_button("res://assets/title/btn_new_game.png")
	new_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn"))
	GameState.add_space_shortcut(new_button)
	box.add_child(new_button)
	
	# 2. 불러오기 버튼 (크기: 280x140으로 아담하게 동일)
	load_button = _texture_button("res://assets/title/btn_load_game.png")
	load_button.disabled = not GameState.has_save_file()
	if load_button.disabled:
		load_button.modulate = Color(0.5, 0.5, 0.5, 0.7) # 저장 파일 없을 때는 어둡게 표시
	load_button.pressed.connect(_load_game)
	box.add_child(load_button)
	
	# 안내 라벨 (평소에는 빈 글씨로 숨겨두어 화면이 전혀 산만하지 않음, 로드 오류 시에만 하단에 표시)
	notice = Label.new()
	notice.text = ""
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.position = Vector2(0, 670)
	notice.size = Vector2(1280, 40)
	notice.add_theme_font_size_override("font_size", 20)
	notice.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	notice.add_theme_constant_override("outline_size", 6)
	add_child(notice)


func _load_game() -> void:
	if GameState.load_game():
		get_tree().change_scene_to_file("res://scenes/MainField.tscn")
	else:
		notice.text = "저장된 모험 파일을 읽지 못했어요. 새 게임을 눌러 시작해 주세요!"


func _make_background() -> void:
	var bg_path := "res://assets/title/title_bg.png"
	if ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	else:
		var bg := ColorRect.new()
		bg.color = Color("DDF3FF")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)


func _texture_button(tex_path: String) -> TextureButton:
	var btn := TextureButton.new()
	if ResourceLoader.exists(tex_path):
		btn.texture_normal = load(tex_path)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	# 두 버튼의 크기를 280 x 140 으로 아담하고 세련되게 통일!
	btn.custom_minimum_size = Vector2(280, 140)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		if get_tree().current_scene.name == "Title":
			get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
			if get_viewport() != null: get_viewport().set_input_as_handled()

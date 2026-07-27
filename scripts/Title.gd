extends Control

var notice: Label
var load_button: TextureButton


func _ready() -> void:
	_make_background()
	
	# 버튼 3개를 담는 세로 컨테이너 (화면 중앙 하단에 가지런히 배치)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(280, 360)
	# 1280x720 화면에서 가로 중앙(x = 500), 세로 위치(y = 310)에 반듯하게 위치
	box.position = Vector2(500, 310)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10) # 버튼 사이의 간격을 10으로 설정
	add_child(box)
	
	# 1. 새 게임 버튼 (크기: 280x140으로 아담하게 동일)
	var new_button := _texture_button("res://assets/title/btn_new_game.png")
	new_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn"))
	box.add_child(new_button)
	
	# 2. 불러오기 버튼 (크기: 280x140으로 아담하게 동일)
	load_button = _texture_button("res://assets/title/btn_load_game.png")
	load_button.disabled = not GameState.has_save_file()
	if load_button.disabled:
		load_button.modulate = Color(0.5, 0.5, 0.5, 0.7) # 저장 파일 없을 때는 어둡게 표시
	load_button.pressed.connect(_load_game)
	box.add_child(load_button)
	
	# 3. 3번째 게임(공기 퀘스트) 즉시 시작 버튼
	var air_btn := Button.new()
	air_btn.text = "⚡ 3차 공기 퀘스트 바로 시작!"
	air_btn.custom_minimum_size = Vector2(280, 54)
	air_btn.add_theme_font_size_override("font_size", 20)
	air_btn.add_theme_color_override("font_color", Color("FEE761"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("181425")
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.border_color = Color("2CE8F5")
	air_btn.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color("262B44")
	air_btn.add_theme_stylebox_override("hover", sb_hover)
	air_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	air_btn.pressed.connect(func():
		GameState.new_game("새싹이", "sky_seed", 0)
		get_tree().change_scene_to_file("res://scenes/MainField.tscn")
	)
	box.add_child(air_btn)
	
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

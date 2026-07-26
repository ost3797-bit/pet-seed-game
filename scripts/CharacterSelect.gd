extends Control

var selected_style := 0
var name_input: LineEdit
var selected_label: Label
var notice: Label
var blue_button: Button
var pink_button: Button

# 걷기 애니메이션 & 바운스용 변수
var blue_atlas: AtlasTexture   # 남자 캐릭터 아틀라스 (프레임 교체용)
var pink_atlas: AtlasTexture   # 여자 캐릭터 아틀라스 (프레임 교체용)
var _anim_time := 0.0
var _walk_frame := 0


func _ready() -> void:
	_make_background()

	# 1. 상단 컨테이너 (이름 입력창 + 캐릭터 선택 버튼)
	var box := VBoxContainer.new()
	box.position = Vector2(280, 48)
	box.size = Vector2(720, 420)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	add_child(box)

	# 상단 여백 155px 유지
	box.add_child(_spacer(155))

	# 이름 입력창
	name_input = LineEdit.new()
	name_input.placeholder_text = ""
	name_input.max_length = 8
	name_input.text = GameState.player_name
	name_input.custom_minimum_size = Vector2(720, 64)
	name_input.flat = true
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.add_theme_font_size_override("font_size", 32)
	name_input.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	var empty_style := StyleBoxEmpty.new()
	name_input.add_theme_stylebox_override("normal", empty_style)
	name_input.add_theme_stylebox_override("focus", empty_style)
	name_input.add_theme_stylebox_override("read_only", empty_style)
	box.add_child(name_input)

	var choices := HBoxContainer.new()
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation", 32)
	box.add_child(choices)

	# 캐릭터 선택 버튼 생성 (아틀라스 참조 저장!)
	blue_button = _choice_button(0)
	pink_button = _choice_button(1)
	blue_button.pressed.connect(func(): _select_style(0))
	pink_button.pressed.connect(func(): _select_style(1))
	choices.add_child(blue_button)
	choices.add_child(pink_button)

	# 스케일이 중앙 기준으로 이루어지도록 피벗 설정
	blue_button.pivot_offset = blue_button.custom_minimum_size / 2.0
	pink_button.pivot_offset = pink_button.custom_minimum_size / 2.0

	# 2. 하단 컨테이너 (다음 단계 버튼 + 타이틀 돌아가기 버튼)
	var bottom_box := VBoxContainer.new()
	bottom_box.position = Vector2(280, 515)
	bottom_box.size = Vector2(720, 180)
	bottom_box.add_theme_constant_override("separation", 14)
	add_child(bottom_box)

	notice = Label.new()
	notice.text = ""
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_size_override("font_size", 22)
	notice.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	notice.add_theme_constant_override("outline_size", 6)
	bottom_box.add_child(notice)

	var start := _button()
	start.pressed.connect(_next_step)
	bottom_box.add_child(start)

	var back := _button()
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Title.tscn"))
	bottom_box.add_child(back)

	_select_style(0)


func _process(delta: float) -> void:
	_anim_time += delta

	# 선택된 캐릭터만 걷기 프레임 애니메이션 (초당 6프레임으로 4컷 순환!)
	var new_frame := int(_anim_time * 6.0) % 4
	if new_frame != _walk_frame:
		_walk_frame = new_frame
		var atlas := blue_atlas if selected_style == 0 else pink_atlas
		if atlas != null:
			atlas.region = Rect2(_walk_frame * 200, 0, 200, 300)


func _select_style(index: int) -> void:
	selected_style = index
	_anim_time = 0.0
	_walk_frame = 0

	# 비선택 캐릭터의 atlas를 정지 프레임(0번)으로 초기화
	if blue_atlas != null:
		blue_atlas.region = Rect2(0, 0, 200, 300)
	if pink_atlas != null:
		pink_atlas.region = Rect2(0, 0, 200, 300)

	# 크기 애니메이션: Tween으로 부드럽게 1.15배 / 0.9배 전환
	var tween := create_tween().set_parallel(true)
	tween.tween_property(blue_button, "scale",
		Vector2(1.15, 1.15) if index == 0 else Vector2(0.9, 0.9), 0.18)
	tween.tween_property(pink_button, "scale",
		Vector2(1.15, 1.15) if index == 1 else Vector2(0.9, 0.9), 0.18)

	# 밝기: 선택된 캐릭터는 화사하게, 비선택 캐릭터는 어둡고 반투명하게
	blue_button.modulate  = Color(1.0, 1.0, 1.0, 1.0) if index == 0 else Color(0.55, 0.55, 0.55, 0.65)
	pink_button.modulate  = Color(1.0, 1.0, 1.0, 1.0) if index == 1 else Color(0.55, 0.55, 0.55, 0.65)


func _next_step() -> void:
	var chosen_name := name_input.text.strip_edges()
	if chosen_name.is_empty():
		notice.text = "친구 이름을 입력해 주세요!"
		name_input.grab_focus()
		return
	GameState.player_name = chosen_name
	GameState.character_style_id = selected_style
	get_tree().change_scene_to_file("res://scenes/SeedSelect.tscn")


func _make_background() -> void:
	var bg_path := "res://assets/select/select_bg.png"
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
		bg.color = Color("F3F9DE")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)


func _choice_button(style_id: int) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(340, 225)
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var tex_path := "res://assets/characters/character_3_aligned.png" if style_id == 0 \
		else "res://assets/characters/character_2_aligned.png"

	if ResourceLoader.exists(tex_path):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(tex_path)
		atlas.region = Rect2(0, 0, 200, 300)  # 정면 정지 첫 프레임

		# 아틀라스 참조를 멤버 변수에 저장해 두어야 _process에서 region을 교체할 수 있음!
		if style_id == 0:
			blue_atlas = atlas
		else:
			pink_atlas = atlas

		var preview := TextureRect.new()
		preview.texture = atlas
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		preview.offset_top -= 10   # 캐릭터 이미지를 10픽셀 위로!
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(preview)

	return button


func _button() -> Button:
	var node := Button.new()
	node.text = ""
	node.custom_minimum_size = Vector2(720, 66)
	node.flat = false
	node.modulate = Color(1.0, 1.0, 1.0, 0.35)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return node


func _spacer(height: float) -> Control:
	var node := Control.new()
	node.custom_minimum_size.y = height
	return node

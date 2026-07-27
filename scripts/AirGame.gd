extends Control

const TOTAL_ROUNDS := 5
const GAIN_PER_SMOKE := 15.0
const LOSS_PER_SECOND := 4.0
const MAX_SMOKE := 4

var current_round := 0
var finished := false
var smoke_container: Control
var breath_gauge: TextureProgressBar
var round_label: Label
var feedback: Label
var spawn_timer: Timer


func _ready() -> void:
	_build_screen()
	_start_round()


func _process(delta: float) -> void:
	if finished:
		return
	var smoke_count := smoke_container.get_child_count()
	if smoke_count > 0:
		breath_gauge.value -= LOSS_PER_SECOND * minf(float(smoke_count), 3.0) * delta
	breath_gauge.value = clampf(breath_gauge.value, 0.0, 100.0)
	_update_gauge_text()


func _build_screen() -> void:
	# 8-bit 레트로 다크 네이비 배경
	var bg := ColorRect.new()
	bg.color = Color("181425")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	
	# 레트로 도트 스타일 그리드 패턴 효과 (장식)
	for i in range(0, 1280, 40):
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.03)
		line.position = Vector2(i, 0)
		line.size = Vector2(2, 720)
		add_child(line)
	for j in range(0, 720, 40):
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.03)
		line.position = Vector2(0, j)
		line.size = Vector2(1280, 2)
		add_child(line)
		
	# 상단 레트로 프레임
	var top_bar := ColorRect.new()
	top_bar.color = Color("262b44")
	top_bar.position = Vector2(40, 20)
	top_bar.size = Vector2(1200, 65)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)
	
	var top_border := ReferenceRect.new()
	top_border.position = Vector2(40, 20)
	top_border.size = Vector2(1200, 65)
	top_border.border_color = Color("2ce8f5")
	top_border.border_width = 4.0
	top_border.editor_only = false
	top_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_border)
	
	add_child(_label("✨ [8-BIT] 마법봉으로 공기 정화하기 - 매연 몬스터 소탕 작전! ✨", Vector2(40, 32), Vector2(1200, 40), 28, Color("2ce8f5")))
	add_child(_label("귀여운 픽셀 매연 몬스터들을 빠르게 톡톡 터치하여 맑은 공기로 정화해요!", Vector2(180, 95), Vector2(920, 30), 22, Color("fee761")))
	
	round_label = _label("", Vector2(420, 130), Vector2(440, 35), 26, Color("ffffff"))
	add_child(round_label)
	feedback = _label("", Vector2(210, 175), Vector2(860, 35), 22, Color("38b764"))
	add_child(feedback)
	
	smoke_container = Control.new()
	smoke_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	smoke_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(smoke_container)
	
	# 레트로 배터리 형태의 게이지 영역
	var frame := ColorRect.new()
	frame.color = Color("12101a")
	frame.position = Vector2(300, 620)
	frame.size = Vector2(680, 75)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	
	var frame_border := ReferenceRect.new()
	frame_border.position = Vector2(300, 620)
	frame_border.size = Vector2(680, 75)
	frame_border.border_color = Color("ffffff")
	frame_border.border_width = 4.0
	frame_border.editor_only = false
	frame_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame_border)
	
	breath_gauge = TextureProgressBar.new()
	breath_gauge.position = Vector2(6, 6)
	breath_gauge.size = Vector2(668, 63)
	breath_gauge.max_value = 100.0
	breath_gauge.value = 40.0
	breath_gauge.texture_progress = _solid_texture(Color("38b764"), 32, 32)
	breath_gauge.nine_patch_stretch = true
	breath_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(breath_gauge)
	
	var gauge_text := _label("", Vector2(0, 20), Vector2(680, 40), 25, Color("ffffff"))
	gauge_text.name = "GaugeText"
	gauge_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(gauge_text)
	
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_smoke)
	add_child(spawn_timer)


func _start_round() -> void:
	_clear_smoke()
	breath_gauge.value = 40.0
	round_label.text = "👾 정화 라운드  " + str(current_round + 1) + " / " + str(TOTAL_ROUNDS)
	feedback.text = "매연 몬스터를 터치하여 깨끗한 공기를 만들어요!"
	spawn_timer.wait_time = maxf(0.9, 1.8 - current_round * 0.15)
	spawn_timer.start()
	_spawn_smoke()
	_update_gauge_text()


func _input(event: InputEvent) -> void:
	if finished:
		return
	var click_pos := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		click_pos = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		click_pos = event.position
	else:
		return
		
	for child in smoke_container.get_children():
		if child is Control and is_instance_valid(child):
			if child.get_global_rect().grow(20.0).has_point(click_pos):
				_clean_smoke(child)
				break


func _spawn_smoke() -> void:
	if finished or smoke_container.get_child_count() >= MAX_SMOKE:
		return
	var btn := Button.new()
	var pos := _random_smoke_position()
	btn.position = pos - Vector2(60, 45)
	btn.size = Vector2(120, 90)
	
	var monster_names := [
		"👾 매연몽 👾\n[ >_< ]",
		"☁️ 먹구름몽 ☁️\n[ @___@ ]",
		"🔥 유해먼지 🔥\n[ +___+ ]",
		"💀 매연괴수 💀\n[ O_o ]"
	]
	var monster_colors := [Color("ff0044"), Color("ff77a8"), Color("fee761"), Color("2ce8f5")]
	var idx := randi() % monster_names.size()
	
	btn.text = monster_names[idx]
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color("ffffff"))
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("2a2f4e")
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_width_top = 4
	sb.border_width_bottom = 4
	sb.border_color = monster_colors[idx]
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color("4d4268")
	sb_hover.border_color = Color("ffffff")
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	
	btn.pressed.connect(func():
		_clean_smoke(btn)
	)
	smoke_container.add_child(btn)


func _clean_smoke(smoke: Node) -> void:
	if finished or not is_instance_valid(smoke):
		return
	smoke.queue_free()
	breath_gauge.value = minf(100.0, breath_gauge.value + GAIN_PER_SMOKE)
	feedback.text = "좋아요! 매연이 걷히고 상쾌한 공기가 퍼집니다! 🌿"
	if breath_gauge.value >= 100.0:
		_complete_round()



func _complete_round() -> void:
	spawn_timer.stop()
	_clear_smoke()
	current_round += 1
	if current_round >= TOTAL_ROUNDS:
		_finish_game()
		return
	feedback.text = "🎉 라운드 성공! 다음 매연 몬스터들이 나타납니다!"
	await get_tree().create_timer(0.8).timeout
	if not finished:
		_start_round()


func _finish_game() -> void:
	finished = true
	spawn_timer.stop()
	_clear_smoke()
	GameState.complete_quest(&"air")
	_show_result("🎉 대성공! 🌱\n씨앗이 깨끗하고 상쾌한 공기를 마셨어요!", "텃밭으로 돌아가기")


func _clear_smoke() -> void:
	if smoke_container == null:
		return
	for smoke in smoke_container.get_children():
		smoke.queue_free()


func _random_smoke_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	return Vector2(randf_range(90.0, viewport_size.x - 90.0), randf_range(235.0, viewport_size.y - 180.0))


func _update_gauge_text() -> void:
	var text_node: Label = breath_gauge.get_parent().get_node("GaugeText")
	text_node.text = "⚡ 맑은 공기 배터리  " + str(roundi(breath_gauge.value)) + "%"


func _show_result(message: String, button_text: String) -> void:
	var panel := Panel.new()
	panel.position = Vector2(250, 205)
	panel.size = Vector2(780, 300)
	panel.z_index = 10
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("181425")
	sb.border_width_left = 6
	sb.border_width_right = 6
	sb.border_width_top = 6
	sb.border_width_bottom = 6
	sb.border_color = Color("2ce8f5")
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	
	panel.add_child(_label(message, Vector2(40, 55), Vector2(700, 110), 32, Color("fee761")))
	var button := Button.new()
	button.text = button_text
	button.position = Vector2(190, 190)
	button.size = Vector2(400, 70)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", Color("ffffff"))
	
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color("2a2f4e")
	btn_sb.border_width_left = 4
	btn_sb.border_width_right = 4
	btn_sb.border_width_top = 4
	btn_sb.border_width_bottom = 4
	btn_sb.border_color = Color("38b764")
	btn_sb.corner_radius_top_left = 0
	btn_sb.corner_radius_top_right = 0
	btn_sb.corner_radius_bottom_left = 0
	btn_sb.corner_radius_bottom_right = 0
	button.add_theme_stylebox_override("normal", btn_sb)
	
	var btn_hover := btn_sb.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color("38b764")
	button.add_theme_stylebox_override("hover", btn_hover)
	button.add_theme_stylebox_override("pressed", btn_hover)
	
	button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainField.tscn"))
	panel.add_child(button)


func _label(value: String, pos: Vector2, control_size: Vector2, font_size: int, font_color: Color = Color.WHITE) -> Label:
	var node := Label.new()
	node.text = value
	node.position = pos
	node.size = control_size
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", font_color)
	return node


func _solid_texture(color: Color, width: int, height: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, color])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = width
	texture.height = height
	return texture

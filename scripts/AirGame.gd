extends Control

# ─── 게임 상수 ───────────────────────────────────────
const TOTAL_ROUNDS := 3
const GAIN_PER_SMOKE := 20.0   # 매연 클릭 시 게이지 증가
const LOSS_PER_SECOND := 3.0   # 초당 게이지 감소
const MAX_SMOKE := 4            # 화면 최대 매연 수

# 라운드3 보스 상수
const BOSS_MAX_HP := 8          # 보스 클릭 횟수

# ─── 상태 변수 ───────────────────────────────────────
var current_round := 0
var finished := false
var waiting_for_popup := false  # 팝업 표시 중 게임 일시 정지

# Round2: 착한 구름 관련
var has_good_cloud := false

# Round3: 보스 관련
var boss_hp := 0
var boss_btn: Button = null
var boss_hp_label: Label = null

# UI 노드 참조
var smoke_container: Control
var breath_gauge: TextureProgressBar
var round_label: Label
var feedback: Label
var spawn_timer: Timer
var popup_layer: Control  # 팝업 전용 레이어


# ─── 라운드별 안내 정보 ──────────────────────────────
func _get_round_info(round_idx: int) -> Dictionary:
	match round_idx:
		0:
			return {
				"title": "🌟 라운드 1: 매연 소탕 작전!",
				"rule": "☁️ 화면에 나타나는 매연 몬스터를\n빠르게 터치해서 물리쳐요!\n\n매연을 없애면 맑은 공기 배터리가 충전됩니다.\n배터리를 100%로 채우면 성공!",
				"icon": "👾",
				"color": Color("2ce8f5")
			}
		1:
			return {
				"title": "⚠️ 라운드 2: 착한 구름을 조심해요!",
				"rule": "이번엔 매연 몬스터와 함께\n🌤️ 착한 바람구름도 나타나요!\n\n✅ 매연 몬스터(붉은색/노란색) → 터치!\n❌ 착한 바람구름(하늘색 🌤️) → 터치 금지!\n\n착한 구름을 건드리면 게이지가 -15% 감소해요!",
				"icon": "🌤️",
				"color": Color("fee761")
			}
		2:
			return {
				"title": "👹 라운드 3: 대왕 매연 보스 등장!",
				"rule": "거대한 대왕 매연 보스가 나타났어요!\n\n💥 보스를 " + str(BOSS_MAX_HP) + "번 연타해서 물리치세요!\n클릭할수록 보스가 약해집니다!\n\n보스를 처치하면 하늘이 맑아져요!",
				"icon": "👹",
				"color": Color("ff0044")
			}
	return {}


# ─── 초기화 ──────────────────────────────────────────
func _ready() -> void:
	GameState.play_bgm("res://assets/audio/Hidden_Moss_Trail.mp3")
	_build_screen()
	_show_round_popup()


func _build_screen() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = Color("181425")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 도트 그리드 패턴
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

	# 상단 타이틀 바
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

	# 라운드 / 피드백 레이블
	round_label = _label("", Vector2(420, 100), Vector2(440, 35), 26, Color("ffffff"))
	add_child(round_label)
	feedback = _label("", Vector2(210, 145), Vector2(860, 35), 22, Color("38b764"))
	add_child(feedback)

	# 매연 컨테이너
	smoke_container = Control.new()
	smoke_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	smoke_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(smoke_container)

	# 배터리 게이지
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

	# 스폰 타이머
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_smoke)
	add_child(spawn_timer)

	# 팝업 레이어 (항상 최상단)
	popup_layer = Control.new()
	popup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_layer.z_index = 50
	add_child(popup_layer)


# ─── 라운드 시작 팝업 ─────────────────────────────────
func _show_round_popup() -> void:
	waiting_for_popup = true
	spawn_timer.stop()

	# 기존 팝업 제거
	for child in popup_layer.get_children():
		child.queue_free()

	var info := _get_round_info(current_round)

	# 반투명 오버레이
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(overlay)

	# 상단 규칙 패널 (버튼이 없으므로 남은 영역을 모두 설명문으로 사용하여 절대 겹치지 않음!)
	var rule_panel := Panel.new()
	rule_panel.position = Vector2(200, 100)
	rule_panel.size = Vector2(880, 360)
	rule_panel.z_index = 51
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1a1a2e")
	sb.border_width_left = 6
	sb.border_width_right = 6
	sb.border_width_top = 6
	sb.border_width_bottom = 6
	sb.border_color = info["color"]
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	rule_panel.add_theme_stylebox_override("panel", sb)
	popup_layer.add_child(rule_panel)

	# 라운드 번호 상단 뱃지
	var badge_bg := ColorRect.new()
	badge_bg.color = info["color"]
	badge_bg.position = Vector2(0, 0)
	badge_bg.size = Vector2(880, 55)
	badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule_panel.add_child(badge_bg)

	var badge_label := _label("ROUND  " + str(current_round + 1) + "  /  " + str(TOTAL_ROUNDS), Vector2(0, 10), Vector2(880, 35), 26, Color("181425"))
	rule_panel.add_child(badge_label)

	# 제목
	var title_lbl := _label(info["title"], Vector2(20, 65), Vector2(840, 45), 28, info["color"])
	rule_panel.add_child(title_lbl)

	# 구분선
	var divider := ColorRect.new()
	divider.color = info["color"]
	divider.position = Vector2(40, 115)
	divider.size = Vector2(800, 3)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule_panel.add_child(divider)

	# 규칙 설명 (버튼이 하단 창으로 분리되었으므로 높이를 230px까지 넉넉하게 사용!)
	var rule_lbl := _label(info["rule"], Vector2(30, 130), Vector2(820, 220), 22, Color("e0e0e0"))
	rule_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	rule_panel.add_child(rule_lbl)

	# 하단 시작 버튼 패널 (규칙 패널 아래에 별도의 창으로 완벽히 분리!)
	var btn_panel := Panel.new()
	btn_panel.position = Vector2(340, 485)
	btn_panel.size = Vector2(600, 90)
	btn_panel.z_index = 51
	var btn_panel_sb := StyleBoxFlat.new()
	btn_panel_sb.bg_color = Color("1a1a2e")
	btn_panel_sb.border_width_left = 6
	btn_panel_sb.border_width_right = 6
	btn_panel_sb.border_width_top = 6
	btn_panel_sb.border_width_bottom = 6
	btn_panel_sb.border_color = info["color"]
	btn_panel.add_theme_stylebox_override("panel", btn_panel_sb)
	popup_layer.add_child(btn_panel)

	# 시작 버튼
	var start_btn := Button.new()
	var btn_text := "👾 소탕 시작!" if current_round == 0 else ("🌤️ 라운드 2 시작!" if current_round == 1 else "👹 보스전 시작!")
	start_btn.text = btn_text
	start_btn.position = Vector2(50, 15)
	start_btn.size = Vector2(500, 60)
	start_btn.add_theme_font_size_override("font_size", 26)
	start_btn.add_theme_color_override("font_color", Color("ffffff"))
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color("2a2f4e")
	btn_sb.border_width_left = 4
	btn_sb.border_width_right = 4
	btn_sb.border_width_top = 4
	btn_sb.border_width_bottom = 4
	btn_sb.border_color = info["color"]
	start_btn.add_theme_stylebox_override("normal", btn_sb)
	var btn_hover := btn_sb.duplicate() as StyleBoxFlat
	btn_hover.bg_color = info["color"]
	start_btn.add_theme_stylebox_override("hover", btn_hover)
	start_btn.add_theme_stylebox_override("pressed", btn_hover)
	start_btn.pressed.connect(func():
		for c in popup_layer.get_children():
			c.queue_free()
		waiting_for_popup = false
		_start_round()
	)
	btn_panel.add_child(start_btn)


# ─── 라운드 시작 ──────────────────────────────────────
func _start_round() -> void:
	_clear_smoke()
	boss_btn = null
	boss_hp_label = null
	breath_gauge.value = 40.0
	round_label.text = "👾 정화 라운드  " + str(current_round + 1) + " / " + str(TOTAL_ROUNDS)
	_update_gauge_text()

	match current_round:
		0: # 라운드1: 기본 매연 소탕
			has_good_cloud = false
			feedback.text = "매연 몬스터를 터치하여 깨끗한 공기를 만들어요! 💨"
			spawn_timer.wait_time = 1.5
			spawn_timer.start()
			_spawn_smoke()
		1: # 라운드2: 착한 구름 피하기
			has_good_cloud = true
			feedback.text = "주의! 🌤️ 하늘색 착한 구름은 터치하면 안 돼요!"
			spawn_timer.wait_time = 1.3
			spawn_timer.start()
			_spawn_smoke()
		2: # 라운드3: 보스전
			has_good_cloud = false
			feedback.text = "👹 대왕 매연 보스 등장! " + str(BOSS_MAX_HP) + "번 연타로 처치하세요!"
			_spawn_boss()


# ─── 라운드1·2: 일반 매연 스폰 ───────────────────────
func _spawn_smoke() -> void:
	if finished or waiting_for_popup:
		return
	if current_round == 2:  # 라운드3는 보스만
		return
	if smoke_container.get_child_count() >= MAX_SMOKE:
		return

	var btn := Button.new()
	var pos := _random_smoke_position()
	btn.position = pos - Vector2(60, 45)
	btn.size = Vector2(120, 90)

	# 라운드2: 착한 구름 10% 확률로 등장
	var is_good := (has_good_cloud and randf() < 0.30)
	btn.set_meta("is_good", is_good)

	if is_good:
		btn.text = "🌤️ 바람구름 🌤️\n[ ^_^ ]"
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("12304a")
		sb.border_width_left = 4
		sb.border_width_right = 4
		sb.border_width_top = 4
		sb.border_width_bottom = 4
		sb.border_color = Color("2ce8f5")
		sb.corner_radius_top_left = 0
		sb.corner_radius_top_right = 0
		sb.corner_radius_bottom_left = 0
		sb.corner_radius_bottom_right = 0
		btn.add_theme_stylebox_override("normal", sb)
		var sb_h := sb.duplicate() as StyleBoxFlat
		sb_h.bg_color = Color("1a4a6a")
		sb_h.border_color = Color("ffffff")
		btn.add_theme_stylebox_override("hover", sb_h)
		btn.add_theme_stylebox_override("pressed", sb_h)
		btn.add_theme_color_override("font_color", Color("2ce8f5"))
	else:
		var monster_names := [
			"👾 매연몽 👾\n[ >_< ]",
			"🔥 유해먼지 🔥\n[ +___+ ]",
			"💀 매연괴수 💀\n[ O_o ]",
			"🌫️ 오염덩어리\n[ X_X ]"
		]
		var monster_colors := [Color("ff0044"), Color("ff5500"), Color("cc00cc"), Color("886600")]
		var idx := randi() % monster_names.size()
		btn.text = monster_names[idx]
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("2a2f4e")
		sb.border_width_left = 4
		sb.border_width_right = 4
		sb.border_width_top = 4
		sb.border_width_bottom = 4
		sb.border_color = monster_colors[idx]
		sb.corner_radius_top_left = 0
		sb.corner_radius_top_right = 0
		sb.corner_radius_bottom_left = 0
		sb.corner_radius_bottom_right = 0
		btn.add_theme_stylebox_override("normal", sb)
		var sb_h := sb.duplicate() as StyleBoxFlat
		sb_h.bg_color = Color("4d4268")
		sb_h.border_color = Color("ffffff")
		btn.add_theme_stylebox_override("hover", sb_h)
		btn.add_theme_stylebox_override("pressed", sb_h)
		btn.add_theme_color_override("font_color", Color("ffffff"))

	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(func():
		_on_smoke_clicked(btn)
	)
	smoke_container.add_child(btn)


func _on_smoke_clicked(smoke: Button) -> void:
	if finished or waiting_for_popup or not is_instance_valid(smoke):
		return
	var is_good: bool = smoke.get_meta("is_good", false)
	if is_good:
		# 착한 구름 클릭 패널티
		breath_gauge.value = maxf(0.0, breath_gauge.value - 15.0)
		feedback.text = "❌ 앗! 착한 구름을 터치했어요! 게이지 -15% 😱"
		smoke.queue_free()
		_update_gauge_text()
	else:
		# 일반 매연 제거
		smoke.queue_free()
		breath_gauge.value = minf(100.0, breath_gauge.value + GAIN_PER_SMOKE)
		feedback.text = "좋아요! 매연이 걷히고 상쾌한 공기가 퍼집니다! 🌿"
		_update_gauge_text()
		if breath_gauge.value >= 100.0:
			_complete_round()


# ─── 라운드3: 보스 스폰 ──────────────────────────────
func _spawn_boss() -> void:
	boss_hp = BOSS_MAX_HP
	var viewport_size := get_viewport_rect().size

	boss_btn = Button.new()
	boss_btn.position = Vector2(viewport_size.x / 2.0 - 120, viewport_size.y / 2.0 - 100)
	boss_btn.size = Vector2(240, 180)
	boss_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	boss_btn.add_theme_font_size_override("font_size", 36)
	boss_btn.add_theme_color_override("font_color", Color("fee761"))
	_update_boss_style()
	boss_btn.pressed.connect(_on_boss_clicked)
	smoke_container.add_child(boss_btn)

	# 보스 HP 레이블
	boss_hp_label = _label("💥 HP: " + str(boss_hp) + " / " + str(BOSS_MAX_HP), Vector2(0, 190), Vector2(240, 35), 22, Color("ff6666"))
	boss_hp_label.position = Vector2(viewport_size.x / 2.0 - 120, viewport_size.y / 2.0 + 80)
	boss_hp_label.size = Vector2(240, 35)
	smoke_container.add_child(boss_hp_label)


func _update_boss_style() -> void:
	if boss_btn == null or not is_instance_valid(boss_btn):
		return
	var ratio := float(boss_hp) / float(BOSS_MAX_HP)
	# HP 비율에 따라 보스 색상 변화
	var border_col: Color
	var bg_col: Color
	var boss_text: String
	if ratio > 0.6:
		border_col = Color("ff0044")
		bg_col = Color("3a0a1e")
		boss_text = "👹 대왕 매연보스\n[ >:( ]\n연타하세요!"
	elif ratio > 0.3:
		border_col = Color("ff6600")
		bg_col = Color("3a1a00")
		boss_text = "👹 대왕 매연보스\n[ x_X ]\n거의 다 됐어요!"
	else:
		border_col = Color("fee761")
		bg_col = Color("2a2000")
		boss_text = "👹 대왕 매연보스\n[ @_@ ]\n조금만 더!!"

	boss_btn.text = boss_text
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_width_left = 6
	sb.border_width_right = 6
	sb.border_width_top = 6
	sb.border_width_bottom = 6
	sb.border_color = border_col
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	boss_btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = border_col
	boss_btn.add_theme_stylebox_override("hover", sb_h)
	boss_btn.add_theme_stylebox_override("pressed", sb_h)


func _on_boss_clicked() -> void:
	if finished or waiting_for_popup or boss_btn == null:
		return
	boss_hp -= 1
	var viewport_size := get_viewport_rect().size
	var base_pos := Vector2(viewport_size.x / 2.0 - 120, viewport_size.y / 2.0 - 100)
	boss_btn.position = base_pos + Vector2(randf_range(-14, 14), randf_range(-14, 14))

	# 게이지 업데이트
	breath_gauge.value = minf(100.0, float(BOSS_MAX_HP - boss_hp) / float(BOSS_MAX_HP) * 100.0)
	_update_gauge_text()

	if boss_hp_label != null and is_instance_valid(boss_hp_label):
		boss_hp_label.text = "💥 HP: " + str(boss_hp) + " / " + str(BOSS_MAX_HP)

	feedback.text = "💥 " + str(BOSS_MAX_HP - boss_hp) + "번 연타! 조금만 더!"
	_update_boss_style()

	if boss_hp <= 0:
		boss_btn.position = base_pos
		feedback.text = "🎉 보스 처치 완료! 하늘이 맑아졌어요! ✨"
		if is_instance_valid(boss_btn):
			boss_btn.disabled = true
		_complete_round()


# ─── 라운드 완료 ──────────────────────────────────────
func _complete_round() -> void:
	spawn_timer.stop()
	_clear_smoke()
	boss_btn = null
	boss_hp_label = null
	current_round += 1
	if current_round >= TOTAL_ROUNDS:
		_finish_game()
		return
	# 다음 라운드 팝업
	await get_tree().create_timer(0.5).timeout
	if not finished:
		_show_round_popup()


func _finish_game() -> void:
	finished = true
	spawn_timer.stop()
	_clear_smoke()
	GameState.complete_quest(&"air")
	_show_result("🎉 전체 클리어! 🌱\n씨앗이 깨끗하고 상쾌한 공기를 마셨어요!\n당신은 훌륭한 공기 지킴이예요!", "텃밭으로 돌아가기")


# ─── _process (게이지 감소 및 보스 위치 복구) ──────────────────────────
func _process(_delta: float) -> void:
	if finished or waiting_for_popup:
		return
	if current_round == 2:  # 라운드3는 보스 흔들림 부드럽게 원위치 복구
		if boss_btn != null and is_instance_valid(boss_btn):
			var base_pos := Vector2(get_viewport_rect().size.x / 2.0 - 120, get_viewport_rect().size.y / 2.0 - 100)
			boss_btn.position = boss_btn.position.lerp(base_pos, 15.0 * _delta)
		return
	var smoke_count := smoke_container.get_child_count()
	if smoke_count > 0:
		breath_gauge.value -= LOSS_PER_SECOND * minf(float(smoke_count), 3.0) * _delta
	breath_gauge.value = clampf(breath_gauge.value, 0.0, 100.0)
	_update_gauge_text()


# ─── _input (터치/마우스 폴백) ───────────────────────
func _input(event: InputEvent) -> void:
	if finished:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ENTER)):
			get_tree().change_scene_to_file("res://scenes/MainField.tscn")
			if get_viewport() != null: get_viewport().set_input_as_handled()
		return
	if waiting_for_popup:
		return
	var click_pos := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		click_pos = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		click_pos = event.position
	else:
		return
	for child in smoke_container.get_children():
		if child is Button and is_instance_valid(child):
			if child.get_global_rect().grow(20.0).has_point(click_pos):
				if current_round == 2:
					_on_boss_clicked()
				else:
					_on_smoke_clicked(child)
				break


# ─── 유틸 ────────────────────────────────────────────
func _clear_smoke() -> void:
	if smoke_container == null:
		return
	for smoke in smoke_container.get_children():
		smoke.queue_free()


func _random_smoke_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	return Vector2(randf_range(90.0, viewport_size.x - 90.0), randf_range(235.0, viewport_size.y - 180.0))


func _update_gauge_text() -> void:
	var text_node: Label = breath_gauge.get_parent().get_node_or_null("GaugeText")
	if text_node != null:
		text_node.text = "⚡ 맑은 공기 배터리  " + str(roundi(breath_gauge.value)) + "%"


func _show_result(message: String, button_text: String) -> void:
	var panel := Panel.new()
	panel.position = Vector2(190, 175)
	panel.size = Vector2(900, 360)
	panel.z_index = 60
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

	panel.add_child(_label(message, Vector2(40, 60), Vector2(820, 160), 30, Color("fee761")))

	var button := Button.new()
	button.text = button_text
	button.position = Vector2(250, 260)
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
	button.grab_focus()


func _label(value: String, pos: Vector2, control_size: Vector2, font_size: int, font_color: Color = Color.WHITE) -> Label:
	var node := Label.new()
	node.text = value
	node.position = pos
	node.size = control_size
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", font_color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _solid_texture(color: Color, width: int, height: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, color])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = width
	texture.height = height
	return texture

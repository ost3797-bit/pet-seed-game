extends Control

# ─── 라운드별 난이도 설정 ───────────────────────────────────────────────
# [0=1라운드, 1=2라운드, 2=3라운드]
const RISE_SPEEDS  := [14.0, 22.0, 34.0]
const FALL_SPEEDS  := [7.0,  14.0, 22.0]
const HOLD_TIMES   := [4.0,  3.5,  3.0]
const TIME_LIMITS  := [30.0, 25.0, 20.0]
const TARGET_MINS  := [68.0, 65.0, 62.0]
const TARGET_MAXS  := [80.0, 77.0, 74.0]
const TOTAL_ROUNDS := 3

const BG_COLORS := [
	Color("DDF3FF"),
	Color("B3DCFF"),
	Color("85BCEE"),
]
const TARGET_COLORS := [
	Color(0.84, 0.69, 0.22, 0.90),   # 1라운드: 따뜻한 황금색
	Color(1.0,  0.65, 0.10, 0.90),   # 2라운드: 주황
	Color(1.0,  0.35, 0.35, 0.90),   # 3라운드: 빨강
]

var current_round := 0
var watering := false
var round_finished := false
var game_finished := false
var held_seconds := 0.0
var result_mode := ""

@onready var bg_rect: ColorRect = $Background
@onready var round_label: Label = $RoundLabel
@onready var title_label: Label = $TitleLabel
@onready var desc_label: Label = $DescLabel
@onready var frame_wood: TextureRect = $FrameWood
@onready var inner_bg: ColorRect = $FrameWood/InnerBG
@onready var target_rect: ColorRect = $FrameWood/InnerBG/TargetRect
@onready var gauge: ProgressBar = $FrameWood/InnerBG/Gauge
@onready var held_bar: ProgressBar = $HeldFrame/HeldBar
@onready var time_label: Label = $TimeLabel
@onready var feedback: Label = $FeedbackLabel
@onready var water_button: TextureButton = $WaterButton
@onready var round_timer: Timer = $RoundTimer


func _ready() -> void:
	_setup_background_image()
	_setup_styles_and_signals()
	_start_round()


func _setup_background_image() -> void:
	var bg_path := "res://assets/game_bg.png"
	if ResourceLoader.exists(bg_path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(bg_path)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if bg_rect != null and is_instance_valid(bg_rect):
			bg_rect.hide()
		add_child(tex_rect)
		move_child(tex_rect, 0)


func _setup_styles_and_signals() -> void:
	# 에디터에서 사용자가 배치한 InnerBG 크기에 맞춰 내부 게이지 바 동기화
	gauge.position = Vector2.ZERO
	gauge.size = inner_bg.size
	
	# 게이지 스타일 지정 (배경 투명, 반투명 하늘색 물 채움)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	gauge.add_theme_stylebox_override("background", bg_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.36, 0.72, 0.96, 0.82)
	fill_style.set_corner_radius_all(6)
	gauge.add_theme_stylebox_override("fill", fill_style)
	
	# 유지 시간 바 스타일 지정
	var hbg := StyleBoxFlat.new()
	hbg.bg_color = Color("1A2A3A")
	hbg.set_corner_radius_all(3)
	held_bar.add_theme_stylebox_override("background", hbg)
	var hfill := StyleBoxFlat.new()
	hfill.bg_color = Color("FFE36B")
	hfill.set_corner_radius_all(3)
	held_bar.add_theme_stylebox_override("fill", hfill)
	
	# 버튼 및 타이머 연결
	if not water_button.button_down.is_connected(func(): watering = true):
		water_button.button_down.connect(func(): watering = true)
		water_button.button_up.connect(func(): watering = false)
	if not round_timer.timeout.is_connected(_fail):
		round_timer.timeout.connect(_fail)


func _process(delta: float) -> void:
	if game_finished or round_finished:
		return
	var pressing := watering or Input.is_action_pressed(&"interact")
	gauge.value += (float(RISE_SPEEDS[current_round]) if pressing else -float(FALL_SPEEDS[current_round])) * delta
	gauge.value = clampf(gauge.value, 0.0, 100.0)
	var in_target: bool = gauge.value >= float(TARGET_MINS[current_round]) and gauge.value <= float(TARGET_MAXS[current_round])
	if in_target:
		held_seconds += delta
		var remain := ceili(float(HOLD_TIMES[current_round]) - held_seconds)
		feedback.text = "딱 좋아요! 💧 " + str(remain) + "초만 더 유지!"
		held_bar.value = (held_seconds / float(HOLD_TIMES[current_round])) * 100.0
	else:
		held_seconds = 0.0
		held_bar.value = 0.0
		if gauge.value < float(TARGET_MINS[current_round]):
			feedback.text = "게이지가 너무 낮아요! 버튼을 꾹 눌러요."
		else:
			feedback.text = "게이지가 너무 높아요! 버튼을 살짝 놓아요."
	time_label.text = "남은 시간: " + str(ceili(round_timer.time_left)) + "초   수분: " + str(roundi(gauge.value)) + "%"
	if held_seconds >= float(HOLD_TIMES[current_round]):
		_round_clear()


func _start_round() -> void:
	round_finished = false
	held_seconds = 0.0
	watering = false
	gauge.value = 30.0
	held_bar.value = 0.0
	bg_rect.color = BG_COLORS[current_round]
	target_rect.color = TARGET_COLORS[current_round]
	var t_min := float(TARGET_MINS[current_round])
	var t_max := float(TARGET_MAXS[current_round])
	var gh := inner_bg.size.y
	var gw := inner_bg.size.x
	var top_px := gh * (1.0 - t_max / 100.0)
	var height_px := gh * (t_max - t_min) / 100.0
	target_rect.position = Vector2(0.0, top_px)
	target_rect.size = Vector2(gw, height_px)
	round_label.text = "라운드 " + str(current_round + 1) + " / " + str(TOTAL_ROUNDS)
	title_label.text = _round_title()
	desc_label.text = _round_desc()
	feedback.text = "구간에 게이지를 맞춰 보세요."
	time_label.text = ""
	round_timer.wait_time = float(TIME_LIMITS[current_round])
	round_timer.start()


func _round_title() -> String:
	match current_round:
		0: return "씨앗에게 물을 주세요! (1단계)"
		1: return "좀 더 조심스럽게! (2단계)"
		2: return "마지막 한 모금! (3단계)"
	return ""


func _round_desc() -> String:
	match current_round:
		0: return "노란 구간에 게이지를 맞춰 " + str(HOLD_TIMES[0]) + "초 유지하세요."
		1: return "속도가 빨라졌어요! 주황 구간에 " + str(HOLD_TIMES[1]) + "초 유지하세요."
		2: return "더 빠르고 좁아요! 빨간 구간에 " + str(HOLD_TIMES[2]) + "초 유지하세요."
	return ""


func _round_clear() -> void:
	if round_finished:
		return
	round_finished = true
	round_timer.stop()
	if current_round + 1 >= TOTAL_ROUNDS:
		game_finished = true
		GameState.complete_quest(&"water")
		result_mode = "return_to_field"
		_show_result("씨앗에게 물 주기 성공!\n3라운드를 모두 통과했어요!", "밭으로 돌아가기")
	else:
		current_round += 1
		_show_round_clear_panel()


func _show_round_clear_panel() -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.12, 0.22, 0.93)
	panel.position = Vector2(280, 220)
	panel.size = Vector2(720, 260)
	panel.z_index = 10
	add_child(panel)
	var msg := Label.new()
	msg.text = "라운드 " + str(current_round) + " 클리어!\n다음 라운드가 시작됩니다."
	msg.position = Vector2(40, 30)
	msg.size = Vector2(640, 100)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 32)
	msg.add_theme_color_override("font_color", Color("FFE36B"))
	panel.add_child(msg)
	var next_btn := Button.new()
	next_btn.text = "다음 라운드 도전!"
	next_btn.position = Vector2(110, 160)
	next_btn.size = Vector2(500, 68)
	next_btn.add_theme_font_size_override("font_size", 28)
	next_btn.pressed.connect(func():
		panel.queue_free()
		_start_round()
	)
	GameState.add_space_shortcut(next_btn)
	panel.add_child(next_btn)


func _fail() -> void:
	if game_finished or round_finished:
		return
	round_finished = true
	game_finished = true
	result_mode = "retry"
	_show_result("시간 초과!\n라운드 " + str(current_round + 1) + "을 통과하지 못했어요.\n처음부터 다시 도전해요!", "다시 하기")


func _show_result(message: String, button_text: String) -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.12, 0.18, 0.92)
	panel.position = Vector2(250, 180)
	panel.size = Vector2(780, 340)
	panel.z_index = 20
	add_child(panel)
	var result := Label.new()
	result.text = message
	result.position = Vector2(40, 40)
	result.size = Vector2(700, 160)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", 32)
	panel.add_child(result)
	var button := Button.new()
	button.text = button_text
	button.position = Vector2(140, 250)
	button.size = Vector2(500, 70)
	button.add_theme_font_size_override("font_size", 27)
	button.pressed.connect(_on_result_button_pressed)
	GameState.add_space_shortcut(button)
	panel.add_child(button)


func _on_result_button_pressed() -> void:
	if result_mode == "return_to_field":
		get_tree().change_scene_to_file("res://scenes/MainField.tscn")
	else:
		get_tree().reload_current_scene()

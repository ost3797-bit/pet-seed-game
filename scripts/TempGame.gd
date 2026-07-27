extends Control

const TARGETS := [Vector2(360, 405), Vector2(265, 310), Vector2(155, 200), Vector2(75, 120), Vector2(300, 345)]
const SPEEDS := [230.0, 280.0, 330.0, 380.0, 430.0]
const MIN_Y := 20.0
const MAX_Y := 468.0

var current_round := 0
var needle_y := MIN_Y
var direction := 1.0
var moving := true
var finished := false
var needle: ColorRect
var target: ColorRect
var round_label: Label
var feedback: Label
var retry_timer: Timer


func _ready() -> void:
	_build_screen()
	_start_round()


func _process(delta: float) -> void:
	if finished or not moving:
		return
	needle_y += SPEEDS[current_round] * direction * delta
	if needle_y >= MAX_Y:
		needle_y = MAX_Y
		direction = -1.0
	elif needle_y <= MIN_Y:
		needle_y = MIN_Y
		direction = 1.0
	needle.position.y = needle_y


func _unhandled_input(event: InputEvent) -> void:
	if finished or not moving:
		return
	var touched: bool = false
	if event is InputEventScreenTouch:
		touched = event.pressed
	var clicked: bool = false
	if event is InputEventMouseButton:
		clicked = (event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
	var interact_pressed: bool = event.is_action_pressed(&"interact")
	if touched or clicked or interact_pressed:
		_stop_and_check()


func _build_screen() -> void:
	_background(Color("FFF3D4"))
	add_child(_label("씨앗에게 딱 맞는 온도를 찾아요!", Vector2(180, 28), Vector2(920, 58), 40))
	add_child(_label("초록색 칸에 바늘이 왔을 때 화면을 톡 눌러요!", Vector2(180, 86), Vector2(920, 42), 25))
	round_label = _label("", Vector2(400, 130), Vector2(480, 40), 28)
	add_child(round_label)
	feedback = _label("", Vector2(270, 570), Vector2(740, 40), 24)
	add_child(feedback)
	var frame := ColorRect.new()
	frame.color = Color("E7EDF5")
	frame.position = Vector2(550, 175)
	frame.size = Vector2(180, 500)
	add_child(frame)
	target = ColorRect.new()
	target.color = Color("8DDB84")
	target.position.x = 15
	target.size.x = 150
	frame.add_child(target)
	needle = ColorRect.new()
	needle.color = Color("FF5F5F")
	needle.position = Vector2(0, MIN_Y)
	needle.size = Vector2(180, 12)
	frame.add_child(needle)
	add_child(_label("화면을 터치!  /  PC: Space 또는 마우스 클릭", Vector2(250, 685), Vector2(780, 30), 21))
	retry_timer = Timer.new()
	retry_timer.wait_time = 0.8
	retry_timer.one_shot = true
	retry_timer.timeout.connect(_start_round)
	add_child(retry_timer)


func _start_round() -> void:
	needle_y = MIN_Y
	direction = 1.0
	moving = true
	needle.position.y = needle_y
	var target_range: Vector2 = TARGETS[current_round]
	target.position.y = target_range.x
	target.size.y = target_range.y - target_range.x
	round_label.text = "온도 맞추기  " + str(current_round + 1) + " / 5"
	feedback.text = "초록색 온도 구간을 노려 보세요."


func _stop_and_check() -> void:
	moving = false
	var target_range: Vector2 = TARGETS[current_round]
	var center_y := needle_y + needle.size.y * 0.5
	if center_y >= target_range.x and center_y <= target_range.y:
		feedback.text = "정확해요! 아주 좋아요! ✨"
		current_round += 1
		if current_round >= 5:
			_finish_game()
			return
		await get_tree().create_timer(0.7).timeout
		if not finished:
			_start_round()
	else:
		feedback.text = "조금 아쉬워요. 같은 온도를 다시 맞춰 봐요!"
		retry_timer.start()


func _finish_game() -> void:
	finished = true
	GameState.complete_quest(&"temp")
	_show_result("성공! ☀️\n씨앗에게 알맞은 온도를 찾아 주었어요!", "밭으로 돌아가기")


func _show_result(message: String, button_text: String) -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.12, 0.18, 0.92)
	panel.position = Vector2(250, 205)
	panel.size = Vector2(780, 300)
	panel.z_index = 10
	add_child(panel)
	panel.add_child(_label(message, Vector2(40, 55), Vector2(700, 110), 34))
	var button := Button.new()
	button.text = button_text
	button.position = Vector2(140, 190)
	button.size = Vector2(500, 70)
	button.add_theme_font_size_override("font_size", 27)
	button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainField.tscn"))
	panel.add_child(button)


func _background(color: Color) -> void:
	var node := ColorRect.new()
	node.color = color
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(node)


func _label(value: String, pos: Vector2, control_size: Vector2, font_size: int) -> Label:
	var node := Label.new()
	node.text = value
	node.position = pos
	node.size = control_size
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	return node

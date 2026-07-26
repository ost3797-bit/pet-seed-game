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
	var bg := ColorRect.new()
	bg.color = Color("707782")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	add_child(_label("매연을 없애고 깨끗한 공기를 만들어요!", Vector2(130, 25), Vector2(1020, 55), 38))
	add_child(_label("회색 매연을 빠르게 톡톡 눌러 없애요!", Vector2(180, 82), Vector2(920, 40), 25))
	round_label = _label("", Vector2(420, 125), Vector2(440, 38), 28)
	add_child(round_label)
	feedback = _label("", Vector2(210, 175), Vector2(860, 35), 23)
	add_child(feedback)
	smoke_container = Control.new()
	smoke_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	smoke_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(smoke_container)
	var frame := ColorRect.new()
	frame.color = Color("263747")
	frame.position = Vector2(300, 615)
	frame.size = Vector2(680, 85)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	breath_gauge = TextureProgressBar.new()
	breath_gauge.position = Vector2(20, 15)
	breath_gauge.size = Vector2(640, 55)
	breath_gauge.max_value = 100.0
	breath_gauge.value = 40.0
	breath_gauge.texture_progress = _solid_texture(Color("75D66F"), 32, 32)
	breath_gauge.nine_patch_stretch = true
	breath_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(breath_gauge)
	var gauge_text := _label("", Vector2(0, 15), Vector2(680, 55), 27)
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
	round_label.text = "공기 정화  " + str(current_round + 1) + " / " + str(TOTAL_ROUNDS)
	feedback.text = "매연을 눌러 깨끗한 공기를 만들어요!"
	spawn_timer.wait_time = maxf(0.9, 1.8 - current_round * 0.15)
	spawn_timer.start()
	_spawn_smoke()
	_update_gauge_text()


func _spawn_smoke() -> void:
	if finished or smoke_container.get_child_count() >= MAX_SMOKE:
		return
	var smoke := Area2D.new()
	smoke.position = _random_smoke_position()
	smoke.input_pickable = true
	smoke.z_index = 3
	var cloud := Polygon2D.new()
	cloud.polygon = PackedVector2Array([Vector2(-42, 5), Vector2(-35, -20), Vector2(-12, -38), Vector2(12, -32), Vector2(35, -16), Vector2(44, 10), Vector2(28, 34), Vector2(0, 42), Vector2(-25, 32)])
	cloud.color = Color("3F454D")
	smoke.add_child(cloud)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 44.0
	collision.shape = shape
	smoke.add_child(collision)
	var label := Label.new()
	label.text = "매연!"
	label.position = Vector2(-31, -13)
	label.size = Vector2(62, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	smoke.add_child(label)
	smoke.input_event.connect(func(_viewport: Node, event: InputEvent, _shape: int):
		if event is InputEventScreenTouch and event.pressed:
			_clean_smoke(smoke)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_clean_smoke(smoke)
	)
	smoke_container.add_child(smoke)


func _clean_smoke(smoke: Area2D) -> void:
	if finished or not is_instance_valid(smoke):
		return
	smoke.queue_free()
	breath_gauge.value = minf(100.0, breath_gauge.value + GAIN_PER_SMOKE)
	feedback.text = "좋아요! 공기가 더 깨끗해졌어요! 🌿"
	if breath_gauge.value >= 100.0:
		_complete_round()


func _complete_round() -> void:
	spawn_timer.stop()
	_clear_smoke()
	current_round += 1
	if current_round >= TOTAL_ROUNDS:
		_finish_game()
		return
	feedback.text = "라운드 성공! 다음 공기를 정화해요!"
	await get_tree().create_timer(0.8).timeout
	if not finished:
		_start_round()


func _finish_game() -> void:
	finished = true
	spawn_timer.stop()
	_clear_smoke()
	GameState.complete_quest(&"air")
	_show_result("대성공! 🌱\n씨앗이 깨끗한 공기를 마셨어요!", "밭으로 돌아가기")


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
	text_node.text = "호흡 게이지  " + str(roundi(breath_gauge.value)) + "%"


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


func _label(value: String, pos: Vector2, control_size: Vector2, font_size: int) -> Label:
	var node := Label.new()
	node.text = value
	node.position = pos
	node.size = control_size
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	return node


func _solid_texture(color: Color, width: int, height: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, color])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = width
	texture.height = height
	return texture

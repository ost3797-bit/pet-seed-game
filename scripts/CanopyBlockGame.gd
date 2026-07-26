extends Control

# 게임 설정
const TARGET_BLOCK_COUNT := 15
const CANOPY_Y := 520.0
const MIN_X := 90.0
const MAX_X := 1190.0

var blocked_count := 0
var is_game_over := false
var is_dragging := false

# 주요 노드
var canopy: Area2D
var canopy_rect: ColorRect
var seed_sprite: Sprite2D
var spawner_timer: Timer
var score_label: Label
var feedback_label: Label
var return_btn: Button

# 생성된 햇빛(Sunbeam) 배열
var sunbeams: Array[Area2D] = []
var sunbeam_speed := 300.0


func _ready() -> void:
	_build_ui()
	_build_canopy()
	_build_seed()
	_start_game()


func _process(delta: float) -> void:
	if is_game_over:
		return
		
	# 키보드 이동 처리 (A/D 또는 좌우 방향키)
	var move_dir := Input.get_axis(&"move_left", &"move_right")
	if move_dir != 0.0:
		canopy.position.x += move_dir * 500.0 * delta
		canopy.position.x = clamp(canopy.position.x, MIN_X, MAX_X)
	
	# 햇빛 이동 및 바닥 충돌 처리
	for i in range(sunbeams.size() - 1, -1, -1):
		var beam := sunbeams[i]
		if not is_instance_valid(beam):
			sunbeams.remove_at(i)
			continue
			
		beam.position.y += sunbeam_speed * delta
		
		# 바닥(씨앗)에 닿았을 때 (놓침)
		if beam.position.y > 630.0:
			_on_beam_missed(beam)
			sunbeams.remove_at(i)


func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		return
	
	# 마우스 및 터치 드래그로 그늘막 좌우 이동
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			if is_dragging:
				canopy.position.x = clamp(event.position.x, MIN_X, MAX_X)
	elif event is InputEventMouseMotion and is_dragging:
		canopy.position.x = clamp(event.position.x, MIN_X, MAX_X)
	elif event is InputEventScreenTouch:
		is_dragging = event.pressed
		if is_dragging:
			canopy.position.x = clamp(event.position.x, MIN_X, MAX_X)
	elif event is InputEventScreenDrag and is_dragging:
		canopy.position.x = clamp(event.position.x, MIN_X, MAX_X)


func _build_ui() -> void:
	# 배경 (따뜻하고 맑은 하늘빛)
	var bg := ColorRect.new()
	bg.color = Color("E0F7FA")
	bg.size = Vector2(1280, 720)
	add_child(bg)
	
	# 상단 장식 바
	var top_bar := ColorRect.new()
	top_bar.color = Color("DA863E")
	top_bar.size = Vector2(1280, 70)
	add_child(top_bar)
	
	var title_lbl := _label("☀️ 햇빛 막기 대작전!", Vector2(0, 15), Vector2(1280, 40), 32)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(title_lbl)
	
	score_label = _label("막아낸 햇빛: 0 / " + str(TARGET_BLOCK_COUNT) + "개", Vector2(40, 90), Vector2(400, 40), 28)
	score_label.add_theme_color_override("font_color", Color("D94141"))
	add_child(score_label)
	
	feedback_label = _label("좌우 방향키(A/D) 또는 마우스 드래그로 그늘막을 움직여 씨앗을 보호하세요!", Vector2(0, 95), Vector2(1280, 30), 22)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_color_override("font_color", Color("333333"))
	add_child(feedback_label)
	
	# 바닥 땅
	var ground := ColorRect.new()
	ground.color = Color("8DDB84")
	ground.position = Vector2(0, 630)
	ground.size = Vector2(1280, 90)
	add_child(ground)
	
	# 클리어 귀환 버튼
	return_btn = Button.new()
	return_btn.text = "🎉 적절한 온도 완성! 마을로 돌아가기"
	return_btn.position = Vector2(440, 320)
	return_btn.size = Vector2(400, 70)
	return_btn.add_theme_font_size_override("font_size", 24)
	return_btn.hide()
	return_btn.pressed.connect(_on_return_pressed)
	add_child(return_btn)


func _build_canopy() -> void:
	canopy = Area2D.new()
	canopy.name = "Canopy"
	canopy.position = Vector2(640, CANOPY_Y)
	canopy.collision_layer = 1
	canopy.collision_mask = 2
	add_child(canopy)
	
	# 그늘막 그래픽 (목재 천막 스타일)
	canopy_rect = ColorRect.new()
	canopy_rect.color = Color("8B4513")
	canopy_rect.position = Vector2(-90, -15)
	canopy_rect.size = Vector2(180, 30)
	canopy.add_child(canopy_rect)
	
	var roof_top := Polygon2D.new()
	roof_top.color = Color("DA863E")
	roof_top.polygon = PackedVector2Array([Vector2(-95, -15), Vector2(0, -35), Vector2(95, -15)])
	canopy.add_child(roof_top)
	
	# 충돌 영역
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(180, 35)
	col.shape = shape
	canopy.add_child(col)
	
	canopy.area_entered.connect(_on_canopy_hit)


func _build_seed() -> void:
	var seed_node := Node2D.new()
	seed_node.position = Vector2(640, 610)
	add_child(seed_node)
	
	# 씨앗 이미지 (없으면 초록 원형 폴리곤 대체)
	var tex := load("res://assets/sky_seed.png") as Texture2D
	if tex != null:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.scale = Vector2(0.5, 0.5)
		seed_node.add_child(spr)
	else:
		var poly := Polygon2D.new()
		poly.color = Color("2E8B57")
		poly.polygon = PackedVector2Array([Vector2(0, -30), Vector2(25, 0), Vector2(0, 30), Vector2(-25, 0)])
		seed_node.add_child(poly)
	
	var lbl := Label.new()
	lbl.text = "🌱 새싹이"
	lbl.position = Vector2(-50, -60)
	lbl.size = Vector2(100, 25)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color("006400"))
	seed_node.add_child(lbl)


func _start_game() -> void:
	blocked_count = 0
	is_game_over = false
	
	spawner_timer = Timer.new()
	spawner_timer.wait_time = 0.7
	spawner_timer.timeout.connect(_spawn_sunbeam)
	add_child(spawner_timer)
	spawner_timer.start()


func _spawn_sunbeam() -> void:
	if is_game_over:
		return
		
	var beam := Area2D.new()
	beam.position = Vector2(randf_range(MIN_X, MAX_X), -30)
	beam.collision_layer = 2
	beam.collision_mask = 0
	add_child(beam)
	
	# 햇빛 그래픽 (노란빛/빨간빛 태양 불꽃)
	var poly := Polygon2D.new()
	poly.color = Color("FF8C00") if randf() > 0.5 else Color("FFD700")
	poly.polygon = PackedVector2Array([Vector2(0, -20), Vector2(15, 0), Vector2(0, 20), Vector2(-15, 0)])
	beam.add_child(poly)
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	col.shape = shape
	beam.add_child(col)
	
	sunbeams.append(beam)


func _on_canopy_hit(area: Area2D) -> void:
	if is_game_over:
		return
		
	if area in sunbeams:
		sunbeams.erase(area)
		area.queue_free()
		
		blocked_count += 1
		score_label.text = "막아낸 햇빛: " + str(blocked_count) + " / " + str(TARGET_BLOCK_COUNT) + "개"
		
		# 막아낼 때마다 약간 속도 증가로 재미 추가
		sunbeam_speed = min(550.0, sunbeam_speed + 12.0)
		
		if blocked_count >= TARGET_BLOCK_COUNT:
			_on_game_cleared()


func _on_beam_missed(beam: Area2D) -> void:
	beam.queue_free()
	feedback_label.text = "앗 뜨거! 햇빛이 씨앗에 닿았습니다! 그늘막으로 막아주세요!"
	feedback_label.add_theme_color_override("font_color", Color("D94141"))


func _on_game_cleared() -> void:
	is_game_over = true
	if spawner_timer != null:
		spawner_timer.stop()
		
	for beam in sunbeams:
		if is_instance_valid(beam):
			beam.queue_free()
	sunbeams.clear()
	
	feedback_label.text = "🎉 축하합니다! 그늘막 덕분에 씨앗이 시원한 온도를 찾았습니다!"
	feedback_label.add_theme_color_override("font_color", Color("228B22"))
	return_btn.show()
	
	# 게임 클리어 처리 (온도 퀘스트 완료)
	GameState.complete_quest(&"temp")
	GameState.just_cleared_temp = true


func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainField.tscn")


func _label(value: String, pos: Vector2, control_size: Vector2, font_size: int) -> Label:
	var node := Label.new()
	node.text = value
	node.position = pos
	node.size = control_size
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color.WHITE)
	return node

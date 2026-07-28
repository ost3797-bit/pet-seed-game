extends Control

# 3x3 퍼즐 타일 정보
const GRID_SIZE := 3
const TILE_SIZE := Vector2(150, 150)
const GRID_START := Vector2(415, 135)

var tiles: Array[Button] = []
var board_state: Array[int] = []  # 0부터 8까지의 현재 타일 인덱스
var selected_index := -1
var is_cleared := false

var title_label: Label
var info_label: Label
var feedback_label: Label
var return_btn: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = Color("FFF3D4")
	bg.size = Vector2(1280, 720)
	add_child(bg)
	
	# 상단 장식 바
	var top_bar := ColorRect.new()
	top_bar.color = Color("DA863E")
	top_bar.size = Vector2(1280, 70)
	add_child(top_bar)
	
	title_label = _label("🎪 그늘막 그림조각 맞추기", Vector2(0, 15), Vector2(1280, 40), 32)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(title_label)
	
	info_label = _label("두 조각을 차례로 클릭하여 올바른 위치(1~9번)로 맞춰주세요!", Vector2(0, 85), Vector2(1280, 35), 22)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_color_override("font_color", Color("555555"))
	add_child(info_label)
	
	# 퍼즐 배경 프레임
	var frame := ColorRect.new()
	frame.color = Color("8B4513")
	frame.position = GRID_START - Vector2(15, 15)
	frame.size = Vector2(GRID_SIZE * TILE_SIZE.x + 30, GRID_SIZE * TILE_SIZE.y + 30)
	add_child(frame)
	
	# 피드백 라벨
	feedback_label = _label("", Vector2(0, 605), Vector2(1280, 40), 26)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_color_override("font_color", Color("D94141"))
	add_child(feedback_label)
	
	# 치트 버튼 삭제됨
	
	# 씨앗에게 돌아가기 버튼 (클리어 시 표시)
	return_btn = Button.new()
	return_btn.text = "🌱 그늘막 들고 씨앗에게 돌아가기!"
	return_btn.position = Vector2(465, 645)
	return_btn.size = Vector2(350, 55)
	return_btn.add_theme_font_size_override("font_size", 22)
	return_btn.hide()
	return_btn.pressed.connect(_on_return_pressed)
	add_child(return_btn)
	
	# 규칙 설명 패널
	var rule_panel := ColorRect.new()
	rule_panel.color = Color(0, 0, 0, 0.85)
	rule_panel.size = Vector2(1280, 720)
	add_child(rule_panel)
	
	var rule_title := _label("💡 목수님의 그늘막 퍼즐 규칙 💡", Vector2(0, 200), Vector2(1280, 60), 40)
	rule_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule_panel.add_child(rule_title)
	
	var rule_text := _label("두 개의 퍼즐 조각을 차례대로 클릭하면 서로 위치가 바뀝니다.\n조각들을 이리저리 교환하여 1번부터 9번까지 순서대로 맞춰주세요!", Vector2(0, 320), Vector2(1280, 100), 28)
	rule_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule_panel.add_child(rule_text)
	
	var start_btn := Button.new()
	start_btn.text = "퍼즐 시작하기!"
	start_btn.position = Vector2(515, 480)
	start_btn.size = Vector2(250, 60)
	start_btn.add_theme_font_size_override("font_size", 28)
	start_btn.pressed.connect(func(): rule_panel.hide(); _init_board())
	rule_panel.add_child(start_btn)


func _init_board() -> void:
	board_state.clear()
	for i in range(GRID_SIZE * GRID_SIZE):
		board_state.append(i)
	
	# 타일 섞기 (클리어 상태가 안 되도록)
	board_state.shuffle()
	while _check_win():
		board_state.shuffle()
	
	# 타일 버튼 생성
	for i in range(board_state.size()):
		var btn := Button.new()
		btn.size = TILE_SIZE - Vector2(6, 6)
		btn.add_theme_font_size_override("font_size", 32)
		btn.pressed.connect(func(): _on_tile_clicked(i))
		add_child(btn)
		tiles.append(btn)
	
	_update_board_visuals()


func _on_tile_clicked(index: int) -> void:
	if is_cleared:
		return
		
	if selected_index == -1:
		selected_index = index
		feedback_label.text = "조각을 선택했습니다. 바꿀 다른 조각을 선택하세요!"
		feedback_label.add_theme_color_override("font_color", Color("228B22"))
	elif selected_index == index:
		selected_index = -1
		feedback_label.text = "선택을 취소했습니다."
		feedback_label.add_theme_color_override("font_color", Color("555555"))
	else:
		# 두 조각 위치 교환
		var temp := board_state[selected_index]
		board_state[selected_index] = board_state[index]
		board_state[index] = temp
		
		selected_index = -1
		_update_board_visuals()
		
		if _check_win():
			_on_puzzle_cleared()
		else:
			feedback_label.text = "조각을 교환했습니다! 계속 맞춰보세요."
			feedback_label.add_theme_color_override("font_color", Color("555555"))


func _update_board_visuals() -> void:
	for i in range(tiles.size()):
		var btn := tiles[i]
		var val := board_state[i]
		
		# 그리드 위치 계산
		var row := i / GRID_SIZE
		var col := i % GRID_SIZE
		btn.position = GRID_START + Vector2(col * TILE_SIZE.x + 3, row * TILE_SIZE.y + 3)
		
		# 조각 번호 및 예쁜 색상 표시
		btn.text = "그늘막\n[" + str(val + 1) + "번]"
		
		if i == selected_index:
			btn.modulate = Color(1.0, 0.5, 0.5)  # 선택된 타일 하이라이트
		elif val == i:
			btn.modulate = Color(0.7, 1.0, 0.7)  # 제자리에 맞는 타일 초록빛
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)


func _check_win() -> bool:
	for i in range(board_state.size()):
		if board_state[i] != i:
			return false
	return true





func _on_puzzle_cleared() -> void:
	is_cleared = true
	feedback_label.text = "🎉 짝짝짝! 완벽한 그늘막이 완성되었습니다! 목수님이 그늘막을 건네주십니다."
	feedback_label.add_theme_color_override("font_color", Color("228B22"))
	return_btn.show()
	
	# 게임 상태 업데이트
	GameState.temp_phase_id = 2  # READY_TO_SHADE
	GameState.save_game()


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

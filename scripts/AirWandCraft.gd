extends Control

# ─────────────────────────────────────────────
# 레트로 8비트 스타일 - 공기정화 마법봉 제작 분류 미니게임
# ─────────────────────────────────────────────

enum CardType {
	POLLUTION,  # 오염 원인 (왼쪽)
	CLEAN       # 정화 요소 (오른쪽)
}

class CardData:
	var icon_name: String
	var type: int
	var hint: String
	func _init(p_name: String, p_type: int, p_hint: String) -> void:
		icon_name = p_name
		type = p_type
		hint = p_hint

var card_deck: Array[CardData] = []
var current_card_idx := 0
var correct_count := 0
const TARGET_CORRECT := 7
var is_cleared := false

# UI 노드들
var gauge_label: Label
var gauge_bar_fill: ColorRect
var card_panel: Panel
var card_label: Label
var card_hint_label: Label
var feedback_label: Label
var btn_left: Button
var btn_right: Button
var btn_return: Button
var win_panel: Panel

func _ready() -> void:
	_init_deck()
	_build_retro_ui()
	_show_next_card()

func _init_deck() -> void:
	card_deck.clear()
	card_deck.append(CardData.new("🚗 자동차 매연", CardType.POLLUTION, "내연기관 자동차의 배기가스는 대기오염의 주범이에요!"))
	card_deck.append(CardData.new("🌳 나무 심기", CardType.CLEAN, "나무와 숲은 오염된 공기를 흡수하고 산소를 뿜어내요!"))
	card_deck.append(CardData.new("🏭 공장 검은 연기", CardType.POLLUTION, "공장에서 정화 없이 내뿜는 연기는 공기를 더럽혀요!"))
	card_deck.append(CardData.new("🚌 대중교통(버스/지하철) 이용", CardType.CLEAN, "자가용 대신 대중교통을 타면 매연을 크게 줄일 수 있어요!"))
	card_deck.append(CardData.new("🗑️ 쓰레기 불법 소각", CardType.POLLUTION, "쓰레기를 함부로 태우면 독한 유해 가스가 발생해요!"))
	card_deck.append(CardData.new("🌬️ 맑은 바람과 숲", CardType.CLEAN, "자연의 시원한 바람과 깨끗한 숲은 공기를 순환시켜요!"))
	card_deck.append(CardData.new("🚲 자전거 타기와 걷기", CardType.CLEAN, "가까운 거리는 자전거를 타면 매연이 전혀 나오지 않아요!"))
	card_deck.append(CardData.new("⚡ 일회용품 낭비", CardType.POLLUTION, "일회용품을 많이 쓰고 태우면 공기가 오염돼요!"))
	card_deck.append(CardData.new("☀️ 친환경 태양열 에너지", CardType.CLEAN, "깨끗한 태양광 에너지는 매연을 만들지 않아요!"))
	card_deck.append(CardData.new("🔥 화학 연료 남용", CardType.POLLUTION, "석탄과 석유를 과도하게 태우면 대기가 탁해져요!"))
	card_deck.shuffle()

func _build_retro_ui() -> void:
	# 8-bit 레트로 밤하늘/다크 네이비 배경
	var bg := ColorRect.new()
	bg.color = Color("181425")
	bg.size = Vector2(1280, 720)
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

	# 상단 타이틀 바
	var top_bar := ColorRect.new()
	top_bar.color = Color("262b44")
	top_bar.position = Vector2(40, 20)
	top_bar.size = Vector2(1200, 70)
	add_child(top_bar)
	
	var top_border := ReferenceRect.new()
	top_border.position = Vector2(40, 20)
	top_border.size = Vector2(1200, 70)
	top_border.border_color = Color("2ce8f5")
	top_border.border_width = 4.0
	top_border.editor_only = false
	add_child(top_border)

	var title_lbl := _label("✨ 공기정화 마법봉 충전 - 환경 요소 분류 게임", Vector2(40, 35), Vector2(1200, 40), 28, Color("2ce8f5"))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_lbl)

	# 안내 텍스트
	var info_lbl := _label("공기를 오염시키는 원인은 [⬅️ 왼쪽], 공기를 정화하는 요소는 [➡️ 오른쪽]으로 분류하여 마법봉을 충전하세요!", Vector2(0, 105), Vector2(1280, 30), 20, Color("fee761"))
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(info_lbl)

	# 마법봉 충전 게이지 영역 (레트로 배터리 스타일)
	var gauge_box := ColorRect.new()
	gauge_box.color = Color("12101a")
	gauge_box.position = Vector2(340, 145)
	gauge_box.size = Vector2(600, 50)
	add_child(gauge_box)
	
	var gauge_border := ReferenceRect.new()
	gauge_border.position = Vector2(340, 145)
	gauge_border.size = Vector2(600, 50)
	gauge_border.border_color = Color("ffffff")
	gauge_border.border_width = 4.0
	gauge_border.editor_only = false
	add_child(gauge_border)

	gauge_bar_fill = ColorRect.new()
	gauge_bar_fill.color = Color("38b764")
	gauge_bar_fill.position = Vector2(344, 149)
	gauge_bar_fill.size = Vector2(0, 42)
	add_child(gauge_bar_fill)

	gauge_label = _label("⚡ 마법봉 충전율: [0%] (0/7)", Vector2(340, 155), Vector2(600, 30), 22, Color("ffffff"))
	gauge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(gauge_label)

	# 중앙 카드 영역 (레트로 픽셀 박스)
	card_panel = Panel.new()
	card_panel.position = Vector2(390, 220)
	card_panel.size = Vector2(500, 240)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("2a2f4e")
	sb.border_width_left = 6
	sb.border_width_right = 6
	sb.border_width_top = 6
	sb.border_width_bottom = 6
	sb.border_color = Color("f0f6f0")
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	card_panel.add_theme_stylebox_override("panel", sb)
	add_child(card_panel)

	card_label = _label("🚗 자동차 매연", Vector2(0, 50), Vector2(500, 60), 36, Color("ffffff"))
	card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_panel.add_child(card_label)

	card_hint_label = _label("이 요소는 공기를 오염시킬까요, 깨끗하게 할까요?", Vector2(20, 140), Vector2(460, 60), 20, Color("a7ba4a"))
	card_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	card_panel.add_child(card_hint_label)

	# 피드백 텍스트
	feedback_label = _label("키보드 [← / A] 또는 [→ / D] 키를 누르거나 아래 버튼을 클릭하세요!", Vector2(140, 480), Vector2(1000, 40), 22, Color("ffffff"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(feedback_label)

	# 하단 좌우 분류 버튼 (레트로 스타일)
	btn_left = _create_retro_button("⬅️ 오염 원인\n[왼쪽 / A]", Vector2(180, 540), Vector2(380, 90), Color("e43b44"))
	btn_left.pressed.connect(func(): _classify_card(CardType.POLLUTION))
	add_child(btn_left)

	btn_right = _create_retro_button("➡️ 정화 요소\n[오른쪽 / D]", Vector2(720, 540), Vector2(380, 90), Color("38b764"))
	btn_right.pressed.connect(func(): _classify_card(CardType.CLEAN))
	add_child(btn_right)

	# 클리어 시 표시될 윈도우 패널
	win_panel = Panel.new()
	win_panel.position = Vector2(290, 180)
	win_panel.size = Vector2(700, 380)
	var win_sb := StyleBoxFlat.new()
	win_sb.bg_color = Color("181425")
	win_sb.border_width_left = 8
	win_sb.border_width_right = 8
	win_sb.border_width_top = 8
	win_sb.border_width_bottom = 8
	win_sb.border_color = Color("fee761")
	win_panel.add_theme_stylebox_override("panel", win_sb)
	win_panel.hide()
	add_child(win_panel)

	var win_title := _label("🎉 공기정화 마법봉 100% 충전 완료! ✨", Vector2(0, 40), Vector2(700, 50), 32, Color("fee761"))
	win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_panel.add_child(win_title)

	var win_desc := _label("완벽합니다! 여러분의 환경 지혜로 맑고 강력한\n'공기정화 마법봉'이 완성되었습니다!\n\n이제 숨쉬기 힘들어하는 씨앗에게 돌아가\n까만 매연 구름을 모두 깨끗이 정화해 줍시다!", Vector2(50, 110), Vector2(600, 120), 22, Color("ffffff"))
	win_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	win_panel.add_child(win_desc)

	btn_return = _create_retro_button("🌱 텃밭으로 돌아가서 매연 정화하기!", Vector2(150, 290), Vector2(400, 60), Color("2ce8f5"), Color("000000"))
	btn_return.pressed.connect(_on_return_pressed)
	win_panel.add_child(btn_return)

func _create_retro_button(text: String, pos: Vector2, btn_size: Vector2, bg_color: Color, text_color: Color = Color.WHITE) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = btn_size
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = bg_color
	sb_normal.border_width_left = 4
	sb_normal.border_width_right = 4
	sb_normal.border_width_top = 4
	sb_normal.border_width_bottom = 4
	sb_normal.border_color = Color.WHITE
	sb_normal.corner_radius_top_left = 0
	sb_normal.corner_radius_top_right = 0
	sb_normal.corner_radius_bottom_left = 0
	sb_normal.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("normal", sb_normal)
	
	var sb_hover := sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = bg_color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", sb_hover)
	
	var sb_pressed := sb_normal.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = bg_color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	
	return btn

func _input(event: InputEvent) -> void:
	if is_cleared:
		return
	if event.is_action_pressed("move_left") or (event is InputEventKey and event.pressed and event.keycode == KEY_LEFT):
		_classify_card(CardType.POLLUTION)
	elif event.is_action_pressed("move_right") or (event is InputEventKey and event.pressed and event.keycode == KEY_RIGHT):
		_classify_card(CardType.CLEAN)

func _show_next_card() -> void:
	if current_card_idx >= card_deck.size():
		card_deck.shuffle()
		current_card_idx = 0
	var card := card_deck[current_card_idx]
	card_label.text = card.icon_name
	card_hint_label.text = "이 요소는 공기를 오염시킬까요, 깨끗하게 할까요?"
	card_hint_label.add_theme_color_override("font_color", Color("a7ba4a"))

func _classify_card(chosen_type: int) -> void:
	if is_cleared:
		return
	var card := card_deck[current_card_idx]
	if chosen_type == card.type:
		# 정답 처리
		correct_count += 1
		var pct: int = int(min(100.0, float(correct_count) / float(TARGET_CORRECT) * 100.0))
		gauge_label.text = "⚡ 마법봉 충전율: [" + str(pct) + "%] (" + str(correct_count) + "/" + str(TARGET_CORRECT) + ")"
		gauge_bar_fill.size.x = float(min(592.0, float(correct_count) / float(TARGET_CORRECT) * 592.0))
		
		feedback_label.text = "✨ 정답입니다! [" + card.icon_name + "] ➔ 맑은 기운이 마법봉에 흡수됩니다!"
		feedback_label.add_theme_color_override("font_color", Color("38b764"))
		
		if correct_count >= TARGET_CORRECT:
			_on_game_cleared()
		else:
			current_card_idx += 1
			_show_next_card()
	else:
		# 오답 처리 (힌트 제공)
		feedback_label.text = "아차! " + card.hint
		feedback_label.add_theme_color_override("font_color", Color("e43b44"))
		card_hint_label.text = "💡 힌트: " + card.hint
		card_hint_label.add_theme_color_override("font_color", Color("fee761"))

func _on_game_cleared() -> void:
	is_cleared = true
	card_panel.hide()
	btn_left.hide()
	btn_right.hide()
	feedback_label.text = "🎉 마법봉 충전 완료! 어서 씨앗에게 돌아갑시다!"
	feedback_label.add_theme_color_override("font_color", Color("fee761"))
	win_panel.show()
	
	# 상태 업데이트 (2: 마법봉 획득 완료)
	GameState.air_phase_id = 2
	GameState.save_game()

func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainField.tscn")

func _label(val: String, pos: Vector2, sz: Vector2, font_size: int, font_color: Color = Color.WHITE) -> Label:
	var lbl := Label.new()
	lbl.text = val
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", font_color)
	return lbl

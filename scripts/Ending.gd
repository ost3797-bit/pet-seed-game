extends Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("FFF4B8")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.position = Vector2(300, 100)
	box.size = Vector2(680, 530)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	add_child(box)
	box.add_child(_label("축하합니다! 🌱", 52))
	box.add_child(_label(GameState.player_name + " 덕분에 씨앗이 건강한 새싹으로 자랐어요!\n물, 온도, 공기를 모두 모은 멋진 친구예요.", 29))
	var sprout := Label.new()
	sprout.text = "🪴"
	sprout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sprout.add_theme_font_size_override("font_size", 130)
	box.add_child(sprout)
	var restart := _button("새 친구와 다시 시작하기", 28)
	restart.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn"))
	box.add_child(restart)
	var title := _button("타이틀 화면으로", 24)
	title.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Title.tscn"))
	box.add_child(title)
	var quit := _button("게임 종료", 21)
	quit.pressed.connect(func(): get_tree().quit())
	box.add_child(quit)


func _label(value: String, size: int) -> Label:
	var node := Label.new()
	node.text = value
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", size)
	return node


func _button(value: String, size: int) -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size = Vector2(680, 65)
	node.add_theme_font_size_override("font_size", size)
	return node

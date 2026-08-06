extends Control

var video_player: VideoStreamPlayer
var char_rect: TextureRect
var dialogue_panel: ColorRect
var dialogue_text: Label
var next_btn: Button
var button_container: VBoxContainer
var _js_callback: JavaScriptObject

func _ready() -> void:
	# 배경 (비디오 뒤)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 캐릭터 이미지 (비디오 종료 후 표시)
	char_rect = TextureRect.new()
	char_rect.texture = load("res://assets/seed/seed7.png")
	char_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_rect.position = Vector2(340, 50)
	char_rect.size = Vector2(600, 600)
	char_rect.hide()
	add_child(char_rect)
	
	# 대화창 UI (비디오 종료 후 표시)
	dialogue_panel = ColorRect.new()
	dialogue_panel.color = Color("FFF4B8")
	dialogue_panel.position = Vector2(140, 500)
	dialogue_panel.size = Vector2(1000, 200)
	dialogue_panel.hide()
	add_child(dialogue_panel)
	
	dialogue_text = Label.new()
	dialogue_text.text = "와아아~! 앗싸! 파릇파릇하고 예쁜 새싹이 돋아났어요!! 🌱✨\n당신이 깨끗한 물, 따뜻한 그늘, 그리고 맑은 공기를 선물해 준 덕분이에요!\n정말 정말 고마워요!! 우리 함께 축하하러 가요!"
	dialogue_text.position = Vector2(40, 30)
	dialogue_text.size = Vector2(920, 100)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_size_override("font_size", 28)
	dialogue_text.add_theme_color_override("font_color", Color.BLACK)
	dialogue_panel.add_child(dialogue_text)
	
	next_btn = Button.new()
	next_btn.text = "엔딩 메뉴 보기 🎉"
	next_btn.position = Vector2(750, 130)
	next_btn.size = Vector2(220, 50)
	next_btn.add_theme_font_size_override("font_size", 22)
	next_btn.pressed.connect(_show_ending_menu)
	dialogue_panel.add_child(next_btn)
	
	# 종료 메뉴 컨테이너
	button_container = VBoxContainer.new()
	button_container.position = Vector2(300, 500)
	button_container.size = Vector2(680, 200)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 20)
	button_container.hide()
	add_child(button_container)
	
	var restart := _button("새 친구와 다시 시작하기", 28)
	restart.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn"))
	button_container.add_child(restart)
	
	var title := _button("타이틀 화면으로", 24)
	title.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Title.tscn"))
	button_container.add_child(title)
	
	var quit := _button("게임 종료", 21)
	quit.pressed.connect(func(): get_tree().quit())
	button_container.add_child(quit)
	
	# 비디오 재생
	if OS.has_feature("web"):
		_play_html5_video()
	else:
		_play_godot_video()

func _play_html5_video() -> void:
	_js_callback = JavaScriptBridge.create_callback(_on_js_video_finished)
	var window = JavaScriptBridge.get_interface("window")
	if window != null:
		window.godotEndingVideoCallback = _js_callback
		
		var js_code = """
		var video = document.createElement('video');
		video.id = 'godot_ending_video';
		video.src = './video1-ortx30.ogv';
		video.style.position = 'absolute';
		video.style.top = '0';
		video.style.left = '0';
		video.style.width = '100vw';
		video.style.height = '100vh';
		video.style.zIndex = '9999';
		video.style.backgroundColor = 'black';
		video.style.objectFit = 'contain';
		video.controls = false;
		video.playsInline = true;
		
		video.onclick = function() {
			video.pause();
			video.remove();
			window.godotEndingVideoCallback();
		};
		
		video.onended = function() {
			video.remove();
			window.godotEndingVideoCallback();
		};
		
		document.body.appendChild(video);
		video.play().catch(function(e) {
			console.log('Video autoplay failed', e);
			video.remove();
			window.godotEndingVideoCallback();
		});
		"""
		JavaScriptBridge.eval(js_code)
	else:
		_on_video_finished()

func _on_js_video_finished(args) -> void:
	_on_video_finished()

func _play_godot_video() -> void:
	video_player = VideoStreamPlayer.new()
	var stream = load("res://assets/video/video1-ortx30.ogv")
	if stream != null:
		video_player.stream = stream
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	add_child(video_player)
	video_player.finished.connect(_on_video_finished)
	if video_player.stream != null:
		video_player.play()
	
	var t = get_tree().create_timer(2.0)
	t.timeout.connect(func():
		if not video_player.is_playing() and not dialogue_panel.visible and not button_container.visible:
			_on_video_finished()
	)

func _on_video_finished() -> void:
	if is_instance_valid(video_player):
		video_player.hide()
	
	# 혹시 캔버스 아래로 남아있는 HTML 비디오를 강제 삭제 시도 (보험)
	if OS.has_feature("web"):
		var js_cleanup = "var v = document.getElementById('godot_ending_video'); if(v){ v.pause(); v.remove(); }"
		JavaScriptBridge.eval(js_cleanup)
		
	char_rect.show()
	dialogue_panel.show()
	
	# 배경색을 어두운 블랙에서 밝은 색으로 전환
	var bg = get_child(0) as ColorRect
	var tween = create_tween()
	tween.tween_property(bg, "color", Color("FDF6E3"), 1.0)

func _show_ending_menu() -> void:
	dialogue_panel.hide()
	var tween = create_tween()
	tween.tween_property(char_rect, "position", Vector2(340, -50), 0.5).set_trans(Tween.TRANS_QUAD)
	button_container.show()

func _button(value: String, size: int) -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size = Vector2(680, 65)
	node.add_theme_font_size_override("font_size", size)
	return node

func _input(event: InputEvent) -> void:
	if not OS.has_feature("web") and is_instance_valid(video_player):
		var skip_pressed = false
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			skip_pressed = true
		elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			skip_pressed = true
		elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			skip_pressed = true
			
		if skip_pressed:
			if video_player.visible and video_player.is_playing():
				video_player.stop()
				_on_video_finished()

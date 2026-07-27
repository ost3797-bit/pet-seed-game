extends Node2D

var speed := 280.0

# 물 주기 퀘스트 진행 단계 (5단계 리뉴얼)
enum WaterPhase {
	INIT_TALK_SEED,     # 0: 시작 (씨앗 머리 위 ❓)
	GO_TO_GRANDMA,      # 1: 할머니 찾아가기 (할머니 머리 위 ❓)
	FIND_CAN,           # 2: 물뿌리개 찾기
	RETURN_TO_GRANDMA,  # 3: 할머니에게 보고 (할머니 머리 위 ❗)
	READY_TO_WATER      # 4: 씨앗에게 최종 보고 (씨앗 머리 위 ❗)
}

# 온도 맞추기 퀘스트 진행 단계 (3단계 리뉴얼)
enum TempPhase {
	INIT_TALK_SEED,     # 0: 씨앗에게 대화 -> 목수에게 가라
	GO_TO_CARPENTER,    # 1: 목수에게 가기 -> 퍼즐 미니게임
	READY_TO_SHADE      # 2: 그늘막 획득 후 씨앗에게 대화 -> 햇빛 막기 미니게임
}

# 공기 맞추기 퀘스트 진행 단계
enum AirPhase {
	INIT_TALK_SEED,     # 0: 씨앗에게 대화 -> 마법사에게 가라
	GO_TO_WIZARD,       # 1: 마법사에게 가기 -> 분류 미니게임
	READY_TO_CLEAN      # 2: 마법봉 획득 후 씨앗에게 대화 -> 공기 정화 미니게임
}

var player: CharacterBody2D
var player_body: Polygon2D
var player_sprite: Sprite2D = null
var anim_timer := 0.0
var current_dir := 0  # 0: 아래, 1: 왼쪽, 2: 오른쪽, 3: 위
var anim_frame := 0
var near_seed := false
var near_can := false
var near_grandma := false
var near_carpenter := false
var near_wizard := false
var water_phase := WaterPhase.INIT_TALK_SEED
var temp_phase := TempPhase.INIT_TALK_SEED
var air_phase := AirPhase.INIT_TALK_SEED
var watering_can_items: Array[Area2D] = []
var found_can_count := 0
var near_can_index := -1
var grandma_npc: Area2D = null
var carpenter_npc: Area2D = null
var wizard_npc: Area2D = null

var quest_label: Label
var hint_label: Label
var bubble_label: Label
var can_bubble_label: Label
var grandma_bubble_label: Label
var carpenter_bubble_label: Label
var wizard_bubble_label: Label
var grandma_quest_icon: Label
var seed_quest_icon: Label
var carpenter_quest_icon: Label
var wizard_quest_icon: Label

# 대화창 노드
var dialogue_panel: ColorRect
var dialogue_npc_name: Label
var dialogue_text: Label
var dialogue_accept_btn: Button
var dialogue_cancel_btn: Button

# 대화 수락/취소 콜백
var _pending_accept := Callable()
var _pending_cancel := Callable()


func _ready() -> void:
	_build_field()
	_build_player()
	_build_seed()
	if not GameState.water_cleared:
		_build_grandma()
		_build_watering_can()
	else:
		# 물뿌리개 퀘스트 완료 후 복귀 시 맵에 남은 물뿌리개 아이템들과 할머니 NPC를 완벽히 제거
		for i in range(1, 4):
			var can_item := get_node_or_null("WateringCan" + str(i))
			if is_instance_valid(can_item):
				can_item.queue_free()
		var grandma := get_node_or_null("GrandmaNPC")
		if is_instance_valid(grandma):
			grandma.queue_free()

	_build_carpenter()
	_build_wizard()
	_build_ui()
	temp_phase = GameState.temp_phase_id as TempPhase
	air_phase = GameState.air_phase_id as AirPhase
	_update_quest_icons()
	_update_quest_text()
	if GameState.is_all_clear():
		get_tree().change_scene_to_file("res://scenes/Ending.tscn")

	# 그늘막 만들기 퀘스트 완료 후 복귀 시 목수님 앞 위치로 이동 및 대화 자연스럽게 연결
	if GameState.current_quest == &"temp" and temp_phase == TempPhase.READY_TO_SHADE:
		if player != null and carpenter_npc != null:
			player.position = carpenter_npc.position + Vector2(0, 50) # 목수 바로 앞 위치
			current_dir = 3 # 위쪽(목수 방향) 바라보기
			if player_sprite != null:
				player_sprite.frame = 12
		_on_interact_carpenter()

	# 공기정화 마법봉 만들기 미니게임 완료 후 복귀 시 또는 스킵 시 마법사님 옆 위치로 이동 및 대화 자연스럽게 연결
	if GameState.current_quest == &"air" and (air_phase == AirPhase.READY_TO_CLEAN or air_phase == AirPhase.GO_TO_WIZARD):
		if player != null and wizard_npc != null:
			player.position = wizard_npc.position + Vector2(70, 0) # 마법사 NPC 오른쪽 옆 위치
			current_dir = 1 # 왼쪽(마법사 방향) 바라보기
			if player_sprite != null:
				player_sprite.frame = 4
		if air_phase == AirPhase.READY_TO_CLEAN:
			_on_interact_wizard()


	# 햇빛 막기 게임 완료 후 복귀 시 씨앗 감사 대화 표시
	if GameState.just_cleared_temp:
		GameState.just_cleared_temp = false
		if player != null:
			player.position = Vector2(640, 410) # 씨앗 바로 앞 위치
			current_dir = 3 # 위쪽(씨앗 방향) 바라보기
			if player_sprite != null:
				player_sprite.frame = 12
		_show_temp_clear_thankyou()



func _physics_process(delta: float) -> void:
	var movement := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	player.velocity = movement * speed
	player.move_and_slide()

	# 퀘스트 아이콘(❓ / ❗) 위아래로 둥둥 떠다니는 애니메이션 (시선 유도 효과)
	var float_offset := sin(Time.get_ticks_msec() * 0.005) * 6.0
	if seed_quest_icon != null and seed_quest_icon.text != "":
		seed_quest_icon.position.y = -75.0 + float_offset
	if grandma_quest_icon != null and grandma_quest_icon.text != "":
		grandma_quest_icon.position.y = -70.0 + float_offset
	if carpenter_quest_icon != null and carpenter_quest_icon.text != "":
		carpenter_quest_icon.position.y = -70.0 + float_offset
	if wizard_quest_icon != null and wizard_quest_icon.text != "":
		wizard_quest_icon.position.y = -70.0 + float_offset

	# 4방향 스프라이트 시트 애니메이션 처리
	if player_sprite != null:
		if movement.length() > 0.05:
			if abs(movement.x) > abs(movement.y):
				current_dir = 2 if movement.x > 0 else 1  # 오른쪽 or 왼쪽
			else:
				current_dir = 0 if movement.y > 0 else 3  # 아래 or 위
			
			anim_timer += delta * 8.0  # 초당 8프레임 속도
			if anim_timer >= 1.0:
				anim_timer -= 1.0
				anim_frame = (anim_frame + 1) % 4
		else:
			anim_frame = 0
			anim_timer = 0.0
		
		player_sprite.frame = current_dir * 4 + anim_frame

	# 대화창이 열려 있으면 상호작용 차단
	if dialogue_panel != null and dialogue_panel.visible:
		return

	if Input.is_action_just_pressed(&"interact"):
		if near_seed:
			_on_interact_seed()
		elif near_grandma:
			_on_interact_grandma()
		elif near_carpenter:
			_on_interact_carpenter()
		elif near_wizard:
			_on_interact_wizard()
		elif near_can and water_phase == WaterPhase.FIND_CAN:
			_on_pickup_can()


# ─────────────────────────────────────────────
# 개발자 테스트(Cheat) 빠른 스킵 단축키
# ─────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				# 물뿌리개 3개 즉시 획득 치트
				found_can_count = 3
				water_phase = WaterPhase.RETURN_TO_GRANDMA
				for item in watering_can_items:
					if is_instance_valid(item):
						item.hide()
				_update_quest_icons()
				if hint_label != null:
					hint_label.text = "[치트] 물뿌리개 3개 수집 완료! 오른쪽 할머니에게 말을 걸어요."
			KEY_2:
				get_tree().change_scene_to_file("res://scenes/WaterGame.tscn")
			KEY_3:
				get_tree().change_scene_to_file("res://scenes/CanopyPuzzle.tscn")
			KEY_4:
				get_tree().change_scene_to_file("res://scenes/AirGame.tscn")
			KEY_5:
				get_tree().change_scene_to_file("res://scenes/Ending.tscn")
			KEY_6:
				get_tree().change_scene_to_file("res://scenes/CanopyBlockGame.tscn")
			KEY_0:
				# 캐릭터 스피드 3배 토글
				speed = 800.0 if speed == 280.0 else 280.0
				if hint_label != null:
					hint_label.text = "[치트] 초고속 이동 모드: " + ("ON ⚡ (800)" if speed > 300.0 else "OFF (280)")


# ─────────────────────────────────────────────
# 맵 빌드
# ─────────────────────────────────────────────

func _build_field() -> void:
	# 씬 트리에 추가된 배경 노드의 스케일 조정 (중복 생성 방지)
	var bg := get_node_or_null("Background") as Sprite2D
	if bg != null and bg.texture != null:
		var tex_size: Vector2 = bg.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			bg.scale = Vector2(1280.0 / tex_size.x, 720.0 / tex_size.y)
	else:
		# 백업: 배경 노드가 없을 경우 초록 배경 생성
		var ground := Polygon2D.new()
		ground.polygon = PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
		ground.color = Color("9CD778")
		add_child(ground)
	# 씬 트리에 벽(Wall_Top)이 없으면 백업으로 코드에서 4방향 벽 생성
	if get_node_or_null("Wall_Top") == null:
		for wall in [
			[Vector2(640, 150), Vector2(980, 25)], [Vector2(640, 600), Vector2(980, 25)],
			[Vector2(150, 375), Vector2(25, 470)], [Vector2(1130, 375), Vector2(25, 470)]
		]:
			_add_wall(wall[0], wall[1])
	
	# 씬 트리에 추가된 HouseObstacle 노드의 위치/크기를 게임 화면에 빨간 가이드 박스로 표시
	# ※ 에디터 2D 화면에서 마우스 조절을 모두 마치고 가이드 박스를 숨기고 싶을 땐 아래 함수 호출 맨 앞에 #을 붙여 주세요.
	_show_house_obstacle_preview()


func _show_house_obstacle_preview() -> void:
	var house := get_node_or_null("HouseObstacle")
	if house != null:
		var collision: CollisionShape2D = house.get_node_or_null("CollisionShape2D")
		if collision != null and collision.shape is RectangleShape2D:
			var shape_size: Vector2 = collision.shape.size
			var preview := ColorRect.new()
			preview.color = Color(1.0, 0.2, 0.2, 0.5)  # 반투명 빨간색
			preview.position = house.position + collision.position - (shape_size / 2.0)
			preview.size = shape_size
			preview.z_index = -5
			add_child(preview)


func _add_wall(wall_position: Vector2, wall_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = wall_position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = wall_size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


# ─────────────────────────────────────────────
# 플레이어 빌드
# ─────────────────────────────────────────────

func _build_player() -> void:
	# 씬에 추가된 Player 노드가 있으면 가져와서 사용 (에디터 2D 화면에서 설정한 충돌 영역 유지)
	player = get_node_or_null("Player") as CharacterBody2D
	if player == null:
		# 백업: 씬에 Player가 없으면 동적 생성
		player = CharacterBody2D.new()
		player.name = "Player"
		player.position = Vector2(640, 400)
		player.collision_layer = 1
		player.collision_mask = 1
		add_child(player)
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(48, 50)
		collision.shape = shape
		player.add_child(collision)

	# 캐릭터 이미지 경로 (0: 남자 캐릭터 -> character_3_aligned.png, 1: 여자 캐릭터 -> character_2_aligned.png)
	var char_path := "res://assets/characters/character_2_aligned.png" if GameState.character_style_id == 1 else "res://assets/characters/character_3_aligned.png"
	var char_texture := load(char_path) if ResourceLoader.exists(char_path) else null

	if char_texture != null:
		# 씬의 기존 Sprite2D를 사용하거나 없으면 생성
		player_sprite = player.get_node_or_null("Sprite2D") as Sprite2D
		if player_sprite == null:
			player_sprite = Sprite2D.new()
			player_sprite.name = "Sprite2D"
			player.add_child(player_sprite)
		player_sprite.texture = char_texture
		player_sprite.hframes = 4
		player_sprite.vframes = 4
		# 한 프레임(전체 세로/4)의 높이를 기준으로 균일 스케일 적용 (높이 약 70픽셀, 비율 유지)
		var tex_size: Vector2 = char_texture.get_size()
		if tex_size.y > 0:
			var frame_h := tex_size.y / 4.0
			var s := 70.0 / frame_h
			player_sprite.scale = Vector2(s, s)
		player_body = null  # 이미지 사용 시 Polygon2D 불필요
	else:
		# 이미지가 없으면 기존 Polygon2D 도형으로 표시
		player_body = player.get_node_or_null("Polygon2D") as Polygon2D
		if player_body == null:
			player_body = Polygon2D.new()
			player_body.name = "Polygon2D"
			player.add_child(player_body)
		player_body.polygon = PackedVector2Array([Vector2(-23, -28), Vector2(23, -28), Vector2(28, 20), Vector2(-28, 20)])
		player_body.color = Color("5D8DFF") if GameState.character_style_id == 0 else Color("FF8CB8")

	var name_tag := player.get_node_or_null("NameTag") as Label
	if name_tag == null:
		name_tag = Label.new()
		name_tag.name = "NameTag"
		name_tag.position = Vector2(-50, -60)
		name_tag.size = Vector2(100, 30)
		name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_tag.add_theme_font_size_override("font_size", 18)
		player.add_child(name_tag)
	name_tag.text = GameState.player_name


# ─────────────────────────────────────────────
# 씨앗 NPC 빌드
# ─────────────────────────────────────────────

func _build_seed() -> void:
	var seed_npc := get_node_or_null("SeedNPC") as Area2D
	if seed_npc == null:
		seed_npc = Area2D.new()
		seed_npc.name = "SeedNPC"
		seed_npc.position = Vector2(640, 310)
		seed_npc.collision_layer = 0
		seed_npc.collision_mask = 1
		add_child(seed_npc)
		var body := Polygon2D.new()
		body.name = "Polygon2D"
		body.polygon = PackedVector2Array([Vector2(0, -40), Vector2(32, -10), Vector2(22, 32), Vector2(0, 45), Vector2(-22, 32), Vector2(-32, -10)])
		seed_npc.add_child(body)
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 115.0
		collision.shape = shape
		seed_npc.add_child(collision)

	var poly := seed_npc.get_node_or_null("Polygon2D") as Polygon2D
	if poly != null:
		match GameState.seed_type:
			"seed_1": poly.color = Color("76D7C4")
			"seed_2": poly.color = Color("FFE36B")
			"seed_3": poly.color = Color("85C1E9")
			_: poly.color = Color("FFE36B")

	seed_quest_icon = seed_npc.get_node_or_null("SeedQuestIcon") as Label
	if seed_quest_icon == null:
		seed_quest_icon = Label.new()
		seed_quest_icon.name = "SeedQuestIcon"
		seed_quest_icon.position = Vector2(-20, -75)
		seed_quest_icon.size = Vector2(40, 40)
		seed_quest_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		seed_quest_icon.add_theme_font_size_override("font_size", 26)
		seed_npc.add_child(seed_quest_icon)

	seed_npc.body_entered.connect(func(body_node: Node2D):
		if body_node == player:
			near_seed = true
			if bubble_label != null:
				bubble_label.show()
	)
	seed_npc.body_exited.connect(func(body_node: Node2D):
		if body_node == player:
			near_seed = false
			if bubble_label != null:
				bubble_label.hide()
	)


# ─────────────────────────────────────────────
# 할머니 NPC 빌드
# ─────────────────────────────────────────────

func _build_grandma() -> void:
	grandma_npc = get_node_or_null("GrandmaNPC") as Area2D
	if grandma_npc == null:
		grandma_npc = Area2D.new()
		grandma_npc.name = "GrandmaNPC"
		# 오른쪽 초록색 지붕 집 앞 위치
		grandma_npc.position = Vector2(1021, 424)
		grandma_npc.collision_layer = 0
		grandma_npc.collision_mask = 1
		add_child(grandma_npc)
		
		var spr := Sprite2D.new()
		spr.name = "Sprite2D"
		grandma_npc.add_child(spr)
		
		var body := Polygon2D.new()
		body.name = "Polygon2D"
		body.polygon = PackedVector2Array([Vector2(0, -35), Vector2(25, -10), Vector2(20, 35), Vector2(-20, 35), Vector2(-25, -10)])
		body.color = Color("D279EE") # 자애로운 라벤더색
		grandma_npc.add_child(body)
		
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 100.0
		collision.shape = shape
		grandma_npc.add_child(collision)

	# 이름표
	var name_tag := grandma_npc.get_node_or_null("NameTag") as Label
	if name_tag == null:
		name_tag = Label.new()
		name_tag.name = "NameTag"
		name_tag.position = Vector2(-50, 40)
		name_tag.size = Vector2(100, 28)
		name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_tag.add_theme_font_size_override("font_size", 18)
		name_tag.add_theme_color_override("font_color", Color("FFE36B"))
		grandma_npc.add_child(name_tag)
	name_tag.text = "마을 할머니"

	# 머리 위 퀘스트 아이콘
	grandma_quest_icon = grandma_npc.get_node_or_null("GrandmaQuestIcon") as Label
	if grandma_quest_icon == null:
		grandma_quest_icon = Label.new()
		grandma_quest_icon.name = "GrandmaQuestIcon"
		grandma_quest_icon.position = Vector2(-20, -70)
		grandma_quest_icon.size = Vector2(40, 40)
		grandma_quest_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grandma_quest_icon.add_theme_font_size_override("font_size", 26)
		grandma_npc.add_child(grandma_quest_icon)

	grandma_npc.body_entered.connect(func(body_node: Node2D):
		if body_node == player:
			near_grandma = true
			if grandma_bubble_label != null:
				grandma_bubble_label.show()
	)
	grandma_npc.body_exited.connect(func(body_node: Node2D):
		if body_node == player:
			near_grandma = false
			if grandma_bubble_label != null:
				grandma_bubble_label.hide()
	)



# ─────────────────────────────────────────────
# 물뿌리개 아이템 빌드
# ─────────────────────────────────────────────

func _build_watering_can() -> void:
	watering_can_items.clear()
	for i in range(1, 4):
		var node_name := "WateringCan" + str(i)
		var item := get_node_or_null(node_name) as Area2D
		if item != null:
			watering_can_items.append(item)
			var idx := watering_can_items.size() - 1
			item.body_entered.connect(func(body_node: Node2D):
				if body_node == player:
					near_can = true
					near_can_index = idx
					if can_bubble_label != null and water_phase == WaterPhase.FIND_CAN:
						can_bubble_label.show()
			)
			item.body_exited.connect(func(body_node: Node2D):
				if body_node == player:
					if near_can_index == idx:
						near_can = false
						near_can_index = -1
					if can_bubble_label != null:
						can_bubble_label.hide()
			)
			# 기존 파란색 플레이스홀더 박스 및 영어 텍스트 숨김
			var color_rect := item.get_node_or_null("ColorRect")
			if color_rect != null:
				color_rect.hide()
			var icon_lbl := item.get_node_or_null("IconLabel")
			if icon_lbl != null:
				icon_lbl.hide()

			# 사용자가 디자인한 커스텀 물뿌리개 이미지 적용
			var can_spr := item.get_node_or_null("CustomCanSprite") as Sprite2D
			if can_spr == null:
				can_spr = Sprite2D.new()
				can_spr.name = "CustomCanSprite"
				var tex := load("res://assets/water_can.png") as Texture2D
				if tex != null:
					can_spr.texture = tex
					var tex_size := tex.get_size()
					if tex_size.x > 0 and tex_size.y > 0:
						var scale_factor: float = 60.0 / float(max(tex_size.x, tex_size.y))
						can_spr.scale = Vector2(scale_factor, scale_factor)

				# 충돌 영역(CollisionShape2D)의 중심점에 맞춰 스프라이트 배치
				var col_shape := item.get_node_or_null("CollisionShape2D") as Node2D
				if col_shape != null:
					can_spr.position = col_shape.position
				else:
					can_spr.position = Vector2(-70, -5)
				item.add_child(can_spr)

			# 게임 실행 시 퀘스트 수락 전에는 숨김 (에디터에서는 보임 상태)
			item.hide()



# ─────────────────────────────────────────────
# 온도 목수 NPC 빌드
# ─────────────────────────────────────────────

func _build_carpenter() -> void:
	carpenter_npc = get_node_or_null("CarpenterNPC") as Area2D
	if carpenter_npc == null:
		carpenter_npc = Area2D.new()
		carpenter_npc.name = "CarpenterNPC"
		carpenter_npc.position = Vector2(210, 419)
		carpenter_npc.collision_layer = 0

		carpenter_npc.collision_mask = 1
		add_child(carpenter_npc)
		
		var spr := Sprite2D.new()
		spr.name = "Sprite2D"
		carpenter_npc.add_child(spr)
		
		var body := Polygon2D.new()
		body.name = "Polygon2D"
		body.polygon = PackedVector2Array([Vector2(0, -35), Vector2(25, -10), Vector2(20, 35), Vector2(-20, 35), Vector2(-25, -10)])
		body.color = Color("DA863E")
		carpenter_npc.add_child(body)
		
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 100.0
		collision.shape = shape
		carpenter_npc.add_child(collision)

	# 이름표
	var name_tag := carpenter_npc.get_node_or_null("NameTag") as Label
	if name_tag == null:
		name_tag = Label.new()
		name_tag.name = "NameTag"
		name_tag.position = Vector2(-50, 40)
		name_tag.size = Vector2(100, 28)
		name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_tag.add_theme_font_size_override("font_size", 18)
		name_tag.add_theme_color_override("font_color", Color("FFE36B"))
		carpenter_npc.add_child(name_tag)
	name_tag.text = "온도 목수"

	# 머리 위 퀘스트 아이콘
	carpenter_quest_icon = carpenter_npc.get_node_or_null("CarpenterQuestIcon") as Label
	if carpenter_quest_icon == null:
		carpenter_quest_icon = Label.new()
		carpenter_quest_icon.name = "CarpenterQuestIcon"
		carpenter_quest_icon.position = Vector2(-20, -70)
		carpenter_quest_icon.size = Vector2(40, 40)
		carpenter_quest_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		carpenter_quest_icon.add_theme_font_size_override("font_size", 26)
		carpenter_npc.add_child(carpenter_quest_icon)

	carpenter_npc.body_entered.connect(func(body_node: Node2D):
		if body_node == player:
			near_carpenter = true
			if carpenter_bubble_label != null:
				carpenter_bubble_label.show()
	)
	carpenter_npc.body_exited.connect(func(body_node: Node2D):
		if body_node == player:
			near_carpenter = false
			if carpenter_bubble_label != null:
				carpenter_bubble_label.hide()
	)


# ─────────────────────────────────────────────
# 공기정화 마법사 NPC 빌드
# ─────────────────────────────────────────────

func _build_wizard() -> void:
	wizard_npc = get_node_or_null("WizardNPC") as Area2D
	if wizard_npc == null:
		wizard_npc = Area2D.new()
		wizard_npc.name = "WizardNPC"
		wizard_npc.position = Vector2(490, 180)
		wizard_npc.collision_layer = 0
		wizard_npc.collision_mask = 1
		add_child(wizard_npc)
		
		var spr := Sprite2D.new()
		spr.name = "Sprite2D"
		wizard_npc.add_child(spr)
		
		var body := Polygon2D.new()
		body.name = "Polygon2D"
		body.polygon = PackedVector2Array([Vector2(0, -40), Vector2(30, -10), Vector2(22, 35), Vector2(-22, 35), Vector2(-30, -10)])
		body.color = Color("5A69E1")
		wizard_npc.add_child(body)
		
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 100.0
		collision.shape = shape
		wizard_npc.add_child(collision)

	# 이름표
	var name_tag := wizard_npc.get_node_or_null("NameTag") as Label
	if name_tag == null:
		name_tag = Label.new()
		name_tag.name = "NameTag"
		name_tag.position = Vector2(-70, 40)
		name_tag.size = Vector2(140, 28)
		name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_tag.add_theme_font_size_override("font_size", 18)
		name_tag.add_theme_color_override("font_color", Color("FFE36B"))
		wizard_npc.add_child(name_tag)
	name_tag.text = "공기정화 마법사"

	# 머리 위 퀘스트 아이콘
	wizard_quest_icon = wizard_npc.get_node_or_null("WizardQuestIcon") as Label
	if wizard_quest_icon == null:
		wizard_quest_icon = Label.new()
		wizard_quest_icon.name = "WizardQuestIcon"
		wizard_quest_icon.position = Vector2(-20, -70)
		wizard_quest_icon.size = Vector2(40, 40)
		wizard_quest_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wizard_quest_icon.add_theme_font_size_override("font_size", 26)
		wizard_npc.add_child(wizard_quest_icon)

	wizard_npc.body_entered.connect(func(body_node: Node2D):
		if body_node == player:
			near_wizard = true
			if wizard_bubble_label != null:
				wizard_bubble_label.show()
	)
	wizard_npc.body_exited.connect(func(body_node: Node2D):
		if body_node == player:
			near_wizard = false
			if wizard_bubble_label != null:
				wizard_bubble_label.hide()
	)



# ─────────────────────────────────────────────
# UI 빌드
# ─────────────────────────────────────────────

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# 화면 우측 상단 퀘스트 정보 HUD 박스 (시야 가림 방지)
	var top := ColorRect.new()
	top.color = Color(0.06, 0.12, 0.18, 1.0) # 100% 불투명
	top.position = Vector2(790, 12)
	top.size = Vector2(478, 86)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(top)

	var border := ColorRect.new()
	border.color = Color("4A90E2")
	border.position = Vector2(0, 0)
	border.size = Vector2(4, 86)
	top.add_child(border)

	var name_label := _label("🌱 플레이어: " + GameState.player_name, Vector2(805, 18), Vector2(450, 22), 17)
	name_label.add_theme_color_override("font_color", Color("76D7C4"))
	layer.add_child(name_label)
	quest_label = _label("", Vector2(805, 40), Vector2(450, 22), 18)
	quest_label.add_theme_color_override("font_color", Color("FFE36B"))
	layer.add_child(quest_label)
	hint_label = _label("", Vector2(805, 64), Vector2(450, 22), 15)
	hint_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	layer.add_child(hint_label)

	# 빠른 3차 시나리오 테스트용 스킵 버튼 (좌측 상단 배치)
	var skip_btn := Button.new()
	skip_btn.text = "⏩ 3차 공기 퀘스트 바로 스킵!"
	skip_btn.position = Vector2(15, 12)
	skip_btn.size = Vector2(250, 40)
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.add_theme_color_override("font_color", Color("FEE761"))
	skip_btn.pressed.connect(func():
		GameState.jump_to_air_quest()
		get_tree().change_scene_to_file("res://scenes/MainField.tscn")
	)
	layer.add_child(skip_btn)

	bubble_label = _label("씨앗 가까이에 왔어요!\n[Space] 또는 말하기 버튼을 눌러요.", Vector2(390, 195), Vector2(500, 72), 22)
	bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_label.hide()
	layer.add_child(bubble_label)

	can_bubble_label = _label("[Space] 물뿌리개 줍기!", Vector2(80, 290), Vector2(280, 44), 22)
	can_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	can_bubble_label.add_theme_color_override("font_color", Color("FFE36B"))
	can_bubble_label.hide()
	layer.add_child(can_bubble_label)

	grandma_bubble_label = _label("[Space] 할머니에게 말 걸기!", Vector2(740, 360), Vector2(300, 44), 22)
	grandma_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grandma_bubble_label.add_theme_color_override("font_color", Color("FFE36B"))
	grandma_bubble_label.hide()
	layer.add_child(grandma_bubble_label)

	carpenter_bubble_label = _label("[Space] 목수에게 말 걸기!", Vector2(230, 360), Vector2(300, 44), 22)
	carpenter_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carpenter_bubble_label.add_theme_color_override("font_color", Color("FFE36B"))
	carpenter_bubble_label.hide()
	layer.add_child(carpenter_bubble_label)

	wizard_bubble_label = _label("[Space] 마법사에게 말 걸기!", Vector2(490, 100), Vector2(300, 44), 22)
	wizard_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wizard_bubble_label.add_theme_color_override("font_color", Color("FFE36B"))
	wizard_bubble_label.hide()
	layer.add_child(wizard_bubble_label)

	# 모바일/터치용 화면 조이스틱 및 말하기 버튼 (나중에 필요 시 if true: 로 바꾸면 다시 생성됩니다)
	if false:
		_add_touch_button(layer, Vector2(45, 585), &"move_left", "L")
		_add_touch_button(layer, Vector2(170, 585), &"move_right", "R")
		_add_touch_button(layer, Vector2(108, 522), &"move_up", "U")
		_add_touch_button(layer, Vector2(108, 648), &"move_down", "D")
		_add_touch_button(layer, Vector2(1050, 585), &"interact", "말하기", Vector2(180, 95))

	_build_dialogue_panel(layer)

	_update_quest_text()


func _build_dialogue_panel(layer: CanvasLayer) -> void:
	dialogue_panel = ColorRect.new()
	dialogue_panel.color = Color(0.05, 0.09, 0.15, 0.96)
	dialogue_panel.position = Vector2(100, 415)
	dialogue_panel.size = Vector2(1080, 275)
	dialogue_panel.z_index = 20
	dialogue_panel.hide()
	layer.add_child(dialogue_panel)

	var border := ColorRect.new()
	border.color = Color("4A90E2")
	border.position = Vector2(0, 0)
	border.size = Vector2(1080, 5)
	dialogue_panel.add_child(border)

	dialogue_npc_name = Label.new()
	dialogue_npc_name.position = Vector2(22, 14)
	dialogue_npc_name.size = Vector2(500, 38)
	dialogue_npc_name.add_theme_font_size_override("font_size", 27)
	dialogue_npc_name.add_theme_color_override("font_color", Color("FFE36B"))
	dialogue_panel.add_child(dialogue_npc_name)

	dialogue_text = Label.new()
	dialogue_text.position = Vector2(22, 58)
	dialogue_text.size = Vector2(1036, 150)
	dialogue_text.add_theme_font_size_override("font_size", 21)
	dialogue_text.add_theme_color_override("font_color", Color.WHITE)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_panel.add_child(dialogue_text)

	dialogue_accept_btn = Button.new()
	dialogue_accept_btn.position = Vector2(560, 216)
	dialogue_accept_btn.size = Vector2(190, 46)
	dialogue_accept_btn.add_theme_font_size_override("font_size", 20)
	dialogue_accept_btn.pressed.connect(_on_dialogue_accept)
	dialogue_panel.add_child(dialogue_accept_btn)

	dialogue_cancel_btn = Button.new()
	dialogue_cancel_btn.position = Vector2(780, 216)
	dialogue_cancel_btn.size = Vector2(190, 46)
	dialogue_cancel_btn.add_theme_font_size_override("font_size", 20)
	dialogue_cancel_btn.pressed.connect(_on_dialogue_cancel)
	dialogue_panel.add_child(dialogue_cancel_btn)


# ─────────────────────────────────────────────
# 대화창 제어
# ─────────────────────────────────────────────

func _show_dialogue(speaker: String, text: String,
		accept_text: String, accept_cb: Callable,
		cancel_text: String, cancel_cb: Callable) -> void:
	_pending_accept = accept_cb
	_pending_cancel = cancel_cb
	dialogue_npc_name.text = speaker
	dialogue_text.text = text
	dialogue_accept_btn.text = accept_text
	dialogue_accept_btn.visible = not accept_text.is_empty()
	dialogue_cancel_btn.text = cancel_text
	dialogue_cancel_btn.visible = not cancel_text.is_empty()
	if cancel_text.is_empty():
		dialogue_accept_btn.position = Vector2(780, 216) # 버튼 1개일 때 오른쪽 테두리 안쪽 안전한 여백에 배치
	else:
		dialogue_accept_btn.position = Vector2(560, 216) # 버튼 2개일 때 나란히 배치
	bubble_label.hide()
	can_bubble_label.hide()
	if grandma_bubble_label != null:
		grandma_bubble_label.hide()
	if carpenter_bubble_label != null:
		carpenter_bubble_label.hide()
	if wizard_bubble_label != null:
		wizard_bubble_label.hide()
	dialogue_panel.show()


func _hide_dialogue() -> void:
	dialogue_panel.hide()
	if near_seed:
		bubble_label.show()
	if near_grandma and grandma_bubble_label != null:
		grandma_bubble_label.show()
	if near_carpenter and carpenter_bubble_label != null:
		carpenter_bubble_label.show()
	if near_wizard and wizard_bubble_label != null:
		wizard_bubble_label.show()
	if near_can and water_phase == WaterPhase.FIND_CAN:
		can_bubble_label.show()


func _on_dialogue_accept() -> void:
	_hide_dialogue()
	if _pending_accept.is_valid():
		_pending_accept.call()


func _on_dialogue_cancel() -> void:
	_hide_dialogue()
	if _pending_cancel.is_valid():
		_pending_cancel.call()


# ─────────────────────────────────────────────
# 씨앗 상호작용 라우터
# ─────────────────────────────────────────────

func _on_interact_seed() -> void:
	match GameState.current_quest:
		&"water":
			match water_phase:
				WaterPhase.INIT_TALK_SEED:
					_show_dialogue(
						"씨앗",
						"안녕! 나를 돌보러 와주었구나! 만나서 반가워, 앞으로 잘 부탁해~\n우리가 함께하면 예쁜 싹을 활짝 틔울 수 있을 거야!",
						"안녕! 나도 잘 부탁해!",
						_show_seed_favor_dialogue,
						"",
						Callable()
					)
				WaterPhase.GO_TO_GRANDMA:
					_show_dialogue(
						"씨앗",
						"오른쪽 초록색 지붕 집 앞의 할머니에게 가보세요!\n물이 어디 있는지 알고 계실 지도 몰라요.",
						"",
						Callable(),
						"알겠어요!",
						Callable()
					)
				WaterPhase.FIND_CAN:
					_show_dialogue(
						"씨앗",
						"할머니가 잃어버린 물뿌리개를 찾고 계시군요...\n마을 주변이나 왼쪽 풀숲을 잘 살펴봐 주세요!",
						"",
						Callable(),
						"알겠어요, 찾아볼게요!",
						Callable()
					)
				WaterPhase.RETURN_TO_GRANDMA:
					_show_dialogue(
						"씨앗",
						"물뿌리개를 찾으셨군요! 어서 할머니에게 돌아가 말씀드려 보세요!",
						"",
						Callable(),
						"알겠어요!",
						Callable()
					)
				WaterPhase.READY_TO_WATER:
					_show_dialogue(
						"씨앗",
						"오! 시원한 물뿌리개를 구해 오셨군요! 정말 고마워요!\n이제 제게 물을 듬뿍 뿌려 주시겠어요?",
						"규칙 확인하기!",
						_show_water_rules_popup,
						"",
						Callable()
					)
		&"temp":
			match temp_phase:
				TempPhase.INIT_TALK_SEED:
					_show_dialogue(
						"씨앗",
						"으으... 너무 더워서 힘들어하고 있어요...\n저기 빨간 지붕집에 사는 온도 목수님에게 가서 온도를 조절할 수 있는 물건을 구해와 주세요!",
						"목수님께 가기!",
						_accept_find_carpenter,
						"",
						Callable()
					)
				TempPhase.GO_TO_CARPENTER:
					_show_dialogue(
						"씨앗",
						"저기 빨간 지붕집의 목수님께 가서 온도 조절 물건(그늘막)을 구해와 주세요!",
						"",
						Callable(),
						"알겠어요!",
						Callable()
					)
				TempPhase.READY_TO_SHADE:
					_show_dialogue(
						"씨앗",
						"우와, 목수님께 그늘막을 구해오셨군요! 정말 고마워요!\n지금 하늘에서 뜨거운 햇빛이 쏟아져 내려오고 있어요.\n그늘막으로 햇빛을 막아주세요!",
						"햇빛 막기 시작!",
						func(): get_tree().change_scene_to_file("res://scenes/CanopyBlockGame.tscn"),
						"",
						Callable()
					)
		&"air":
			match air_phase:
				AirPhase.INIT_TALK_SEED:
					_show_dialogue(
						"씨앗",
						"콜록콜록... 공기가 너무 탁하고 매연 냄새가 나서 숨쉬기 힘들어요... 😭\n저기 위쪽 언덕에 사는 공기정화 마법사님에게 가서 맑은 공기를 만들 수 있는 방법을 물어봐 주세요!",
						"마법사님께 가기!",
						_accept_find_wizard,
						"",
						Callable()
					)
				AirPhase.GO_TO_WIZARD:
					_show_dialogue(
						"씨앗",
						"위쪽 언덕에 계신 공기정화 마법사님에게 가서 맑은 공기를 만드는 방법을 물어봐 주세요!",
						"",
						Callable(),
						"알겠어요!",
						Callable()
					)
				AirPhase.READY_TO_CLEAN:
					_show_dialogue(
						"씨앗",
						"우와! 마법사님과 함께 반짝이는 마법봉을 만들어 오셨군요! 정말 고마워요!\n지금 하늘에서 탁한 매연 구름들이 몰려오고 있어요.\n마법봉으로 탁한 공기를 모두 정화해 주세요!",
						"공기 정화 시작!",
						func(): get_tree().change_scene_to_file("res://scenes/AirGame.tscn"),
						"",
						Callable()
					)
		&"complete":
			get_tree().change_scene_to_file("res://scenes/Ending.tscn")


func _show_seed_favor_dialogue() -> void:
	_show_dialogue(
		"씨앗",
		"고마워! 그런데 사실... 지금 목이 너무 말라서 싹을 틔울 힘이 없어...\n물이 필요한데 어디서 구해야 할지 모르겠어.\n오른쪽 초록색 지붕 집 앞의 할머니에게 방법을 물어봐 주실 수 있나요?",
		"할머니에게 물어볼게!",
		_accept_find_grandma,
		"",
		Callable()
	)


func _on_interact_grandma() -> void:
	if GameState.current_quest == &"water":
		match water_phase:
			WaterPhase.INIT_TALK_SEED:
				_show_dialogue(
					"마을 할머니",
					"호호, 안녕하신가~ 허허, 텃밭에 있는 씨앗과 먼저 이야기 나누어 보렴.",
					"",
					Callable(),
					"네!",
					Callable()
				)
			WaterPhase.GO_TO_GRANDMA:
				_show_dialogue(
					"마을 할머니",
					"호호, 씨앗에게 물이 필요한 거로구나!\n그런데 어쩌지? 내가 아끼던 물뿌리개를 3조각으로 잃어버렸단다.\n마을 구석구석에 흩어진 물뿌리개 3개를 모두 찾아와 주겠니?",
					"물뿌리개 3개 찾기!",
					_show_can_rules_popup,
					"",
					Callable()
				)
			WaterPhase.FIND_CAN:
				_show_dialogue(
					"마을 할머니",
					"아직 물뿌리개 3개를 다 못 찾았구나... (현재 " + str(found_can_count) + "/3개)\n마을 풀숲이나 건물 주변 구석을 잘 살펴보렴!",
					"",
					Callable(),
					"알겠어요, 찾아볼게요!",
					Callable()
				)
			WaterPhase.RETURN_TO_GRANDMA:
				_show_dialogue(
					"마을 할머니",
					"아고! 잃어버린 물뿌리개 3개를 모두 찾아주었구나, 정말 고맙다!\n약속대로 이 완벽한 물뿌리개를 너에게 선물로 주마.\n이제 목말라하는 씨앗에게 시원한 물을 주렴!",
					"고맙습니다! 씨앗에게 갈게요.",
					_accept_got_can,
					"",
					Callable()
				)
			WaterPhase.READY_TO_WATER:
				_show_dialogue(
					"마을 할머니",
					"호호~ 씨앗에게 물뿌리개로 시원한 물을 듬뿍 뿌려주렴~",
					"",
					Callable(),
					"네, 갈게요!",
					Callable()
				)
	else:
		_show_dialogue(
			"마을 할머니",
			"호호, 착하고 부지런한 학생이로구나.\n씨앗을 예쁘고 건강하게 잘 키워주렴~",
			"",
			Callable(),
			"고맙습니다!",
			Callable()
		)


func _on_interact_carpenter() -> void:
	if GameState.current_quest == &"temp":
		match temp_phase:
			TempPhase.INIT_TALK_SEED:
				_show_dialogue(
					"온도 목수",
					"허허! 텃밭의 씨앗과 먼저 이야기를 나누어 보게나!",
					"",
					Callable(),
					"네!",
					Callable()
				)
			TempPhase.GO_TO_CARPENTER:
				_show_dialogue(
					"온도 목수",
					"허허, 씨앗이 더워해서 그늘막이 필요한 거로구나!\n그늘막을 이용하면 되지만 지금 남은 그늘막이 없단다.\n그늘막 만드는 것을 도와주면 그늘막을 주마!",
					"그늘막 만들기 돕기!",
					func(): get_tree().change_scene_to_file("res://scenes/CanopyPuzzle.tscn"),
					"",
					Callable()
				)
			TempPhase.READY_TO_SHADE:
				_show_dialogue(
					"온도 목수",
					"허허! 고맙네! 자네가 도와준 덕분에 튼튼하고 멋진 그늘막이 완성되었어!\n자, 여기 완성된 그늘막을 주마. 어서 더위에 지친 씨앗에게 가져가서 햇빛을 막아주게나!",
					"🎪 그늘막 받기!",
					Callable(),
					"",
					Callable()
				)
	elif GameState.current_quest == &"water":
		_show_dialogue(
			"온도 목수",
			"허허, 지금은 씨앗에게 물이 먼저 필요한 모양이군.\n오른쪽 집의 할머니를 찾아가 보게나!",
			"",
			Callable(),
			"알겠어요!",
			Callable()
		)
	else:
		_show_dialogue(
			"온도 목수",
			"나중에 텃밭에 온실을 지을 일이 생기면 언제든 이 목수를 찾아오게나, 허허!",
			"",
			Callable(),
			"고맙습니다!",
			Callable()
		)


func _on_interact_wizard() -> void:
	if GameState.current_quest == &"air":
		match air_phase:
			AirPhase.INIT_TALK_SEED:
				_show_dialogue(
					"공기정화 마법사",
					"허허! 먼저 텃밭에서 숨막혀하는 씨앗과 이야기를 나누어 보게나!",
					"",
					Callable(),
					"네!",
					Callable()
				)
			AirPhase.GO_TO_WIZARD:
				_show_dialogue(
					"공기정화 마법사",
					"허허, 오염된 공기 때문에 씨앗이 고통받고 있군요. 이를 해결하려면 강력한 '공기정화 마법봉'이 필요합니다.\n마법봉에 맑은 기운을 담으려면 세상의 공기를 오염시키는 원인과 깨끗하게 하는 요소를 올바르게 구별할 줄 알아야 하지요.\n나와 함께 마법봉 만드는 것을 도와주시겠습니까?",
					"✨ 마법봉 만들기 돕기!",
					func(): get_tree().change_scene_to_file("res://scenes/AirWandCraft.tscn"),
					"",
					Callable()
				)
			AirPhase.READY_TO_CLEAN:
				_show_dialogue(
					"공기정화 마법사",
					"훌륭합니다! 그대의 환경에 대한 지혜 덕분에 맑고 빛나는 '공기정화 마법봉'이 완성되었습니다!\n자, 이 마법봉을 가지고 어서 씨앗에게 가서 탁한 매연을 걷어내 주십시오!",
					"✨ 마법봉 챙겨서 가기!",
					Callable(),
					"",
					Callable()
				)
	elif GameState.current_quest == &"water":
		_show_dialogue(
			"공기정화 마법사",
			"음... 맑은 물의 기운이 씨앗에게 먼저 닿아야 합니다.\n오른쪽 초록 지붕 집에 계신 할머니께 조언을 구해보세요.",
			"",
			Callable(),
			"네, 알겠어요!",
			Callable()
		)
	else:
		_show_dialogue(
			"공기정화 마법사",
			"바람과 공기가 아주 맑고 상쾌하군요.\n그대의 따뜻한 보살핌이 씨앗에게 큰 힘이 되고 있습니다.",
			"",
			Callable(),
			"고맙습니다!",
			Callable()
		)


func _accept_find_grandma() -> void:
	water_phase = WaterPhase.GO_TO_GRANDMA
	_update_quest_icons()
	hint_label.text = "오른쪽 초록색 지붕 집 앞의 할머니에게 가서 말을 걸어보세요!"


func _accept_find_can() -> void:
	water_phase = WaterPhase.FIND_CAN
	found_can_count = 0
	for item in watering_can_items:
		if is_instance_valid(item):
			item.show()
	_update_quest_icons()
	hint_label.text = "마을 구석구석에 흩어진 물뿌리개 3개를 찾아 [Space]로 주우세요! (0/3)"


func _show_can_rules_popup() -> void:
	_show_dialogue(
		"📋 물뿌리개 찾기 - 규칙 안내",
		"🔍 미션: 마을 곳곳에 숨겨진 물뿌리개 3개를 모두 찾아주세요!\n🚶 방법: 마을에 숨어있는 물뿌리개를 찾고 근처에서 [Space] 또는 [말하기] 버튼을 누르면 줍습니다.\n✅ 목표: 3개를 모두 줍고 할머니에게 가서 말을 걸어봅시다.",
		"🎮 게임 시작!",
		_accept_find_can,
		"",
		Callable()
	)


func _show_water_rules_popup() -> void:
	_show_dialogue(
		"📋 물 주기 게임 - 규칙 안내",
		"💧 미션: 씨앗이 목마르지 않도록 알맞은 양의 물을 공급해 주세요!\n👆 방법: [물 주기 (꾹 눌러요)] 버튼을 마우스 좌클릭(또는 스페이스바)으로 꾹 누르면 게이지가 올라갑니다.\n✅ 목표: 초록색 목표 구간 안에 게이지를 맞추고 유지하면 성공!",
		"🎮 게임 시작!",
		func(): get_tree().change_scene_to_file("res://scenes/WaterGame.tscn"),
		"",
		Callable()
	)


func _show_temp_clear_thankyou() -> void:
	_show_dialogue(
		"씨앗",
		"우와, 정말 고마워요! 덕분에 적절한 온도에서 시원하고 편하게 있을 수 있게 되었어요!\n그늘막으로 지켜주셔서 정말 감사해요!",
		"다행이야!",
		Callable(),
		"",
		Callable()
	)



func _on_pickup_can() -> void:
	if near_can_index >= 0 and near_can_index < watering_can_items.size():
		var item := watering_can_items[near_can_index]
		if is_instance_valid(item):
			item.queue_free()
	near_can = false
	near_can_index = -1
	can_bubble_label.hide()
	found_can_count += 1
	
	if found_can_count < 3:
		hint_label.text = "물뿌리개를 주웠어요! (" + str(found_can_count) + "/3) 남은 물뿌리개를 더 찾아보세요!"
	else:
		water_phase = WaterPhase.RETURN_TO_GRANDMA
		_update_quest_icons()
		hint_label.text = "물뿌리개 3개를 모두 찾았어요! 오른쪽 집 앞 할머니에게 돌아가 말을 걸어요."


func _accept_got_can() -> void:
	water_phase = WaterPhase.READY_TO_WATER
	_update_quest_icons()
	hint_label.text = "물뿌리개를 선물로 받았어요! 가운데 씨앗에게 돌아가 말을 걸어요."


func _accept_find_carpenter() -> void:
	temp_phase = TempPhase.GO_TO_CARPENTER
	GameState.temp_phase_id = 1
	GameState.save_game()
	_update_quest_icons()
	_update_quest_text()
	hint_label.text = "빨간 지붕집 앞의 온도 목수님에게 가서 말을 걸어보세요!"


func _accept_find_wizard() -> void:
	air_phase = AirPhase.GO_TO_WIZARD
	GameState.air_phase_id = 1
	GameState.save_game()
	_update_quest_icons()
	_update_quest_text()
	hint_label.text = "위쪽 언덕의 공기정화 마법사님에게 가서 말을 걸어보세요!"


func _update_quest_icons() -> void:
	if seed_quest_icon != null:
		seed_quest_icon.text = ""
	if grandma_quest_icon != null:
		grandma_quest_icon.text = ""
	if carpenter_quest_icon != null:
		carpenter_quest_icon.text = ""
	if wizard_quest_icon != null:
		wizard_quest_icon.text = ""
		
	if GameState.current_quest == &"water" and not GameState.water_cleared:
		match water_phase:
			WaterPhase.INIT_TALK_SEED:
				if seed_quest_icon != null: seed_quest_icon.text = "❓"
			WaterPhase.GO_TO_GRANDMA:
				if grandma_quest_icon != null: grandma_quest_icon.text = "❓"
			WaterPhase.RETURN_TO_GRANDMA:
				if grandma_quest_icon != null: grandma_quest_icon.text = "❗"
			WaterPhase.READY_TO_WATER:
				if seed_quest_icon != null: seed_quest_icon.text = "❗"
	elif GameState.current_quest == &"temp" and not GameState.temp_cleared:
		match temp_phase:
			TempPhase.INIT_TALK_SEED:
				if seed_quest_icon != null: seed_quest_icon.text = "❓"
			TempPhase.GO_TO_CARPENTER:
				if carpenter_quest_icon != null: carpenter_quest_icon.text = "❓"
			TempPhase.READY_TO_SHADE:
				if seed_quest_icon != null: seed_quest_icon.text = "❗"
	elif GameState.current_quest == &"air" and not GameState.air_cleared:
		match air_phase:
			AirPhase.INIT_TALK_SEED:
				if seed_quest_icon != null: seed_quest_icon.text = "❓"
			AirPhase.GO_TO_WIZARD:
				if wizard_quest_icon != null: wizard_quest_icon.text = "❓"
			AirPhase.READY_TO_CLEAN:
				if seed_quest_icon != null: seed_quest_icon.text = "❗"


# ─────────────────────────────────────────────
# 유틸리티
# ─────────────────────────────────────────────

func _add_touch_button(layer: CanvasLayer, button_position: Vector2, action: StringName, caption: String, button_size := Vector2(110, 110)) -> void:
	var touch := TouchScreenButton.new()
	touch.position = button_position
	touch.action = action
	touch.texture_normal = _solid_texture(Color("4A90E2"), int(button_size.x), int(button_size.y))
	layer.add_child(touch)
	var lbl := Label.new()
	lbl.text = caption
	lbl.position = Vector2(0, 20)
	lbl.size = button_size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 23)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch.add_child(lbl)


func _update_quest_text() -> void:
	var text := ""
	match GameState.current_quest:
		&"water":   text = "해야 할 일: 씨앗에게 알맞은 물 주기"
		&"temp":
			match temp_phase:
				TempPhase.INIT_TALK_SEED: text = "해야 할 일: 텃밭의 씨앗과 대화하기"
				TempPhase.GO_TO_CARPENTER: text = "해야 할 일: 빨간 지붕집 목수에게 그늘막 구하기"
				TempPhase.READY_TO_SHADE: text = "해야 할 일: 씨앗에게 돌아가 그늘막으로 햇빛 막기"
		&"air":
			match air_phase:
				AirPhase.INIT_TALK_SEED: text = "해야 할 일: 텃밭의 씨앗과 대화하기"
				AirPhase.GO_TO_WIZARD: text = "해야 할 일: 언덕 위 마법사와 공기정화 마법봉 만들기"
				AirPhase.READY_TO_CLEAN: text = "해야 할 일: 씨앗에게 돌아가 마법봉으로 매연 정화하기"
		&"complete": text = "모든 준비가 끝났어요!"
	quest_label.text = text
	
	if GameState.current_quest == &"water":
		pass # 이미 각 콜백에서 설정됨
	elif GameState.current_quest == &"temp":
		match temp_phase:
			TempPhase.INIT_TALK_SEED:
				hint_label.text = "가운데 씨앗에게 말을 걸어보세요!"
			TempPhase.GO_TO_CARPENTER:
				hint_label.text = "빨간 지붕집 앞의 온도 목수님에게 가서 말을 걸어보세요!"
			TempPhase.READY_TO_SHADE:
				hint_label.text = "그늘막을 획득했어요! 가운데 씨앗에게 돌아가 말을 걸어요."
	elif GameState.current_quest == &"air":
		match air_phase:
			AirPhase.INIT_TALK_SEED:
				hint_label.text = "가운데 씨앗에게 말을 걸어보세요!"
			AirPhase.GO_TO_WIZARD:
				hint_label.text = "위쪽 언덕의 공기정화 마법사님에게 가서 말을 걸어보세요!"
			AirPhase.READY_TO_CLEAN:
				hint_label.text = "마법봉을 획득했어요! 가운데 씨앗에게 돌아가 말을 걸어요."
	else:
		hint_label.text = "WASD / 방향키 또는 화면 버튼으로 움직여요."


func _label(value: String, pos: Vector2, control_size: Vector2, font_size: int) -> Label:
	var node := Label.new()
	node.text = value
	node.position = pos
	node.size = control_size
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color.WHITE)
	return node


func _solid_texture(color: Color, width: int, height: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, color])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = width
	texture.height = height
	return texture

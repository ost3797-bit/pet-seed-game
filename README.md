# 반려 씨앗 키우기 게임

Godot Engine 4.x용 실행 가능한 기능 프로토타입입니다. 별도 에셋 없이 ColorRect, Polygon2D, Label로 구성했습니다.

## 실행

1. Godot 4.x에서 `project.godot`를 Import합니다.
2. 프로젝트를 실행합니다. 시작 씬은 `scenes/Title.tscn`입니다.
3. PC에서는 WASD/방향키로 이동하고 Space 또는 Enter로 씨앗과 상호작용합니다.
4. 태블릿에서는 필드 하단의 터치 이동 버튼과 `말하기` 버튼을 사용합니다.

## 구성

- `scripts/GameState.gd`: Autoload 저장 데이터와 InputMap 자동 등록
- `scenes/Title.tscn`: 새 게임/불러오기
- `scenes/CharacterSelect.tscn`: 이름 및 친구 색상 선택
- `scenes/MainField.tscn`: 이동, 씨앗 상호작용, 가상 조이스틱
- `scenes/WaterGame.tscn`: 70~80 수분 유지 게임
- `scenes/TempGame.tscn`: 5라운드 온도 바늘 게임
- `scenes/AirGame.tscn`: 5라운드 매연 제거 게임
- `scenes/Ending.tscn`: 축하와 재시작

진행 상태는 `user://savegame.save`에 JSON으로 저장됩니다.

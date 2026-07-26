# 🚀 깃허브(GitHub) & 버셀(Vercel) 배포 완벽 가이드

이 문서에서는 Godot 4로 제작된 **Pet Seed Game**을 깃허브에 올리고, 무료 호스팅 플랫폼인 **Vercel(버셀)**을 통해 전 세계 누구나 브라우저에서 플레이할 수 있도록 배포하는 방법을 안내합니다.

---

## 💡 왜 `vercel.json` 파일이 필요한가요? (중요!)
Godot 4 엔진의 웹(HTML5) 내보내기는 고성능 게임 구동을 위해 브라우저의 `SharedArrayBuffer` 및 멀티스레딩 기능을 필수적으로 사용합니다.
일반적인 웹 호스팅 환경에서는 최신 브라우저 보안 정책으로 인해 이 기능이 차단되어 게임이 실행되지 않거나 검은 화면만 나옵니다.

하지만 프로젝트 루트에 생성된 **`vercel.json`** 파일이 Vercel 서버에게 브라우저 보안 헤더(**COOP**, **COEP**)를 전송하도록 명령하므로, 어떤 설정도 추가할 필요 없이 **Vercel에서 100% 완벽하게 구동**됩니다!

---

## 🛠️ 1단계: 고도(Godot) 엔진에서 웹 빌드(HTML5) 뽑기

1. 고도 엔진 에디터 상단 메뉴에서 **[프로젝트 (Project)] ➔ [수출 (Export)...]**를 클릭합니다.
2. 상단의 **[추가... (Add...)]** 버튼을 누르고 **[Web]**을 선택합니다.
   * *※ 만약 "내보내기 템플릿이 누락되었습니다"라는 빨간 글씨가 보이면 **[템플릿 다운로드 및 설치]**를 눌러 설치해 주세요.*
3. 우측 하단의 **[프로젝트 내보내기 (Export Project)]** 버튼을 누릅니다.
4. 파일 저장 창이 열리면, `PetSeedGame` 폴더 안에 **`public`** 이라는 이름의 새 폴더를 만듭니다.
5. **`public`** 폴더 안으로 들어간 뒤, 파일 이름을 반드시 **`index.html`**로 입력하고 **[저장 (Save)]**을 누릅니다.
6. 내보내기가 완료되면 `public` 폴더 안에 `index.html`, `index.wasm`, `index.pck`, `index.js` 등의 파일이 생성됩니다.

---

## 📦 2단계: 깃허브(GitHub)에 리포지토리 만들고 업로드하기

1. [GitHub](https://github.com)에 로그인한 후, 우측 상단의 `+` 버튼을 눌러 **[New repository]**를 클릭합니다.
2. Repository name(저장소 이름)에 `pet-seed-game` 등 원하는 이름을 적고 **[Create repository]**를 클릭합니다.
3. 내 컴퓨터의 터미널(명령 프롬프트, PowerShell, VSCode 터미널 등)에서 `PetSeedGame` 폴더로 이동한 뒤 아래 명령어를 순서대로 실행합니다:

```bash
# 1. 깃 초기화
git init

# 2. 파일 전체 추가 (우리가 만든 .gitignore가 불필요한 캐시를 자동으로 제외해 줍니다)
git add .

# 3. 커밋 생성
git commit -m "Initial commit: Pet Seed Game with Vercel deployment configuration"

# 4. 기본 브랜치 이름을 main으로 지정
git branch -M main

# 5. 깃허브 원격 저장소 연결 (아래 URL은 본인의 깃허브 주소로 변경하세요)
git remote add origin https://github.com/본인계정/pet-seed-game.git

# 6. 깃허브로 업로드
git push -u origin main
```

---

## 🌐 3단계: Vercel(버셀)과 연동하여 라이브 서비스 시작하기

1. [Vercel 공식 홈페이지](https://vercel.com)에 접속하여 **GitHub 계정으로 로그인**합니다.
2. 대시보드 우측 상단의 **[Add New...] ➔ [Project]**를 클릭합니다.
3. **Import Git Repository** 목록에서 방금 올린 `pet-seed-game` 리포지토리 옆의 **[Import]** 버튼을 클릭합니다.
4. **Configure Project** 창에서 아래 설정이 맞는지 확인합니다:
   * **Framework Preset**: `Other` (기본값)
   * **Output Directory**: 우리가 생성한 `vercel.json` 덕분에 자동으로 **`public`**으로 인식됩니다. (별도 수정 필요 없음!)
5. 하단의 파란색 **[Deploy]** 버튼을 클릭합니다!
6. 약 1분 정도 빌드 과정이 지나면 축하 폭죽(🎉)과 함께 배포가 완료됩니다.
7. 생성된 **Vercel 도메인 주소(예: `https://pet-seed-game.vercel.app`)**를 클릭하면 브라우저에서 게임이 즉시 실행되며, 친구들에게 링크를 공유하여 함께 즐길 수 있습니다!

---

### 📌 팁: 게임 내용을 업데이트하고 싶을 때는?
게임을 수정한 뒤 1단계처럼 `public` 폴더에 다시 내보내기를 하고, 깃허브에 변경 사항을 `git push`하기만 하면 **Vercel이 알아서 1분 만에 자동으로 업데이트를 반영**해 줍니다!

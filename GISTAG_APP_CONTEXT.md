# Gistag App Context for AI Agents

이 문서는 다른 AI Agent가 Gistag 앱의 제품 맥락과 코드 구조를 빠르게 이해하고 작업을 이어갈 수 있도록 작성한 핸드오프 브리프입니다.

## 한 줄 소개

Gistag는 사용자가 GIST 주변 운동 장소의 NFC 태그를 스캔해 운동을 시작하고, 세션 종료 후 XP, 레벨, 스트릭, 기록, 랭킹을 관리하는 Flutter 모바일 앱입니다.

## 제품 컨셉

Gistag의 핵심 아이디어는 "운동 장소에 비치된 NFC 태그를 찍으면 그 장소에서의 운동이 인증되고 기록된다"는 것입니다. 사용자는 앱에서 주변 운동 장소를 확인하고, NFC 태그로 장소를 검증한 뒤 운동 세션을 시작합니다. 일정 시간 이상 운동한 뒤 세션을 종료하면 서버가 운동 기록과 보상을 계산하고 앱은 결과 화면에 XP, 레벨업 여부, 스트릭을 보여줍니다.

현재 코드 기준으로 주요 사용 맥락은 GIST 캠퍼스 또는 GIST 주변 운동 장소입니다. 위치 권한이 없거나 지도 API 키가 없는 경우에도 GIST 기준 좌표와 fallback 장소 목록으로 홈/지도 UI가 동작합니다.

## 주요 사용자 흐름

1. 앱 시작
   - `lib/main.dart`에서 `.env`를 선택적으로 로드합니다.
   - Naver Map Client ID가 있으면 `FlutterNaverMap`을 초기화합니다.
   - `ProviderScope`로 `GistagApp`을 실행합니다.

2. 인증
   - 초기 라우트는 `/splash`입니다.
   - `AuthController`가 저장된 토큰을 복원합니다.
   - 미인증 사용자는 `/login` 또는 `/register`로 이동합니다.
   - 인증 사용자는 `/home`으로 이동합니다.
   - 이메일 로그인/회원가입과 Infoteam OAuth 로그인을 지원합니다.

3. 온보딩
   - `HomeShellScreen` 진입 시 `UserProfileController`가 프로필을 로드합니다.
   - `onboardingCompleted == false`이면 `/onboarding`으로 보냅니다.
   - 온보딩은 성별, 선호 운동 타입, 운동 빈도 정보를 받습니다.

4. 홈
   - 홈 탭은 사용자 레벨, 총 XP, 스트릭, 최근 기록, 주변 운동 장소를 보여줍니다.
   - 주변 장소는 위치 권한이 있으면 현재 위치 기준, 없으면 GIST fallback 좌표 기준으로 조회합니다.
   - 하단 고정 액션에서 NFC 스캔, 지도, 기록 접근을 제공합니다.
   - 로고 long press로 `/admin/nfc-tags` 관리자 화면에 진입할 수 있습니다.

5. NFC 운동 시작
   - `/scan` 진입 시 NFC 태그 읽기가 자동 시작됩니다.
   - 읽은 태그는 `GistagService.verifyNfcTag()`로 서버 검증합니다.
   - 검증 성공 후 `/tag-success`에서 장소 정보를 확인합니다.
   - 사용자가 "운동 시작"을 누르면 서버에 운동 세션을 생성하고 `/workout`으로 이동합니다.

6. 운동 진행/종료
   - `/workout`은 진행 시간 타이머와 같은 장소에서 운동 중인 사용자 목록을 보여줍니다.
   - 운동 종료는 최소 60초 이후에 가능합니다.
   - 종료 시 서버 `/workout-sessions/{id}/finish`가 기록과 보상을 계산합니다.
   - 성공하면 `/workout-result`에서 XP, 레벨, 스트릭, 운동 장소/시간을 보여줍니다.
   - 사용자는 세션을 "기록 없이 취소"할 수도 있습니다.

7. 기록/랭킹
   - 홈 쉘의 탭은 홈, 랭킹, 히스토리입니다.
   - 랭킹은 페이지네이션을 지원하고 내 순위(`me`)를 별도 표시할 수 있습니다.
   - 히스토리는 최근 운동 기록을 보여줍니다.

8. NFC 관리자
   - `/admin/nfc-tags`는 `.env`의 `GISTAG_NFC_ADMIN_PASSWORD`가 있을 때 활성화됩니다.
   - 관리자 비밀번호를 통과하면 NFC 태그를 읽고 장소/메타데이터를 서버에 등록합니다.
   - demo 태그(`DEMO-NFC-TAG`)는 서버 등록 없이 앱 내부 demo resolution으로 처리됩니다.

## 기술 스택

- Flutter/Dart
- Riverpod: 앱 상태, 컨트롤러, 서비스 의존성 주입
- GoRouter: 라우팅과 인증 redirect
- Dio: REST API 통신
- flutter_secure_storage: 토큰 저장
- flutter_web_auth_2: Infoteam OAuth 플로우
- flutter_dotenv: 로컬 환경 변수 로딩
- flutter_naver_map: 지도
- geolocator: 현재 위치 확인
- nfc_manager, nfc_manager_ndef: NFC 읽기/쓰기/검사
- amplitude_flutter: 이벤트 분석
- Pretendard font, Material 3 theme

## 주요 파일 맵

- `lib/main.dart`: 앱 부트스트랩, `.env` 로드, Naver Map 초기화
- `lib/app/gistag_app.dart`: `MaterialApp.router` 구성
- `lib/app/app_theme.dart`: 브랜드 색상과 Pretendard 기반 테마
- `lib/router/app_router.dart`: GoRouter 라우트와 인증 redirect
- `lib/providers/app_providers.dart`: Riverpod provider, auth/home/ranking/workout/location controller
- `lib/models/auth_models.dart`: 인증 토큰/사용자 모델
- `lib/models/user_profile_models.dart`: 온보딩/운동 프로필 모델
- `lib/models/gistag_models.dart`: 홈, 장소, NFC, 운동 세션, 기록, 랭킹 모델
- `lib/services/gistag_service.dart`: 앱 기능용 서비스 인터페이스
- `lib/services/api_gistag_service.dart`: 실제 REST API 구현
- `lib/services/mock_gistag_service.dart`: 로컬 mock 데이터 구현
- `lib/services/gistag_nfc_service.dart`: NFC 읽기/쓰기/검사 구현과 demo mode
- `lib/services/nfc_payload_parser.dart`: Gistag NFC payload 파싱/생성
- `lib/services/auth_repository.dart`: 인증 유스케이스 조합
- `lib/services/auth_api.dart`: 인증 API
- `lib/services/api_client.dart`: 인증 토큰 자동 첨부/refresh interceptor
- `lib/screens/home_shell_screen.dart`: 홈/랭킹/히스토리 탭 쉘, 온보딩/활성 세션 복원
- `lib/screens/home_screen.dart`: 홈 화면
- `lib/screens/nfc_scan_screen.dart`: NFC 스캔 화면
- `lib/screens/tag_success_screen.dart`: 태그 검증 후 장소 확인 화면
- `lib/screens/active_workout_screen.dart`: 운동 진행 화면
- `lib/screens/workout_result_screen.dart`: 운동 결과 화면
- `lib/screens/ranking_screen.dart`: 랭킹 화면
- `lib/screens/history_screen.dart`: 기록 화면
- `lib/screens/onboarding_screen.dart`: 온보딩 화면
- `lib/screens/settings_screen.dart`: 설정/프로필 화면
- `lib/screens/nfc_admin_screen.dart`: 관리자용 NFC 태그 등록 화면
- `lib/widgets/common/*`: 공통 버튼, 헤더, 푸터, 다이얼로그, 카드성 UI
- `lib/widgets/gistag/*`: 장소 카드, 지도 패널, 랭킹 행, 운동 기록 카드, NFC CTA

## 라우트

라우트는 `lib/router/app_router.dart`에 정의되어 있습니다.

- `/splash`: 세션 복원 중
- `/login`: 로그인
- `/register`: 회원가입
- `/home`: 홈 쉘
- `/onboarding`: 운동 프로필 온보딩
- `/settings`: 설정
- `/places-map`: 주변 운동 장소 지도
- `/scan`: NFC 태그 스캔
- `/admin/nfc-tags`: 관리자 NFC 태그 등록
- `/tag-success`: 태그 검증 후 장소 확인
- `/workout`: 운동 진행
- `/workout-result`: 운동 결과

## 상태 관리 구조

앱은 Riverpod provider를 통해 환경 설정, 서비스, 컨트롤러를 구성합니다.

- 설정 provider
  - `authConfigProvider`
  - `mapConfigProvider`
  - `adminConfigProvider`
  - `analyticsConfigProvider`

- 서비스 provider
  - `authApiProvider`
  - `authTokenManagerProvider`
  - `authRepositoryProvider`
  - `apiClientProvider`
  - `gistagServiceProvider`
  - `gistagNfcServiceProvider`
  - `userProfileApiProvider`
  - `analyticsServiceProvider`

- 컨트롤러 provider
  - `authControllerProvider`
  - `userProfileControllerProvider`
  - `homeControllerProvider`
  - `nearbyPlacesControllerProvider`
  - `rankingControllerProvider`
  - `workoutControllerProvider`
  - `workoutPeersControllerProvider`
  - `selectedHomeTabProvider`

중요한 패턴은 UI가 직접 API를 호출하지 않고 controller 또는 service interface를 통해 호출한다는 점입니다. 새 기능을 추가할 때도 가능하면 `GistagService` 인터페이스를 확장하고 `ApiGistagService`에 실제 구현을 추가한 뒤 provider/controller/UI 순서로 연결하는 것이 현재 구조와 맞습니다.

## 백엔드 API 계약

현재 `ApiGistagService`와 `AuthApi`가 사용하는 주요 엔드포인트입니다.

인증:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/infoteam/token`
- `POST /auth/refresh`
- `POST /auth/logout`
- `GET /auth/me`

프로필:

- `UserProfileApi`가 담당합니다. 프로필 조회, 온보딩 제출, 프로필 수정 API가 있습니다.

Gistag 기능:

- `GET /users/me/stats`
- `GET /places/nearby?lat={lat}&lng={lng}&radius={radiusKm}`
- `POST /tags/resolve`
- `POST /admin/nfc-tags/register`
- `GET /workout-sessions/active`
- `POST /workout-sessions/start`
- `POST /workout-sessions/{id}/finish`
- `POST /workout-sessions/{id}/cancel`
- `GET /workout-records/me/recent?limit=5`
- `GET /rankings?limit={limit}&offset={offset}`
- `GET /workout-sessions/active/peers`

API 응답 파서는 방어적으로 작성되어 있습니다. 예를 들어 장소 이름은 `placeName`을 우선 사용하고 없으면 `name`을 사용합니다. 카테고리는 `category`를 읽어 한국어 운동 타입 라벨로 변환합니다.

## 환경 변수

`.env.example` 기준 키:

- `GISTAG_API_DEBUG_BASE_URL`: debug/profile 빌드 API base URL
- `GISTAG_API_PROD_BASE_URL`: release 빌드 API base URL
- `GISTAG_IDP_AUTHORIZE_URL`: Infoteam OAuth authorize URL
- `GISTAG_IDP_CLIENT_ID`: Infoteam OAuth client id
- `GISTAG_IDP_REDIRECT_URI`: 기본값은 `gistag://oauth/callback`
- `GISTAG_NAVER_MAP_CLIENT_ID`: Naver Map 활성화용 client id
- `GISTAG_NFC_ADMIN_PASSWORD`: 관리자 NFC 등록 화면 잠금 해제 비밀번호
- `GISTAG_NFC_DEMO_MODE`: `true`이면 실제 NFC 대신 demo 태그를 반환
- `AMPLITUDE_API_KEY`: Amplitude 분석 활성화용 키

`AuthConfig`는 release 빌드에서 `GISTAG_API_PROD_BASE_URL`, 그 외 빌드에서 `GISTAG_API_DEBUG_BASE_URL`을 우선 사용합니다. 둘 다 비어 있으면 `GISTAG_API_BASE_URL` 또는 `http://localhost:3000` fallback을 사용합니다.

## NFC 동작

NFC 서비스는 `GistagNfcService` 인터페이스와 `NfcManagerGistagNfcService` 구현으로 나뉩니다.

- 태그 읽기: hardware UID를 우선 읽고, 없으면 NDEF payload에서 Gistag tag code를 읽습니다.
- 태그 쓰기: `buildGistagNdefMessage(tagCode)`와 `buildGistagTagPayload(tagCode)`를 사용합니다.
- payload 형식: `gistag://tag/{tagCode}` 또는 `GISTAG_TAG_...` 코드 계열을 처리합니다.
- demo mode: `GISTAG_NFC_DEMO_MODE=true`이면 `DEMO-NFC-TAG`와 `gistag://tag/GISTAG_TAG_DEMO_001`을 반환합니다.
- Android에서는 가능한 경우 NDEF format을 시도합니다.
- iOS에서는 NDEF 쓰기 가능한 스티커 사용을 전제로 합니다.

## UX/브랜드 톤

현재 앱의 UI 톤은 가볍고 명확한 피트니스 앱에 가깝습니다.

- 주요 색상: primary `#FF4A3D`, primary dark `#D92D27`, soft background `#FFF7F6`
- 폰트: Pretendard
- UI 문구: 한국어 중심, 친근하지만 과장되지 않은 안내 문구
- 주요 시각 요소: NFC 아이콘, 운동 장소 카드, 진행 시간 패널, XP/레벨/스트릭 지표
- 지도: Naver Map 사용 가능 시 실제 지도, 없으면 fallback 지도성 패널

새 화면을 만들 때는 기존 `GistagButton`, `GistagHeader`, `GistagFooter`, `GistagFixedBottomActions`, `GistagPressable`, `GistagDialog` 같은 공통 위젯을 우선 사용하세요.

## 현재 구현상 중요한 제약

- 운동 종료는 UI상 60초 이후에만 가능합니다. 서버도 최소 운동 시간 정책을 갖는 것으로 보이며, 실패 메시지는 "최소 운동 시간은 60초"로 처리됩니다.
- 홈 진입 시 프로필 로드, 온보딩 여부 확인, 홈 데이터 refresh, 활성 운동 세션 복원이 순차적으로 일어납니다.
- 활성 운동 세션이 있으면 홈 대신 `/workout`으로 이동합니다.
- `gistagServiceProvider`는 현재 `ApiGistagService`를 기본 사용합니다. `mock_gistag_service.dart`는 존재하지만 provider에 연결되어 있지 않습니다.
- 웹 또는 비 IO 환경에서는 conditional import로 `api_gistag_service_stub.dart`가 사용될 수 있습니다.
- 위치 권한 실패, 지도 키 부재, API 데이터 부재에 대한 fallback UI가 여러 화면에 있습니다.
- 사용자 프로필 nickname은 `UserProfile`, `AuthUser`, `HomeSnapshot.user.name` 순으로 fallback되어 표시됩니다.
- 관리자 NFC 화면은 앱 내 long press로 접근 가능하지만 비밀번호 환경 변수가 없으면 사용할 수 없습니다.

## 작업할 때의 권장 방식

- UI 변경은 먼저 해당 screen 파일을 보고, 공통 스타일은 `app_theme.dart`와 `widgets/common`을 따르세요.
- 새 API 기능은 `GistagService` 인터페이스에 메서드를 추가하고 `ApiGistagService`에 구현하세요.
- 인증이 필요한 API는 `apiClientProvider`의 Dio를 사용하면 토큰 첨부와 401 refresh가 자동 처리됩니다.
- 인증을 건너뛰어야 하는 요청은 `Options(extra: {AuthRefreshInterceptor.skipAuthKey: true})` 패턴을 사용합니다.
- 화면 이동은 hardcoded string보다 가능하면 `AppRouteNames.paths`와 라우터 정의를 확인하고 맞추세요.
- 이벤트 분석은 `analyticsServiceProvider`를 통해 `track`, `trackButton`, route observer를 사용합니다.
- 기존 작업자가 만든 변경 사항이 있을 수 있으므로 git diff를 먼저 확인하고 관련 없는 변경은 되돌리지 마세요.

## 빠른 실행/검증

일반 개발 흐름:

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

로컬 `.env`가 필요하면 `.env.example`을 기준으로 작성합니다. 모바일 OAuth redirect URI는 현재 Android/iOS가 `gistag://oauth/callback` 기준으로 설정되어 있습니다.


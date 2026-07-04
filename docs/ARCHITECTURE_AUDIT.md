# Architecture Audit — EARLYHS iOS

> Step 1 of the code-quality refactor (`REFACTOR.md`). **No code changes in this PR.** This documents the actual state of the codebase against the Senior-iOS bar and proposes a behaviour-preserving refactor plan. **Awaiting approval before any refactor PR begins.**

Severity legend: **blocker** (correctness / leak / testability defect), **should** (clear SOLID/decoupling win), **nice** (polish).

Every finding below was verified against the current `main`.

---

## 1. Dependency direction & leaks

Intended: `Views → ViewModels → Services → (Player / Storage)`. Actual graph is close, with three real leaks.

| # | Finding | Severity | Where | Fix → PR |
|---|---|---|---|---|
| 1.1 | **`Features` transitively depends on WebKit.** `WebKitYouTubePlayer.swift` (`import WebKit`) lives inside the `Features` module, so every feature compiles against WebKit. The engine should sit behind a boundary that Features doesn't import. | should | `Features/Player/WebKitYouTubePlayer.swift` (only file importing WebKit) | `refactor/player-engine-protocol` |
| 1.2 | **The player engine protocol leaks UI.** `YouTubePlayer` exposes `var surface: AnyView` — a View is part of the "engine" contract, so the playback abstraction is coupled to SwiftUI. `PlayerViewModel` re-exposes `surface` too. | should | `Features/Player/YouTubePlayer.swift:13`, `PlayerViewModel.swift:44` | `refactor/player-engine-protocol` |
| 1.3 | Views are otherwise logic-free (state lives in `@Observable` ViewModels). No `@EnvironmentObject`-as-logic; `PlaybackController` is passed via `.environment` but is a legitimate app-level state container, not hidden logic. | ok | — | — |

## 2. The Player seam (priority #1)

A `YouTubePlayer` protocol already exists with `WebKitYouTubePlayer` (live) and `MockYouTubePlayer` (tests), and `PlayerViewModel` is unit-testable today — a good starting point. The defects:

| # | Finding | Severity | Where | Fix → PR |
|---|---|---|---|---|
| 2.1 | **Retain cycle in the JS bridge.** `WebKitYouTubePlayer` calls `controller.add(self, name: "yt")`; `WKUserContentController` retains its script-message handler **strongly**, and there is **no `deinit`** removing it. Cycle: engine → `webView` → `configuration` → `userContentController` → (strong) → engine. The engine and its `WKWebView` never deallocate when the player closes. This is the exact retain-cycle lesson from the DebuggingLab, live in the real app. | **blocker** | `WebKitYouTubePlayer.swift:33` (no `deinit`) | `refactor/player-engine-protocol` (+ Instruments proof) |
| 2.2 | **Callbacks are a mutable closure, not a stream.** State/progress arrive via `var onEvent: ((PlaybackEvent) -> Void)?`. A single mutable sink is fragile (last-writer-wins) and harder to compose/cancel than an `AsyncStream<PlaybackEvent>`. | should | `YouTubePlayer.swift`, `WebKitYouTubePlayer.swift`, `PlayerViewModel.swift` | `refactor/player-engine-protocol` |
| 2.3 | Delegate/closure captures are otherwise safe: `PlayerViewModel.onEvent` and `PlaybackController.onPlaybackEnded` both use `[weak self]` (verified). | ok | `PlayerViewModel.swift:28`, `PlaybackController.swift:157` | — |
| 2.4 | The live JS bridge (`WebKitYouTubePlayer`) has **no tests** (understandably — it needs a real web view). After 2.1/2.2 the adapter's translation logic (message → event) should be testable without WebKit. | should | `WebKitYouTubePlayer.swift` | `refactor/player-engine-protocol` |

## 3. SOLID

| # | Principle | Finding | Severity | Where | Fix → PR |
|---|---|---|---|---|---|
| 3.1 | **S** | `PlaybackController` has several jobs: queue management, current-track playback, **favourites toggling** (`toggleSaveCurrent`), and expansion/UI state (`isExpanded`). Favourites toggling in particular belongs to the favourites source of truth, not the playback controller. | should | `Features/Player/PlaybackController.swift` | `refactor/single-source-favourites`, `refactor/queue-and-nowplaying-state` |
| 3.2 | **S / I** | `YouTubePlayer` mixes **control** (`load/play/pause/seek`) with **UI** (`surface`). One protocol, two responsibilities; the mock is forced to provide a dummy view. | should | `YouTubePlayer.swift` | `refactor/player-engine-protocol` |
| 3.3 | **I** | Services are already narrow (`CatalogService` = `loadCatalog`; `FavouritesService` = all/ids/isFavourite/toggle). No fat "does-everything" service. The refactor's `CatalogBrowsing`/`FavouritesManaging`/`PlaybackControlling` split is largely **already satisfied**; only `PlaybackController` needs slimming (3.1). | nice | — | `refactor/service-protocol-segregation` (light) |
| 3.4 | **D** | No singletons (`grep '.shared'` → none). Concrete engine is built at the composition root (`AppRootView` / `AppDependencies`) and injected as a protocol. Good. | ok | — | — |
| 3.5 | **L** | `YouTubePlayer.surface` has a default returning `Color.black` so `MockYouTubePlayer` "no-ops" part of the contract — a minor Liskov smell that disappears once `surface` leaves the protocol (3.2). | nice | `YouTubePlayer.swift:25` | `refactor/player-engine-protocol` |
| 3.6 | **O** | No content/media-type `switch`es requiring edits to extend. | ok | — | — |

## 4. State & concurrency

| # | Finding | Severity | Where | Fix → PR |
|---|---|---|---|---|
| 4.1 | **Favourites has no single observable source of truth.** `FavouritesService` is a store, but `LibraryViewModel`, `DJDetailViewModel` and `SetDetailViewModel` each keep a private `favouriteIDs` cache and reconcile only `onAppear`; `SavedViewModel` re-reads on appear. Toggling a heart on one screen does **not** live-update the others until they reappear. There should be one observable `FavouritesStore` every screen reads. | should | `LibraryViewModel`, `DJDetailViewModel`, `SetDetailViewModel`, `SavedViewModel` | `refactor/single-source-favourites` |
| 4.2 | **Playback/queue source of truth is single** (`PlaybackController`) — good. But its slices are coarse. Needs verification that the progress tick doesn't invalidate the Library grid (the known re-render trap). Static reasoning suggests the mini-player only reads `nowPlaying`/`isPlaying`/`currentIsSaved` (not `currentTime`), so ticks shouldn't re-render `AppRootView`/Library — **but this must be Instruments-verified**, not assumed. | should (verify) | `PlaybackController`, `AppRootView`, `PlayerView` | `refactor/queue-and-nowplaying-state` |
| 4.3 | **Unstructured `Task`s without cancellation.** Fire-and-forget `Task { await … }` in button actions (`onToggleSave`) and `PlaybackController.refreshCurrentSaved()` aren't cancelled. Short-lived, low risk, but should be tightened (owned by the store / structured). | nice | Views' `onToggleSave`, `PlaybackController.swift` | `refactor/concurrency-audit` |
| 4.4 | `@MainActor` is applied to all ViewModels + `PlaybackController`; stores are actor- or lock-backed; Swift 6 language mode is on. No known data races. | ok | — | — |

## 5. DesignSystem discipline

| # | Finding | Severity | Where | Fix → PR |
|---|---|---|---|---|
| 5.1 | Hex literals are confined to `Palette` (verified — no hex outside DesignSystem). Components are shared, not duplicated per screen. Strong. | ok | — | — |
| 5.2 | A few raw `.black.opacity(0.55)` / `0.35` literals in `Badges`/`SaveHeart`/`MiniPlayer` scrims aren't tokenised. | nice | `DesignSystem/Components/*` | `refactor/designsystem-consolidation` |
| 5.3 | Stale doc comment: `SetCard` still reads "Tilts on press and pulses when playing" after the tilt was removed (PR #16). | nice | `DesignSystem/Components/SetCard.swift` | `refactor/clean-sweep` |

## 6. Clean-code inventory

- **Dead code:** none significant. `SetPlaceholderView` is still referenced as a nav fallback — keep. `TiltEffect` already removed (#16).
- **Naming glossary** is consistent: `HardstyleSet` (never `Set`), `Dj`, `Favourite`, `QueueItem`, `NowPlaying`, `PlayerState`, `PlaybackEvent`. One nit: `Dj` vs `DJCardModel`/`DJsView` casing — acceptable (domain model vs UI).
- **Sizes:** no function > ~40 lines of logic; largest files are `WebKitYouTubePlayer.swift` (~160, mostly an HTML string) and `PlaybackController.swift` (~175). Within limits; a stricter `file_length`/`type_body_length`/`cyclomatic_complexity` ruleset can be enabled and will pass with minor slimming.

## 7. Test coverage map

| Area | Tested? | Gap |
|---|---|---|
| Library / DJs / DJ detail / Saved / Set detail ViewModels | ✅ happy/empty/error/search/favourites/analytics | — |
| Player state machine (via `MockYouTubePlayer`) | ✅ | — |
| `PlaybackController` (queue/autoplay/reorder/remove/save) | ✅ | `refreshCurrentSaved` async path thin |
| Catalog / Favourites (in-memory + UserDefaults) / SeedCatalog / error mapping | ✅ | — |
| DesignSystem (hex, duration/label helpers) | ✅ | — |
| **`WebKitYouTubePlayer` message→event translation** | ❌ | testable after 2.1/2.2 (adapter split) → `refactor/player-engine-protocol` |
| UI smoke (scroll / open detail / tabs) | ✅ (XCUITest, #16) | expand per `refactor/tests-expansion` |

**Characterization tests needed BEFORE moving code** (the safety net): player state transitions, favourites toggle propagation, queue ordering/autoplay — `refactor/test-safety-net`.

---

## Proposed PR sequence (behaviour-preserving)

1. `refactor/test-safety-net` — pin player transitions, favourites toggle, queue ordering (4.1/2.x characterization).
2. `refactor/player-engine-protocol` — **fix the retain cycle (2.1)**; UI-free `PlayerEngine` protocol with a state stream (2.2/3.2/3.5); `YouTubePlayerAdapter` owns WebKit; provide the video surface separately; add adapter tests (2.4); confine WebKit so Features no longer imports it (1.1/1.2). Instruments: prove the player deallocates on close.
3. `refactor/single-source-favourites` — one observable `FavouritesStore`; delete per-VM `favouriteIDs` caches; move `toggleSaveCurrent` off `PlaybackController` (4.1/3.1).
4. `refactor/queue-and-nowplaying-state` — narrow observation slices; Instruments-verify the Library grid isn't invalidated by progress ticks (4.2).
5. `refactor/service-protocol-segregation` — light; slim `PlaybackController` (3.1/3.3).
6. `refactor/designsystem-consolidation` — tokenise stray scrims (5.2).
7. `refactor/concurrency-audit` — structured/cancelled tasks; strict-concurrency clean (4.3).
8. `refactor/clean-sweep` — stale comments (5.3), stricter SwiftLint ruleset.
9. `refactor/tests-expansion` — fill the map (7).

### Top priorities
1. **2.1 — WKScriptMessageHandler retain cycle (blocker, real leak).**
2. **1.1/1.2/3.2 — player engine protocol leaks UI + WebKit into Features.**
3. **4.1 — favourites single source of truth.**

**Awaiting Eryk's approval of this audit before opening any refactor PR.**

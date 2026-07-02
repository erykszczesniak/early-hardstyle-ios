# CLAUDE.md — Swift App 2: Early Hardstyle (iOS, MVVM)

> Operating manual for Claude Code in this repository. Read fully before coding. Follow every rule in **WORKFLOW RULES**.

---

## 0. PROJECT IDENTITY

**Name:** `early-hardstyle-ios`
**Owner / sole author:** Eryk Szczesniak (`erykszczesniak`)
**One-line pitch:** A native iOS app cataloguing the golden era of early hardstyle (1999–2007) — DJs, legendary sets, events — with browse/search, filters, and a personal "Saved" library. Project built to a production "serious app" standard with **MVVM**.

Playback uses the **official YouTube player** (YouTube iframe/player API in a WKWebView, or a maintained Swift wrapper). Store a `youtubeId`/`sourceUrl` per set and play it through the official embedded player — free to use any YouTube URLs for the sets. A full in-app player screen (play/pause/buffering/error state), a mini-player, and a queue are expected. **The one thing NOT to do:** do not rip/download or self-host raw audio/video files (that breaks YouTube's ToS and is technically weaker than a clean player integration). Use the official video's own thumbnail (via its id), not copied artwork. A small "tribute / not affiliated with any labels or events" note is a nice touch but this is a portfolio piece, not a published product.

---

## 1. THE "SERIOUS APP" STANDARD (applies to every feature)

Not a demo. Every feature MUST handle: **complex state** (loading/loaded/empty/error/refreshing explicitly), **error handling** (typed errors + recovery, no silent fails/crashes), **loading failures** (network/timeout/decoding → designed error + retry), **edge cases** (empty/partial/huge/offline/stale/malformed), **accessibility** (Dynamic Type, VoiceOver, contrast, reduced motion), **analytics** (privacy-respecting protocol abstraction, no PII), **crash monitoring** (protocol abstraction, log/default impl, pluggable). One well-finished app beats ten demos.

---

## 1b. SENIOR iOS BAR (portfolio targets a Senior Software Engineer, iOS)

This project is portfolio evidence for a **Senior iOS** role, so go beyond "it works":

- **Modularisation:** split the app into Swift Package modules (Core, Services, DesignSystem, Features) with clear boundaries and minimal coupling; features depend on protocols, not concretions.
- **Dependency injection** throughout; no hidden singletons in testable code; everything swappable for tests.
- **Testing depth:** meaningful unit tests for ViewModels (happy/failure/edge), services, decoding, and the player state machine; aim for coverage that demonstrates discipline, not vanity %.
- **Concurrency correctness:** structured concurrency (async/await, `@MainActor` for UI), no data races; cancellation handled.
- **Performance awareness:** lazy loading, image/thumbnail caching, no main-thread blocking, smooth scrolling on large grids.
- **Tooling:** SwiftLint + SwiftFormat enforced in CI; GitHub Actions build+test on every PR.
- **Documentation:** a README that explains architecture decisions a senior would defend in review.
- **Language/UI:** Swift (latest), SwiftUI, **async/await**.
- **Architecture:** **MVVM** — Views ← ViewModels (`ObservableObject`/`@Observable`) ← Services/Repositories ← Networking. Dependency injection via initialisers (no singletons in testable units).
- **Networking:** async API client (or local data store) behind a protocol; `Codable`; typed errors; a mock impl.
- **Persistence:** local store for the "Saved" library + catalogue cache (SwiftData or a simple store) behind a protocol.
- **Media playback:** official **YouTube player** integration (iframe/player API via WKWebView, or a maintained Swift wrapper) driven by a stored `youtubeId`/`sourceUrl`; full player state (play/pause/buffering/ended/error) surfaced to the ViewModel. No ripping/self-hosting of raw files.
- **Analytics & crash:** protocol-based abstractions injected (log/no-op defaults; pluggable).
- **Testing:** XCTest — ViewModel tests (with mocked services) + decoding/error tests.
- **Quality:** SwiftLint + SwiftFormat. **CI:** GitHub Actions (build + test).

### Structure

```
EarlyHardstyle/
├── App/                 -> entry, DI composition root
├── Core/
│   ├── Models/          -> Dj, Set, Event, Genre, Favourite (Codable)
│   ├── Services/        -> CatalogService, FavouritesService (protocols + impls + mocks)
│   └── Telemetry/       -> Analytics + CrashReporter protocols + default impls
├── Features/
│   ├── Library/         -> View + ViewModel (set cards: year, duration, DJ, event, tags)
│   ├── DJs/             -> View + ViewModel (DJ cards: avatar, country, set count) + detail
│   ├── Saved/           -> View + ViewModel (favourites, empty state)
│   ├── Player/          -> View + ViewModel (YouTube player, play/pause/buffer/error, mini-player, queue)
│   └── SetDetail/       -> player entry point, genres, related
├── DesignSystem/        -> dark theme + orange accent, cards, badges, states
└── Tests/               -> ViewModel + decoding tests + fixtures
```

> Note: the DesignSystem brand direction is superseded by `DESIGN.md` — black / white / electric blue, not orange. The iOS app has its own identity.

---

## 3. FEATURES

- **Library** — grid of set cards (year badge, thumbnail, duration, DJ, event line, genre tags); search + filters (year, event brand, genre, country).
- **DJs** — grid of DJ cards (avatar, name, set count, country) + DJ detail.
- **Saved** — favourites (heart toggle), per-device/user; designed empty state.
- **Set detail** — entry point to the player, genres, related sets.
- **Player** — full-screen YouTube player with play/pause/seek/buffering/error states, a **mini-player** that persists across navigation, and a **play queue** (play next, autoplay next set).
- **Theme** — see `DESIGN.md`.

All UI in English; every screen meets section-1.

---

## 4. FEATURE BREAKDOWN (one branch + one PR per item)

1. `feature/project-scaffold` — Xcode project, SPM, SwiftLint/SwiftFormat, GitHub Actions CI, DI composition root, folders.
2. `feature/telemetry-abstractions` — Analytics + CrashReporter protocols + default impls (wired first).
3. `feature/models-and-services` — Codable models + Catalog/Favourites service protocols + mocks; decoding tests.
4. `feature/design-system` — theme, cards, badges, loading/empty/error states.
5. `feature/library` — Library View + ViewModel (set cards, full state enum) + search; tests; a11y; analytics.
6. `feature/library-filters` — filters (year/brand/genre/country); tests.
7. `feature/djs-list-detail` — DJs grid + DJ detail; tests.
8. `feature/saved-favourites` — favourites store + heart toggle + Saved view + empty state; tests for toggle/persistence.
9. `feature/set-detail` — set detail screen + entry point to the player; tests.
10. `feature/youtube-player` — official YouTube player integration (iframe/player API via WKWebView or a maintained wrapper); full player-state ViewModel (play/pause/buffering/ended/error) with error + retry; tests with a mock player.
11. `feature/mini-player-and-queue` — persistent mini-player across navigation + play queue (play next / autoplay); state tests.
12. `feature/seed-content` — seed real early-hardstyle DJs/sets (Showtek, A-Lusion, Headhunterz, The Prophet, Technoboy, Brennan Heart...) with YouTube ids.
13. `feature/error-and-edge-hardening` — sweep loading failures/edge cases/accessibility across features (incl. player error/offline states).
14. `feature/docs-readme` — final README. LAST PR.

### PR granularity

Minimum, not a cap. Split large features into stacked PRs (≤ ~400 lines diff), merge bottom-up, rebase next onto updated `main`. Many small PRs > few large. Each ships tests + passes CI.

---

## 5. WORKFLOW RULES (NON-NEGOTIABLE)

- **Authorship:** all commits by **Eryk Szczesniak** (`user.name "erykszczesniak"`, `user.email "erykszczit@gmail.com"`). **No `Co-Authored-By` / no AI attribution anywhere.** Don't reference this assistant in any git artefact.
- **Language:** everything in git + UI in **English**.
- **Branching:** `main` only long-lived; one feature = one branch `feature/<short-kebab-case>` off latest `main`.
- **Commits:** small, Conventional Commits, imperative, English (e.g. `feat(saved): add favourites toggle and store`). No AI attribution.
- **PRs & merge:** PR per feature into `main`. **Auto-merge**, **Squash & Merge ONLY**, exact subject `Merge pull request #<PR_NUMBER> from erykszczesniak/<branch-name>`, `--delete-branch=false`. **Do NOT delete branches.** Confirm `gh` authed as Eryk.
- **Quality gates:** app builds; `swift test` green; SwiftLint/SwiftFormat clean; CI green; playback via official YouTube player (no ripped/self-hosted files); no secrets.
- **Build with understanding:** reviewable PRs, idiomatic MVVM (DI, testable ViewModels) the author can explain.

---

## 6. ENGINEERING BEST PRACTICES (2026)

- **MVVM + DI:** dumb views; logic in ViewModels; dependencies injected via initialisers for testability; no business logic in views.
- **Explicit state machines:** loading/loaded/empty/error in ViewModel state, not nil-inferred.
- **Typed errors + recovery** surfaced in UI; retry.
- **Telemetry built in** from feature #2; privacy-respecting; no PII.
- **Playback via official player:** YouTube player API integration with full state handling; no ripped/self-hosted media.
- **Accessibility from the start.**
- **Testing depth:** ViewModel happy/failure/edge tests with mocked services; decoding tests.
- **CI on every PR.**

---

## 7. DEFINITION OF DONE

- All features merged to `main` via squash merge with the exact message format; no branches deleted; CI green.
- Every feature meets the section-1 "serious app" standard.
- Playback works via the official YouTube player (full state handling); mini-player + queue functional; no ripped/self-hosted media.
- MVVM used idiomatically with ViewModel test coverage; seed content reproduces the catalogue; README complete.
- DebuggingLab present: each theme-matched bug has a `lab/broken-*` PR and a `lab/fix-*` PR with full explanations; the README lab table is complete; `lab/broken-*` branches retained.
- No AI attribution anywhere; commits by Eryk Szczesniak; UI/docs in English.

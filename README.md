# Early Hardstyle — iOS

> Native iOS app cataloguing the golden era of early hardstyle (1999–2007): DJs, legendary sets and events, with browse/search, filters and a personal **Saved** library. Playback via the **official YouTube player**. Built to a production, senior-iOS standard with **MVVM**.

**Status:** 🚧 in active development — see the [feature roadmap](CLAUDE.md#4-feature-breakdown-one-branch--one-pr-per-item). This README is expanded in the final documentation PR.

> Tribute project — not affiliated with any labels, events or artists.

---

## Architecture

MVVM with strict module boundaries, enforced by a local Swift Package (`Packages/Modules`) whose products are consumed by a thin app target:

```
early-hardstyle-ios/
├── project.yml               XcodeGen spec — the .xcodeproj is generated, never committed
├── App/                      thin app target: entry point + DI composition root
│   ├── Sources/              EarlyHardstyleApp, AppDependencies (composition root)
│   └── Resources/            Assets (AccentColor, AppIcon)
├── Packages/Modules/         local Swift Package — the app's real code
│   └── Sources/
│       ├── Core/             models, telemetry protocols, typed errors (no UI)
│       ├── Services/         catalog/favourites/player services (protocols + impls + mocks)
│       ├── DesignSystem/     tokens, components, motion modifiers
│       └── Features/         screen View + ViewModel pairs
├── .github/workflows/ci.yml  lint + build + test on every PR
├── .swiftlint.yml / .swiftformat
├── CLAUDE.md                 engineering operating manual
└── DESIGN.md                 UI/UX single source of truth
```

**Dependency direction:** `Features → DesignSystem / Services / Core`. Features depend on **protocols**, never concretions. Concrete implementations are constructed in exactly one place — `App/Sources/AppDependencies.swift`, the composition root — and injected downstream via initialisers. No hidden singletons in testable code.

### Why a generated project

The `.xcodeproj` is produced by [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml` and is **git-ignored**. This keeps the repo free of merge-conflict-prone project files and makes the build configuration reviewable as plain YAML.

---

## Getting started

Requirements: **Xcode 16+** (developed on Xcode 26), and the tools below.

```bash
# one-time: install tooling
brew install xcodegen swiftlint swiftformat

# generate the Xcode project (whenever project.yml or the file tree changes)
xcodegen generate

# open in Xcode
open EarlyHardstyle.xcodeproj
```

### Command line

```bash
# build the app
xcodebuild build -project EarlyHardstyle.xcodeproj -scheme EarlyHardstyle \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# run the module tests
cd Packages/Modules && xcodebuild test -scheme EarlyHardstyleKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# lint / format check
swiftformat . --lint
swiftlint lint --strict
```

---

## Quality gates

Every PR runs [`CI`](.github/workflows/ci.yml): **SwiftFormat** (lint mode) + **SwiftLint** (`--strict`), an app build, and the full module test suite on an iOS simulator. Green CI is required to merge.

---

## Design & brand

Minimalist, modern: **black / white / electric blue**, with 3D used as depth and motion — never as gimmick. The full design system, tokens, screen maps and motion language live in [`DESIGN.md`](DESIGN.md).

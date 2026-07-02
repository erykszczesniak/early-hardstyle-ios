# DESIGN.md — Early Hardstyle iOS: Screens & Design System

> Companion to `CLAUDE.md`. This file is the single source of truth for UI/UX.
> Brand direction: **minimalist, modern, black / white / electric blue, with 3D used as depth & motion — never as gimmick.**
> This supersedes the earlier dark+orange mockups: the iOS app gets its own identity.

---

## 1. DESIGN PRINCIPLES

1. **Minimal surface, maximal depth.** Few elements per screen, generous spacing — but every card/artwork has physical depth (parallax, tilt, layered shadows). Flat layouts, non-flat materials.
2. **Black canvas, blue energy.** Near-black backgrounds; electric blue is the ONLY accent and is used sparingly (active states, progress, glows). White carries typography.
3. **Motion = meaning.** Every animation communicates state (playing, loading, transition). No decorative motion. Respect Reduce Motion.
4. **The music is the hero.** Artwork/thumbnails are the largest visual elements; chrome recedes.
5. **One-hand reachability.** Primary actions in the bottom half; tab bar + mini-player anchored bottom.

---

## 2. DESIGN TOKENS

### Colors (dark-first; a light theme is optional/later)
| Token | Value | Use |
|---|---|---|
| `bg.base` | `#0A0A0C` | app background (near-black, slightly blue-tinted) |
| `bg.elevated` | `#121216` | cards, sheets |
| `bg.elevated2` | `#1A1A20` | nested surfaces, chips |
| `accent.blue` | `#3B82F6` | THE accent: active tab, play states, progress, links |
| `accent.blueBright` | `#60A5FA` | glows, gradients' hot end, "now playing" pulse |
| `accent.blueDeep` | `#1D4ED8` | pressed states, gradient cold end |
| `text.primary` | `#FFFFFF` | headings, titles |
| `text.secondary` | `#9CA3AF` | metadata (event, year, duration) |
| `text.tertiary` | `#5B616E` | hints, placeholders |
| `stroke.subtle` | `#FFFFFF` @ 6% | card borders (1px) |
| `glow.blue` | `#3B82F6` @ 25–35% | soft outer glow on active/playing elements |

Rules: never introduce a second hue; states are expressed with blue intensity + white opacity. Blue on `bg.base` must pass 4.5:1 for text (use `accent.blueBright` for text-sized blue).

### Typography
- **Display / numerals:** SF Pro Rounded or a condensed grotesque — heavy weight, tight tracking, UPPERCASE for the wordmark & year badges.
- **UI text:** SF Pro (Text/Display per size). Dynamic Type mandatory.
- Scale: Hero 34/41 bold · Title 22/28 semibold · Body 17/22 · Meta 13/18 secondary · Badge 11/13 uppercase +4% tracking.

### Shape, depth & spacing
- Radius: cards 20, chips 10, buttons 14, thumbnails 16, mini-player 24 (capsule-ish).
- Spacing grid: 4pt; screen gutters 20; card gap 14.
- Depth recipe per card: 1px `stroke.subtle` border + shadow(black 40%, y 8, blur 24) + inner top highlight (white 4% gradient, top 20%). Playing card adds `glow.blue`.
- Materials: `.ultraThinMaterial` for the tab bar, sheets, and mini-player over content.

---

## 3. 3D & MOTION LANGUAGE (the "wow", done tastefully)

Implement with plain SwiftUI — no SceneKit unless noted. Everything below degrades gracefully under Reduce Motion (falls back to opacity/scale only).

1. **Tilt cards (signature interaction):** set cards respond to press-and-drag with `rotation3DEffect` (max ~6° on x/y around center), scale 1.02, and the blue glow following the tilt direction. Spring: response 0.35, damping 0.8.
2. **Parallax artwork:** inside each card, the thumbnail layer translates 6–10pt opposite to scroll (via `scrollTransition`/`visualEffect`), creating depth between artwork and card frame.
3. **Scroll depth:** cards entering the viewport start at 0.96 scale / 12° x-rotation / 0 opacity and settle upright (`scrollTransition(.interactive)`), like tiles standing up.
4. **Mesh-gradient hero:** the Home hero background is an animated `MeshGradient` (iOS 18+) in deep blues on black, drifting very slowly (60s loop). This is the app's living texture. Fallback: static radial gradient.
5. **Now-playing pulse:** the playing card/mini-player has a slow (2s) breathing blue glow synced to a subtle 1.00→1.01 scale.
6. **3D flip for Save:** tapping the save action flips the heart chip 180° on the y-axis (`rotation3DEffect`), landing filled-blue.
7. **Hero transition:** card → Player uses `matchedGeometryEffect` (or `navigationTransition(.zoom)` on iOS 18) so the artwork grows into the player — one continuous object, no crossfade.
8. **(Optional, one place only)** a Metal/`Shader` audio-reactive-style visualizer behind the Player artwork — abstract blue waves. If it risks the schedule, ship a static layered-blur version first.

Anti-goals: no skeuomorphic 3D objects, no rotating logos, no per-frame physics on lists. If a 3D effect doesn't communicate state or depth, cut it.

---

## 4. SCREEN MAP & LAYOUTS

Navigation: bottom **tab bar** (3 tabs) + persistent **mini-player** docked above it. Tabs: `Library` · `DJs` · `Saved`. Search is a top-bar action on every tab. Player and Set Detail are pushed/zoomed contexts.

### 4.1 Home / Library (default tab)
- Wordmark left (white, heavy), search icon right.
- Hero ~38% height: animated blue mesh on black; eyebrow 11pt uppercase; "Early" white / "Hardstyle" accent.blueBright; one meta line; single blue pill "Play latest".
- Minimal filter chip row (`bg.elevated2`, blue when active).
- 2-col grid of SET CARDS (tilt + parallax): thumbnail 16r, year badge top-left, duration bottom-right on art, title white 17 semibold, event · year secondary 13, max 2 ghost chips.
- Empty state: centered ghost card outline + "No sets yet" + blue text-button.

### 4.2 DJs
- Grid of **DJ cards** (2-col): circular avatar 72pt with a 1px blue ring on press, name white 17, `Netherlands · 2 sets` secondary 13. Tilt interaction identical to set cards.
- Tap → **DJ Detail**: large avatar left-aligned, name as 28pt display, country + set count meta, then a vertical list of that DJ's set cards (full-width row variant).

### 4.3 Saved
- Identical grid to Library but filtered; each card's heart chip is filled blue.
- Empty state is a designed moment: outlined heart with a faint blue mesh behind it, "Nothing saved yet — tap ♥ on any set." Single blue button "Browse Library".

### 4.4 Set Detail (pushed from any card, hero transition)
- Back + heart top row.
- Artwork ~55% width, centered, 20r, parallax vs a blurred copy behind it (blur(40) + scale 1.3 backdrop).
- Title 28 display white; secondary meta line (event, year, duration); ghost chips.
- Full-width blue pill PLAY, 56pt tall.
- Horizontal rail of related sets.

### 4.5 Player (full screen, zoom transition from card/mini-player)
- Drag-down chevron, overflow (queue/share).
- Artwork ~78% width, subtle idle float (±2pt y, 6s) + optional shader waves behind.
- Title 22 semibold; secondary subtitle.
- Progress: 3pt track white@10%, fill blue, draggable knob w/ blue glow; times secondary.
- Controls: 64pt center (white circle, black glyph), 44pt sides (white@70%).
- Save + queue row, quiet icons.
- Required YouTube attribution line at the bottom.
- Player states are first-class UI: buffering = indeterminate blue shimmer on the progress track; error = compact inline card (white text, blue "Retry"); ended = replay glyph. Audio-first presentation, video one tap away.

### 4.6 Queue (sheet over Player)
- `.ultraThinMaterial` sheet, drag indicator, list rows: 48pt art, title, duration; current row has the pulse glow; swipe to remove; drag to reorder. "Autoplay next" toggle at top (blue).

### 4.7 Search (modal from top bar)
- Full-screen cover, huge input (28pt) on black, results grouped: **Sets / DJs / Events** with the same card/row components. Recent searches as ghost chips. Cancel top-right.

---

## 5. COMPONENT INVENTORY (build once in DesignSystem, reuse everywhere)

`SetCardGrid` & `SetCardRow` (tilt+parallax variants) · `DJCard` · `Chip` (ghost / filled-blue) · `YearBadge` · `DurationBadge` · `PillButton` (blue primary / ghost secondary) · `MiniPlayer` · `ProgressBar` (player + inline) · `PulseGlow` modifier · `TiltEffect` modifier · `HeroMesh` background · `EmptyState` (icon + line + action) · `ErrorInline` (message + Retry) · `SectionHeader`.

Every list screen must use `EmptyState`; every network surface must use `ErrorInline`. No one-off styling outside DesignSystem.

---

## 6. ACCESSIBILITY & QUALITY BARS

- Contrast: all text ≥ 4.5:1 on its surface (blue text uses `blueBright`); never blue-on-blue.
- Dynamic Type up to XXL without truncating titles (cards grow vertically); VoiceOver labels on cards read "Set, Showtek, Defqon.1 2007, one hour eight minutes, saved".
- Reduce Motion: tilt/parallax/mesh-drift disabled → simple opacity/scale; hero becomes static gradient.
- Hit targets ≥ 44pt (heart chip included). Haptics: light on tilt-press, success on save, selection on queue reorder.
- 60fps scroll on the grid is a hard requirement — profile with Instruments; parallax must be `visualEffect`-based (no GeometryReader-per-cell).

---

## 7. IMPLEMENTATION NOTES FOR CLAUDE CODE

- Build `feature/design-system` strictly from this file BEFORE feature screens; include a `/StyleguideView` (debug scheme) rendering every component + both motion modes (normal / reduced).
- Tokens as an enum/`Color` asset catalog; no hex literals outside DesignSystem.
- iOS 18 APIs (`MeshGradient`, `navigationTransition(.zoom)`) preferred with documented fallbacks for the minimum target.
- The optional Metal visualizer (3.8) is Extended scope — a separate PR, never blocking the Player MVP.
- Screenshot each screen (light on device frames) for the README once built.

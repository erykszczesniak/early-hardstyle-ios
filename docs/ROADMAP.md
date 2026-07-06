# Roadmap — EarlyHS

> Planned work, in priority order. Each item ships as its own branch + PR.

---

## 1. 🔊 True background & lock-screen playback (the big one)

**Why it doesn't work today:** playback is the official YouTube embed, and background playback of embeds is gated by YouTube itself (Premium feature) — WebKit suspends the video when the app leaves the foreground. Two workarounds were tried and empirically disproven (keep-alive nudge; `webkitSetPresentationMode` PiP — no user gesture in web content, audio dies within seconds). The shipped behaviour is honest: audio survives collapsing the player, pauses in background, auto-resumes on return.

**The real fix — a licensed audio engine behind the existing seam:**

- The architecture is already prepared: `PlayerViewModel`/`PlaybackController` depend on the `YouTubePlayer` protocol (control + events), not on any web view. A second engine slots in without touching a single screen.
- **`AVPlayerAudioEngine`**: `AVPlayer`-based engine conforming to the same protocol, playing **properly licensed audio** — options, in order of realism:
  1. user-imported files (document picker / Files app) — zero licensing risk, "bring your own sets",
  2. royalty-free / CC-licensed hardstyle mixes hosted as plain audio,
  3. a streaming API whose terms permit background playback.
- Once audio is native AVPlayer, the platform gives us the rest legitimately:
  - **lock-screen & Control Center**: `MPNowPlayingInfoCenter` (title/artist/artwork/position) + `MPRemoteCommandCenter` (play/pause/seek/next/prev, headphone controls),
  - background audio just works (the `audio` background mode + `.playback` session are already in place from #35),
  - **AirPlay** for free,
  - optional **Live Activity / Dynamic Island** now-playing.
- Catalogue model: `HardstyleSet` gains an optional `audioSource` (local file URL / stream URL) next to `youtubeID`; the controller picks the engine per set — YouTube sets keep today's behaviour, licensed sets get full background playback.
- Tests: the engine is mockable by construction; add characterization tests mirroring the YouTube engine's (state machine, autoplay chain) + Now Playing info assertions.

**Scope:** ~3 PRs (engine + remote commands/now-playing + import UI). The single most valuable feature both for daily use and as a portfolio piece (AVFoundation + MediaPlayer frameworks, protocol-driven architecture proving its worth).

---

## 2. Recommended features (prioritised)

| # | Feature | Why | Effort |
|---|---------|-----|--------|
| 2.1 | **Resume long sets** — persist per-set playback position, "Continue listening" rail on Home | Sets are 50–70 min; losing your place is the #1 pain in a DJ-set app. We already track progress — persist `setID → seconds` and seek on start. | S |
| 2.2 | **Recently played** — history store + rail, pairs with 2.1 | Cheap once 2.1 exists; makes Home feel alive. | S |
| 2.3 | **Search screen** — full-screen cover, grouped results (Sets / DJs / Events), recent searches as chips | Closes the last designed-but-unbuilt screen. | M |
| 2.4 | **App Intents + deep links** — `earlyhs://set/<id>`, "Play the latest set" Siri/Shortcuts/Spotlight | Modern-iOS portfolio signal; deep links are also the foundation for 2.5. | M |
| 2.5 | **WidgetKit widget** — "Set of the day" / Continue listening on the Home Screen | High visible wow; exercises app groups + shared storage + timeline provider. | M |
| 2.6 | **Sleep timer** — stop playback after N minutes / end of set | Classic music-app nicety; trivial with the playback controller. | S |
| 2.7 | **Event browse** — tap an event chip → all sets from that brand (Defqon.1 page) | Natural catalogue navigation; reuses existing grid + filter machinery. | S |
| 2.8 | **Metal audio-reactive visualizer** behind the player artwork | Extended-scope item — pure portfolio flex (Shaders/Metal). | L |

Suggested order: **2.1 → 2.2** (one arc), then **1** (the big one), then 2.3–2.5.

# Debugging Lab

A small collection of **deliberately introduced, theme-matched bugs**, each paired with a fix — a record of the kind of subtle defects that hide in a catalogue/player app, and how the test suite catches them.

Each bug ships as two PRs:

- a **`lab/broken-*`** branch that introduces the bug (retained, **not** merged — CI is intentionally red because a test catches the defect), and
- a **`lab/fix-*`** branch that fixes it, with the root cause explained.

The point isn't the one-line change — it's that a meaningful unit test turns each of these from a silent runtime bug into a red build.

## Bugs

| Bug | Symptom | Root cause | Caught by | Broken | Fix |
|---|---|---|---|---|---|
| **Reversed catalogue ordering** | The Library leads with the *oldest* sets instead of the newest golden-era ones | `LibraryViewModel.map` sorted ascending (`$0.year < $1.year`) | `LibraryViewModelTests.test_load_success_populatesNewestFirst` | `lab/broken-reverse-ordering` (PR #18) | `lab/fix-reverse-ordering` (PR #17) |
| **Player progress NaN** | The player crashes as it starts, before the video reports its duration | `PlayerViewModel.progress` divided by `duration` with no zero-guard → `0/0 = NaN`, and NaN fed to a SwiftUI frame width crashes | `PlayerViewModelTests.test_progress_withZeroDuration_isNotScrubbable` | `lab/broken-player-progress-nan` (PR #19) | `lab/fix-player-progress-nan` (PR #20) |

## Detail

### Reversed catalogue ordering

The Library's promise is to surface the newest sets of the 1999–2007 era first. A single flipped comparator (`<` instead of `>`) silently inverts the whole grid — no crash, no warning, just wrong. The existing ordering assertion turns it into a red build, which is exactly why the assertion exists.

### Player progress NaN

`currentTime / duration` looks harmless until you remember that the YouTube player reports a duration of `0` for a beat before it's ready. `0 / 0` is `NaN`, `min`/`max` propagate `NaN`, and handing `NaN` to a `frame(width:)` is a hard SwiftUI crash. The `duration > 0` guard makes `progress` a safe `0` until the real duration arrives. The test pins the zero-duration case so the guard can never be dropped unnoticed.

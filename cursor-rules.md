# Important rules you HAVE TO FOLLOW
- Always add debug logs & comments in the code for easier debugging & readability
- Every time you choose to apply a rule(s), explicitly state the rule(s) in the output. You can abbreviate the rule description to a single word or phrase.
- Do not make any changes until you have 95% confidence that you know what to build. Ask me follow-up questions until you reach that confidence.

# Project structure
- All files go inside /adhd-todo
- The main Swift file is adhd_todoApp.swift
- Organize files into these folders:
  - /Models — SwiftData model definitions (Task.swift, Category.swift)
  - /Views — All SwiftUI screens (TodayView.swift, HistoryView.swift, RecapView.swift)
  - /ViewModels — Observable view model classes
  - /Components — Reusable UI pieces (TaskRow.swift, CategoryPill.swift, StreakBadge.swift, ProgressBar.swift, ConfettiCanvas.swift, AllDoneCard.swift, MilestoneCard.swift)
  - /Helpers — Utility functions (DateHelpers.swift, StreakCalculator.swift, RecapCalculator.swift)

# Tech Stack
- SwiftUI for all UI (fall back to UIKit only if absolutely necessary and explain why in a comment)
- Swift for all code and logic
- iOS 17+ only
- SwiftData for local on-device persistence — no backend, no login, no cloud sync
- Space Grotesk custom font (embed .ttf files in the Xcode project — do NOT use a system font as a substitute)
- Custom SwiftUI Canvas confetti (do NOT use ConfettiSwiftUI package — implement it directly, see Section 3)
- RevenueCat for monetization — scaffold only, do not implement in v1
- TelemetryDeck for analytics — scaffold only, do not implement in v1

# Design System

## 1. Color Tokens
Use these exact hex values throughout the app. Define them as a Swift extension on `Color` in a file called `Colors.swift` so they are reusable everywhere.

```swift
// Brand colors
Color.violet    = #7B2FFF   // Primary — buttons, active tabs, progress bar, checkboxes
Color.fuchsia   = #E040FB   // Accent — category: Creative, gradient endpoint on completion
Color.pink      = #FF3399   // Category: Social, gradient midpoint
Color.yellow    = #FFCC00   // Streak 14+ days, milestone card background

// Category colors (main dot / border / text)
Color.catWork       = #7B2FFF,  light bg: #EDE8FF
Color.catHealth     = #00C875,  light bg: #E0FFF3
Color.catHome       = #FF6B00,  light bg: #FFE8D6
Color.catGroceries  = #E8A800,  light bg: #FFF5CC
Color.catSocial     = #FF3399,  light bg: #FFE0EF
Color.catCreative   = #E040FB,  light bg: #F8E0FF
Color.catOther      = #6B7280,  light bg: #F3F4F6

// Surface colors (light mode)
Color.appBackground = #F5F5F7   // App background — NOT pure white
Color.cardSurface   = #FFFFFF   // Task cards, form background
Color.tabBar        = gray-200  // Tab bar pill background (#E5E7EB equivalent)
Color.inputBg       = #EDEDF0   // Input fields

// Text colors
Color.textPrimary   = #0F0F0F   // Main text
Color.textMuted     = #6B7280   // Secondary text, inactive tabs
Color.textDisabled  = #9CA3AF   // Completed task text, date chips
Color.border        = rgba(0,0,0,0.08)  // Subtle borders

// Dark mode: use .dark variants for background, card, and text — refer to theme.css values
```

## 2. Typography
- **Font family:** Space Grotesk, embedded as a custom font. Add all weights: Light (300), Regular (400), Medium (500), SemiBold (600), Bold (700).
- **Do not use SF Pro or any system font** — the design specifically uses Space Grotesk.
- Font size base: 16pt. Scale using SwiftUI's built-in text styles but apply Space Grotesk at each size.
- Key type styles used in the design:
  - Screen title ("Today", "History", "Recap"): 30pt Bold
  - Date subtitle below title: 12pt Medium, `textDisabled` color
  - Task text (incomplete): 14pt Medium, `textPrimary`
  - Task text (complete): 14pt Regular, `textDisabled`
  - Category badge: 12pt SemiBold
  - Progress label: 12pt SemiBold, `textMuted`
  - Section header ("By category"): 12pt Bold, uppercase, letter-spacing 0.1em
  - Streak number: 20pt Bold
  - Summary card value: 24pt Bold

## 3. Confetti (Custom Canvas)
Do NOT use any external package. Implement a SwiftUI `TimelineView` + `Canvas` confetti view that matches the Figma design exactly:
- 180 particles, each with random position, velocity, angle, rotation speed, shape (60% rect, 40% circle), and opacity
- Colors: `[#7B2FFF, #E040FB, #FF3399, #FFCC00, #FF6B00, #00C875, #111111, #CC00FF]`
- Particles start above the screen (y = -30 to -170) and fall with gravity (vy += 0.1 per frame), horizontal drag (vx *= 0.993)
- Opacity starts fading after 100 frames, decrement 0.016 per frame
- Animation stops automatically when all particles reach opacity ≤ 0
- The canvas must be full-screen, fixed/overlay (`.ignoresSafeArea()`), non-interactive (`.allowsHitTesting(false)`), z-index above everything
- Guard: only launch if today's list has ≥ 1 task and all are completed. Use a `prevAllDone` ref to prevent re-triggering on toggle

## 4. Animations
Match the Framer Motion values from the Figma design as closely as possible in SwiftUI:
- **Task row entry:** `opacity 0→1, offset y +10→0`, spring stiffness 360 / damping 30. Use `.transition(.opacity.combined(with: .move(edge: .bottom)))` with `.spring(response: 0.25, dampingFraction: 0.75)`.
- **Task row exit:** `opacity 0, offset x -30`, duration 0.15s ease. Use `.transition(.asymmetric(insertion: ..., removal: .opacity.combined(with: .offset(x: -30))))`.
- **Checkbox tap:** scale 0.72 on tap (use `scaleEffect` + `onLongPressGesture` or `buttonStyle`). Checkmark path draws from `trimFrom: 0 / trimTo: 0` to `trimTo: 1`, duration 0.22s easeOut.
- **Strikethrough sweep:** animate a `Rectangle` overlay width from 0 to full text width, 0.25s easeOut.
- **Progress bar fill:** animate width 0→percentage, 0.45s easeOut.
- **Category bar fill (Recap):** animate width 0→percentage, 0.7s easeOut, staggered delay of 0.04s per row.
- **View transitions (tab switching):** `opacity + offset y 8→0`, duration 0.15s, use `AnimatePresence`-equivalent (SwiftUI `id`-keyed view swapping with `.transition`).
- **Streak badge entry:** spring stiffness 400, damping 22, scale 0.85→1 with opacity 0→1.
- **All Done card:** `opacity 0, offset y +12→0`, delay 0.12s.
- **Milestone card:** spring stiffness 320, damping 22, scale 0.9→1, delay 0.3s.

## 5. Navigation — TabView
Use SwiftUI `TabView` with 3 tabs:
- Tab 1: Today (SF Symbol `checkmark.square` or custom equivalent)
- Tab 2: History (SF Symbol `calendar`)
- Tab 3: Recap (SF Symbol `chart.bar`)

Do NOT use `NavigationStack` or push navigation between the three main screens. They are coordinate tabs, not a hierarchy.

The tab bar uses a pill/segment style matching the Figma design — NOT the default iOS tab bar at the bottom. Implement it as a custom segmented control in the header area (above the content, inside a `VStack`) rather than as a native iOS tab bar. Style it as a rounded rectangle (`bg: tabBar color`, active tab: white background with shadow, active text: `violet`, inactive text: `textMuted`).

## 6. Task Row Component
Each task row (`TaskRow.swift`) must match the Figma design exactly:
- White card background, `cornerRadius: 12`, `shadow: 0 1px 4px rgba(0,0,0,0.05)`
- Left border: `3pt wide`, color = category color (when incomplete) or `#E5E7EB` (when complete)
- Circle checkbox: `24×24pt`, border `2pt`. Filled with category color when complete. Unfilled with `#D1D5DB` border when incomplete.
- Task text: right of checkbox, `flex 1`, 14pt (see Section 2 typography)
- Category badge: right side, small pill with category light-bg color and category color text (12pt SemiBold). Grays out when complete.
- Delete: on iOS, use swipe-to-delete (`.onDelete` modifier or `swipeActions`). Do NOT use a hover-reveal button (that's web behavior).
- Row padding: `horizontal: 16pt, vertical: 16pt`
- `gap` between elements: `16pt`

## 7. Add Task Form (Inline, NOT a Sheet)
The add task form is NOT a `.sheet` or modal. It expands inline within the `ScrollView` of the Today screen:
- Triggered by an "Add task" button row at the bottom of the task list (Plus icon + "Add task" text, gray, full width)
- When expanded: a white card appears in place of the button (same position in the list), `cornerRadius: 12`, `outline: 2pt solid violet`
- Form content: text field at top ("What needs doing?" placeholder), then a wrapping row of 7 category pill buttons, then a row with "Add task" (primary, violet) and "Cancel" (secondary, gray) buttons
- Auto-focus the text field when the form expands
- Category pills: selected = category color bg + white text; unselected = light bg + category color text
- "Add task" button: disabled + opacity 0.3 when text is empty
- On submit (button tap or Enter key): save task, collapse form, clear text field
- Animate the form expansion: `opacity 0, offset y -8 → opacity 1, y 0`, 0.15s

## 8. Progress Bar Component
- Only shown on Today screen when `todayTasks.count > 0`
- Row above bar: left side "X of Y done" (12pt SemiBold, `textMuted`), right side percentage % (12pt Bold, `violet`) — or "Complete" badge (white text on violet pill) when 100%
- Bar: height 10pt, `cornerRadius: 5pt`, gray background (`#E5E7EB`), animated fill
- Fill gradient: `violet → pink` normally; `violet → fuchsia` when 100%
- Animate fill width with `animation(.easeOut(duration: 0.45))`

## 9. Streak Badge Component
Reusable `StreakBadge.swift` component, used in the header of all 3 screens:
- Flame icon (SF Symbol `flame.fill`) + number + "day"/"days" label
- Color tier based on streak count:
  - 1–3 days: `#FF3399` (pink)
  - 4–6 days: `#E040FB` (fuchsia)
  - 7–13 days: `#7B2FFF` (violet)
  - 14+ days: `#FFCC00` (yellow)
  - 0 days: `#9CA3AF` (gray)
- Background: `streakColor` at 8% opacity
- Border: `streakColor` at 19% opacity, `1.5pt`
- Padding: `horizontal: 14pt, vertical: 10pt`, `cornerRadius: 16pt`
- Animate badge with spring when streak value changes (scale 0.85→1, opacity 0→1)

## 10. Streak Calculation
Implement `StreakCalculator.swift` as a pure function (no side effects):
- Walk backwards from today (up to 90 days)
- If a day has 0 tasks: skip it (do not break the streak, do not count it)
- If a day has tasks and ALL are complete: increment streak, continue
- **Today** with any incomplete tasks: skip (do not break, do not count) — in-progress day must not lower the badge
- **Past days** with any incomplete tasks: stop, return current streak (that day is finished)
- Streak for today counts only when today's tasks are all complete
- This must be unit-tested (see Section 7)

## 11. History Screen
- Default date on open: yesterday
- Arrow buttons: `40×40pt`, white card, `cornerRadius: 12pt`, `shadow: 0 1px 3px rgba(0,0,0,0.08)`
- Right arrow is disabled (opacity 0.3) when the next day would be today or in the future
- Date chips row: horizontally scrollable, `scrollIndicators: .hidden`, shows last 20 days that have at least 1 task
- Chip: shows `fmtShort` date (e.g., "May 20") and completion ratio (e.g., "3/5") in a smaller line. Selected: violet bg + white text. Complete & unselected: violet border + violet text. Default: white bg + gray text.
- Task list below chips is fully read-only — no toggling, no swipe-to-delete, no "Done Later"
- Show a progress bar for the selected day using the same `ProgressBar` component (but in read-only/display mode)

## 12. Recap Screen
- Summary cards: 3 cards in a horizontal grid, each `cornerRadius: 12pt`
  - Total Tasks: white bg, black value
  - Done: `#E0FFF3` bg, `#00C875` value
  - Rate %: `#EDE8FF` bg, `violet` value
- Streak card: shown only if streak > 0. Uses `streakColor`, flame icon, "X-day streak" title, subtitle "Keep completing your daily tasks to grow it."
- Category section header: "BY CATEGORY" in 12pt Bold uppercase, `textMuted` color, `letter-spacing: 0.1em`
- Each category row: color dot (10×10pt circle) + label left; task count + percentage right; animated bar below
- Insight card at bottom: soft gradient (`violet 4% + fuchsia 4%`), `border: 1.5pt solid violet 12%`. Text names top 1–2 categories using their category color inline.
- Month/year toggle uses the same pill-style as the main tab bar. Active state: `violet` bg + white text.

## 13. Dark Mode
Support both light and dark mode using SwiftUI's `colorScheme` environment. Map the CSS dark mode tokens from the Figma design:
- Background: near-black (`oklch(0.145 0 0)` ≈ `#1A1A1A`)
- Cards: same near-black (no separate card color in dark mode)
- Text: near-white (`#F9F9F9`)
- Muted text: `oklch(0.708 0 0)` ≈ `#A8A8A8`
- Borders: `oklch(0.269 0 0)` ≈ `#3A3A3A`
- Primary (violet) lightens to near-white in dark mode for text, but category colors remain the same

Use `@Environment(\.colorScheme)` to conditionally apply dark variants, OR define `Color` assets in the asset catalog with light/dark variants.

## 14. SwiftData Rules
- Define all models in /Models using the `@Model` macro
- Always use `@Query` in views to observe model changes reactively
- Initialize a single `ModelContainer` at the app entry point (`adhd_todoApp.swift`) and share via `@Environment(\.modelContext)`
- The storage key concept from the web app maps to SwiftData: all tasks are stored with their date as a property (YYYY-MM-DD string), not grouped into separate containers

## 15. State Management
- Annotate view models with `@Observable`, e.g. `@Observable final class TodayViewModel`
- Do not use `@State` for view model observation in SwiftUI views — use `let model: MyModel`
- Use `@Environment` for the SwiftData modelContext and app-level state
- Use `@State` only for local view state (e.g., `showAddForm`, `selectedCategory`)
- Use a `prevAllDone` boolean ref (stored in the view model) to guard confetti from re-triggering

## 16. General Coding Rules
- Always prefer simple solutions
- Avoid duplication of code — check for existing similar code before writing new code
- Only make changes that are explicitly requested or directly related to the request
- When fixing a bug, exhaust existing implementation options before introducing new patterns. If you do introduce a new pattern, remove the old implementation.
- Keep the codebase clean and organized
- Avoid files over 200–300 lines — refactor at that point
- Mocking data is only for tests — never mock data for dev or prod
- Never overwrite my .env file without confirming first
- Account for dev, test, and prod environments in all code

## 17. Testing
- Write unit tests for all helpers and calculators, especially:
  - `StreakCalculator` — test all cases: all done, partial, empty days, 0 streak, 30-day streak
  - `RecapCalculator` — test category percentages, month vs year filtering
  - Date helpers — `offsetDay`, `todayKey`, day-change detection
- Write UI tests for the 3 critical flows:
  1. Add a task → check it off → confetti fires (Today screen)
  2. Add multiple tasks → check all off → all-done card + streak increments
  3. Recap screen shows correct category percentages after completing tasks
- Use Preview providers for every view and component

## 18. No Modules
Do not create extra Swift packages or modules. Keep all files in the same Xcode target and project.

## 19. ADHD-Friendly UI Rules
- Never show more than one expanded form or overlay at a time
- Every empty state must show a friendly message — no blank white screens
- Error feedback must be gentle: use a shake animation on the input, not a red error label
- The confetti (F-004) must only fire once per completion event — never on an empty list
- History is always 100% read-only — no editing, no toggling, no deleting
- The recap screen must never include the current in-progress day's data
- Do not use red for errors — use amber or the existing muted gray palette
- Completed tasks should visually recede (gray text, gray border) rather than disappear abruptly

# ADHD Focus List — Requirements Document
*(Updated to match Figma design)*

## 1. App Overview

This is a simple, calming to-do list app made for people with ADHD. Every day starts with a fresh, blank list — no stress from yesterday's unfinished tasks. You add what you want to get done today, check each task off with a satisfying animation, and when you finish everything, the app throws confetti to celebrate. A streak counter tracks how many days in a row you've completed your full list, adding a gentle motivational layer. You can look back at previous days' lists using arrow navigation, and browse a horizontal row of past-day chips. At the end of each month or year, the app shows a recap: a breakdown of completed tasks by category shown as animated horizontal bars, plus a short insight sentence. The app is iOS only, works fully offline, and stores everything on the device.

---

## 2. Main Goals

1. Give users a clean, distraction-free space to plan their day.
2. Make checking off tasks feel rewarding and visually satisfying.
3. Show a streak to build momentum without creating pressure.
4. Let users look back at past days without guilt.
5. Show helpful stats about what kinds of tasks the user completes most.
6. Keep everything simple — no complicated settings or menus.

---

## 3. User Stories

- **US-001** — As a user, I want to see a fresh, empty list when I open the app on a new day, so I don't feel overwhelmed by yesterday's tasks.
- **US-002** — As a user, I want to add a task with a title and a category using an inline form, so I can quickly capture what I need to do without leaving the screen.
- **US-003** — As a user, I want to tap a task checkbox to check it off with a satisfying animation, so completing tasks feels rewarding.
- **US-004** — As a user, I want to see confetti when I complete my entire list for the day, so I feel celebrated.
- **US-005** — As a user, I want to see my current daily streak with a flame icon, so I feel motivated to keep going.
- **US-006** — As a user, I want to get a special message at streak milestones (3, 7, 14, 30 days), so I feel recognized for my progress.
- **US-007** — As a user, I want to browse past days using left/right arrows and tappable date chips, so I can review my previous work easily.
- **US-008** — As a user, I want to see a monthly recap with category breakdown bars and an insight sentence, so I can understand my habits.
- **US-009** — As a user, I want to see a yearly recap with the same breakdown, so I can see my big-picture patterns.
- **US-010** — As a user, I want to swipe a task to delete it, so I can remove mistakes quickly.
- **US-011** — As a user, I want to see a progress bar on today's screen showing how much of my list I've finished, so I feel a sense of momentum.
- **US-012** — As a user, I want to see an "All done" celebration card after completing my list, so the app acknowledges my achievement even after the confetti ends.

---

## 4. Features

**F-001 — Daily Clean Slate**
- What it does: Every day, the app starts with an empty to-do list. Tasks from the previous day do NOT carry over automatically.
- When it appears: Every time the user opens the app on a new calendar day.
- If something goes wrong: If the app cannot detect the new day, show the last known day's list. No automatic reset until the day is confirmed.

**F-002 — Add a Task (Inline Form)**
- What it does: Tapping the "Add task" button at the bottom of the Today screen expands an inline form directly in the list. The form has a text field ("What needs doing?"), a row of 7 category pills, and Add/Cancel buttons. Pressing Enter on the keyboard also submits. The form closes after saving.
- When it appears: Today screen only. There is no separate sheet or modal — it expands in place.
- If something goes wrong: The Add button stays disabled and the form does not submit if the text field is empty.

**F-003 — Check Off a Task (Satisfying Tick)**
- What it does: Tapping the circular checkbox marks the task as complete. The circle fills with the category color. A white checkmark path draws itself from left to right (path animation). A strikethrough line sweeps across the task text from left to right. The task text turns gray and gets lighter font weight. The category badge turns gray.
- When it appears: Today screen (interactive). History screen (display-only, no tapping).
- If something goes wrong: If the animation fails, still mark the task done visually.

**F-004 — Confetti Celebration**
- What it does: When the last task on today's list is checked off, a full-screen canvas-based confetti animation plays. 180 particles (mix of small rectangles and circles) fall from above in the brand colors. They fade out naturally as they fall off-screen. There is no timer — the animation ends when all particles have faded.
- When it appears: Today screen only, only when ALL tasks are completed and the list has at least 1 task. Does not re-trigger if the user unchecks and re-checks a task.
- If something goes wrong: If the canvas cannot render, skip the animation silently — do not crash.

**F-005 — Swipe to Delete**
- What it does: On the Today screen, swiping left on a task reveals a delete button. Tapping it removes the task immediately. There is no confirmation alert for delete (the gesture is intentional enough).
- When it appears: Today screen only. History is fully read-only.
- If something goes wrong: If the swipe gesture fails, no action is taken.

**F-006 — Progress Bar**
- What it does: When today's list has at least one task, a horizontal progress bar appears in the header below the date. It shows "X of Y done" on the left and the current percentage on the right. The bar animates smoothly as tasks are checked off. When all tasks are done, the bar changes from a violet→pink gradient to a violet→fuchsia gradient and the percentage is replaced with a "Complete" badge.
- When it appears: Today screen only, only when there is at least one task.
- If something goes wrong: If the count is wrong, clamp it between 0 and the total task count.

**F-007 — Streak Counter**
- What it does: A flame icon badge in the top-right corner of the header shows the current daily streak (number of consecutive days where all tasks were completed). Days with no tasks at all are skipped without breaking the streak. An in-progress today (tasks added but not all done yet) does not reduce the streak; only a finished past day with incomplete tasks breaks it. The flame color changes based on the streak level: pink for 1–3 days, fuchsia for 4–6 days, violet for 7–13 days, yellow/gold for 14+ days. The badge is visible on all three screens (Today, History, Recap).
- When it appears: Always in the header. Shows 0 if no streak.
- If something goes wrong: If streak cannot be calculated, show 0.

**F-008 — Streak Milestone Messages**
- What it does: On the Today screen, after completing all tasks, if the streak hits exactly 3, 7, 14, or 30 days, a yellow milestone card appears below the "All done" card with a short congratulation message. Messages: "3-day streak — building momentum.", "One full week. Seriously impressive.", "Two weeks straight. This is a habit now.", "30 days. You are unstoppable."
- When it appears: Today screen only, after all tasks are done, at the exact milestone numbers.
- If something goes wrong: If the streak count is unavailable, skip the milestone card.

**F-009 — "All Done" Celebration Card**
- What it does: After completing all tasks today, a soft gradient card appears below the task list (below the Add Task button area) saying "Done. All of it." with the count of tasks completed. If there is a streak, it shows the streak number with a flame icon inside the card.
- When it appears: Today screen only, when all tasks are checked off and there is at least one task.
- If something goes wrong: If the card cannot render, skip it — the confetti celebration is sufficient.

**F-010 — History Screen with Arrow Navigation**
- What it does: The History screen lets users browse past days using left/right chevron arrow buttons. Below the arrows, a horizontally scrollable row of date chips shows the last 20 days that had any tasks. Each chip shows the date (e.g., "May 20") and a completion ratio (e.g., "3/5"). Tapping a chip jumps to that day. The selected chip is highlighted in violet. Fully completed days have a violet border. The task list below is read-only — no toggling, no deleting, no "Done Later" option.
- When it appears: History screen.
- If something goes wrong: If no past data exists, show an empty state message: "Nothing here. Try another day."

**F-011 — Recap Screen**
- What it does: Shows stats for the current month (default) or the full year. A toggle switches between month name and year number. Three summary cards show total tasks added, total completed, and completion rate percentage. A streak card appears if the streak is greater than 0. Below that, a "By category" section shows each category as an animated horizontal bar with its percentage. At the bottom, an insight sentence names the top 1–2 categories: e.g., "45% of your completed tasks were work, followed by health at 20%."
- When it appears: Recap screen.
- If something goes wrong: If there is no data for the period, show an empty state: "No data yet. Start adding tasks to see your recap."

---

## 5. Screens

**S-001 — Today Screen** *(Tab 1 — default on launch)*
- What's on it: A "Today" title and the current date in small text. A streak badge (flame icon + number) in the top right. A progress bar below the date when tasks exist. A 3-tab navigation bar (Today, History, Recap). The list of today's tasks. An inline "Add task" form that expands in place when tapped. An "All done" card and optional milestone message when all tasks are complete.
- How you get there: This is Tab 1. App opens here by default.

**S-002 — History Screen** *(Tab 2)*
- What's on it: "History" title and streak badge. Left/right arrow buttons to navigate by day. The selected day's full date in the center. A horizontally scrollable row of date chips (last 20 days with tasks). A progress bar for the selected day. A read-only task list for the selected day.
- How you get there: Tap the History tab in the tab bar.

**S-003 — Recap Screen** *(Tab 3)*
- What's on it: "Recap" title and streak badge. A month/year toggle. Three summary cards (Tasks, Done, Rate). A streak card if streak > 0. A "By category" section with animated horizontal bar rows. An insight sentence at the bottom.
- How you get there: Tap the Recap tab in the tab bar.

*(Note: There is no separate Add Task sheet — the add form is inline within S-001.)*

---

## 6. Data

**D-001 — Task**
Each task has: a unique ID, a title (text the user typed), a category (from D-002), the date the task belongs to (YYYY-MM-DD), and whether it is completed (yes or no).
*(No "Done Later" field — history is read-only and tasks cannot be retroactively updated.)*

**D-002 — Category**
Seven fixed categories, each with a color and a light background color:
- **Work** — color: `#7B2FFF`, light: `#EDE8FF`
- **Health** — color: `#00C875`, light: `#E0FFF3`
- **Home** — color: `#FF6B00`, light: `#FFE8D6`
- **Groceries** — color: `#E8A800`, light: `#FFF5CC`
- **Social** — color: `#FF3399`, light: `#FFE0EF`
- **Creative** — color: `#E040FB`, light: `#F8E0FF`
- **Other** — color: `#6B7280`, light: `#F3F4F6`

Categories are a hardcoded enum — users cannot create custom categories in v1.

**D-003 — App Storage**
All tasks are stored locally in a single dictionary keyed by date string (YYYY-MM-DD). The streak is calculated at runtime by walking backwards through the stored dates. No separate summary table is needed in v1.

---

## 7. Extra Details

- **Internet:** Not needed. The app works fully offline.
- **Storage:** All data is saved on the device using SwiftData. No account or login required.
- **Permissions:** No special iPhone permissions needed.
- **Notifications:** Not in v1.
- **Dark mode:** Must support both light and dark mode. (See Section 13 of cursor-rules for dark mode token values.)
- **Accessibility:** Must support Dynamic Type for larger text sizes.
- **Minimum iOS version:** iOS 17.
- **Font:** Space Grotesk (embed as a custom font in the Xcode project).
- **Animations:** Checkpoint animations under 0.25–0.3s. Progress bar 0.45s. Confetti runs until all particles fade naturally.
- **Tab bar:** Use SwiftUI `TabView` with 3 tabs. No sidebar, no NavigationStack between main views.

---

## 8. Build Steps

- **B-001** — Verify that the Xcode project is set up with SwiftUI and SwiftData. Add Space Grotesk font files. Add ConfettiCanvas (custom SwiftUI view — see cursor-rules Section 3). Create folder structure.
- **B-002** — Define the Category enum (D-002) with all 7 values, colors, and light colors. Define the Task model (D-001) with SwiftData `@Model`.
- **B-003** — Build the TabView shell for S-001, S-002, S-003 with placeholder content and correct tab icons (CheckSquare, Calendar, BarChart2 from SF Symbols equivalents).
- **B-004** — Build S-001 Today Screen with a static list. Add the date header, streak badge placeholder, and progress bar.
- **B-005** — Connect S-001 to SwiftData so tasks load and save. Implement the daily clean slate logic (F-001) — detect a new day using stored "last opened date."
- **B-006** — Build F-002 (inline add form) with text field, 7 category pills, and Add/Cancel buttons. Auto-focus the text field when it expands.
- **B-007** — Build F-003 (satisfying tick animation): circle fill, checkmark path draw, strikethrough sweep, text color fade.
- **B-008** — Build F-004 (custom confetti): SwiftUI Canvas view with 180 particles, brand colors, natural fade-out. Trigger on last task completion.
- **B-009** — Build F-006 (progress bar) with animated fill and gradient. Show "Complete" badge and gradient change when all done.
- **B-010** — Build F-007 (streak counter): calculate streak by walking backwards through task data. Add streak badge to all screen headers with color-tier logic.
- **B-011** — Build F-009 (All Done card) with gradient background and streak display. Add F-008 (milestone messages) for 3/7/14/30-day milestones.
- **B-012** — Build F-005 (swipe to delete) on Today screen task rows.
- **B-013** — Build S-002 (History Screen): arrow navigation, date chips row, read-only task list, progress bar for selected day.
- **B-014** — Build S-003 (Recap Screen): summary cards, category bar chart rows with animations, insight sentence, month/year toggle.
- **B-015** — Test all screens in light and dark mode. Verify Dynamic Type, streak edge cases (no tasks days, streak breaks), and confetti does not re-trigger.
- **B-016** — Final end-to-end test: add tasks → check off → confetti + all-done card → streak increments → history shows the day → recap shows correct percentages.

## 9. Future Builds (add after B-016 is complete)

**F-012 — Schedule a Task for a Future Date**
- What it does: In the add task form (F-002), an optional "Scheduled for" field defaults to today. Tapping it opens a date picker — only today and future dates are selectable. Tasks scheduled for a future date do NOT appear on the Today screen until that day arrives. In the History/Days screen (S-002), the right arrow is now unlocked for future dates too. Future days with scheduled tasks appear as chips in the date row alongside past days. Future days are fully editable (add and delete tasks), unlike past days which remain read-only. Streak and Recap are unaffected — future tasks are ignored by both.
- When it appears: Add form (date field), History screen (right arrow unlocked, future chips).
- If something goes wrong: If the date picker fails, default to today silently.

**F-013 — Recurring Tasks (opt-in)**
- What it does: In the add task form, an optional "Repeat" toggle (off by default — this is opt-in, never opt-out). When turned on, a recurrence picker appears with options: Daily, Weekly (same day of the week), or Custom (pick specific days of the week, e.g. Mon / Wed / Fri). On save, the task is stored as a recurring template with a recurrence rule. The app auto-generates individual task instances for the next 60 days based on the rule, stored as normal tasks so they appear on the correct day's list. Each instance is independent — completing one day does not complete others. The user can delete a single instance (just that day) or all future instances (long-press → "Delete all upcoming"). Recurring tasks show a small repeat icon on their task row so they are visually distinct.
- When it appears: Add form only (the repeat toggle). The resulting tasks appear as normal tasks on their scheduled days.
- If something goes wrong: If generation fails, save the task for today only and show a gentle message: "Couldn't set up repeat — task saved for today."

- **B-017** — Update the Task model (D-001) to add two optional fields: `scheduledDate` (Date, defaults to today) and `recurrenceRule` (enum: none / daily / weekly / custom days). Update SwiftData schema accordingly.
- **B-018** — Add the "Scheduled for" date picker to the add form (F-012). Unlock the right arrow in S-002 for future dates. Make future days editable in S-002. Verify today's screen is unaffected.
- **B-019** — Build the recurring task system (F-013): add the Repeat toggle and recurrence picker to the add form. Write a `RecurrenceGenerator` helper that creates task instances for the next 60 days. Add the repeat icon to `TaskRow`. Implement single-instance delete and "delete all upcoming" via long-press menu.
- **B-020** — Test scheduling and recurrence: schedule a task for tomorrow → does not appear today, appears tomorrow ✓. Create a daily recurring task → appears on each day for 60 days ✓. Delete one instance → others unaffected ✓. Delete all upcoming → clears future instances only ✓. Recap and streak ignore future tasks ✓.

**F-014 — Month/Year Jump in History**
- What it does: In the History screen (S-002), add a tappable date label between the two arrows (where the full date currently shows). Tapping it opens a two-step picker: first pick a year, then pick a month. On confirm, the screen jumps directly to the first day of that month that has any tasks. If no tasks exist for that month, it lands on the 1st of the month and shows the empty state. This replaces having to tap the left arrow hundreds of times to go back.
- When it appears: History screen, as an upgrade to the existing date header.
- If something goes wrong: If no data exists for the selected month/year, show the empty state ("Nothing here. Try another day.") — do not crash or show a blank screen.

- **B-021** — Add the month/year jump picker to S-002 (F-014). Make the date label between the arrows tappable. Build the two-step year → month picker sheet. On confirm, find the most recent day with tasks in that month and navigate to it, or fall back to the 1st. Keep the existing arrow navigation working unchanged.
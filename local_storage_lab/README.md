# In-Class 08 - Local Storage: Fall Festival Roster

**Name:** Swami Reddy Ailuri (Sai) | **Pathway:** Graduate | **Date:** 2026-10-06

## Submission status (honest note)
The full app (Add/Edit/Delete/Refresh, validation, init pattern, ID-based targeting) is complete and was run on an Android emulator. T1, T2 and T3 (save) were run and observed. T4 screenshots are included, but see the note on T4. T5 and T6 and the `flutter analyze` output were NOT completed or recorded before upload; they are marked "not recorded" below. No result is listed that I did not observe.

## Environment
- Flutter version: FILL IN (first line of `flutter --version`)
- Device: Android Emulator, Medium_Phone (emulator-5554)
- Packages (unchanged from supplied sample): sqflite ^2.4.1, path_provider ^2.1.5, path ^1.9.0
- AI assistance disclosure: Claude (Anthropic) generated the app code and this README draft; I ran the app and collected the screenshots myself.

## Files
- `lib/database_helper.dart` - helper. Schema: `my_table(_id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER NOT NULL)`; `queryAllRows()` orders by `_id ASC`.
- `lib/main.dart` - init pattern plus one-screen roster: one form reused for Add/Edit, Delete with confirmation, Refresh, count, busy flag, validation (trimmed non-empty name, `int.tryParse` age 0-130).
- `evidence/` - screenshots.

## Test results
Format: test | action/input | expected | observed rows/count | pass/fail

| Test | Action / input | Expected | Observed | Result |
|---|---|---|---|---|
| T1 | Open fresh app / Refresh | Count 0, empty-state message | "Guests: 0", "No festival guests yet. Add the first one above!" | Pass |
| T2 | Add River 21, River 34 | Count 2, distinct IDs | A = ID 1 (River, 21), B = ID 2 (River, 34); count 2 | Pass |
| T3 | Edit B to 99 then Cancel; Edit B, save 35 | Cancel leaves 34; save returns 1, A stays 21, B becomes 35 | Save: "Updated ID 2: 1 row affected."; ID 1 age 21, ID 2 age 35; count 2. The cancel step was not captured in a screenshot. | Pass (save); cancel not recorded |
| T4 | Stop app, force-stop, relaunch without clearing data | Same IDs/names/ages/count | Before and after screenshots both show ID 1 age 21, ID 2 age 35, count 2. Method used: FILL IN (e.g. "Ctrl+C, Force stop in App info, flutter run again, pressed Refresh"). | Pass only if the method above is accurate |
| T5 | Cancel delete A; confirm delete A; Refresh | Cancel: count 2; confirm: 1 row, only B left | Not recorded | Not recorded |
| T6 | Invalid inputs (space-only name; Maple with abc, 1.5, -1, 131); valid Acorn 0, Oak 130 | Rejected with feedback; final count 3 | Not recorded | Not recorded |

Screenshots in `evidence/`: `T4_before.png`, `T4_after.png`. `T6_invalid.png` and `analysis_output.txt` not recorded.

## Reflection prompts

**1. The disappearing-data mystery.**
Prediction (before T4): both River records (ID 1 age 21, ID 2 age 35, count 2) will survive an app restart, because insert and update wrote rows to the SQLite file `MyDatabase.db` in the documents directory, while screen state in memory is rebuilt by a new process. Path in my code: `main()` awaits `helper.init()`, which opens the existing file (`onCreate` runs only for a new database); then `RosterScreen.initState()` calls `_initialLoad()`, which calls `_loadRows()`, which awaits `queryAllRows()` and `queryRowCount()` and calls `setState` to draw the list. Evidence: `T4_before.png` and `T4_after.png` both show IDs 1 and 2 with ages 21 and 35 and count 2. What would disprove it: after relaunch the list is empty, ages differ, or new rows restart IDs at 1, which would mean the data was only in memory or the database was recreated.

**2. Two Rivers, one wrong edit.**
Both guests have the name "River", so the name or list position cannot identify a row safely. Edit stores the tapped row's integer `_id` (`_selectedId`) and `update()` runs `WHERE _id = ?`. When I changed ID 2 from 34 to 35, the app reported 1 row affected and ID 1 stayed at 21. An update by name would have changed both Rivers.

**3. Usability walkthrough.**
The form, count and feedback message are all visible at the top, and the feedback text says the ID and affected rows, which helped me confirm I changed the right guest. The Edit and Delete buttons sit next to each other, so a mis-tap on Delete is possible (the confirmation dialog protects against it). Small improvement I would add: show the destructive Delete button in a different style and keep the newest feedback message visually distinct. I did not implement it.

**4. Defend the storage boundary (graduate).**
- Validation boundary: I validate in the UI (trimmed non-empty name, `int.tryParse` age between 0 and 130) because `NOT NULL` in the schema only rejects missing values and still accepts an empty string or -1. UI validation gives field-level feedback but only protects this screen; a `CHECK(age BETWEEN 0 AND 130)` constraint or validation inside the helper would protect every code path.
- Schema-change risk: `onCreate` runs only when the database file is first created. If I add a column by editing the CREATE statement, existing installs keep the old table and queries using the new column fail with "no such column". The fix is to raise `version` and add an `onUpgrade` migration (for example `ALTER TABLE ... ADD COLUMN`); not implemented, per the lab scope.

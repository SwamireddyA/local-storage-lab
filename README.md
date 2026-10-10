# In-Class Activity 09 — Local Storage, Part II

**Student:** Swamireddy Ailuri  
**Student ID:** 003044424  
**Pathway:** Graduate  
**Project:** `local_storage_lab`

## Overview
Flutter/SQLite app extending Part I with folders and cards. The folder screen shows card counts; opening a folder lists cards filtered by folder ID. The UI supports folder creation/deletion and card create/edit/delete, confirmation dialogs, empty states, and an image fallback.

## Setup
```powershell
flutter pub get
flutter analyze
flutter run -d emulator-5554
```
Automated test command: `flutter test --reporter expanded`. Record the actual result; do not claim a pass if it hangs or fails.

## Database and migration
- Database: `MyDatabase.db`, version 2.
- Existing Part I table retained: `my_table` (`_id`, `name`, `age`).
- New `folders` table: `id`, `name`, `created_at`.
- New `cards` table: `id`, `title`, `suit`, `notes`, nullable `image_ref`, `folder_id`.
- `cards.folder_id` references `folders.id` with `ON DELETE CASCADE`; index on `cards(folder_id)`.
- Foreign keys enabled in `onConfigure` using `PRAGMA foreign_keys = ON`.
- Fresh `onCreate` creates the old and new tables. Upgrade from v1 to v2 creates only the new tables and index, preserving the existing `my_table` rows.
- The database filename remains unchanged to upgrade the installed database.

## Feature summary
| Feature | Implementation |
|---|---|
| Folder list and counts | `getFoldersWithCounts()` |
| Cards by folder ID | `getCards(folderId)` |
| Create/delete folder | `insertFolder()`, `deleteFolder()` |
| Add/edit/delete card | `insertCard()`, `updateCard()`, `deleteCard()` |
| Empty states | Folder and card screens |
| Image fallback | Placeholder for missing, malformed, or unavailable image |
| Part I data | Original table and CRUD methods retained |

## Manual tests T1–T6
Fill actual IDs/counts from your run. Do not invent values.
| Test | Procedure | Result/evidence |
|---|---|---|
| T1 Upgrade preservation | Compare `my_table` count/IDs before and after upgrade. | Student reports old records existed before UI replacement. Before count: **[enter actual]**; after count: **[enter actual]**. `evidence/T1_before.png` |
| T2 Parent/child | Create folder and card; confirm count and folder-specific listing. | Student reports workflow works. Folder ID **[actual]**; card ID **[actual]**. `evidence/T2_cards.png` |
| T3 Edit/cancel | Cancel edit, then save edit; verify same card ID and no change on cancel. | Card ID/result: **[enter actual]** |
| T4 Persistence | Restart app and verify folder/card remain. | Student reports persistence works. `evidence/T4_after.png` |
| T5 Delete | Delete card and delete a folder with child cards; verify cascade. | Student reports deletion works. IDs/counts: **[enter actual]** |
| T6 Invalid/image | Try blank title and null/broken image; verify no invalid write and fallback. | Student reports checks work. Inputs used: **[enter actual]** |

## Evidence directory
Add these actual files inside `evidence/`:
- `T1_before.png` — Part I data before upgrade, if captured.
- `T2_cards.png` — folder/card screen.
- `T4_after.png` — screen after restart.
- `analysis_output.txt` — actual `flutter analyze` output.

Do not fabricate screenshots or output. If T1 was not captured before migration, state that limitation.

## Release APK
```powershell
flutter build apk --release
```
Expected path: `build/app/outputs/flutter-apk/app-release.apk`. Install and smoke-test the release APK.

## Known limitations
- Suit/category is currently free text, not a dropdown restricting supported suit values.
- A separate typed model/repository layer has not been implemented; the helper uses typed method parameters and row maps.
- Enter actual test IDs/counts and add evidence files before submission.
- The widget test previously stalled at its test name; do not claim it passed unless rerun successfully.

## Submission checklist
- [ ] Commit README and dependency files.
- [ ] Add available evidence screenshots and `analysis_output.txt`.
- [ ] `github_link.txt` contains the real GitHub URL.
- [ ] Build and smoke-test release APK; use the exact naming format required by iCollege.
- [ ] Save this reflection as `Ailuri_Swamireddy_CriticalThinking.docx` if consistent with the instructor's lastname-firstname format.
- [ ] Verify all three required iCollege uploads.

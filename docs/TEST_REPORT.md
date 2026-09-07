# PRESENZA — VERIFICATION & TEST REPORT

**Product:** Presenza (Flutter QR Attendance & Campus Community Platform)  
**Test Suite:** `test/widget_test.dart`  
**Analyzer Command:** `flutter analyze`  
**Test Runner Command:** `flutter test`  
**Date:** September 7, 2026  
**Auditor:** Antigravity AI Engineering  

---

## 1. Test Execution Summary

| Metric | Result | Status |
|---|---|---|
| **Static Code Analysis** | 0 warnings, 0 errors, 0 lints | **PASS** |
| **Total Automated Tests** | 19 tests executed | **PASS** |
| **Tests Passed** | 19 | **100% PASS** |
| **Tests Failed** | 0 | **0** |
| **Tests Skipped** | 0 | **0** |
| **Execution Duration** | ~5.2 seconds | **OPTIMAL** |

---

## 2. Test Suite Breakdown

### 2.1 SubjectAttendance Model Tests & Edge Cases
- **Test 1: Calculates attendance percentage accurately**  
  *Status:* **PASS**  
  *Assertion:* 15 present out of 20 classes yields exactly $75.0\%$. Correctly flags `isBelowThreshold(75.0)` as `false` and `isBelowThreshold(80.0)` as `true`.
- **Test 2: Calculates classes needed to reach threshold**  
  *Status:* **PASS**  
  *Assertion:* 5 present out of 10 classes requires 10 consecutive attended classes to reach $75\%$.
- **Test 3: Calculates classes can miss before dropping below threshold**  
  *Status:* **PASS**  
  *Assertion:* 10 present out of 10 classes permits missing 3 classes before falling below $75\%$.
- **Test 4: getStatusMessage handles 0 classes cleanly without confusing messages**  
  *Status:* **PASS**  
  *Assertion:* Returns `"No classes conducted yet"` without division by zero or negative metrics.
- **Test 5: getStatusMessage handles 100% attendance and buffer classes**  
  *Status:* **PASS**  
  *Assertion:* 8/8 attended returns `"Can miss 2 more classes"`.
- **Test 6: getStatusMessage handles at-risk attendance correctly**  
  *Status:* **PASS**  
  *Assertion:* 5/10 attended returns `"Need 10 classes to reach 75%"`.

### 2.2 User Profile & Academic Defaults Tests
- **Test 7: UserModel initials extraction**  
  *Status:* **PASS**  
  *Assertion:* `"Mayank Bajpai"` correctly resolves to `'MB'`.
- **Test 8: AcademicDefaults 30 degree programs catalogue**  
  *Status:* **PASS**  
  *Assertion:* All 30 academic degrees contain valid departments, course IDs, and categories.
- **Test 9: Deterministic batch generation and synthetic batch helper**  
  *Status:* **PASS**  
  *Assertion:* Accurately builds cohorts (e.g., `batch-2024-a`) with correct start and graduation dates.

### 2.3 Attendance Session Lifecycle & Rich Serialization
- **Test 10: Correctly identifies expired sessions**  
  *Status:* **PASS**  
  *Assertion:* Sessions where `endTime < DateTime.now()` report `isExpired == true`.
- **Test 11: Serializes session with rich metadata**  
  *Status:* **PASS**  
  *Assertion:* JSON serialization preserves `subjectName`, `room`, and `teacherName`.
- **Test 12: ActivityPostModel reaction & bookmark serialization**  
  *Status:* **PASS**  
  *Assertion:* Preserves reactive state arrays and counts across serialization rounds.
- **Test 13: AppTheme light and dark mode initialize with valid color schemes**  
  *Status:* **PASS**  
  *Assertion:* Validates Material 3 color schemes, contrast tokens, and surface colors.

### 2.4 Widget & Responsive UI Tests
- **Test 14: RegisterScreen course & section selection**  
  *Status:* **PASS**  
  *Assertion:* Correctly selects Course, Year 2026, Section D without widget tree exceptions.
- **Test 15: TeacherAttendanceTab narrow viewport rendering (360x800)**  
  *Status:* **PASS**  
  *Assertion:* Renders Course, Batch, Section, Room, QR Expiry chips, and GPS switch without overflows.
- **Test 16: TeacherAttendanceTab ultra-narrow screen rendering (320x600)**  
  *Status:* **PASS**  
  *Assertion:* Renders cleanly on ultra-narrow 320px viewport without RenderFlex overflows.

### 2.5 Session Status, Expiry Clamping & Idempotency Tests
- **Test 17: AttendanceSessionStatus flags correctly determine accepting state**  
  *Status:* **PASS**  
  *Assertion:* `active.isAcceptingAttendance == true`, `expired.isAcceptingAttendance == false`, `closed.isAcceptingAttendance == false`. `active.displayName == 'Live'`.
- **Test 18: AttendanceSessionModel accurately reports expiry and clamps remaining duration to zero**  
  *Status:* **PASS**  
  *Assertion:* Expired sessions clamp `remainingSeconds` to `0` and `remainingDuration` to `Duration.zero` rather than yielding negative values.
- **Test 19: Deterministic record ID guarantees idempotency format**  
  *Status:* **PASS**  
  *Assertion:* Concatenating `sessionId` and `studentUid` yields format `${sessionId}_$studentUid`, ensuring atomic transaction uniqueness.

---

## 3. Verification Command Outputs

### 3.1 Static Analysis Output
```
$ flutter analyze
Analyzing presenza...
No issues found! (ran in 20.0s)
Exit Code: 0
```

### 3.2 Automated Test Runner Output
```
$ flutter test
00:05 +19: All tests passed!
Exit Code: 0
```

# Presenza V2 — SIH25011 Implementation Plan & Architecture Specification

**Project**: Presenza (Smart Curriculum Activity & Attendance App)  
**Problem Statement**: SIH25011 — Government of Punjab (Smart Education)  
**Target Branch**: `feature/presenza-v2`  
**Base Production Branch**: `main` (Preserved stable)  
**Firebase Project**: `presenza-9115c`  

---

## 1. System Overview & Objectives
Presenza is designed as a secure, production-ready solution for SIH25011. Rather than being a simple QR attendance demo, it unifies:
1. **Smart Attendance Verification** (QR code + GPS location geofencing + Firestore atomic transaction verification).
2. **Curriculum & Academic Management** (Subjects, credits, courses, semesters, batches/sections).
3. **Academic Activities & Events Hub** (Distinguishing official institutional announcements from student-organized club/hackathon/study group activities).
4. **Academic & Attendance Insights** (Replacing generic empty leaderboards with student attendance health, streaks, at-risk warnings, and milestones).
5. **Teacher Live Session Management** (Real-time roster counting: present, absent, rate, live attendee feed, session countdown).
6. **Platform & Database Security** (Android `FLAG_SECURE` screenshot/recording prevention, robust role-based Firestore security rules, sanitized logging).
7. **Production SaaS Mobile UI** (Un-truncated bottom navigation, responsive glassmorphism, 5-second student dashboard hierarchy, elegant empty and loading states).

---

## 2. Pre-Implementation Safety Report

| Metric | Status |
| :--- | :--- |
| **Current Branch** | `feature/presenza-v2` |
| **Production Branch** | `main` (Untouched, sync with `origin/main`) |
| **Base Commit** | `1f67fa6` (*Production Firebase hardening, registration flow, index-free queries, and Vercel/APK build optimizations*) |
| **Working Tree** | Clean, 0 uncommitted changes |
| **Firebase Project** | `presenza-9115c` |
| **Database Safety** | Zero destructive changes; additive collections & backward-compatible document fields |

---

## 3. Detailed Component Architecture & Changes

### 3.1 Attendance Context & Mathematical Precision
- **Context Details**:
  - Each attendance record / session detail displays: Subject Name, Subject Code, Teacher, Class/Batch, Date, Start/End time, Present/Absent/Late status, and Verification Method (QR / Geofenced).
- **Mathematical Edge Cases**:
  - Prevent confusing "0 classes" or "Need 0 classes to pass" when no classes have occurred yet (`totalClasses == 0`).
  - `classesNeededForThreshold(75.0)`: Formula `((0.75 * total - present - late) / 0.25).ceil()` with safety bounds.
  - `classesCanMiss(75.0)`: Formula `((present + late) / 0.75 - total).floor()` with safety bounds.
- **Student Session History**:
  - Detailed list view of attended/missed classes per subject with real timestamps.

### 3.2 Teacher Subject Management & Flexible Session Creator
- **Subject Management**:
  - Teachers can select from assigned subjects or create a new subject (Name, Code, Semester, Credits, Course) on demand.
  - New subjects are persisted in Firestore `/subjects/` and linked to the teacher profile (`subjectIds`).
- **Session Creator**:
  - Teacher selects Subject, Batch/Section, Duration (minutes), and optional Location/Room.
  - Generates secure session document in Firestore `/sessions/` with ISO timestamps.

### 3.3 Real-Time Teacher Attendance Monitoring
- **Live Roster Counts**:
  - Compares scanned students in `/attendance_records` against total students enrolled in the selected `/batches/{batchId}`.
  - Real-time updates: Present, Absent, Attendance Percentage.
- **Attendee Roster**:
  - Real-time stream of verified students with check-in timestamp and verification badges.
- **Session Control**:
  - Live countdown timer, automatic expiry, and immediate "Close Session" button.

### 3.4 QR Attendance Security & Transactions
- **Scan Flow**:
  - Camera opening does NOT mark attendance.
  - Attendance requires: valid QR decoding -> session lookup -> active status -> non-expired check -> student course/batch eligibility check -> atomic duplicate check -> transaction write.
- **Atomicity**:
  - Handled via `FirestoreService.markAttendanceWithTransaction` using Firestore `runTransaction`.
- **Manual Code Entry**:
  - Evaluated against identical server transaction rules.

### 3.5 Academic Insights (Replacing Leaderboard)
- **Attendance Insights**:
  - Overall attendance percentage across all enrolled subjects.
  - Highest & Lowest attendance subjects (Highlighting subjects < 75%).
  - Streak & Consistency tracker.
  - Achievement & Milestone badges (e.g. "Perfect Record", "75%+ Safe Zone", "5-Day Streak", "Activity Champion").
- **Real Data**:
  - Computed purely from student's Firestore attendance records.

### 3.6 Academic Activities & Events System
- **Models**:
  - `ActivityModel` / `EventModel` supporting scope (`official` vs `studentCreated`), categories (`assignment`, `exam`, `workshop`, `seminar`, `hackathon`, `club`, `studyGroup`, `holiday`, `department`), date/time, location, organizer, attachment, creator role.
- **Teacher/Admin Experience**:
  - Create official academic notices, exam announcements, department workshops.
  - Edit/archive author's own notices.
- **Student Experience**:
  - Create student activities (Club event, study group, hackathon).
  - Clear visual badges: `OFFICIAL ACADEMIC` vs `STUDENT CREATED`.
- **Upcoming Events**:
  - Chronological schedule cards with a full detail sheet/dialog.

### 3.7 Platform Security & Android Screenshot Protection
- **Android `FLAG_SECURE`**:
  - Implemented via MethodChannel in `MainActivity.kt` (`presenza/security`) to prevent screenshots and screen recording on sensitive screens (Profile, QR Scanner, Student ID, Teacher Live Session).
  - Dart `SecurityService` to enable/disable protection per screen lifecycle.
- **Logging**:
  - Clean debug output with zero sensitive credentials or tokens.

### 3.8 Firestore Security Rules Hardening
- Strengthen `firestore.rules` for:
  - Role-based authorization.
  - Preventing students from modifying other users' attendance.
  - Enforcing author restrictions on activities and circulars.

### 3.9 UI/UX Redesign & Navigation Refinements
- **Bottom Navigation**:
  - Fix truncated labels.
  - Student: `Home`, `Attendance`, `Activities`, `Insights`, `Profile`
  - Teacher: `Home`, `Sessions`, `Activities`, `Students`, `Profile`
  - Admin: `Analytics`, `Policies`, `Users`, `Audit`, `Profile`
- **Dashboard**:
  - 5-second hierarchy: Greeting, Overall %, Today's Classes, Quick Action Buttons, Attendance Alert Banner, Upcoming Activities.

---

## 4. Git Commit Strategy (10 Logical Commits)

1. `chore: create Presenza v2 development branch`
2. `feat: improve attendance session context and mathematical edge-case handling`
3. `feat: add teacher subject management and dynamic session creator`
4. `feat: improve teacher live attendance monitoring and roster dashboard`
5. `feat: replace leaderboard with real-time academic insights and milestones`
6. `feat: expand circulars into academic activities and student events hub`
7. `security: add Android FLAG_SECURE platform screenshot protection`
8. `security: harden Firestore security rules and role authorization`
9. `ui: refine mobile experience, navigation labels, and empty/loading states`
10. `test: add Presenza v2 unit and widget regression tests`

---

## 5. Verification & Testing

- Run `flutter test` for all mathematical calculations, models, and widget behaviors.
- Perform static analysis with `dart analyze`.
- Verify student, teacher, and admin workflows interactively.

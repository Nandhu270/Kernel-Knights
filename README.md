# Lab Record Book (iOS)

A modern, role-based academic Lab Record Book iOS application built with **Swift 5.9+**, **SwiftUI**, and the **Observation** framework (`@Observable`).

Designed following pure **MVVM** architecture, dependency injection, and in-memory state simulation for single-device demonstration without third-party dependencies.

---

## 🚀 Key Features

### 1. Role-Based Authentication & Navigation
- Predefined accounts for **Administrator**, **Mentor**, and **Student**.
- Dynamic routing via `AppCoordinator`.
- Deactivated user protection preventing unauthorized login attempts.

### 2. Department Management & Multi-Stage Mapping
- **Department Administration**: View, search, add, and manage academic departments (e.g. CSE, IT, EEE, ECE, MECH, CIVIL, AI&DS).
- **Dropdown Selection**: Mentors and students select from officially registered departments.
- **Two-Stage Mentor Assignment**: Administrators select the mentor's department first, dynamically filtering available mentors within that department.

### 3. Comprehensive Filtering Across All Portals
- **Admin**:
  - *User Management*: Filter by Department, Role (Students/Mentors), Status (Active/Inactive), and Search.
  - *Mentor Assignments*: Filter unassigned/assigned students by Department.
  - *All Experiments*: Filter by Department, Student, Subject, and Status.
  - *Audit History*: Filter verification logs by Department, Status (Verified/Rejected), and keyword search.
- **Mentor**:
  - *My Students*: Filter supervised students by Department, Progress (Pending Review, Needs Revision, Completed), and Account Status.
  - *Review Queue*: Filter submitted student experiments by Department, Student, and Subject.
  - *Assigned Experiments*: Filter assignments by Department, Student, and Lifecycle Status.
  - *Assign Experiment*: Filter recipients by Department with one-tap "Select Filtered" action.
- **Student**:
  - Filter experiments by Subject, Lifecycle Status, and Search query.

### 4. Academic Experiment Lifecycle
- **Drafting & CRUD**: Create, edit, and delete draft experiments.
- **Mentor Assignment**: Mentors author master templates and assign them to students with submission deadlines.
- **Submission & Verification**:
  - Students submit experiments to their assigned mentor.
  - Mentors verify/approve or reject with mandatory constructive feedback.
  - Locked state prevents modifying submitted or approved experiments.
  - Resubmission workflow for corrected experiments.
  - Comprehensive immutable verification audit history.

---

## 🛠 Tech Stack & Architecture

- **Language**: Swift 5.9 / Swift 6
- **UI Framework**: SwiftUI (iOS 17+)
- **Architecture**: Model-View-ViewModel (MVVM)
- **State Management**: `@Observable` via Apple Observation framework
- **Data Layer**: In-memory `AppDataStore` single source of truth
- **Testing**: Native modular test suites

---

## 📱 Running the Project

1. Clone the repository:
   ```bash
   git clone <your-repo-url>
   cd "Kernel Knights"
   ```
2. Open **`LabRecordBook.xcodeproj`** in Xcode (Xcode 15+ recommended).
3. Ensure the active scheme is set to **`LabRecordBook`** and destination is an iOS 17+ Simulator (e.g. **iPhone 18 Pro**).
4. Press **`Cmd + R`** to Run or **`Cmd + B`** to Build.

---

## 🔐 Demo Credentials

| Role | Username | Password | Department |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin` | `admin123` | Academic Office |
| **Mentor** | `dr.smith` | `mentor123` | Computer Science & Engineering |
| **Mentor** | `prof.alan` | `mentor123` | Information Technology |
| **Student** | `john.doe` | `student123` | Computer Science & Engineering |
| **Student** | `jane.smith` | `student123` | Computer Science & Engineering |
| **Student** | `alex.jones` | `student123` | Information Technology |
| **Inactive** | `inactive.user` | `pass123` | Computer Science & Engineering |

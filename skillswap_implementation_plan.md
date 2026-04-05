# SkillSwap Core Implementation Plan

This document outlines the focused implementation plan for the missing core functionalities required for a complete skill-exchange workflow in the SkillSwap Flutter app. It is designed to be realistic, minimal, and suitable for a college-level project.

---

## 1. Upgrade State Management (Provider/Riverpod)
**Purpose:** Replace localized `setState` scattered across the app with a clean, scalable state management solution (e.g., Riverpod or Provider) to handle user state, skills, and requests globally.

**Required UI Changes:**
- Remove deep widget tree parameter passing.
- Replace `StatefulWidget` loops with reactive consumers (`ConsumerWidget` for Riverpod or `Consumer` for Provider).

**Required Backend/Data Structure:**
- No database changes.
- Create global providers (e.g., `userProvider`, `skillsProvider`, `requestsProvider`) in `lib/core/providers/`.

**Step-by-Step Implementation:**
1. Add `flutter_riverpod` or `provider` to `pubspec.yaml`.
2. Wrap the root `MaterialApp` in `ProviderScope` (or `MultiProvider`).
3. Create an `AuthNotifier` to stream and manage the Firebase Auth state natively without manual `setState` listeners.
4. Refactor `LoginScreen`, `RegisterScreen`, and `HomeScreen` to consume the new auth state.

---

## 2. Proper Firestore Database Structure
**Purpose:** Establish an organized, queryable NoSQL schema for users, their offered skills, and skill requests.

**Required UI Changes:**
- None immediately (backend-centric task).

**Required Backend/Data Structure:**
- **Collections:**
  - `users/{userId}`: `{ name, email, createdAt, fcmToken }`
  - `skills/{skillId}`: `{ userId, title, category, description, level, location }`
  - `requests/{requestId}`: `{ senderId, targetSkillId, status ('pending', 'accepted', 'rejected'), createdAt, message }`

**Step-by-Step Implementation:**
1. Define clear Dart models (`UserModel`, `SkillModel`, `SkillRequestModel`) matching the schema.
2. Add `toMap()` and `fromMap()` serialization methods to all models.
3. Update `FirestoreService` with generic CRUD functions for these specific paths.

---

## 3. Functional "My Skills" Screen
**Purpose:** Allow the user to add, edit, and delete the skills they are offering to the community independently of the generic feed.

**Required UI Changes:**
- A new screen `MySkillsScreen` accessible via bottom navigation or a drawer.
- A list showing currently offered skills.
- A Floating Action Button opening a "Create Skill" modal/screen with inputs for Title, Category, Description, and Skill Level.

**Required Backend/Data Structure:**
- Uses the `skills` collection. Write access for the current `userId`.

**Step-by-Step Implementation:**
1. Build a `MySkillsScreen` utilizing a provider/stream to listen to `skills` where `userId == currentUser.uid`.
2. Implement an `AddSkillForm` inside a bottom sheet or new page for users to input skill details.
3. Hook the form submission to `FirestoreService.addSkill()`.
4. Add basic swipe-to-delete functionality for users to remove their skills.

---

## 4. Skill Request System
**Purpose:** Enable users to actively request an exchange when they find an interesting skill offered by someone else on the map or feed.

**Required UI Changes:**
- Add a "Request Exchange" button to the `PostCard` or Map `InfoWindow`.
- A simple popup dialog allowing the requester to write a short message.

**Required Backend/Data Structure:**
- Creates documents in the `requests` collection with `status: 'pending'`.

**Step-by-Step Implementation:**
1. In the UI where other users' skills are listed, bind a "Request" CTA.
2. Present a dialog taking an optional message string.
3. On submit, call `FirestoreService.sendRequest(targetSkillId, targetUserId, message)`.
4. Update UI to show the button as "Requested" disabled state.

---

## 5. Request Approval Flow (Accept/Reject)
**Purpose:** Provide the targeted user the ability to review incoming requests and either accept or reject the exchange.

**Required UI Changes:**
- A new `RequestsScreen` or tab showing incoming and outgoing requests.
- Cards showing requester details, message, and "Accept" / "Reject" buttons.
- Simple status badges ("Pending", "Accepted").

**Required Backend/Data Structure:**
- Updates the `status` field on the specific document in the `requests` collection.

**Step-by-Step Implementation:**
1. Create a `RequestsScreen` that listens to two queries: incoming (where target == currentUser) and outgoing (where sender == currentUser).
2. Wire the "Accept" and "Reject" buttons to a function `FirestoreService.updateRequestStatus(requestId, status)`.
3. Visually alter the card when a request resolves (e.g., transition from action buttons to a "Chat Now" or "Email" button on accept).

---

## 6. Skill Matching Logic (Indirect/Direct)
**Purpose:** Automatically connect or suggest users when their mutual "wanted" and "offered" skills align.

**Required UI Changes:**
- A "Matches" tab or a persistent carousel on the `HomeScreen` showing suggested users.

**Required Backend/Data Structure:**
- Extend user profiles to include `wantedSkills: [String]`.
- Logic on the client to cross-reference lists.

**Step-by-Step Implementation:**
1. Update registration/profile setup to allow users to declare `wantedCategories` or `wantedSkills`.
2. In the State Provider, write a specialized query/getter that fetches `skills` offered by others matching the current user's `wantedSkills`.
3. Display these high-affinity results prominently on the Home Screen.

---

## 7. Data Flow from Firestore to UI (Realtime sync)
**Purpose:** Ensure state always reflects reality (if a request is accepted, it immediately shows as accepted without reloading).

**Required UI Changes:**
- None locally, rely entirely on Providers handling Streams.

**Required Backend/Data Structure:**
- Firestore Realtime Streams (`snapshots()`).

**Step-by-Step Implementation:**
1. Setup `StreamProvider` (Riverpod) or `StreamBuilder` wrappers around core Firebase queries (`getUserSkillsStream()`, `getRequestsStream()`).
2. Bind UI lists directly to these streams so any backend changes magically rewrite the local UI seamlessly.

---

## 8. Minimal User Interaction / Notifications
**Purpose:** Notify a user natively when they receive a new request or when a request is accepted.

**Required UI Changes:**
- A notification badge or icon on the `Requests` tab.
- System snackbars triggered on state change.

**Required Backend/Data Structure:**
- Use the existing `NotificationService` and Firebase Cloud Messaging (FCM).

**Step-by-Step Implementation:**
1. When `FirestoreService.sendRequest()` is called, add a trigger (or write to a `notifications` collection) to execute a scheduled local notification or use the pre-built `showLocalNotification`.
2. Use a Firestore listener for incoming `requests` that fires a local push alert (e.g., "Someone wants to learn X from you!") using the existing `flutter_local_notifications` setup.

---

## 9. Session Persistence & Guarded Navigation
**Purpose:** Keep the user logged in across app restarts and prevent unauthenticated access to core features.

**Required UI Changes:**
- Initial splash/loading screen while checking auth state.

**Required Backend/Data Structure:**
- Firebase Auth instance native cache.

**Step-by-Step Implementation:**
1. Use Auth Stream (`FirebaseAuth.instance.authStateChanges()`) to determine the root widget of the `MaterialApp` (`MainNavigationScreen` vs `LoginScreen`).
2. Remove any manual manual persistent login logic; Firebase handles the token storage securely by default.

---

## 10. Form Validation Improvements
**Purpose:** Enforce secure and accurate data entry on login, registration, and skill creation forms.

**Required UI Changes:**
- Red inline text for errors under `TextField` elements.

**Required Backend/Data Structure:**
- Local client-side evaluation.

**Step-by-Step Implementation:**
1. Wrap all inputs inside a Flutter `Form` widget utilizing `TextFormField`.
2. Provide simple `validator:` closures to ensure non-empty inputs, valid email formats (regex), and minimum password lengths (6 chars).
3. Move away from triggering standalone error Snackbars for invalid inputs in favor of native red-bordered form feedback.

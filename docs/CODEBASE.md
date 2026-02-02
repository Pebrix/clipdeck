# Clipdeck Codebase Overview

A macOS menu bar clipboard manager that tracks copied text, lets you pin favorites, search, and edit clips.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  clipdeckApp (App entry)                                        │
│  ├── MenuBarExtra (scissors icon)                               │
│  │   └── ContentView (main popover UI)                          │
│  └── AppDelegate (hides from Dock)                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  ClipdeckStore (@EnvironmentObject)                             │
│  ├── clips: [Clip]                                              │
│  ├── editingClipID: UUID?                                        │
│  ├── Pasteboard monitoring (NSPasteboard)                       │
│  └── UserDefaults persistence (pinned clips)                    │
└─────────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐
│  ContentView    │  │  SettingsView   │  │  SettingsWindow     │
│  (popover)      │  │  (preferences)  │  │  Controller (NSPanel)│
└─────────────────┘  └─────────────────┘  └─────────────────────┘
```

---

## File Structure

| File | Purpose |
|------|---------|
| `clipdeckApp.swift` | App entry point, `MenuBarExtra`, AppDelegate for Dock hiding |
| `ContentView.swift` | Main UI: header, search, clip list, footer actions |
| `ClipdeckStore.swift` | State, pasteboard monitoring, persistence, clip CRUD |
| `SettingsView.swift` | Preferences UI (trim spaces toggle) |
| `SettingsWindowController.swift` | Manages floating NSPanel for settings |

---

## Data Model

### `Clip` (ContentView.swift)

```swift
struct Clip: Identifiable, Equatable, Codable {
    let id: UUID
    var text: String
    var isPinned: Bool
    var dateAdded: Date
}
```

- **Identifiable** – Used by `ForEach(clip in clips)`.
- **Equatable** – For comparisons and diffing.
- **Codable** – For JSON encode/decode to `UserDefaults`.

---

## Data Flow

### Clipboard → Store

1. `ClipdeckStore` starts a `Timer` (1s interval) in `startPasteboardMonitoring()`.
2. Compares `NSPasteboard.general.changeCount` with `lastKnownChangeCount`.
3. On change, reads string from pasteboard and calls `checkPasteboardForNewContent()`.
4. Skips empty/whitespace-only text and duplicates of the most recent clip.
5. Uses `DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)` before `addClip()` to avoid layout recursion.

### Store → UI

- `ClipdeckStore` conforms to `ObservableObject` with `@Published` properties.
- `ContentView` uses `@EnvironmentObject private var store: ClipdeckStore`.
- Changes to `clips` and `editingClipID` trigger view updates.

### Persistence

- **Pinned clips** – Saved to `UserDefaults` under `clipdeck.pinnedClips`.
- **Save** – Triggered by `clips.didSet`, debounced with `DispatchWorkItem` (0.5s).
- **Load** – On init in `loadPinnedClips()`.
- **Recent clips** – In-memory only, capped at 50.

---

## Key Components

### ContentView

- **Header** – Title, settings button, pinned/recent counts.
- **Search** – Filters clips by text (case-insensitive).
- **Clip list** – `ScrollView` + `LazyVStack` (avoids `List` preview issues on macOS).
- **Clip row** – Click to copy, pin/unpin, edit, delete.
- **Footer** – Add sample, Clear Unpinned, Quit.

### ClipdeckStore

- **`binding(for: clip)`** – Returns a `Binding<Clip>` for editing in place.
- **`copyToPasteboard(_:)`** – Copies text and updates `lastKnownChangeCount` to avoid re-adding.
- **`addClip(text:isPinned:)`** – Applies trim setting, inserts clip, trims recent list if needed.

### Settings

- **SettingsView** – Uses `@AppStorage("clipdeck.trimSpaces")` for the trim toggle.
- **SettingsWindowController** – Creates a floating `NSPanel` so settings stay open while using the popover.

---

## Platform Handling

- `#if canImport(AppKit)` – macOS-only code (pasteboard, NSApp, NSPanel).
- App runs on macOS; iOS/iPadOS paths are stubbed where needed.

---

## Conventions

- **MARK** – Sections like `// MARK: - Header` for navigation.
- **Private helpers** – `filteredClips`, `sortClips`, `addDummyClip`, etc.
- **Button styles** – `.plain` / `.borderless` for icon buttons.
- **Accessibility** – `.help("…")` on icon-only buttons.

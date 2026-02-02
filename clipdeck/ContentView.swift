//
//  ContentView.swift
//  clipdeck
//
//  Created by Anupam Srivastava on 02/02/26.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

// A simple model representing a clipboard item
struct Clip: Identifiable, Equatable, Codable {
    let id: UUID
    var text: String
    var isPinned: Bool
    var dateAdded: Date

    init(id: UUID = UUID(), text: String, isPinned: Bool = false, dateAdded: Date = .now) {
        self.id = id
        self.text = text
        self.isPinned = isPinned
        self.dateAdded = dateAdded
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: ClipdeckStore
    @State private var searchText: String = ""
    #if canImport(AppKit)
    private let settingsController = SettingsWindowController()
    #endif

    var body: some View {
        VStack(spacing: 8) {
            header
            searchField
            clipList
            footer
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Header
    private var header: some View {
        let pinnedCount = store.clips.filter { $0.isPinned }.count
        let recentCount = store.clips.count - pinnedCount
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("Clipdeck", systemImage: "scissors")
                    .font(.headline)
                Spacer()
                Button {
                    #if canImport(AppKit)
                    settingsController.show()
                    #endif
                } label: {
                    Image(systemName: "gearshape")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            Text("Pinned: \(pinnedCount) · Recent: \(recentCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Search
    private var searchField: some View {
        TextField("Search clips…", text: $searchText)
            .textFieldStyle(.roundedBorder)
    }

    // MARK: - List
    // Using ScrollView instead of List to avoid OutlineListCoordinator crash on macOS
    private var clipList: some View {
        let filtered = filteredClips(from: store.clips)
        let pinned = filtered.filter { $0.isPinned }
        let recent = filtered.filter { !$0.isPinned }

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                sectionHeader("Pinned")
                if pinned.isEmpty {
                    Text("No pinned clips")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                } else {
                    ForEach(pinned) { clip in
                        clipRow(clip)
                        Divider()
                    }
                }

                sectionHeader("Recent")
                    .padding(.top, 12)
                if recent.isEmpty {
                    Text("No recent clips")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                } else {
                    ForEach(recent) { clip in
                        clipRow(clip)
                        Divider()
                    }
                }
            }
            .padding(.trailing, 12)
        }
        .scrollIndicators(.hidden)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }

    // MARK: - Footer actions
    private var footer: some View {
        HStack {
            Button {
                addDummyClip()
            } label: {
                Label("Add", systemImage: "plus")
            }

            Button(role: .destructive) {
                store.clearUnpinned()
            } label: {
                Label("Clear Unpinned", systemImage: "trash")
            }
            .disabled(store.clips.allSatisfy { $0.isPinned })

            Spacer()

            Button {
                quitApp()
            } label: {
                Label("Quit", systemImage: "power")
            }
        }
    }

    // MARK: - Row
    private func clipRow(_ clip: Clip) -> some View {
        HStack(spacing: 8) {
            if store.editingClipID == clip.id {
                TextField("Edit clip", text: store.binding(for: clip).text)
                    .textFieldStyle(.roundedBorder)
            } else {
                Button {
                    store.copyToPasteboard(clip.text)
                } label: {
                    Text(clip.text)
                        .font(.body)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                Button {
                    store.togglePin(clip)
                } label: {
                    Image(systemName: clip.isPinned ? "pin.slash.fill" : "pin")
                }
                .buttonStyle(.borderless)
                .help(clip.isPinned ? "Unpin" : "Pin")

                if store.editingClipID == clip.id {
                    Button {
                        store.editingClipID = nil
                    } label: {
                        Image(systemName: "checkmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .help("Done")
                } else {
                    Button {
                        store.editingClipID = clip.id
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)
                    .help("Edit")
                }

                Button(role: .destructive) {
                    store.delete(clip)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete")
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers
    private func filteredClips(from clips: [Clip]) -> [Clip] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return clips.sorted(by: sortClips) }
        return clips.filter { $0.text.localizedCaseInsensitiveContains(trimmed) }
            .sorted(by: sortClips)
    }

    private func sortClips(_ a: Clip, _ b: Clip) -> Bool {
        if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
        return a.dateAdded > b.dateAdded
    }

    private func addDummyClip() {
        let samples = [
            "New sample clip",
            "Lorem ipsum dolor sit amet",
            "https://developer.apple.com",
            "The quick brown fox jumps over the lazy dog"
        ]
        if let text = samples.randomElement() {
            store.addClip(text: text, isPinned: false)
        }
    }

    private func quitApp() {
        #if canImport(AppKit)
        NSApp.terminate(nil)
        #endif
    }
}

#Preview {
    let store = ClipdeckStore()
    store.addClip(text: "First copied text", isPinned: true)
    store.addClip(text: "A second example clip", isPinned: false)
    store.addClip(text: "SwiftUI + MenuBarExtra demo", isPinned: false)
    return ContentView()
        .environmentObject(store)
}

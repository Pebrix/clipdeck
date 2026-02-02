//
//  ClipdeckStore.swift
//  clipdeck
//
//  Created by Anupam Srivastava on 02/02/26.
//

import SwiftUI
import Combine
#if canImport(AppKit)
import AppKit
#endif

final class ClipdeckStore: ObservableObject {
    @Published var clips: [Clip] = [] {
        didSet { scheduleSavePinnedClips() }
    }
    @Published var editingClipID: UUID?

    private static let pinnedClipsKey = "clipdeck.pinnedClips"
    private static let maxRecentClips = 50

    #if canImport(AppKit)
    private var pasteboardMonitorTimer: Timer?
    private var lastKnownChangeCount: Int = 0
    #endif
    private var saveWorkItem: DispatchWorkItem?

    init() {
        loadPinnedClips()
        #if canImport(AppKit)
        lastKnownChangeCount = NSPasteboard.general.changeCount
        startPasteboardMonitoring()
        #endif
    }

    private func loadPinnedClips() {
        guard let data = UserDefaults.standard.data(forKey: Self.pinnedClipsKey),
              let pinned = try? JSONDecoder().decode([Clip].self, from: data) else { return }
        clips = pinned
    }

    private func scheduleSavePinnedClips() {
        saveWorkItem?.cancel()
        saveWorkItem = DispatchWorkItem { [weak self] in
            self?.savePinnedClips()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: saveWorkItem!)
    }

    private func savePinnedClips() {
        let pinned = clips.filter { $0.isPinned }
        guard let data = try? JSONEncoder().encode(pinned) else { return }
        UserDefaults.standard.set(data, forKey: Self.pinnedClipsKey)
    }

    deinit {
        #if canImport(AppKit)
        pasteboardMonitorTimer?.invalidate()
        #endif
    }

    #if canImport(AppKit)
    private func startPasteboardMonitoring() {
        pasteboardMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let pb = NSPasteboard.general
            let count = pb.changeCount
            guard count != self.lastKnownChangeCount else { return }
            DispatchQueue.main.async { self.checkPasteboardForNewContent() }
        }
        RunLoop.main.add(pasteboardMonitorTimer!, forMode: .common)
    }

    private func checkPasteboardForNewContent() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastKnownChangeCount else { return }

        lastKnownChangeCount = pb.changeCount

        guard let string = pb.string(forType: .string),
              !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }

        let recentUnpinned = clips.filter { !$0.isPinned }.sorted { $0.dateAdded > $1.dateAdded }
        if let mostRecent = recentUnpinned.first, mostRecent.text == string { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.addClip(text: string, isPinned: false)
        }
    }

    func copyToPasteboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        lastKnownChangeCount = pb.changeCount
    }
    #else
    func copyToPasteboard(_ text: String) {}
    #endif

    func addClip(text: String, isPinned: Bool = false) {
        let trimmedText = UserDefaults.standard.bool(forKey: "clipdeck.trimSpaces")
            ? text.trimmingCharacters(in: .whitespacesAndNewlines)
            : text
        let clip = Clip(text: trimmedText, isPinned: isPinned)
        guard !trimmedText.isEmpty else { return }
        if isPinned {
            clips.insert(clip, at: 0)
        } else {
            let pinnedCount = clips.filter { $0.isPinned }.count
            clips.insert(clip, at: pinnedCount)
            trimRecentClipsIfNeeded()
        }
    }

    private func trimRecentClipsIfNeeded() {
        let unpinned = clips.filter { !$0.isPinned }
        guard unpinned.count > Self.maxRecentClips else { return }
        let toRemove = unpinned.sorted { $0.dateAdded < $1.dateAdded }.prefix(unpinned.count - Self.maxRecentClips)
        clips.removeAll { clip in toRemove.contains { $0.id == clip.id } }
    }

    func togglePin(_ clip: Clip) {
        if let idx = clips.firstIndex(where: { $0.id == clip.id }) {
            clips[idx].isPinned.toggle()
        }
    }

    func delete(_ clip: Clip) {
        clips.removeAll { $0.id == clip.id }
        if editingClipID == clip.id {
            editingClipID = nil
        }
    }

    func clearUnpinned() {
        clips.removeAll { !$0.isPinned }
    }

    func binding(for clip: Clip) -> Binding<Clip> {
        guard let idx = clips.firstIndex(where: { $0.id == clip.id }) else {
            return .constant(clip)
        }
        return Binding(
            get: { self.clips[idx] },
            set: { self.clips[idx] = $0 }
        )
    }
}

//
//  clipdeckApp.swift
//  clipdeck
//
//  Created by Anupam Srivastava on 02/02/26.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

#if canImport(AppKit)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
#endif

@main
struct clipdeckApp: App {
    @StateObject private var store = ClipdeckStore()
    #if canImport(AppKit)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        MenuBarExtra("Clipdeck", systemImage: "scissors") {
            ContentView()
                .environmentObject(store)
                .frame(width: 360, height: 420)
        }
        .menuBarExtraStyle(.window)
    }
}

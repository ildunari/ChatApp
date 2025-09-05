//
//  ChatAppApp.swift
//  ChatApp
//
//  Created by Kosta Milovanovic on 9/4/25.
//

import SwiftUI
import SwiftData

@main
struct ChatAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Chat.self,
            Message.self,
            AppSettings.self
        ])
        // Persist to Application Support with a stable file name so we can recover from corruption
        let fm = FileManager.default
        let baseDir = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let storeURL = baseDir.appendingPathComponent("ChatApp.sqlite")
        let config = ModelConfiguration("Default", schema: schema, url: storeURL, allowsSave: true)

        func makeContainer() throws -> ModelContainer {
            try ModelContainer(for: schema, configurations: [config])
        }

        do {
            return try makeContainer()
        } catch {
            // Attempt a one-time recovery by removing the SQLite store (and sidecars) and recreating
            let sidecars = ["", "-wal", "-shm"].map { storeURL.appendingPathExtension("sqlite").deletingPathExtension().appendingPathExtension("sqlite\($0)") }
            // Our storeURL already ends with .sqlite; remove it and common sidecars just in case
            let candidates = [storeURL, storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal"), storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")]
            for url in candidates + sidecars {
                try? fm.removeItem(at: url)
            }
            do {
                return try makeContainer()
            } catch {
                fatalError("Could not create ModelContainer after recovery: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

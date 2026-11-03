import SwiftUI
import AppKit
import Observation

@main
struct PhotoStudioApp: App {
    @NSApplicationDelegateAdaptor(PhotoStudioDelegate.self) private var delegate
    var body: some Scene {
        WindowGroup("PhotoStudio", id: "main") {
            ContentView()
        }
        .defaultSize(width: 1280, height: 820)
        .windowToolbarStyle(.unified)
        .commands { BrowserCommands() }

        Settings { GeneralSettingsView() }
        Window("RAW 相机兼容", id: "compatibility") {
            CameraSupportView()
        }
        .defaultSize(width: 760, height: 570)
    }
}

@MainActor @Observable
final class OpenRequests {
    static let shared = OpenRequests()
    private var urls: [URL] = []
    private(set) var revision = 0
    func enqueue(_ incoming: [URL]) { urls.append(contentsOf: incoming); revision += 1 }
    func consume() -> [URL] { let pending = urls; urls = []; return pending }
}

@MainActor
final class PhotoStudioDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "--open"), index + 1 < args.count {
            OpenRequests.shared.enqueue([URL(fileURLWithPath: args[index + 1])])
        }
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        OpenRequests.shared.enqueue(urls)
        application.activate(ignoringOtherApps: true)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { true }
}

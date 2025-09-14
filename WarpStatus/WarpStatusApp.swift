import SwiftUI

@main
struct WarpStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        menuBarController = MenuBarController()
    }
}
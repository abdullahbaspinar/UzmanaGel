import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct UzmanaGelApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase

    // Session
    @StateObject private var session = SessionViewModel()

    // Preview overlay state
    @State private var showPreviewScreen = true
    @State private var previewWorkItem: DispatchWorkItem?

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Asıl uygulama akışı
                RootView()
                    .environmentObject(session)

                // Her girişte 2sn görünen preview
                if showPreviewScreen {
                    PreViewScreen()
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .onAppear {
                showPreviewFor2Seconds()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // arka plandan geri gelince de göster
                    showPreviewFor2Seconds()
                }
            }
        }
    }

    private func showPreviewFor2Seconds() {
        // Üst üste tetiklenirse eski timer iptal olsun
        previewWorkItem?.cancel()

        showPreviewScreen = true

        let workItem = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.2)) {
                showPreviewScreen = false
            }
        }
        previewWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }
}

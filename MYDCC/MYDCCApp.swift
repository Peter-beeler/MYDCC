import SwiftUI

@main
struct MYDCCApp: App {
    // The main view model for the application.
    // @StateObject ensures the ViewModel lifecycle is managed correctly by SwiftUI.
    @StateObject private var throttleViewModel = ThrottleViewModel()
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoading {
                    LoadingView()
                        .transition(.opacity)
                } else {
                    AdaptiveMainView()
                        .environmentObject(throttleViewModel) // Provide ViewModel to all views
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Simulate loading time for initialization
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isLoading = false
                    }
                }
            }
        }
    }
}

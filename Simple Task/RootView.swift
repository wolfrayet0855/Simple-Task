import SwiftUI
import SwiftData
import SimpleTaskKit

/// Opens the store off the main thread and shows the Horizon, or a calm recovery screen if that fails.
struct RootView: View {
    private enum Phase { case loading, ready(ModelContainer, moved: Int?), failed(BootFailure) }

    @State private var phase: Phase = .loading
    @State private var retrying = false
    @State private var attempts = 0
    @AppStorage("onboarding.v1.done") private var onboardingDone = false

    var body: some View {
        ZStack {
            switch phase {
            case .loading:
                Tokens.ground.ignoresSafeArea()
            case .ready(let container, let moved):
                HorizonView()
                    .modelContainer(container)
                    .environmentObject(CategoryManager()) // Legacy screens only.
                    .fullScreenCover(isPresented: .init(get: { !onboardingDone && !skipsOnboarding }, set: { if !$0 { onboardingDone = true } })) {
                        OnboardingView(movedTasks: moved) { onboardingDone = true }
                            .modelContainer(container)
                    }
                    .transition(.opacity)
            case .failed(let failure):
                RecoveryView(failure: failure, retrying: retrying, attempts: attempts, retry: { Task { await boot(isRetry: true) } })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: phaseKey)
        .task { await boot(isRetry: false) }
    }

    private var skipsOnboarding: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-seedDemo") || ProcessInfo.processInfo.arguments.contains("-skipOnboarding")
        #else
        false
        #endif
    }

    private var phaseKey: Int {
        switch phase { case .loading: 0; case .ready: 1; case .failed: 2 }
    }

    private func boot(isRetry: Bool) async {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if !isRetry, args.contains("-failRelocation") {
            phase = .failed(.relocationMismatch(expected: 23, got: 21))
            return
        }
        #endif
        retrying = true
        let result = await Task.detached(priority: .userInitiated) { Store.tryBootstrap() }.value
        retrying = false
        switch result {
        case .ready(let container, let relocation):
            #if DEBUG
            DemoSeed.run(container)
            #endif
            NotificationDelegate.install(container: container)
            var moved: Int?
            if case .moved(let rows) = relocation, rows > 0 { moved = rows }
            phase = .ready(container, moved: moved)
            if isRetry { UIAccessibility.post(notification: .announcement, argument: "Your tasks are back.") }
        case .failed(let failure):
            attempts += isRetry ? 1 : 0
            phase = .failed(failure)
            if isRetry { UIAccessibility.post(notification: .announcement, argument: "Still couldn't move them. Your original copy is safe.") }
        }
    }
}

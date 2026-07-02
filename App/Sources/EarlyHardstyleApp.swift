import Features
import SwiftUI

/// App entry point. Builds the dependency graph at the composition root and
/// hands the root scene its injected collaborators.
@main
struct EarlyHardstyleApp: App {
    @State private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.dark)
        }
    }
}

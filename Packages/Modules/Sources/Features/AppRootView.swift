import Core
import DesignSystem
import Services
import SwiftUI

/// Root namespace for the Features module: each screen ships as a `View` +
/// `ViewModel` pair (MVVM). ViewModels receive their services via initialiser
/// injection from the app's composition root — no singletons.
public enum Features {
    /// Human-readable module identifier, surfaced in the debug styleguide.
    public static let moduleName = "Features"
}

/// The app's root scene: a three-tab shell (Library · DJs · Saved) matching the
/// navigation defined in `the design spec`. The real screens replace these
/// placeholders in their respective feature PRs; ViewModels and services are
/// injected here from the composition root as they come online.
public struct AppRootView: View {
    public init() {}

    public var body: some View {
        TabView {
            placeholder(title: "Library")
                .tabItem { Label("Library", systemImage: "square.grid.2x2") }

            placeholder(title: "DJs")
                .tabItem { Label("DJs", systemImage: "person.2") }

            placeholder(title: "Saved")
                .tabItem { Label("Saved", systemImage: "heart") }
        }
    }

    private func placeholder(title: String) -> some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text(title)
                    .font(.largeTitle.bold())
                Text("Coming soon")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(title)
        }
    }
}

#Preview {
    AppRootView()
}

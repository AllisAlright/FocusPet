import SwiftUI

private enum MainTab: Hashable {
    case home
    case tasks
    case focus
    case history
    case settings
}

struct ContentView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeSceneView()
                .tabItem {
                    Label("主页", systemImage: "house.fill")
                }
                .tag(MainTab.home)

            NavigationStack {
                TasksPlaceholderView()
            }
            .tabItem {
                Label("待办", systemImage: "checklist")
            }
            .tag(MainTab.tasks)

            NavigationStack {
                FocusSetupView()
            }
            .tabItem {
                Label("专注", systemImage: "timer")
            }
            .tag(MainTab.focus)

            NavigationStack {
                HistoryPlaceholderView()
            }
            .tabItem {
                Label("历史", systemImage: "archivebox.fill")
            }
            .tag(MainTab.history)

            NavigationStack {
                SettingsPlaceholderView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape.fill")
            }
            .tag(MainTab.settings)
        }
        .tint(FocusPetTheme.Palette.ink)
    }
}

#Preview {
    ContentView()
        .environmentObject(FocusPetStore())
}

import SwiftUI

@main
struct MoodJournalApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                if appState.showOnboarding {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.showOnboarding)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            StatisticsView()
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar.fill")
                }
                .tag(0)

            NavigationStack {
                NotesView()
            }
            .tabItem {
                Label("Заметки", systemImage: "note.text")
            }
            .tag(1)

            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("Календарь", systemImage: "calendar")
            }
            .tag(2)

            NavigationStack {
                AIAssistantView()
            }
            .tabItem {
                Label("Помощник", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(3)

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(.appPrimary)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}

import SwiftUI
import UIKit

@main
struct MoodJournalApp: App {
    @StateObject private var appState = AppState.shared

    init() {
        AppAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
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
        .toolbarColorScheme(.light, for: .navigationBar, .tabBar)
    }
}

private enum AppAppearance {
    static func configure() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = UIColor(Color.appBackground)
        navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.appText)]
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.appText)]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.appPrimary)

        UITextField.appearance().textColor = UIColor(Color.appText)
        UITextView.appearance().textColor = UIColor(Color.appText)
        UITextView.appearance().backgroundColor = .clear
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}

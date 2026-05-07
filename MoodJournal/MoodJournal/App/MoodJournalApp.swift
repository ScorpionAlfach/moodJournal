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
        }
    }
}

private enum AppAppearance {
    static func configure() {
        UIView.appearance().overrideUserInterfaceStyle = .light

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = UIColor(hex: "F8FAFC")
        navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor(hex: "1E293B")]
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(hex: "1E293B")]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = UIColor(hex: "6366F1")

        UITextField.appearance().textColor = UIColor(hex: "1E293B")
        UITextField.appearance().tintColor = UIColor(hex: "6366F1")
        UITextView.appearance().textColor = UIColor(hex: "1E293B")
        UITextView.appearance().tintColor = UIColor(hex: "6366F1")
        UITextView.appearance().backgroundColor = .clear
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
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

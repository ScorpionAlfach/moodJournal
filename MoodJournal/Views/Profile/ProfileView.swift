import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        profileHeader

                        // User info card
                        if !viewModel.isEditing {
                            userInfoCard
                        } else {
                            editUserInfoCard
                        }

                        // Actions
                        actionsSection

                        // Danger zone
                        dangerSection
                    }
                    .padding(24)
                }

                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !viewModel.isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.startEditing()
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(.appPrimary)
                        }
                    }
                }
            }
            .alert("Выйти из аккаунта?", isPresented: $viewModel.showLogoutConfirmation) {
                Button("Отмена", role: .cancel) {}
                Button("Выйти", role: .destructive) {
                    Task {
                        await viewModel.logout()
                    }
                }
            }
            .alert("Удалить аккаунт?", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount()
                    }
                }
            } message: {
                Text("Это действие нельзя отменить. Все ваши данные будут удалены.")
            }
            .task {
                if let user = appState.currentUser {
                    viewModel.user = user
                } else {
                    await viewModel.loadProfile()
                }
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Text(initials)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }

            if let user = viewModel.user {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.appText)

                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }
        }
    }

    private var initials: String {
        guard let user = viewModel.user else { return "?" }
        let first = user.firstName.first.map(String.init) ?? ""
        let last = user.lastName.first.map(String.init) ?? ""
        return "\(first)\(last)"
    }

    private var userInfoCard: some View {
        VStack(spacing: 0) {
            if let user = viewModel.user {
                ProfileInfoRow(icon: "person", title: "Имя", value: user.firstName)
                Divider().padding(.leading, 56)
                ProfileInfoRow(icon: "person", title: "Фамилия", value: user.lastName)
                Divider().padding(.leading, 56)
                ProfileInfoRow(icon: "phone", title: "Телефон", value: user.phone)
                Divider().padding(.leading, 56)
                ProfileInfoRow(icon: "calendar", title: "Возраст", value: "\(user.age) лет")
                Divider().padding(.leading, 56)
                ProfileInfoRow(icon: "person.2", title: "Пол", value: user.gender.displayName)
            }
        }
        .cardStyle()
    }

    private var editUserInfoCard: some View {
        VStack(spacing: 16) {
            CustomTextField(
                placeholder: "Имя",
                text: $viewModel.editFirstName,
                icon: "person"
            )

            CustomTextField(
                placeholder: "Фамилия",
                text: $viewModel.editLastName,
                icon: "person"
            )

            CustomTextField(
                placeholder: "Телефон",
                text: $viewModel.editPhone,
                keyboardType: .phonePad,
                icon: "phone"
            )

            CustomTextField(
                placeholder: "Возраст",
                text: $viewModel.editAge,
                keyboardType: .numberPad,
                icon: "calendar"
            )

            // Gender picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Пол")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(User.Gender.allCases, id: \.self) { gender in
                            GenderButton(
                                gender: gender,
                                isSelected: viewModel.editGender == gender
                            ) {
                                viewModel.editGender = gender
                            }
                        }
                    }
                }
            }

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
            }

            HStack(spacing: 16) {
                Button {
                    viewModel.cancelEditing()
                } label: {
                    Text("Отмена")
                        .font(.headline)
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appBackground)
                        .cornerRadius(12)
                }

                CustomButton(
                    title: "Сохранить",
                    action: {
                        Task {
                            await viewModel.saveProfile()
                        }
                    },
                    isLoading: viewModel.isLoading
                )
            }
        }
        .padding(20)
        .cardStyle()
    }

    private var actionsSection: some View {
        VStack(spacing: 0) {
            ProfileActionRow(
                icon: "bell",
                title: "Уведомления",
                hasChevron: true
            ) {
                // Navigate to notifications settings
            }

            Divider().padding(.leading, 56)

            ProfileActionRow(
                icon: "lock",
                title: "Конфиденциальность",
                hasChevron: true
            ) {
                // Navigate to privacy settings
            }

            Divider().padding(.leading, 56)

            ProfileActionRow(
                icon: "questionmark.circle",
                title: "Помощь",
                hasChevron: true
            ) {
                // Navigate to help
            }
        }
        .cardStyle()
    }

    private var dangerSection: some View {
        VStack(spacing: 0) {
            ProfileActionRow(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Выйти",
                titleColor: .appWarning
            ) {
                viewModel.showLogoutConfirmation = true
            }

            Divider().padding(.leading, 56)

            ProfileActionRow(
                icon: "trash",
                title: "Удалить аккаунт",
                titleColor: .appError
            ) {
                viewModel.showDeleteConfirmation = true
            }
        }
        .cardStyle()
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.appPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.appText)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ProfileActionRow: View {
    let icon: String
    let title: String
    var titleColor: Color = .appText
    var hasChevron: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(titleColor)
                    .frame(width: 24)

                Text(title)
                    .font(.body)
                    .foregroundColor(titleColor)

                Spacer()

                if hasChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState.shared)
}

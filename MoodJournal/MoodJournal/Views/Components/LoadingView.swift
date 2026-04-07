import SwiftUI

struct LoadingView: View {
    var message: String = "Загрузка..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.appPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}

struct CustomButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var style: ButtonStyle = .primary

    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(style == .primary ? .white : .appPrimary)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(background)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .appPrimary
        case .destructive: return .white
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            Color.appPrimary.opacity(0.1)
        case .destructive:
            Color.appError
        }
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var icon: String?

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.appTextSecondary)
                    .frame(width: 24)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
        }
        .padding()
        .background(Color.appBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.appError)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.appText)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.appError.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomButton(title: "Primary Button", action: {})
        CustomButton(title: "Secondary Button", action: {}, style: .secondary)
        CustomButton(title: "Loading...", action: {}, isLoading: true)
        CustomTextField(placeholder: "Email", text: .constant(""), icon: "envelope")
        ErrorBanner(message: "Something went wrong")
    }
    .padding()
}

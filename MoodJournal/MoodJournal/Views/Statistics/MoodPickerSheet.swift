import SwiftUI

struct MoodPickerSheet: View {
    @ObservedObject var viewModel: StatisticsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Mood level selection
                    moodLevelSection

                    // Factors selection
                    factorsSection

                    // Note
                    noteSection

                    // Save button
                    CustomButton(
                        title: "Сохранить",
                        action: {
                            Task {
                                await viewModel.saveMood()
                                if viewModel.errorMessage == nil {
                                    dismiss()
                                }
                            }
                        },
                        isLoading: viewModel.isLoading
                    )

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error) {
                            viewModel.errorMessage = nil
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationTitle("Настроение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        viewModel.resetMoodSelection()
                        dismiss()
                    }
                    .foregroundColor(.appTextSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var moodLevelSection: some View {
        VStack(spacing: 20) {
            Text("Как вы себя чувствуете?")
                .font(.headline)
                .foregroundColor(.appText)

            HStack(spacing: 16) {
                ForEach(Mood.MoodLevel.allCases, id: \.self) { level in
                    MoodLevelButton(
                        level: level,
                        isSelected: viewModel.selectedMoodLevel == level
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedMoodLevel = level
                        }
                    }
                }
            }

            // Selected mood info
            VStack(spacing: 8) {
                Text(viewModel.selectedMoodLevel.emoji)
                    .font(.system(size: 60))

                Text(viewModel.selectedMoodLevel.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
            }
            .padding(.top, 8)
        }
    }

    private var factorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Что повлияло на настроение?")
                .font(.headline)
                .foregroundColor(.appText)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Mood.MoodFactor.allCases, id: \.self) { factor in
                    FactorButton(
                        factor: factor,
                        isSelected: viewModel.selectedFactors.contains(factor)
                    ) {
                        viewModel.toggleFactor(factor)
                    }
                }
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Заметка (опционально)")
                .font(.headline)
                .foregroundColor(.appText)

            TextEditor(text: $viewModel.moodNote)
                .frame(minHeight: 100)
                .padding(12)
                .background(Color.appCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.moodNote.isEmpty {
                        Text("Напишите что-нибудь...")
                            .foregroundColor(.appTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}

struct MoodLevelButton: View {
    let level: Mood.MoodLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(level.emoji)
                .font(.system(size: isSelected ? 36 : 28))
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(isSelected ? level.color.opacity(0.2) : Color.appBackground)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? level.color : Color.appBorder, lineWidth: isSelected ? 3 : 1)
                )
                .scaleEffect(isSelected ? 1.1 : 1)
        }
    }
}

struct FactorButton: View {
    let factor: Mood.MoodFactor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: factor.icon)
                    .font(.title3)

                Text(factor.title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : .appText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ?
                AnyView(LinearGradient(
                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )) :
                AnyView(Color.appCardBackground)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.appBorder, lineWidth: 1)
            )
        }
    }
}

#Preview {
    MoodPickerSheet(viewModel: StatisticsViewModel())
}

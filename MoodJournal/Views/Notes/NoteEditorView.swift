import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum Field {
        case title
        case content
        case tag
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Заголовок")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)

                        TextField("Введите заголовок", text: $viewModel.editTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .focused($focusedField, equals: .title)
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Содержание")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)

                        TextEditor(text: $viewModel.editContent)
                            .font(.body)
                            .focused($focusedField, equals: .content)
                            .frame(minHeight: 200)
                            .padding(12)
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                            .overlay(alignment: .topLeading) {
                                if viewModel.editContent.isEmpty {
                                    Text("Напишите что-нибудь...")
                                        .foregroundColor(.appTextSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    // Mood
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Настроение (опционально)")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)

                        HStack(spacing: 12) {
                            ForEach(Mood.MoodLevel.allCases, id: \.self) { level in
                                Button {
                                    if viewModel.editMoodLevel == level {
                                        viewModel.editMoodLevel = nil
                                    } else {
                                        viewModel.editMoodLevel = level
                                    }
                                } label: {
                                    Text(level.emoji)
                                        .font(.title2)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            viewModel.editMoodLevel == level ?
                                            level.color.opacity(0.2) : Color.appBackground
                                        )
                                        .cornerRadius(24)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    viewModel.editMoodLevel == level ?
                                                    level.color : Color.appBorder,
                                                    lineWidth: viewModel.editMoodLevel == level ? 2 : 1
                                                )
                                        )
                                }
                            }
                        }
                    }

                    // Tags
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Теги")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)

                        // Tag input
                        HStack {
                            TextField("Добавить тег", text: $viewModel.newTag)
                                .focused($focusedField, equals: .tag)
                                .onSubmit {
                                    viewModel.addTag()
                                }

                            Button {
                                viewModel.addTag()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.appPrimary)
                            }
                            .disabled(viewModel.newTag.isEmpty)
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )

                        // Tags list
                        if !viewModel.editTags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(viewModel.editTags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text("#\(tag)")
                                            .font(.subheadline)
                                            .foregroundColor(.appPrimary)

                                        Button {
                                            viewModel.removeTag(tag)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.appPrimary.opacity(0.1))
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error) {
                            viewModel.errorMessage = nil
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationTitle(viewModel.isEditing ? "Редактирование" : "Новая заметка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.appTextSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.saveNote()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Сохранить")
                                .fontWeight(.semibold)
                                .foregroundColor(.appPrimary)
                        }
                    }
                    .disabled(viewModel.editTitle.isEmpty || viewModel.isLoading)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        focusedField = nil
                    }
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                maxHeight = max(maxHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + maxHeight)
        }
    }
}

#Preview {
    NoteEditorView(viewModel: NotesViewModel())
}

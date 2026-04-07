import SwiftUI

struct NotesView: View {
    @StateObject private var viewModel = NotesViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if viewModel.notes.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                notesList
            }

            if viewModel.isLoading && viewModel.notes.isEmpty {
                LoadingOverlay()
            }
        }
        .navigationTitle("Заметки")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        viewModel.showFilter = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.appPrimary)
                    }

                    Button {
                        viewModel.startNewNote()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.appPrimary)
                    }
                }
            }
        }
        .searchable(text: $viewModel.filter.searchText, prompt: "Поиск заметок")
        .onChange(of: viewModel.filter.searchText) { _, _ in
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await viewModel.loadNotes(reset: true)
            }
        }
        .sheet(isPresented: $viewModel.showFilter) {
            NotesFilterSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showEditor) {
            NoteEditorView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadNotes(reset: true)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.appTextSecondary)

            VStack(spacing: 8) {
                Text("Нет заметок")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)

                Text("Создайте первую заметку, чтобы начать вести дневник")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.startNewNote()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Создать заметку")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.gradientPrimary)
                .cornerRadius(12)
            }
        }
        .padding(24)
    }

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.notes) { note in
                    NoteCard(note: note) {
                        viewModel.startEditNote(note)
                    } onDelete: {
                        Task {
                            await viewModel.deleteNote(note)
                        }
                    }
                    .onAppear {
                        Task {
                            await viewModel.loadMoreIfNeeded(currentNote: note)
                        }
                    }
                }

                if viewModel.isLoading && !viewModel.notes.isEmpty {
                    ProgressView()
                        .padding()
                }
            }
            .padding(24)
        }
    }
}

struct NoteCard: View {
    let note: Note
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteAlert = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if let moodLevel = note.moodLevel {
                        Text(moodLevel.emoji)
                            .font(.title3)
                    }

                    Text(note.title)
                        .font(.headline)
                        .foregroundColor(.appText)
                        .lineLimit(1)

                    Spacer()

                    Menu {
                        Button {
                            onTap()
                        } label: {
                            Label("Редактировать", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.appTextSecondary)
                            .padding(8)
                    }
                }

                Text(note.shortContent)
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text(note.formattedDate)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)

                    Spacer()

                    if !note.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(note.tags.prefix(2), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.appPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.appPrimary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            if note.tags.count > 2 {
                                Text("+\(note.tags.count - 2)")
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Удалить заметку?", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive, action: onDelete)
        } message: {
            Text("Это действие нельзя отменить")
        }
    }
}

struct NotesFilterSheet: View {
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Sort options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Сортировка")
                            .font(.headline)
                            .foregroundColor(.appText)

                        ForEach(NotesFilter.SortOption.allCases, id: \.self) { option in
                            Button {
                                viewModel.filter.sortBy = option
                            } label: {
                                HStack {
                                    Text(option.displayName)
                                        .foregroundColor(.appText)
                                    Spacer()
                                    if viewModel.filter.sortBy == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.appPrimary)
                                    }
                                }
                                .padding()
                                .background(Color.appCardBackground)
                                .cornerRadius(12)
                            }
                        }
                    }

                    // Mood filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Настроение")
                            .font(.headline)
                            .foregroundColor(.appText)

                        HStack(spacing: 12) {
                            ForEach(Mood.MoodLevel.allCases, id: \.self) { level in
                                Button {
                                    if viewModel.filter.moodLevels.contains(level) {
                                        viewModel.filter.moodLevels.removeAll { $0 == level }
                                    } else {
                                        viewModel.filter.moodLevels.append(level)
                                    }
                                } label: {
                                    Text(level.emoji)
                                        .font(.title2)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            viewModel.filter.moodLevels.contains(level) ?
                                            level.color.opacity(0.2) : Color.appBackground
                                        )
                                        .cornerRadius(24)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    viewModel.filter.moodLevels.contains(level) ?
                                                    level.color : Color.appBorder,
                                                    lineWidth: viewModel.filter.moodLevels.contains(level) ? 2 : 1
                                                )
                                        )
                                }
                            }
                        }
                    }

                    // Buttons
                    HStack(spacing: 16) {
                        Button {
                            viewModel.resetFilter()
                            dismiss()
                        } label: {
                            Text("Сбросить")
                                .font(.headline)
                                .foregroundColor(.appTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appBackground)
                                .cornerRadius(12)
                        }

                        CustomButton(title: "Применить") {
                            viewModel.applyFilter()
                            dismiss()
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    NavigationStack {
        NotesView()
    }
}

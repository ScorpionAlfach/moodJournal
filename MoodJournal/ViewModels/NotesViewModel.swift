import Foundation
import SwiftUI

@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedNote: Note?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var filter = NotesFilter()
    @Published var showFilter = false
    @Published var showEditor = false
    @Published var isEditing = false

    // Editor fields
    @Published var editTitle = ""
    @Published var editContent = ""
    @Published var editMoodLevel: Mood.MoodLevel?
    @Published var editTags: [String] = []
    @Published var newTag = ""

    @Published var totalNotes = 0
    @Published var currentPage = 1
    @Published var hasMorePages = false

    private let pageSize = 20

    func loadNotes(reset: Bool = false) async {
        if reset {
            currentPage = 1
            notes = []
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await NotesService.shared.getNotes(
                filter: filter,
                page: currentPage,
                limit: pageSize
            )
            if reset {
                notes = response.notes
            } else {
                notes.append(contentsOf: response.notes)
            }
            totalNotes = response.total
            hasMorePages = notes.count < totalNotes
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось загрузить заметки"
        }

        isLoading = false
    }

    func loadMoreIfNeeded(currentNote: Note) async {
        guard hasMorePages,
              !isLoading,
              notes.last?.id == currentNote.id else { return }

        currentPage += 1
        await loadNotes()
    }

    func loadNote(id: String) async {
        isLoading = true
        errorMessage = nil

        do {
            selectedNote = try await NotesService.shared.getNote(id: id)
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось загрузить заметку"
        }

        isLoading = false
    }

    func startNewNote() {
        selectedNote = nil
        editTitle = ""
        editContent = ""
        editMoodLevel = nil
        editTags = []
        newTag = ""
        isEditing = false
        showEditor = true
    }

    func startEditNote(_ note: Note) {
        selectedNote = note
        editTitle = note.title
        editContent = note.content
        editMoodLevel = note.moodLevel
        editTags = note.tags
        newTag = ""
        isEditing = true
        showEditor = true
    }

    func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !editTags.contains(tag) {
            editTags.append(tag)
        }
        newTag = ""
    }

    func removeTag(_ tag: String) {
        editTags.removeAll { $0 == tag }
    }

    func saveNote() async {
        guard !editTitle.isEmpty else {
            errorMessage = "Введите заголовок"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            if isEditing, let note = selectedNote {
                let updated = try await NotesService.shared.updateNote(
                    id: note.id,
                    title: editTitle,
                    content: editContent,
                    moodLevel: editMoodLevel,
                    tags: editTags
                )
                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                    notes[index] = updated
                }
                selectedNote = updated
            } else {
                let newNote = try await NotesService.shared.createNote(
                    title: editTitle,
                    content: editContent,
                    moodLevel: editMoodLevel,
                    tags: editTags
                )
                notes.insert(newNote, at: 0)
                totalNotes += 1
            }
            showEditor = false
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось сохранить заметку"
        }

        isLoading = false
    }

    func deleteNote(_ note: Note) async {
        isLoading = true
        errorMessage = nil

        do {
            try await NotesService.shared.deleteNote(id: note.id)
            notes.removeAll { $0.id == note.id }
            totalNotes -= 1
            if selectedNote?.id == note.id {
                selectedNote = nil
            }
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось удалить заметку"
        }

        isLoading = false
    }

    func applyFilter() {
        showFilter = false
        Task {
            await loadNotes(reset: true)
        }
    }

    func resetFilter() {
        filter = NotesFilter()
        showFilter = false
        Task {
            await loadNotes(reset: true)
        }
    }
}

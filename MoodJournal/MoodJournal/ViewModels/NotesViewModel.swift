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
    @Published var hasLoadedNotes = false

    private let pageSize = 20

    var availableTagFilters: [String] {
        var result: [String] = []
        var seen = Set<String>()

        let savedTags = notes.flatMap(\.tags)
        let factorTags = Mood.MoodFactor.allCases.map(\.title)

        for tag in savedTags + factorTags {
            let normalized = tag.normalizedNoteTag
            guard !normalized.isEmpty, !seen.contains(normalized) else { continue }
            result.append(normalized)
            seen.insert(normalized)
        }

        return result.sorted { displayName(forTag: $0) < displayName(forTag: $1) }
    }

    func loadNotes(reset: Bool = false) async {
        guard !isLoading else { return }

        if reset {
            currentPage = 1
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
            hasLoadedNotes = true
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось загрузить заметки"
        }

        isLoading = false
    }

    func loadNotesIfNeeded() async {
        guard !hasLoadedNotes else { return }
        await loadNotes(reset: true)
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
        let tag = newTag.normalizedNoteTag
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

    func toggleTagFilter(_ tag: String) {
        let values = tagFilterValues(for: tag)
        guard !values.isEmpty else { return }

        // Tag filters compare normalized saved note.tags values, not display labels.
        if values.contains(where: { filter.tags.contains($0) }) {
            filter.tags.removeAll { values.contains($0) }
        } else {
            for value in values where !filter.tags.contains(value) {
                filter.tags.append(value)
            }
        }
    }

    func isTagFilterSelected(_ tag: String) -> Bool {
        tagFilterValues(for: tag).contains { filter.tags.contains($0) }
    }

    func displayName(forTag tag: String) -> String {
        let normalized = tag.normalizedNoteTag
        if let factor = Mood.MoodFactor.allCases.first(where: {
            $0.title.normalizedNoteTag == normalized || $0.rawValue.normalizedNoteTag == normalized
        }) {
            return factor.title
        }
        return tag
    }

    private func tagFilterValues(for tag: String) -> [String] {
        let normalized = tag.normalizedNoteTag
        guard !normalized.isEmpty else { return [] }

        if let factor = Mood.MoodFactor.allCases.first(where: {
            $0.title.normalizedNoteTag == normalized || $0.rawValue.normalizedNoteTag == normalized
        }) {
            return Array(Set([factor.title.normalizedNoteTag, factor.rawValue.normalizedNoteTag]))
        }

        return [normalized]
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

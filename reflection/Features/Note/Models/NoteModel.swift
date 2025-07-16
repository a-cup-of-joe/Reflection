import SwiftUI

struct Note : Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(title: String, content: String = "") {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func updateContent(_ newContent: String) {
        self.content = newContent
        self.updatedAt = Date()
    }
}

final class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var currentNote: Note?
    private let dataManager = DataManager.shared
    private var currentNoteId: UUID?

    init() {
        loadNotes()
        loadCurrentNote()
    }

    func addNote(title: String, content: String) {
        let newNote = Note(title: title, content: content)
        notes.append(newNote)
        dataManager.saveNotes(notes)
    }

    func addNote(note: Note) {
        notes.append(note)
        dataManager.saveNotes(notes)
    }

    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        if currentNote?.id == id {
            currentNote = nil
            currentNoteId = nil
            loadCurrentNote()
        }
        dataManager.saveNotes(notes)
        if let id = currentNoteId {
            dataManager.saveCurrentNoteId(id)
        }
    }

    func updateNote(id: UUID, newTitle: String, newContent: String) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].title = newTitle
            notes[index].updateContent(newContent)
        }
        dataManager.saveNotes(notes)
    }

    func updateCurrentNoteContent(title: String, content: String) {
        guard let currentNote = currentNote else { return }
        updateNote(id: currentNote.id, newTitle: title, newContent: content)
    }

    func selectNote(id: UUID) {
        if let matchNote = notes.first(where: { $0.id == id }) {
            currentNote = matchNote
            currentNoteId = matchNote.id
            dataManager.saveCurrentNoteId(matchNote.id)
        }
    }

    private func loadNotes() {
        notes = dataManager.fetchNotes()
    }

    private func loadCurrentNote() {
        currentNoteId = dataManager.fetchCurrentNoteId()
        if let currentNoteId = currentNoteId {
            currentNote = notes.first { $0.id == currentNoteId }
        } else if !notes.isEmpty {
            currentNote = notes.first
            currentNoteId = currentNote?.id
            if let id = currentNoteId {
                dataManager.saveCurrentNoteId(id)
            }
        } else {
            currentNote = Note(title: "备忘录", content: "")
            addNote(note: currentNote!)
            currentNoteId = currentNote?.id
            dataManager.saveCurrentNoteId(currentNoteId!)
        }
    }
}

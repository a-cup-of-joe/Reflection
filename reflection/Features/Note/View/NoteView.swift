import SwiftUI

struct NoteView: View {
    @EnvironmentObject var noteViewModel: NoteViewModel
    @State private var showingNotesPanel = false
    @FocusState private var isTextEditorFocused: Bool




    var body: some View {
        ZStack {
            // 主输入区
            mainNoteEditor

            // 右下角笔记按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingNotesPanel = true
                    }) {
                        Image(systemName: "note.text")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 32)
                    .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showingNotesPanel) {
            NotesPanelView(isPresented: $showingNotesPanel)
                .environmentObject(noteViewModel)
        }
        .onAppear {
            isTextEditorFocused = true
        }
    }

    private var mainNoteEditor: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 40)
                .padding(.vertical, 32)

            VStack(alignment: .leading, spacing: 0) {
                if let note = noteViewModel.currentNote, let idx = noteViewModel.notes.firstIndex(where: { $0.id == note.id }) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(note.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 16)
                            .padding(.horizontal, 24)
                        TextEditor(text: $noteViewModel.notes[idx].content)
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(24)
                            .background(Color.clear)
                            .focused($isTextEditorFocused)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onChange(of: noteViewModel.notes[idx].content) {
                                noteViewModel.updateNote(id: note.id, newTitle: note.title, newContent: noteViewModel.notes[idx].content)
                            }
                    }
                } else {
                    Text("请选择或新建一个笔记")
                        .foregroundColor(.secondaryGray)
                        .font(.title2)
                        .padding(32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .edgesIgnoringSafeArea(.all)
    }


}

// MARK: - NotesPanelView
struct NotesPanelView: View {
    @EnvironmentObject var noteViewModel: NoteViewModel
    @Binding var isPresented: Bool
    @State private var newNoteTitle: String = ""
    @FocusState private var isTitleFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("我的笔记")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)

            HStack(spacing: 8) {
                TextField("新建笔记标题...", text: $newNoteTitle, onCommit: addNote)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 8)
                    .focused($isTitleFieldFocused)
                Button(action: addNote) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(noteViewModel.notes) { note in
                        HStack {
                            Button(action: {
                                noteViewModel.selectNote(id: note.id)
                                isPresented = false
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(note.title)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Text(note.createdAt, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondaryGray)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            Spacer()
                            if noteViewModel.currentNote?.id == note.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            // 删除按钮，备忘录不可删除
                            if note.title != "备忘录" {
                                Button(action: {
                                    noteViewModel.deleteNote(id: note.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .padding(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        Divider()
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(18)
        .shadow(radius: 16)
    }

    private func addNote() {
        var title = newNoteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let allTitles = noteViewModel.notes.map { $0.title }
        if allTitles.contains(title) {
            var idx = 1
            var newTitle = "\(title)(\(idx))"
            while allTitles.contains(newTitle) {
                idx += 1
                newTitle = "\(title)(\(idx))"
            }
            title = newTitle
        }
        noteViewModel.addNote(title: title, content: "")
        noteViewModel.selectNote(id: noteViewModel.notes.last?.id ?? UUID())
        newNoteTitle = ""
        isTitleFieldFocused = true
    }
}



#Preview {
    NoteView()
        .environmentObject(NoteViewModel())
}

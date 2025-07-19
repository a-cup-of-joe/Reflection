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
                            .padding(24)
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
        .edgesIgnoringSafeArea(.all)
    }


}



#Preview {
    NoteView()
        .environmentObject(NoteViewModel())
}

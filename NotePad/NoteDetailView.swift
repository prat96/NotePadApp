import SwiftUI
import CoreData

struct NoteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var note: Note
    
    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedContent: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isEditing {
                    TextField("Title", text: $editedTitle)
                        .font(.largeTitle)
                        .padding(.horizontal)
                    
                    TextEditor(text: $editedContent)
                        .frame(minHeight: 200)
                        .padding(.horizontal)
                } else {
                    Text(note.title ?? "Untitled")
                        .font(.largeTitle)
                        .padding(.horizontal)
                    
                    Text(note.content ?? "")
                        .padding(.horizontal)
                }
                
                if let tags = note.tags as? Set<Tag>, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(tags), id: \.self) { tag in
                                Text(tag.name ?? "")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(tag.color ?? "gray"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle(isEditing ? "Edit Note" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        // Enter edit mode
                        editedTitle = note.title ?? ""
                        editedContent = note.content ?? ""
                        isEditing = true
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        note.title = editedTitle
        note.content = editedContent
        
        do {
            try viewContext.save()
            isEditing = false
        } catch {
            // Handle the CoreData save error
            print("Error updating note: \(error)")
        }
    }
}

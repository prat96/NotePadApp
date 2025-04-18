import SwiftUI
import CoreData

struct AddNoteView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedTags: Set<Tag> = []
    @State private var showingTagSelector = false
    
    // Load all available tags
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    private var allTags: FetchedResults<Tag>
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Details")) {
                    TextField("Title", text: $title)
                    
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Content")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 100)
                    }
                }
                
                Section(header: HStack {
                    Text("Tags")
                    Spacer()
                    Button(action: {
                        showingTagSelector = true
                    }) {
                        Text("Edit")
                            .font(.caption)
                    }
                }) {
                    if selectedTags.isEmpty {
                        Text("No tags selected")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(selectedTags), id: \.self) { tag in
                                    HStack {
                                        Circle()
                                            .fill(Color(tag.color ?? "gray"))
                                            .frame(width: 10, height: 10)
                                        
                                        Text(tag.name ?? "")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(tag.color ?? "gray").opacity(0.2))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingTagSelector) {
                AddNoteTagSelectorView(selectedTags: $selectedTags)
            }
        }
    }
    
    private func saveNote() {
        let newNote = Note(context: viewContext)
        newNote.title = title
        newNote.content = content
        newNote.creationDate = Date()
        
        // Add selected tags to the note
        for tag in selectedTags {
            newNote.addToTags(tag)
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            // Handle the CoreData save error
            print("Error saving note: \(error)")
        }
    }
}

// Tag selector specifically for AddNoteView
struct AddNoteTagSelectorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedTags: Set<Tag>
    
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    private var allTags: FetchedResults<Tag>
    
    @State private var showingAddTagView = false
    
    var body: some View {
        NavigationView {
            List {
                if allTags.isEmpty {
                    Text("No tags available. Create a new tag to get started.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(allTags, id: \.self) { tag in
                        Button(action: {
                            toggleTag(tag)
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color(tag.color ?? "gray"))
                                    .frame(width: 20, height: 20)
                                
                                Text(tag.name ?? "Unnamed")
                                
                                Spacer()
                                
                                if selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Select Tags")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTagView = true
                    }) {
                        Label("Add Tag", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTagView) {
                TagEditView(mode: .create)
            }
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

struct AddNoteView_Previews: PreviewProvider {
    static var previews: some View {
        AddNoteView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

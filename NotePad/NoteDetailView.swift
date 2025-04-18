import SwiftUI
import CoreData

struct NoteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var note: Note
    
    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedContent: String = ""
    @State private var showingTagSelector = false
    
    // Load all available tags
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    private var allTags: FetchedResults<Tag>
    
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
                
                // Tags section
                VStack(alignment: .leading) {
                    HStack {
                        Text("Tags")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showingTagSelector = true
                        }) {
                            Label("Edit Tags", systemImage: "pencil")
                                .font(.caption)
                        }
                    }
                    
                    if let tags = note.tags as? Set<Tag>, !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(tags), id: \.self) { tag in
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
                            .padding(.horizontal)
                        }
                    } else {
                        Text("No tags")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                
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
        .sheet(isPresented: $showingTagSelector) {
            TagSelectorView(note: note)
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

// Tag selector view for adding/removing tags
struct TagSelectorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var note: Note
    
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
                                
                                if isTagSelected(tag) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Tags")
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
    
    private func isTagSelected(_ tag: Tag) -> Bool {
        guard let noteTags = note.tags as? Set<Tag> else { return false }
        return noteTags.contains(tag)
    }
    
    private func toggleTag(_ tag: Tag) {
        if isTagSelected(tag) {
            note.removeFromTags(tag)
        } else {
            note.addToTags(tag)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error toggling tag: \(error)")
        }
    }
}

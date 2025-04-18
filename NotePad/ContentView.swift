import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Note.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.creationDate, ascending: false)],
        animation: .default)
    private var notes: FetchedResults<Note>
    
    @State private var showingAddNoteView = false
    @State private var searchText = ""
    @State private var selectedTag: Tag?
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search notes...")
                    .padding(.horizontal)
                
                // Filter chips
                if selectedTag != nil {
                    HStack {
                        Spacer()
                        
                        FilterChip(
                            label: selectedTag?.name ?? "",
                            color: Color(selectedTag?.color ?? "blue")
                        ) {
                            // Clear filter
                            selectedTag = nil
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
                
                // Note list
                List {
                    ForEach(filteredNotes, id: \.self) { note in
                        NavigationLink {
                            NoteDetailView(note: note)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(note.title ?? "Untitled")
                                    .font(.headline)
                                if let creationDate = note.creationDate {
                                    Text(creationDate, formatter: dateFormatter)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Display tags
                                if let tags = note.tags as? Set<Tag>, !tags.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            ForEach(Array(tags), id: \.self) { tag in
                                                Text(tag.name ?? "")
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color(tag.color ?? "gray").opacity(0.3))
                                                    .cornerRadius(8)
                                                    .onTapGesture {
                                                        selectedTag = tag
                                                    }
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: TagListView()) {
                        Label("Manage Tags", systemImage: "tag")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                
                ToolbarItem {
                    Button(action: { showingAddNoteView = true }) {
                        Label("Add Note", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddNoteView) {
                AddNoteView()
            }
        }
    }
    
    private var filteredNotes: [Note] {
        var result = Array(notes)
        
        // Filter by tag if selected
        if let selectedTag = selectedTag {
            result = result.filter { note in
                guard let noteTags = note.tags as? Set<Tag> else { return false }
                return noteTags.contains(selectedTag)
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { note in
                let titleMatch = note.title?.localizedCaseInsensitiveContains(searchText) ?? false
                let contentMatch = note.content?.localizedCaseInsensitiveContains(searchText) ?? false
                return titleMatch || contentMatch
            }
        }
        
        return result
    }
    
    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredNotes[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Handle the error appropriately
                print("Error deleting note: \(error)")
            }
        }
    }
}

// A simple search bar
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// A filter chip for showing active filters
struct FilterChip: View {
    var label: String
    var color: Color
    var onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.callout)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

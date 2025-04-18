//
//  TagListView.swift
//  NotePad
//
//  Created by Prat B on 18.04.25.
//


import SwiftUI
import CoreData

struct TagListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var tags: FetchedResults<Tag>
    
    @State private var showingAddTagView = false
    @State private var selectedTag: Tag?
    @State private var showingEditTagView = false
    
    var body: some View {
        List {
            ForEach(tags, id: \.self) { tag in
                HStack {
                    Circle()
                        .fill(Color(tag.color ?? "gray"))
                        .frame(width: 20, height: 20)
                    
                    Text(tag.name ?? "Unnamed")
                    
                    Spacer()
                    
                    Text("\(tag.notes?.count ?? 0) notes")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedTag = tag
                    showingEditTagView = true
                }
            }
            .onDelete(perform: deleteTags)
        }
        .navigationTitle("Tags")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button(action: { showingAddTagView = true }) {
                    Label("Add Tag", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTagView) {
            TagEditView(mode: .create)
        }
        .sheet(isPresented: $showingEditTagView, onDismiss: {
            selectedTag = nil
        }) {
            if let tag = selectedTag {
                TagEditView(mode: .edit(tag: tag))
            }
        }
    }
    
    private func deleteTags(offsets: IndexSet) {
        withAnimation {
            offsets.map { tags[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting tag: \(error)")
            }
        }
    }
}

struct TagListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TagListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
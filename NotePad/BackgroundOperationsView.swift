//
//  BackgroundOperationsView.swift
//  NotePad
//
//  Created by Prat B on 18.04.25.
//


import SwiftUI
import CoreData

struct BackgroundOperationsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var importCount: Int = 20
    @State private var isImporting = false
    @State private var importResult: String?
    
    @State private var deleteOlderThanDays: Int = 7
    @State private var isDeleting = false
    @State private var deleteResult: String?
    
    @State private var searchQuery: String = ""
    @State private var isSearching = false
    @State private var searchResults: [Note] = []
    
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    private var allTags: FetchedResults<Tag>
    
    @State private var selectedSearchTag: Tag?
    
    var body: some View {
        Form {
            Section(header: Text("Import Sample Notes")) {
                Stepper("Import \(importCount) Notes", value: $importCount, in: 1...1000)
                
                Button(action: importSampleNotes) {
                    if isImporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Start Import")
                    }
                }
                .disabled(isImporting)
                
                if let result = importResult {
                    Text(result)
                        .foregroundColor(result.contains("Error") ? .red : .green)
                }
            }
            
            Section(header: Text("Batch Delete Old Notes")) {
                Stepper("Delete Notes Older Than \(deleteOlderThanDays) Days", value: $deleteOlderThanDays, in: 1...365)
                
                Button(action: deleteOldNotes) {
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Start Batch Delete")
                    }
                }
                .disabled(isDeleting)
                
                if let result = deleteResult {
                    Text(result)
                        .foregroundColor(result.contains("Error") ? .red : .green)
                }
            }
            
            Section(header: Text("Background Search")) {
                TextField("Search Query", text: $searchQuery)
                
                Picker("Filter by Tag", selection: $selectedSearchTag) {
                    Text("All Tags").tag(nil as Tag?)
                    
                    ForEach(allTags, id: \.self) { tag in
                        Text(tag.name ?? "").tag(tag as Tag?)
                    }
                }
                
                Button(action: performBackgroundSearch) {
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Search")
                    }
                }
                .disabled(isSearching || searchQuery.isEmpty)
                
                if !searchResults.isEmpty {
                    List {
                        ForEach(searchResults, id: \.self) { note in
                            VStack(alignment: .leading) {
                                Text(note.title ?? "Untitled")
                                    .font(.headline)
                                
                                if let date = note.creationDate {
                                    Text(dateFormatter.string(from: date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Background Operations")
    }
    
    private func importSampleNotes() {
        isImporting = true
        importResult = "Importing..."
        
        BackgroundTaskManager.shared.importSampleNotes(count: importCount) { success in
            isImporting = false
            
            if success {
                importResult = "Successfully imported \(importCount) notes"
            } else {
                importResult = "Error importing notes"
            }
        }
    }
    
    private func deleteOldNotes() {
        isDeleting = true
        deleteResult = "Deleting..."
        
        BackgroundTaskManager.shared.deleteOldNotes(olderThanDays: deleteOlderThanDays) { count in
            isDeleting = false
            
            if count >= 0 {
                deleteResult = "Successfully deleted \(count) old notes"
            } else {
                deleteResult = "Error deleting notes"
            }
        }
    }
    
    private func performBackgroundSearch() {
        isSearching = true
        
        BackgroundTaskManager.shared.searchNotes(query: searchQuery, tagFilter: selectedSearchTag) { results in
            searchResults = results
            isSearching = false
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

struct BackgroundOperationsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BackgroundOperationsView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
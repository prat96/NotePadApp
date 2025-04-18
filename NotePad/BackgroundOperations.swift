//
//  to.swift
//  NotePad
//
//  Created by Prat B on 18.04.25.
//


import Foundation
import CoreData
import SwiftUI

// Singleton class to handle background operations
class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    private let persistenceController = PersistenceController.shared
    
    private init() {}
    
    // Import a batch of notes in the background
    func importSampleNotes(count: Int, completion: @escaping (Bool) -> Void) {
        let backgroundContext = persistenceController.container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Configure background context
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.perform {
            // Get all existing tags to randomly assign to notes
            let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
            
            do {
                let allTags = try backgroundContext.fetch(fetchRequest)
                guard !allTags.isEmpty else { 
                    // No tags available, create at least one
                    let defaultTag = Tag(context: backgroundContext)
                    defaultTag.name = "Sample"
                    defaultTag.color = "blue"
                    
                    try backgroundContext.save()
                    
                    // Call the function again now that we have a tag
                    DispatchQueue.main.async {
                        self.importSampleNotes(count: count, completion: completion)
                    }
                    return
                }
                
                // Generate sample notes
                for i in 0..<count {
                    // Create in batches of 10 to avoid overwhelming memory
                    if i % 10 == 0 && i > 0 {
                        try backgroundContext.save()
                    }
                    
                    autoreleasepool {
                        let note = Note(context: backgroundContext)
                        note.title = "Sample Note \(i + 1)"
                        note.content = "This is sample content for note \(i + 1). Generated on \(Date())."
                        note.creationDate = Date().addingTimeInterval(-Double.random(in: 0...86400 * 30)) // Random date within last 30 days
                        
                        // Add 1-3 random tags
                        let randomTagCount = Int.random(in: 1...min(3, allTags.count))
                        let shuffledTags = allTags.shuffled()
                        
                        for j in 0..<randomTagCount {
                            note.addToTags(shuffledTags[j])
                        }
                    }
                }
                
                // Save final batch
                try backgroundContext.save()
                
                // Notify completion on main thread
                DispatchQueue.main.async {
                    completion(true)
                }
                
            } catch {
                print("Error importing sample notes: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // Search notes with a complex predicate in the background
    func searchNotes(query: String, tagFilter: Tag?, completion: @escaping ([Note]) -> Void) {
        let backgroundContext = persistenceController.container.newBackgroundContext()
        
        backgroundContext.perform {
            let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
            var predicates: [NSPredicate] = []
            
            // Add text search predicate (search in both title and content)
            if !query.isEmpty {
                let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
                let contentPredicate = NSPredicate(format: "content CONTAINS[cd] %@", query)
                let textPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
                predicates.append(textPredicate)
            }
            
            // Add tag filter predicate if a tag is selected
            if let tagFilter = tagFilter {
                // We need the objectID to safely reference the tag across contexts
                let tagID = tagFilter.objectID
                // Fetch the tag in this context
                if let tagInContext = backgroundContext.object(with: tagID) as? Tag {
                    let tagPredicate = NSPredicate(format: "ANY tags == %@", tagInContext)
                    predicates.append(tagPredicate)
                }
            }
            
            // Combine predicates if we have more than one
            if predicates.count > 1 {
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            } else if let predicate = predicates.first {
                fetchRequest.predicate = predicate
            }
            
            // Sort by creation date, newest first
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Note.creationDate, ascending: false)]
            
            do {
                let results = try backgroundContext.fetch(fetchRequest)
                
                // Convert to objectIDs to safely pass across contexts
                let objectIDs = results.map { $0.objectID }
                
                DispatchQueue.main.async {
                    // Convert objectIDs back to Notes in the main context
                    let mainContext = self.persistenceController.container.viewContext
                    let notes = objectIDs.compactMap { mainContext.object(with: $0) as? Note }
                    completion(notes)
                }
            } catch {
                print("Error searching notes: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    // Batch delete old notes (older than specified days)
    func deleteOldNotes(olderThanDays: Int, completion: @escaping (Int) -> Void) {
        let backgroundContext = persistenceController.container.newBackgroundContext()
        
        backgroundContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
            
            // Calculate the cutoff date
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date())!
            fetchRequest.predicate = NSPredicate(format: "creationDate < %@", cutoffDate as NSDate)
            
            // Create batch delete request
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            
            do {
                let batchResult = try backgroundContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
                
                if let objectIDs = batchResult?.result as? [NSManagedObjectID] {
                    // Sync the deletions with the main context
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                        into: [self.persistenceController.container.viewContext]
                    )
                    
                    DispatchQueue.main.async {
                        completion(objectIDs.count)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(0)
                    }
                }
            } catch {
                print("Error batch deleting notes: \(error)")
                DispatchQueue.main.async {
                    completion(-1) // Error indicator
                }
            }
        }
    }
}
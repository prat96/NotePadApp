import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleTags = [
            ("Work", "blue"),
            ("Personal", "green"),
            ("Urgent", "red")
        ]
        
        var tags: [Tag] = []
        
        // Create sample tags
        for (name, color) in sampleTags {
            let newTag = Tag(context: viewContext)
            newTag.name = name
            newTag.color = color
            tags.append(newTag)
        }
        
        // Create sample notes
        for i in 0..<5 {
            let newNote = Note(context: viewContext)
            newNote.title = "Sample Note \(i+1)"
            newNote.content = "This is the content for sample note \(i+1). Lorem ipsum dolor sit amet, consectetur adipiscing elit."
            newNote.creationDate = Date().addingTimeInterval(-Double(i * 86400))  // Earlier dates for higher indices
            
            // Add random tags to each note
            let randomTags = tags.shuffled().prefix(Int.random(in: 0...2))
            for tag in randomTags {
                newNote.addToTags(tag)
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Make sure this matches your actual .xcdatamodeld file name
        container = NSPersistentContainer(name: "NotePad")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // In a real app, you'd handle this error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Set merge policy to favor the changes in the current context during conflicts
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

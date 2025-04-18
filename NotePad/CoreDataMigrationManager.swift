//
//  demonstrates.swift
//  NotePad
//
//  Created by Prat B on 18.04.25.
//


import Foundation
import CoreData

// This class demonstrates how to handle CoreData migrations
class CoreDataMigrationManager {
    static let shared = CoreDataMigrationManager()
    
    private init() {}
    
    // MARK: - Migration Guide
    
    /*
    Data Model Migration Guide
    
    When you need to update your CoreData model, follow these steps:
    
    1. Create a new model version:
       - Select the .xcdatamodeld file in Xcode
       - Editor -> Add Model Version
       - Name it with a meaningful version name (e.g., "NotePad 2")
       
    2. Make your changes to the new model version:
       - Add entities, attributes, or relationships
       - Modify existing entities
       - Add validation rules
       
    3. Set the new version as current:
       - Select the .xcdatamodeld file
       - In the File Inspector (right panel), set "Current Version" to your new version
       
    4. For lightweight migrations (attribute additions, optional attributes):
       - Use the setup code in configureForLightweightMigration()
       
    5. For heavy migrations (complex model changes):
       - Create a mapping model (.xcmappingmodel)
       - Implement a custom NSEntityMigrationPolicy
       - Use the setup code in configureForHeavyMigration()
    */
    
    // MARK: - Example Model Update Implementation
    
    /*
    Assuming we're updating our model to add a "priority" attribute to the Note entity,
    and adding a new "Category" entity, here's how we'd set up the persistence container:
    */
    
    func configureForLightweightMigration() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "NotePad")
        
        // Configure for automatic lightweight migration
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Handle migration errors
                /*
                Common migration errors:
                1. NSMigrationMissingSourceModelError - Can't find the model for the existing store
                2. NSMigrationMissingMappingModelError - Can't find a mapping model for migration
                3. NSMigrationError - General migration failure
                */
                fatalError("Migration failed: \(error), \(error.userInfo)")
            }
        }
        
        return container
    }
    
    func configureForHeavyMigration() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "NotePad")
        
        // For heavy migrations, we need to implement a more manual process
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = false // We'll handle migration manually
        description.shouldInferMappingModelAutomatically = false
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Check if this is a migration error
                if self.isMigrationError(error) {
                    // Perform manual migration
                    self.performManualMigration()
                } else {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
        }
        
        return container
    }
    
    private func isMigrationError(_ error: NSError) -> Bool {
        let isMigrationError = error.domain == NSCocoaErrorDomain &&
            (error.code == NSPersistentStoreIncompatibleVersionHashError ||
             error.code == NSMigrationError ||
             error.code == NSMigrationMissingSourceModelError ||
             error.code == NSMigrationMissingMappingModelError)
        
        return isMigrationError
    }
    
    private func performManualMigration() {
        // This would be the implementation of a step-by-step migration process
        // For complex migrations with multiple versions, you'd:
        // 1. Determine the current store version
        // 2. Create a migration path (sequence of migrations)
        // 3. Apply migrations one by one until reaching the current version
        
        // For example, if migrating from V1 -> V3, you might need to:
        // V1 -> V2 -> V3
        
        // This is simplified and would need to be expanded for real use
        print("Performing manual migration...")
    }
    
    // MARK: - Example Model Update: Adding Priority to Notes
    
    /*
    In our hypothetical model update to add 'priority' to Note, here's what we'd do:
    
    1. Create a new model version "NotePad 2"
    2. Add a "priority" attribute (Int16) to the Note entity
    3. Set a default value (e.g., 0) for the priority attribute
    4. Set the new version as current
    5. Configure for lightweight migration
    
    The system would automatically:
    - Copy all existing notes to the new schema
    - Set their priority to the default value
    */
    
    // MARK: - Helper Functions For Adding Version 2 Features
    
    // Example of how we might set priority for an existing note after migration
    func updateNotePriority(note: Note, priority: Int16) {
        // Assuming we've added a 'priority' attribute in version 2
        // We access it using setValue since it might not be in our current Note class
        note.setValue(priority, forKey: "priority")
        
        // Save the context
        do {
            try note.managedObjectContext?.save()
        } catch {
            print("Error setting note priority: \(error)")
        }
    }
    
    // Example of how we might check if we're using the V2 model with the priority attribute
    func doesNoteHavePriority() -> Bool {
        // Check if the Note entity has a 'priority' attribute
        let entity = Note.entity()
        return entity.attributesByName["priority"] != nil
    }
}
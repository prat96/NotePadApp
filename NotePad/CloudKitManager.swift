//
//  CloudKitManager.swift
//  NotePad
//
//  Created by Prat B on 18.04.25.
//


import Foundation
import CoreData
import CloudKit

/*
 CloudKit Integration Overview
 
 To enable CloudKit with CoreData, you need to:
 
 1. Enable CloudKit in your app's capabilities:
    - Open your app target's "Signing & Capabilities"
    - Add the "iCloud" capability
    - Check "CloudKit" and create a CloudKit container
 
 2. Configure your CoreData model:
    - Open your .xcdatamodeld file
    - Select each entity you want to sync
    - In the Data Model Inspector, check "Used with CloudKit"
    - Add a "recordID" or similar attribute if needed
 
 3. Replace NSPersistentContainer with NSPersistentCloudKitContainer
 
 4. Configure the container for syncing
 
 5. Handle notifications and update the UI when changes occur
 
 6. Handle errors and conflicts
 */
/*
class CloudKitManager {
    static let shared = CloudKitManager()
    
    private init() {}
    
    // MARK: - CloudKit Container Setup
    
    func createCloudKitContainer() -> NSPersistentCloudKitContainer {
        // Create a CloudKit container instead of a regular Core Data container
        let container = NSPersistentCloudKitContainer(name: "NotePad")
        
        // Load the stores
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Handle the error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            // Configure the store for CloudKit
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.yourdomain.notepad"
            )
        }
        
        // Set up automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up transaction author name (for conflict resolution)
        container.viewContext.transactionAuthor = UIDevice.current.name
        
        return container
    }
    
    // MARK: - CloudKit Sync Status Monitoring
    
    func setupCloudKitEventMonitoring(container: NSPersistentCloudKitContainer) {
        // Setup notification handlers for CloudKit sync events
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: .main
        ) { notification in
            guard let cloudEvent = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else {
                return
            }
            
            self.handleCloudKitEvent(cloudEvent)
        }
    }
    
    private func handleCloudKitEvent(_ event: NSPersistentCloudKitContainer.Event) {
        // Handle different event types
        switch event.type {
        case .setup:
            if event.succeeded {
                print("CloudKit container setup succeeded")
            } else if let error = event.error {
                print("CloudKit container setup failed: \(error.localizedDescription)")
            }
            
        case .import:
            if event.succeeded {
                print("CloudKit import succeeded")
                // Here you might want to refresh your UI with new data
            } else if let error = event.error {
                print("CloudKit import failed: \(error.localizedDescription)")
            }
            
        case .export:
            if event.succeeded {
                print("CloudKit export succeeded")
            } else if let error = event.error {
                print("CloudKit export failed: \(error.localizedDescription)")
            }
            
        @unknown default:
            print("Unknown CloudKit event type: \(event.type)")
        }
    }
    
    // MARK: - Conflict Resolution
    
    func setupConflictResolution(container: NSPersistentCloudKitContainer) {
        // Set up a conflict resolution policy
        let description = container.persistentStoreDescriptions.first!
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Listen for remote changes
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { notification in
            // Refresh your UI here
            print("Received remote changes from CloudKit")
        }
    }
    
    // MARK: - Account Status Monitoring
    
    func checkCloudKitAccountStatus(completion: @escaping (Bool, Error?) -> Void) {
        CKContainer.default().accountStatus { (status, error) in
            switch status {
            case .available:
                completion(true, nil)
                
            case .noAccount:
                let error = NSError(
                    domain: "CloudKitErrorDomain",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No iCloud account found. Please sign in to your iCloud account."]
                )
                completion(false, error)
                
            case .restricted:
                let error = NSError(
                    domain: "CloudKitErrorDomain",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Your iCloud account is restricted."]
                )
                completion(false, error)
                
            case .couldNotDetermine:
                let error = NSError(
                    domain: "CloudKitErrorDomain",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Could not determine iCloud account status."]
                )
                completion(false, error)
                
            @unknown default:
                let error = NSError(
                    domain: "CloudKitErrorDomain",
                    code: 4,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown iCloud account status."]
                )
                completion(false, error)
            }
        }
    }
    
    // MARK: - Handling CloudKit Errors
    
    func handleCloudKitError(_ error: Error) {
        let nsError = error as NSError
        
        if nsError.domain == CKErrorDomain {
            // CloudKit specific errors
            switch CKError.Code(rawValue: nsError.code) {
            case .networkFailure, .networkUnavailable:
                // Handle network errors
                print("Network is unavailable for CloudKit")
                
            case .notAuthenticated:
                // User needs to be signed in to iCloud
                print("User is not authenticated with iCloud")
                
            case .quotaExceeded:
                // User has exceeded their iCloud quota
                print("iCloud quota exceeded")
                
            case .serverResponseLost, .serviceUnavailable:
                // CloudKit service issues
                print("CloudKit service unavailable")
                
            case .incompatibleVersion:
                // App/CloudKit version mismatch
                print("Incompatible CloudKit version")
                
            case .constraintViolation:
                // Data constraint issues
                print("CloudKit constraint violation")
                
            case .assetFileNotFound:
                // Asset file not found
                print("CloudKit asset file not found")
                
            default:
                print("Unknown CloudKit error: \(error.localizedDescription)")
            }
        } else {
            // Other types of errors
            print("Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Manual Sync Control
    
    func triggerManualSync(container: NSPersistentCloudKitContainer) {
        // You can trigger a manual export to CloudKit
        container.persistentStoreCoordinator.persistentStores.forEach { store in
            if let options = store.options, options[NSPersistentStoreRemoteChangeNotificationPostOptionKey] != nil {
                container.initializeCloudKitSchema(options: nil) { (_, error) in
                    if let error = error {
                        print("Error initializing CloudKit schema: \(error.localizedDescription)")
                    } else {
                        print("Successfully initialized CloudKit schema")
                    }
                }
            }
        }
    }
}

// MARK: - How to Modify PersistenceController for CloudKit
*/
/*
To update your PersistenceController for CloudKit, replace it with this:

```swift
import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        // Create a container that uses CloudKit
        container = NSPersistentCloudKitContainer(name: "NotePad")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure CloudKit integration
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // Enable CloudKit
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.yourdomain.notepad"
        )
        
        // Enable history tracking (needed for sync)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        // Enable remote notifications
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Handle the error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Set up auto-merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up CloudKit event monitoring
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: .main
        ) { notification in
            guard let cloudEvent = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else {
                return
            }
            
            print("CloudKit event: \(cloudEvent.type), success: \(cloudEvent.succeeded)")
            if let error = cloudEvent.error {
                print("CloudKit error: \(error.localizedDescription)")
            }
        }
        
        // Listen for remote changes
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { notification in
            print("Received remote changes from CloudKit")
        }
    }
}
```
*/

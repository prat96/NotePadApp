//
//  NotePadApp.swift
//  NotePad
//
//  Created by Prat B on 17.04.25.
//

import SwiftUI

@main
struct NotePadApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

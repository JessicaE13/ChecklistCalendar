//
//  ChecklistCalendarApp.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 4/11/26.
//

import SwiftUI
import SwiftData

@main
struct ChecklistCalendarApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                ChecklistItem.self,
                ChecklistEntry.self
            ])
            
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

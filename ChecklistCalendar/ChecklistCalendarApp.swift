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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ChecklistItem.self, ChecklistEntry.self], isAutosaveEnabled: true)
    }
}

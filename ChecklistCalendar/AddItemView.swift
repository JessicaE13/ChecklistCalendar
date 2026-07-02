//
//  AddItemView.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 6/10/26.
//

//
//  AddItemView.swift
//  ChecklistCalendar
//
//  Creates new items directly in the model context (no NotificationCenter).
//

import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let defaultDate: Date

    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var scheduleMode: ScheduleMode = .atTime
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var fuzzyDate: Date          // date-only for fuzzy modes
    @State private var durationText: String = ""
    @State private var repeatOption: RepeatOption = .noRepeat
    @State private var icon: String = "checkmark"
    @State private var itemColor: Color = ColorPair.colorPairs[0].background
    @State private var showIconColorPicker = false

    init(defaultDate: Date) {
        self.defaultDate = defaultDate

        // Round to nearest 15 minutes
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: defaultDate)
        let minutes = components.minute ?? 0
        let roundedMinutes = Int(round(Double(minutes) / 15.0) * 15.0)

        var roundedComponents = components
        roundedComponents.minute = roundedMinutes % 60

        // If rounding pushed us to 60 minutes, increment the hour
        if roundedMinutes == 60 {
            roundedComponents.hour = (components.hour ?? 0) + 1
            roundedComponents.minute = 0
        }

        let start = calendar.date(from: roundedComponents) ?? defaultDate
        let end = calendar.date(byAdding: .minute, value: 30, to: start) ?? start

        _startDate = State(initialValue: start)
        _endDate   = State(initialValue: end)
        _fuzzyDate = State(initialValue: defaultDate)
    }

    // Derive the stored date from the current state
    private var resolvedDate: Date {
        switch scheduleMode {
        case .atTime: return startDate
        case .todo:   return Calendar.current.startOfDay(for: Date())
        default:      return Calendar.current.startOfDay(for: fuzzyDate)
        }
    }

    // Duration in minutes, derived from the current state
    private var resolvedDurationMinutes: Int? {
        switch scheduleMode {
        case .atTime:
            let mins = Int(endDate.timeIntervalSince(startDate) / 60)
            return mins > 0 ? mins : nil
        case .allDay, .todo:
            return nil
        default:
            return DurationFormat.minutes(from: durationText)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Details
                Section("Details") {
                    HStack {
                        // Icon & Color picker button with two-tone
                        let colorPair = ColorPair.forColor(itemColor)

                        Button {
                            showIconColorPicker = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(colorPair.background)
                                    .frame(width: 36, height: 36)

                                Image(systemName: icon)
                                    .font(.body)
                                    .foregroundColor(colorPair.icon)
                            }
                        }
                        .buttonStyle(.plain)

                        TextField("Title", text: $title)
                    }
                    HStack {
                        Text("Location").foregroundColor(.secondary)
                        TextField("Location", text: $subtitle).multilineTextAlignment(.trailing)
                    }
                }

                // MARK: Schedule
                Section("Schedule") {
                    ScheduleFields(
                        scheduleMode: $scheduleMode,
                        startDate: $startDate,
                        endDate: $endDate,
                        fuzzyDate: $fuzzyDate,
                        durationText: $durationText,
                        repeatOption: $repeatOption
                    )
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newItem = ChecklistItem(
                            title: title.isEmpty ? "New Item" : title,
                            subtitle: subtitle,
                            icon: icon,
                            color: itemColor.toHex(),
                            date: resolvedDate,
                            durationMinutes: resolvedDurationMinutes,
                            scheduleMode: scheduleMode,
                            repeatOption: repeatOption
                        )
                        modelContext.insert(newItem)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showIconColorPicker) {
                IconColorPickerView(selectedIcon: $icon, selectedColor: $itemColor)
            }
        }
    }
}

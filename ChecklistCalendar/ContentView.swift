//
//  ContentView.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 4/11/26.
//

import SwiftUI
import SwiftData

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let components = UIColor(self).cgColor.components
        let r = components?[0] ?? 0
        let g = components?[1] ?? 0
        let b = components?[2] ?? 0
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(r * 255)),
                      lroundf(Float(g * 255)),
                      lroundf(Float(b * 255)))
    }
}

// MARK: - Checklist Entry
@Model
class ChecklistEntry {
    var id: UUID
    var text: String
    var isComplete: Bool
    
    init(id: UUID = UUID(), text: String, isComplete: Bool = false) {
        self.id = id
        self.text = text
        self.isComplete = isComplete
    }
}

// MARK: - Main View
struct ContentView: View {
    @State private var selectedDate: Date = Date()
    @State private var currentWeekOffset: Int = 0
    @State private var showAddItem: Bool = false

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            VStack() {
                TopHeader()
                    .padding(8)
                DateHeader(selectedDate: $selectedDate, currentWeekOffset: $currentWeekOffset)
                    .padding(8)
                ItemListPager(selectedDate: $selectedDate, currentWeekOffset: $currentWeekOffset)
                    .padding(.top, 8)
                Spacer()
            }
            .padding()

            // MARK: Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        showAddItem = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.primary)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddItemView(defaultDate: selectedDate)
        }
    }
}


// MARK: - Schedule Mode
enum ScheduleMode: String, CaseIterable {
    // Time of day (fuzzy)
    case anytime = "Anytime"
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    // Event (precise)
    case atTime = "At time"
    case allDay = "All day"
    // Task
    case todo = "To-do"

    var icon: String {
        switch self {
        case .anytime:   return "clock"
        case .morning:   return "sunrise"
        case .afternoon: return "sun.max"
        case .evening:   return "moon.stars"
        case .atTime:    return "calendar.badge.clock"
        case .allDay:    return "clock"
        case .todo:      return "tray"
        }
    }

    /// Whether this mode uses fuzzy time-of-day rather than a specific time
    var isFuzzy: Bool {
        switch self {
        case .morning, .afternoon, .evening, .anytime, .allDay, .todo: return true
        case .atTime: return false
        }
    }

    /// Whether this mode needs a date picker at all
    var needsDate: Bool {
        switch self {
        case .todo: return false
        default: return true
        }
    }
}

enum RepeatOption: String, CaseIterable {
    case noRepeat = "No repeat"
    case daily    = "Daily"
    case weekly   = "Weekly"
    case monthly  = "Monthly"
    case yearly   = "Yearly"
}

// MARK: - Add Item View
struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss

    let defaultDate: Date

    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var scheduleMode: ScheduleMode = .atTime
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var fuzzyDate: Date         // date-only for fuzzy modes
    @State private var duration: String = ""
    @State private var repeatOption: RepeatOption = .noRepeat
    @State private var icon: String = "checkmark"
    @State private var itemColor: Color = .blue
    @State private var showTimeOfDayPicker = false
    @State private var showRepeatPicker = false
    @State private var showIconColorPicker = false

    init(defaultDate: Date) {
        self.defaultDate = defaultDate
        let start = defaultDate
        let end = Calendar.current.date(byAdding: .minute, value: 30, to: defaultDate) ?? defaultDate
        _startDate  = State(initialValue: start)
        _endDate    = State(initialValue: end)
        _fuzzyDate  = State(initialValue: defaultDate)
    }

    // Derive a ChecklistItem date from the current state
    private var resolvedDate: Date {
        switch scheduleMode {
        case .atTime:    return startDate
        case .allDay:    return Calendar.current.startOfDay(for: fuzzyDate)
        case .todo:      return Date()
        default:         return Calendar.current.startOfDay(for: fuzzyDate)
        }
    }

    private var resolvedDuration: String {
        switch scheduleMode {
        case .atTime:
            let diff = endDate.timeIntervalSince(startDate)
            if diff <= 0 { return "" }
            let mins = Int(diff / 60)
            if mins < 60 { return "\(mins) min" }
            let hrs = mins / 60
            let rem = mins % 60
            return rem == 0 ? "\(hrs) hr" : "\(hrs) hr \(rem) min"
        default:
            return duration
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Details
                Section("Details") {
                    HStack {
                        // Icon & Color picker button
                        Button {
                            showIconColorPicker = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(itemColor)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: icon)
                                    .font(.body)
                                    .foregroundColor(.white)
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

                    // --- Time of Day row ---
                    HStack {
                        Text("Time of day")
                        Spacer()
                        Button {
                            withAnimation { showTimeOfDayPicker.toggle() }
                        } label: {
                            Label(scheduleMode.rawValue, systemImage: scheduleMode.icon)
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(timeOfDayBadgeColor())
                                )
                                .foregroundColor(timeOfDayBadgeForeground())
                        }
                        .buttonStyle(.plain)
                    }

                    if showTimeOfDayPicker {
                        timeOfDayPickerContent
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // --- Date / Starts / Ends rows (conditional) ---
                    if scheduleMode == .atTime {
                        DatePicker("Starts",
                                   selection: $startDate,
                                   displayedComponents: [.date, .hourAndMinute])
                        DatePicker("Ends",
                                   selection: $endDate,
                                   in: startDate...,
                                   displayedComponents: [.date, .hourAndMinute])
                    } else if scheduleMode.needsDate {
                        DatePicker("Date",
                                   selection: $fuzzyDate,
                                   displayedComponents: [.date])
                        // Duration for fuzzy modes (morning / afternoon / evening / anytime)
                        if scheduleMode != .allDay {
                            HStack {
                                Text("Duration").foregroundColor(.secondary)
                                TextField("e.g. 30 min, 1 hr", text: $duration)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }

                    // --- Repeat row ---
                    HStack {
                        Text("Repeat")
                        Spacer()
                        Button {
                            withAnimation { showRepeatPicker.toggle() }
                        } label: {
                            Label(repeatOption.rawValue, systemImage: "repeat")
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray5))
                                )
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }

                    if showRepeatPicker {
                        repeatPickerContent
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
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
                            duration: resolvedDuration
                        )
                        NotificationCenter.default.post(
                            name: .addChecklistItem,
                            object: newItem
                        )
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showIconColorPicker) {
                IconColorPickerView(selectedIcon: $icon, selectedColor: $itemColor)
            }
        }
    }

    // MARK: - Time of Day Picker (inline dropdown)
    private var timeOfDayPickerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Time of day group
            pickerGroupLabel("Time of day")
            ForEach([ScheduleMode.anytime, .morning, .afternoon, .evening], id: \.self) { mode in
                pickerRow(mode: mode)
            }
            Divider().padding(.vertical, 4)
            // Event group
            pickerGroupLabel("Event")
            ForEach([ScheduleMode.atTime, .allDay], id: \.self) { mode in
                pickerRow(mode: mode)
            }
            Divider().padding(.vertical, 4)
            // Task group
            pickerRow(mode: .todo)
        }
        .padding(.vertical, 4)
    }

    private func pickerGroupLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.leading, 4)
            .padding(.bottom, 2)
    }

    private func pickerRow(mode: ScheduleMode) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            scheduleMode = mode
            showTimeOfDayPicker = false
        } label: {
            HStack {
                if scheduleMode == mode {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .frame(width: 20)
                } else {
                    Spacer().frame(width: 20)
                }
                Image(systemName: mode.icon)
                    .frame(width: 20)
                Text(mode.rawValue)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    // MARK: - Repeat Picker (inline)
    private var repeatPickerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(RepeatOption.allCases, id: \.self) { option in
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    repeatOption = option
                    showRepeatPicker = false
                } label: {
                    HStack {
                        if repeatOption == option {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.semibold))
                                .frame(width: 20)
                        } else {
                            Spacer().frame(width: 20)
                        }
                        Text(option.rawValue)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Badge styling helpers
    private func timeOfDayBadgeColor() -> Color {
        switch scheduleMode {
        case .morning:   return Color(red: 0.75, green: 0.70, blue: 0.45) // warm gold
        case .afternoon: return Color(.systemGray5)
        case .evening:   return Color(.systemGray5)
        case .atTime:    return Color(.systemGray5)
        case .allDay:    return Color(.systemGray5)
        case .anytime:   return Color(.systemGray5)
        case .todo:      return Color(.systemGray5)
        }
    }

    private func timeOfDayBadgeForeground() -> Color {
        switch scheduleMode {
        case .morning: return .white
        default:       return .primary
        }
    }
}
extension Notification.Name {
    static let addChecklistItem = Notification.Name("addChecklistItem")
}


// MARK: - Date Header
struct DateHeader: View {
    @Binding var selectedDate: Date
    @Binding var currentWeekOffset: Int

    private let calendar = Calendar.current
    private let today = Calendar.current.startOfDay(for: Date())

    private func weekDays(for offset: Int) -> [Date] {
        let startOfToday = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: startOfToday)
        let daysFromSunday = weekday - 1

        guard let sunday = calendar.date(byAdding: .day, value: -daysFromSunday + (offset * 7), to: startOfToday) else { return [] }

        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: sunday)
        }
    }

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    var body: some View {
        TabView(selection: Binding(
            get: { currentWeekOffset },
            set: { newOffset in
                let oldWeekday = calendar.component(.weekday, from: selectedDate)
                let days = weekDays(for: newOffset)
                if let matchingDay = days.first(where: {
                    calendar.component(.weekday, from: $0) == oldWeekday
                }) {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    selectedDate = matchingDay
                }
                currentWeekOffset = newOffset
            }
        )) {
            ForEach(-52...52, id: \.self) { offset in
                WeekRow(
                    days: weekDays(for: offset),
                    selectedDate: $selectedDate,
                    today: today,
                    calendar: calendar,
                    dayFormatter: dayFormatter
                )
                .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 56)
    }
}

struct WeekRow: View {
    let days: [Date]
    @Binding var selectedDate: Date
    let today: Date
    let calendar: Calendar
    let dayFormatter: DateFormatter

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.element) { index, date in
                let isToday = calendar.isDate(date, inSameDayAs: today)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isTodaySelected = isSelected && isToday
                let isSelectedNotToday = isSelected && !isToday

                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    selectedDate = date
                }) {
                    VStack(spacing: 4) {
                        Text(dayFormatter.string(from: date))
                            .font(.caption2)
                            .foregroundColor(.primary)

                        ZStack {
                            if isTodaySelected {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 36, height: 36)
                            } else if isSelectedNotToday {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 36, height: 36)
                            }

                            Text("\(calendar.component(.day, from: date))")
                                .font(.title2)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundColor(
                                    isSelected
                                        ? .white
                                        : isToday
                                            ? .red
                                            : .primary
                                )
                        }
                        .frame(width: 36, height: 36)
                    }
                }
                .buttonStyle(.plain)

                if index < days.count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

// MARK: - Data Model
@Model
class ChecklistItem {
    var id: UUID
    var title: String
    var subtitle: String
    var icon: String
    var color: String = "#007AFF"  // Default value for migration compatibility
    var date: Date
    var duration: String
    var isComplete: Bool
    var notes: String
    @Relationship(deleteRule: .cascade) var checklist: [ChecklistEntry]
    
    init(id: UUID = UUID(), title: String, subtitle: String, icon: String, color: String = "#007AFF", date: Date, duration: String = "", isComplete: Bool = false, notes: String = "", checklist: [ChecklistEntry] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.date = date
        self.duration = duration
        self.isComplete = isComplete
        self.notes = notes
        self.checklist = checklist
    }
    
    // Helper to convert hex string to Color
    var uiColor: Color {
        Color(hex: color) ?? .blue
    }
}



// MARK: - Item List Pager
struct ItemListPager: View {
    @Binding var selectedDate: Date
    @Binding var currentWeekOffset: Int

    private let calendar = Calendar.current
    private let dayRange = -365...365

    private var selectedDayOffset: Int {
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return calendar.dateComponents([.day], from: today, to: selected).day ?? 0
    }

    private func date(for dayOffset: Int) -> Date {
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
    }

    private func weekOffset(for date: Date) -> Int {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1
        guard let thisSunday = calendar.date(byAdding: .day, value: -daysFromSunday, to: today),
              let targetSunday = calendar.date(
                byAdding: .day,
                value: -(calendar.component(.weekday, from: date) - 1),
                to: calendar.startOfDay(for: date)
              ) else { return 0 }
        return calendar.dateComponents([.weekOfYear], from: thisSunday, to: targetSunday).weekOfYear ?? 0
    }

    var body: some View {
        TabView(selection: Binding(
            get: { selectedDayOffset },
            set: { newDayOffset in
                let newDate = date(for: newDayOffset)
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                selectedDate = newDate
                currentWeekOffset = weekOffset(for: newDate)
            }
        )) {
            ForEach(dayRange, id: \.self) { dayOffset in
                ScrollView {
                    ItemList(selectedDate: date(for: dayOffset))
                }
                .tag(dayOffset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

// MARK: - Item List
struct ItemList: View {
    let selectedDate: Date
    private let calendar = Calendar.current
    
    @Query private var allItems: [ChecklistItem]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedItem: ChecklistItem? = nil

    private var filteredItems: [ChecklistItem] {
        allItems.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        LazyVStack {
            if filteredItems.isEmpty {
                Text("No items for this day")
                    .foregroundColor(.secondary)
                    .padding(.top, 32)
            } else {
                ForEach(filteredItems) { item in
                    ItemRow(
                        item: item,
                        onTap: {
                            selectedItem = item
                        },
                        onToggle: {
                            item.isComplete.toggle()
                        }
                    )
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(
                item: item,
                onDelete: {
                    modelContext.delete(item)
                    selectedItem = nil
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .addChecklistItem)) { notification in
            if let newItem = notification.object as? ChecklistItem {
                modelContext.insert(newItem)
            }
        }
    }
}

// MARK: - Item Detail Modal
struct ItemDetailView: View {
    var item: ChecklistItem
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) private var editMode
    @Environment(\.modelContext) private var modelContext
    
    @State private var showDeleteConfirmation = false
    @State private var newEntryText: String = ""
    @FocusState private var newEntryFocused: Bool
    
    // Schedule-related state
    @State private var scheduleMode: ScheduleMode = .atTime
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var fuzzyDate: Date = Date()
    @State private var repeatOption: RepeatOption = .noRepeat
    @State private var showTimeOfDayPicker = false
    @State private var showRepeatPicker = false
    @State private var showColorPicker = false
    @State private var showIconColorPicker = false
    @State private var isScheduleExpanded = false
    
    init(item: ChecklistItem, onDelete: @escaping () -> Void) {
        self.item = item
        self.onDelete = onDelete
        
        // Initialize schedule state based on the item
        let itemDate = item.date
        _startDate = State(initialValue: itemDate)
        _endDate = State(initialValue: Calendar.current.date(byAdding: .minute, value: 30, to: itemDate) ?? itemDate)
        _fuzzyDate = State(initialValue: Calendar.current.startOfDay(for: itemDate))
        
        // Default to .atTime mode
        _scheduleMode = State(initialValue: .atTime)
    }
    
    // Update the item's date when schedule changes
    private func updateItemDate() {
        switch scheduleMode {
        case .atTime:
            item.date = startDate
        case .allDay:
            item.date = Calendar.current.startOfDay(for: fuzzyDate)
        case .todo:
            item.date = Date()
        default:
            item.date = Calendar.current.startOfDay(for: fuzzyDate)
        }
    }
    
    private var resolvedDuration: String {
        switch scheduleMode {
        case .atTime:
            let diff = endDate.timeIntervalSince(startDate)
            if diff <= 0 { return "" }
            let mins = Int(diff / 60)
            if mins < 60 { return "\(mins) min" }
            let hrs = mins / 60
            let rem = mins % 60
            return rem == 0 ? "\(hrs) hr" : "\(hrs) hr \(rem) min"
        default:
            return item.duration
        }
    }
    
    // Schedule summary for collapsed state
    private var scheduleSummary: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        
        let dateStr = dateFormatter.string(from: item.date)
        
        switch scheduleMode {
        case .atTime:
            let startTime = timeFormatter.string(from: startDate)
            let endTime = timeFormatter.string(from: endDate)
            let duration = resolvedDuration.isEmpty ? "" : " • \(resolvedDuration)"
            return "\(dateStr) • \(startTime) - \(endTime)\(duration)"
        case .allDay:
            return "\(dateStr) • All day"
        case .todo:
            return "To-do"
        case .morning:
            let duration = item.duration.isEmpty ? "" : " • \(item.duration)"
            return "\(dateStr) • Morning\(duration)"
        case .afternoon:
            let duration = item.duration.isEmpty ? "" : " • \(item.duration)"
            return "\(dateStr) • Afternoon\(duration)"
        case .evening:
            let duration = item.duration.isEmpty ? "" : " • \(item.duration)"
            return "\(dateStr) • Evening\(duration)"
        case .anytime:
            let duration = item.duration.isEmpty ? "" : " • \(item.duration)"
            return "\(dateStr) • Anytime\(duration)"
        }
    }
    
    var body: some View {
        NavigationStack {
                VStack(spacing: 0) {
                    // MARK: Title & Icon Header
                    VStack(spacing: 0) {
                        HStack(alignment: .center, spacing: 16) {
                            // Icon picker button
                            Button {
                                showIconColorPicker = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.3))
                                        .frame(width: 64, height: 64)
                                    
                                    Image(systemName: item.icon)
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                // Title with underline
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 12) {
                                        TextField("Title", text: Binding(
                                            get: { item.title },
                                            set: { item.title = $0 }
                                        ))
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        
                                        // Completion checkbox
                                        Button {
                                            let impact = UIImpactFeedbackGenerator(style: .medium)
                                            impact.impactOccurred()
                                            item.isComplete.toggle()
                                        } label: {
                                            Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    Rectangle()
                                        .fill(.white.opacity(0.5))
                                        .frame(height: 2)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .background(item.uiColor)
                    
                Form {
                    // MARK: Location
                    Section {
                        HStack {
                            Image(systemName: "location")
                                .font(.body)
                                .foregroundColor(.secondary)
                            TextField("Location", text: Binding(
                                get: { item.subtitle },
                                set: { item.subtitle = $0 }
                            ))
                            .font(.body)
                        }
                    }
                    
                    // MARK: Date & Completion
                    Section("Schedule") {
                        
                        // Collapsed view - tap to expand
                        if !isScheduleExpanded {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isScheduleExpanded = true
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(scheduleSummary)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                        
                                        if repeatOption != .noRepeat {
                                            Text("Repeats \(repeatOption.rawValue.lowercased())")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Expanded view - full editing controls
                        if isScheduleExpanded {
                            
                            // Collapse button
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isScheduleExpanded = false
                                    showTimeOfDayPicker = false
                                    showRepeatPicker = false
                                }
                            } label: {
                                HStack {
                                    Text("Collapse")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                    Spacer()
                                    Image(systemName: "chevron.up")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        
                            // --- Time of Day row ---
                            HStack {
                                Text("Time of day")
                                Spacer()
                                Button {
                                    withAnimation { showTimeOfDayPicker.toggle() }
                                } label: {
                                    Label(scheduleMode.rawValue, systemImage: scheduleMode.icon)
                                        .font(.subheadline)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(timeOfDayBadgeColor())
                                        )
                                        .foregroundColor(timeOfDayBadgeForeground())
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if showTimeOfDayPicker {
                                timeOfDayPickerContent
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // --- Date / Starts / Ends rows (conditional) ---
                            if scheduleMode == .atTime {
                                DatePicker("Starts",
                                           selection: $startDate,
                                           displayedComponents: [.date, .hourAndMinute])
                                .onChange(of: startDate) { _, newValue in
                                    updateItemDate()
                                    // Ensure end date is after start date
                                    if endDate <= newValue {
                                        endDate = Calendar.current.date(byAdding: .minute, value: 30, to: newValue) ?? newValue
                                    }
                                }
                                DatePicker("Ends",
                                           selection: $endDate,
                                           in: startDate...,
                                           displayedComponents: [.date, .hourAndMinute])
                                .onChange(of: endDate) { _, _ in
                                    item.duration = resolvedDuration
                                }
                            } else if scheduleMode.needsDate {
                                DatePicker("Date",
                                           selection: $fuzzyDate,
                                           displayedComponents: [.date])
                                .onChange(of: fuzzyDate) { _, _ in
                                    updateItemDate()
                                }
                                // Duration for fuzzy modes (morning / afternoon / evening / anytime)
                                if scheduleMode != .allDay {
                                    HStack {
                                        Text("Duration").foregroundColor(.secondary)
                                        TextField("e.g. 30 min, 1 hr", text: Binding(
                                            get: { item.duration },
                                            set: { item.duration = $0 }
                                        ))
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                            }
                            
                            // --- Repeat row ---
                            HStack {
                                Text("Repeat")
                                Spacer()
                                Button {
                                    withAnimation { showRepeatPicker.toggle() }
                                } label: {
                                    Label(repeatOption.rawValue, systemImage: "repeat")
                                        .font(.subheadline)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color(.systemGray5))
                                        )
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if showRepeatPicker {
                                repeatPickerContent
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    
                    // MARK: Checklist
                    Section {
                        ForEach(item.checklist) { entry in
                            HStack {
                                Image(systemName: entry.isComplete ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(entry.isComplete ? .green : .secondary)
                                TextField("Item", text: Binding(
                                    get: { entry.text },
                                    set: { entry.text = $0 }
                                ))
                                    .strikethrough(entry.isComplete, color: .secondary)
                                    .foregroundColor(entry.isComplete ? .secondary : .primary)
                                    .disabled(editMode?.wrappedValue != .active)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if editMode?.wrappedValue != .active {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    entry.isComplete.toggle()
                                }
                            }
                        }
                        .onDelete { indexSet in
                            item.checklist.remove(atOffsets: indexSet)
                        }
                        .onMove { from, to in
                            item.checklist.move(fromOffsets: from, toOffset: to)
                        }
                        
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                            TextField("Add item...", text: $newEntryText)
                                .focused($newEntryFocused)
                                .onSubmit {
                                    commitNewEntry()
                                }
                        }
                    } header: {
                        HStack {
                            Text("Checklist")
                            Spacer()
                            EditButton()
                                .font(.caption)
                        }
                    }
                    
                    // MARK: Notes
                    Section("Notes") {
                        TextEditor(text: Binding(
                            get: { item.notes },
                            set: { item.notes = $0 }
                        ))
                            .frame(minHeight: 100)
                    }
                    
                    // MARK: Delete
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Item")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            commitNewEntry()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                item.isComplete.toggle()
                            } label: {
                                Label(
                                    item.isComplete ? "Mark as Incomplete" : "Mark as Complete",
                                    systemImage: item.isComplete ? "circle" : "checkmark.circle"
                                )
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete Item", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .toolbarBackground(item.uiColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .confirmationDialog(
                    "Are you sure you want to delete this item?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .sheet(isPresented: $showIconColorPicker) {
                    IconColorPickerView(
                        selectedIcon: Binding(
                            get: { item.icon },
                            set: { 
                                item.icon = $0
                                try? modelContext.save()
                            }
                        ),
                        selectedColor: Binding(
                            get: { item.uiColor },
                            set: { 
                                item.color = $0.toHex()
                                try? modelContext.save()
                            }
                        )
                    )
                }
            }
        }
    }
    
    // MARK: - Time of Day Picker (inline dropdown)
    private var timeOfDayPickerContent: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Time of day group
                pickerGroupLabel("Time of day")
                ForEach([ScheduleMode.anytime, .morning, .afternoon, .evening], id: \.self) { mode in
                    pickerRow(mode: mode)
                }
                Divider().padding(.vertical, 4)
                // Event group
                pickerGroupLabel("Event")
                ForEach([ScheduleMode.atTime, .allDay], id: \.self) { mode in
                    pickerRow(mode: mode)
                }
                Divider().padding(.vertical, 4)
                // Task group
                pickerRow(mode: .todo)
            }
            .padding(.vertical, 4)
        }
    
    private func pickerGroupLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.leading, 4)
            .padding(.bottom, 2)
    }
    
    private func pickerRow(mode: ScheduleMode) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            scheduleMode = mode
            showTimeOfDayPicker = false
            updateItemDate()
        } label: {
            HStack {
                if scheduleMode == mode {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .frame(width: 20)
                } else {
                    Spacer().frame(width: 20)
                }
                Image(systemName: mode.icon)
                    .frame(width: 20)
                Text(mode.rawValue)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
    
    // MARK: - Repeat Picker (inline)
    private var repeatPickerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(RepeatOption.allCases, id: \.self) { option in
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    repeatOption = option
                    showRepeatPicker = false
                } label: {
                    HStack {
                        if repeatOption == option {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.semibold))
                                .frame(width: 20)
                        } else {
                            Spacer().frame(width: 20)
                        }
                        Text(option.rawValue)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Badge styling helpers
    private func timeOfDayBadgeColor() -> Color {
        switch scheduleMode {
        case .morning:   return Color(red: 0.75, green: 0.70, blue: 0.45) // warm gold
        case .afternoon: return Color(.systemGray5)
        case .evening:   return Color(.systemGray5)
        case .atTime:    return Color(.systemGray5)
        case .allDay:    return Color(.systemGray5)
        case .anytime:   return Color(.systemGray5)
        case .todo:      return Color(.systemGray5)
        }
    }
    
    private func timeOfDayBadgeForeground() -> Color {
        switch scheduleMode {
        case .morning: return .white
        default:       return .primary
        }
    }
    
    private func commitNewEntry() {
        let trimmed = newEntryText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let newEntry = ChecklistEntry(text: trimmed)
        item.checklist.append(newEntry)
        newEntryText = ""
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ChecklistItem.self, ChecklistEntry.self])
}


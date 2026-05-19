//
//  ContentView.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 4/11/26.
//

import SwiftUI

// MARK: - Checklist Entry
struct ChecklistEntry: Identifiable {
    let id = UUID()
    var text: String
    var isComplete: Bool = false
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
    @State private var showTimeOfDayPicker = false
    @State private var showRepeatPicker = false

    private let icons = ["sunrise", "calendar", "checkmark", "star", "bell", "flag", "tag", "envelope", "person", "house"]

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
                        Text("Title").foregroundColor(.secondary)
                        TextField("Title", text: $title).multilineTextAlignment(.trailing)
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

                // MARK: Icon
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(icons, id: \.self) { iconName in
                                Button {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    icon = iconName
                                } label: {
                                    Image(systemName: iconName)
                                        .font(.title2)
                                        .foregroundColor(icon == iconName ? .white : .primary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(icon == iconName ? Color.accentColor : Color(.systemGray5))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
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
struct ChecklistItem: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var icon: String
    var date: Date
    var duration: String = ""
    var isComplete: Bool = false
    var notes: String = ""
    var checklist: [ChecklistEntry] = []
}

// MARK: - Item Row
struct ItemRow: View {
    let item: ChecklistItem
    let corner: CGFloat = 16
    let fontSize: Font = .title2
    let onTap: () -> Void
    let onToggle: () -> Void

    private var checklistProgress: String? {
        guard !item.checklist.isEmpty else { return nil }
        let done = item.checklist.filter(\.isComplete).count
        return "\(done)/\(item.checklist.count)"
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    private var timeLabel: String {
        let time = Self.timeFormatter.string(from: item.date)
        if item.duration.isEmpty {
            return time
        }
        return "\(time)  ·  \(item.duration)"
    }

    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .font(fontSize)
                .padding(.trailing, 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(timeLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let progress = checklistProgress {
                Text(progress)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray5))
                    )
                    .padding(.trailing, 6)
            }

            // MARK: Complete Button — 44×44 pt touch target
            Button(action: onToggle) {
                Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.primary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(Color("ItemBackgroundColor"))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
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

    @State private var items: [ChecklistItem] = {
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        func time(_ hour: Int, _ minute: Int, from base: Date) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        return [
            ChecklistItem(title: "Morning Run", subtitle: "Riverside Park", icon: "sunrise",
                          date: time(7, 0, from: today), duration: "45 min"),
            ChecklistItem(title: "Team Standup", subtitle: "Zoom", icon: "calendar",
                          date: time(9, 30, from: today), duration: "30 min"),
            ChecklistItem(title: "Buy Groceries", subtitle: "Publix", icon: "checkmark",
                          date: time(17, 0, from: today)),
            ChecklistItem(title: "Doctor Appointment", subtitle: "Mayo Clinic", icon: "calendar",
                          date: time(10, 0, from: tomorrow), duration: "1 hr"),
            ChecklistItem(title: "Call Mom", subtitle: "Home", icon: "checkmark",
                          date: time(14, 0, from: yesterday)),
        ]
    }()

    @State private var selectedItem: ChecklistItem? = nil

    private var filteredItems: [ChecklistItem] {
        items.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
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
                            if let index = items.firstIndex(where: { $0.id == item.id }) {
                                items[index].isComplete.toggle()
                            }
                        }
                    )
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(
                item: Binding(
                    get: { items.first(where: { $0.id == item.id }) ?? item },
                    set: { updated in
                        if let index = items.firstIndex(where: { $0.id == updated.id }) {
                            items[index] = updated
                        }
                    }
                ),
                onDelete: {
                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                        items.remove(at: index)
                    }
                    selectedItem = nil
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .addChecklistItem)) { notification in
            if let newItem = notification.object as? ChecklistItem {
                items.append(newItem)
            }
        }
    }
}

// MARK: - Item Detail Modal
struct ItemDetailView: View {
    @Binding var item: ChecklistItem
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) private var editMode

    @State private var showDeleteConfirmation = false
    @State private var newEntryText: String = ""
    @FocusState private var newEntryFocused: Bool

    private let icons = ["sunrise", "calendar", "checkmark", "star", "bell", "flag", "tag", "envelope", "person", "house"]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Title & Subtitle
                Section("Details") {
                    HStack {
                        Text("Title")
                            .foregroundColor(.secondary)
                        TextField("Title", text: $item.title)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Location")
                            .foregroundColor(.secondary)
                        TextField("Location", text: $item.subtitle)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // MARK: Date & Completion
                Section("Schedule") {
                    DatePicker("Date", selection: $item.date, displayedComponents: [.date, .hourAndMinute])
                    HStack {
                        Text("Duration")
                            .foregroundColor(.secondary)
                        TextField("e.g. 30 min, 1 hr", text: $item.duration)
                            .multilineTextAlignment(.trailing)
                    }
                    Toggle("Completed", isOn: $item.isComplete)
                        .tint(.green)
                }

                // MARK: Icon Picker
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    item.icon = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(item.icon == icon ? .white : .primary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(item.icon == icon ? Color.accentColor : Color(.systemGray5))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: Checklist
                Section {
                    ForEach($item.checklist) { $entry in
                        HStack {
                            Image(systemName: entry.isComplete ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(entry.isComplete ? .green : .secondary)
                            TextField("Item", text: $entry.text)
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
                    TextEditor(text: $item.notes)
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
            .navigationTitle("Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        commitNewEntry()
                        dismiss()
                    }
                }
            }
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
        }
    }

    private func commitNewEntry() {
        let trimmed = newEntryText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        item.checklist.append(ChecklistEntry(text: trimmed))
        newEntryText = ""
    }
}

#Preview {
    ContentView()
}

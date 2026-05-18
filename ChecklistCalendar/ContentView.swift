//
//  ContentView.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 4/11/26.
//

import SwiftUI

// MARK: - Main View
struct ContentView: View {
    @State private var selectedDate: Date = Date()
    @State private var currentWeekOffset: Int = 0

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
        }
    }
}


// MARK: - Date Header (updated signature)
struct DateHeader: View {
    @Binding var selectedDate: Date
    @Binding var currentWeekOffset: Int
    // ... rest unchanged


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
    var isComplete: Bool = false
    var notes: String = ""
}

// MARK: - Item Row
struct ItemRow: View {
    let item: ChecklistItem
    let corner: CGFloat = 16
    let fontSize: Font = .title2
    let onTap: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .font(fontSize)
                .padding(.trailing, 8)
            VStack(alignment: .leading) {
                Text(item.title)
                Text(item.subtitle)
                    .font(.caption2)
            }
            Spacer()
            Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isComplete ? .green : .primary)
                .onTapGesture {
                    onToggle()
                }
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

    // Convert selectedDate to a day offset from today
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

        return [
            ChecklistItem(title: "Morning Run", subtitle: "Riverside Park", icon: "sunrise", date: today),
            ChecklistItem(title: "Team Standup", subtitle: "Zoom", icon: "calendar", date: today),
            ChecklistItem(title: "Buy Groceries", subtitle: "Publix", icon: "checkmark", date: today),
            ChecklistItem(title: "Doctor Appointment", subtitle: "Mayo Clinic", icon: "calendar", date: tomorrow),
            ChecklistItem(title: "Call Mom", subtitle: "Home", icon: "checkmark", date: yesterday),
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
    }
}

// MARK: - Item Detail Modal
struct ItemDetailView: View {
    @Binding var item: ChecklistItem
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirmation = false

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
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
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
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 4/11/26.
//

import SwiftUI
import SwiftData

// MARK: - Main View

struct ContentView: View {
    @State private var selectedDate: Date = Date()
    @State private var currentWeekOffset: Int = 0
    @State private var showAddItem: Bool = false
    
    private let calendar = Calendar.current
    
    // Calculate the week offset for a given date
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
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            VStack {
                TopHeader(
                    selectedDate: selectedDate,
                    selectedDateBinding: Binding(
                        get: { selectedDate },
                        set: { newDate in
                            selectedDate = newDate
                            currentWeekOffset = weekOffset(for: newDate)
                        }
                    )
                )
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
                    // Today button
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        selectedDate = Date()
                        currentWeekOffset = 0
                    }) {
                        Text("Today")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                    .padding(.leading, 24)
                    
                    Spacer()
                    
                    // Add button
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        showAddItem = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                            .frame(width: 56, height: 56)
                    }
                    .buttonStyle(.glass)
                    .padding(.trailing, 24)
                }
                .padding(.bottom, 24)
            }
        }
        .tint(.red)
        .sheet(isPresented: $showAddItem) {
            AddItemView(defaultDate: selectedDate)
        }
    }
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
                                // .primary adapts to dark mode (was Color.black,
                                // which vanished against a dark background)
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: 36, height: 36)
                            }

                            Text("\(calendar.component(.day, from: date))")
                                .font(.title2)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundColor(
                                    isTodaySelected
                                        ? .white
                                        : isSelectedNotToday
                                            ? Color(.systemBackground)
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

// MARK: - Item List Pager

struct ItemListPager: View {
    @Binding var selectedDate: Date
    @Binding var currentWeekOffset: Int

    private let calendar = Calendar.current
    // ±364 days = exactly ±52 weeks, so the day pager and week header
    // can always reach each other's boundaries.
    private let dayRange = -364...364

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
        allItems
            .filter { shouldShowItem($0, on: selectedDate) }
            .sorted { lhs, rhs in
                if lhs.sortMinutes != rhs.sortMinutes {
                    return lhs.sortMinutes < rhs.sortMinutes
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    // Determine if an item should be shown on the selected date.
    private func shouldShowItem(_ item: ChecklistItem, on date: Date) -> Bool {
        let itemDay = calendar.startOfDay(for: item.date)
        let selectedDay = calendar.startOfDay(for: date)

        // To-dos: visible every day from creation until completed.
        // Once completed, they remain only on the day they were finished.
        if item.scheduleMode == .todo {
            if item.isComplete {
                guard let completedAt = item.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: selectedDay)
            }
            return selectedDay >= itemDay
        }

        // Don't show items scheduled for future dates
        if itemDay > selectedDay {
            return false
        }

        // If it's the exact date, always show it
        if calendar.isDate(itemDay, inSameDayAs: selectedDay) {
            return true
        }

        // Only repeating items appear on other days
        guard item.isRepeating else { return false }

        switch item.repeatRule {
        case .daily:
            return true

        case .weekly:
            return calendar.component(.weekday, from: itemDay)
                == calendar.component(.weekday, from: selectedDay)

        case .monthly:
            return calendar.component(.day, from: itemDay)
                == calendar.component(.day, from: selectedDay)

        case .yearly:
            let itemDayMonth = calendar.dateComponents([.day, .month], from: itemDay)
            let selectedDayMonth = calendar.dateComponents([.day, .month], from: selectedDay)
            return itemDayMonth.day == selectedDayMonth.day
                && itemDayMonth.month == selectedDayMonth.month

        case .noRepeat:
            return false
        }
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
                        displayDate: selectedDate,
                        onTap: {
                            selectedItem = item
                        },
                        onToggle: {
                            item.toggleCompletion(on: selectedDate)
                        }
                    )
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(
                item: item,
                occurrenceDate: selectedDate,
                onDelete: {
                    modelContext.delete(item)
                    selectedItem = nil
                }
            )
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ChecklistItem.self, ChecklistEntry.self])
}

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

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            VStack() {
                TopHeader()
                    .padding(8)
                DateHeader(selectedDate: $selectedDate)
                    .padding(8)
                ItemList(selectedDate: selectedDate)
                    .padding(.top, 8)
                Spacer()
            }
            .padding()
        }
    }
}



struct DateHeader: View {
    @Binding var selectedDate: Date
    @State private var currentWeekOffset: Int = 0


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
    let title: String
    let subtitle: String
    let icon: String
    let date: Date
    var isComplete: Bool = false
}

// MARK: - Item List
struct ItemList: View {
    let selectedDate: Date
    let corner: CGFloat = 16
    let fontSize: Font = .title2
    private let calendar = Calendar.current

    // Sample data — replace with your real data source
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
                                if let index = items.firstIndex(where: { $0.id == item.id }) {
                                    items[index].isComplete.toggle()
                                }
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: corner)
                            .fill(Color("ItemBackgroundColor"))
                    )
                }
            }
        }
    }

}

#Preview {
    ContentView()
}

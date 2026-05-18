//
//  ContentView.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 4/11/26.
//

import SwiftUI

// MARK: - Main View
struct ContentView: View {
    
    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            VStack(){
                TopHeader()
                    .padding(8)
                DateHeader()
                    .padding(8)
                ItemList()
                    .padding(.top, 8)
                Spacer()
            }
            .padding()
        }
    
    }
}



struct DateHeader: View {
    @State private var selectedDate: Date = Date()
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
        .frame(height: 52)
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
                            .font(.caption)
                            .foregroundColor(.primary)

                        ZStack {
                            if isTodaySelected {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 30, height: 30)
                            } else if isSelectedNotToday {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 30, height: 30)
                            }

                            Text("\(calendar.component(.day, from: date))")
                                .font(.body)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundColor(
                                    isSelected
                                        ? .white
                                        : isToday
                                            ? .red
                                            : .primary
                                )
                        }
                        .frame(width: 30, height: 30)
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

struct ItemList: View {
    let corner: CGFloat = 16
    let fontSize: Font = .title2
    
    var body: some View {
        LazyVStack{
            HStack {
                Image(systemName: "sunrise")
                    .font(fontSize)
                    .padding(.trailing, 8)
                VStack (alignment: .leading){
                    
                    Text("Event")
                    Text("Location")
                        .font(.caption2)
                
                }
                Spacer()
                Image(systemName: "circle")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color("ItemBackgroundColor"))
            )
            .padding(.vertical, 0)
            
            
            HStack {
                Image(systemName: "calendar")
                    .font(.title)
                    .padding(.trailing, 8)
                VStack (alignment: .leading){
                    
                    Text("Event")
                    Text("Location")
                        .font(.caption2)
                    
                }
                Spacer()
                Image(systemName: "circle")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color("ItemBackgroundColor"))
            )
            .padding(.vertical, 0)
            
            HStack {
                Image(systemName: "checkmark")
                    .font(.title)
                    .padding(.trailing, 8)
                VStack (alignment: .leading){
                    
                    Text("Event")
                    Text("Location")
                        .font(.caption2)
                
                }
                Spacer()
                Image(systemName: "circle")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color("ItemBackgroundColor"))
            )
            .padding(.vertical, 0)
            
            
        }
        
    }
}

#Preview {
    ContentView()
}

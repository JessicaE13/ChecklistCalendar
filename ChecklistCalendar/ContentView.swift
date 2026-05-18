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
    
    private let calendar = Calendar.current
    private let today = Calendar.current.startOfDay(for: Date())
    
    // Generate the 7 days of the week containing today
    private var weekDays: [Date] {
        let startOfToday = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: startOfToday) // 1 = Sun, 7 = Sat
        let daysFromSunday = weekday - 1
        
        guard let sunday = calendar.date(
            byAdding: .day,
            value: -daysFromSunday,
            to: startOfToday
        ) else { return [] }
        
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: sunday)
        }
    }
    
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE" // "Sun", "Mon", etc.
        return f
    }()
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDays.enumerated()), id: \.element) { index, date in
                let isToday = calendar.isDate(date, inSameDayAs: today)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isTodaySelected = isSelected && isToday
                let isSelectedNotToday = isSelected && !isToday

                Button(action: {
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

                // Add a Spacer after every day except the last
                if index < weekDays.count - 1 {
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

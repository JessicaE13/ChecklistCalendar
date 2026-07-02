//
//  TopHeader.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 5/17/26.
//

import SwiftUI

struct TopHeader: View {
    let selectedDate: Date
    @Binding var selectedDateBinding: Date
    
    @State private var showDatePicker = false

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f
    }()

    var body: some View {
        HStack {
            Text(Self.weekdayFormatter.string(from: selectedDate))
                .font(.largeTitle)
                .bold()
            Spacer()
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showDatePicker = true
            }) {
                HStack(spacing: 4) {
                    Text(Self.monthYearFormatter.string(from: selectedDate).uppercased())
                        .font(.headline)
                    Image(systemName: "chevron.right")
                        .font(.headline)
                }
                .foregroundColor(.primary)
            }
            .popover(isPresented: $showDatePicker) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDateBinding,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .frame(width: 320, height: 330)
                .presentationCompactAdaptation(.popover)
            }
        }
    }
}

#Preview {
    @Previewable @State var date = Date()
    TopHeader(selectedDate: date, selectedDateBinding: $date)
        .padding()
}

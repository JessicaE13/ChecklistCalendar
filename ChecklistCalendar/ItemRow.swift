//
//  ItemRow.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 5/20/26.
//

import SwiftUI

// MARK: - Item Row
struct ItemRow: View {
    let item: ChecklistItem
    let corner: CGFloat = 12
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
    
    private func parseDuration(_ duration: String) -> Int? {
        // Parse duration string like "30 min", "1 hr", "1 hr 30 min"
        var totalMinutes = 0
        let components = duration.components(separatedBy: " ")
        
        var i = 0
        while i < components.count {
            if let value = Int(components[i]) {
                if i + 1 < components.count {
                    let unit = components[i + 1]
                    if unit.hasPrefix("hr") {
                        totalMinutes += value * 60
                    } else if unit.hasPrefix("min") {
                        totalMinutes += value
                    }
                }
                i += 2
            } else {
                i += 1
            }
        }
        
        return totalMinutes > 0 ? totalMinutes : nil
    }
    
    private func formatTime(_ date: Date, showPeriod: Bool) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let period = hour < 12 ? "am" : "pm"
        
        if minute == 0 {
            return showPeriod ? "\(hour12)\(period)" : "\(hour12)"
        } else {
            return showPeriod ? "\(hour12):\(String(format: "%02d", minute))\(period)" : "\(hour12):\(String(format: "%02d", minute))"
        }
    }
    
    private func isPM(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return hour >= 12
    }

    private var timeLabel: String {
        var label = ""
        
        // If there's a duration, try to parse it and show as a time range
        if let durationMinutes = parseDuration(item.duration) {
            let calendar = Calendar.current
            if let endDate = calendar.date(byAdding: .minute, value: durationMinutes, to: item.date) {
                let startIsPM = isPM(item.date)
                let endIsPM = isPM(endDate)
                
                // Only show AM/PM on start time if it differs from end time
                let startTime = formatTime(item.date, showPeriod: startIsPM != endIsPM)
                let endTime = formatTime(endDate, showPeriod: true)
                
                label = "\(startTime) - \(endTime)"
            }
        } else {
            // Fallback to just showing the start time
            label = Self.timeFormatter.string(from: item.date)
        }
        
        // Add recurring symbol if item repeats
        if item.repeatOption != "No repeat" {
            label += " ↻"
        }
        
        return label
    }

    var body: some View {
        HStack(spacing: 0) {
            // Icon with two-tone colored background, rounded only on left side
            let colorPair = item.colorPair
            
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: corner,
                    bottomLeadingRadius: corner,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(colorPair.background)
                
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundColor(colorPair.icon)
            }
            .frame(width: 68)

            VStack(alignment: .leading, spacing: 2) {
                Text(timeLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(item.title)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 12)

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
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(item.isComplete ? Color(.systemGray) : .white)
                        .frame(width: 28, height: 28)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(.systemGray), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if item.isComplete {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .padding(.trailing, 12)
        }
        .frame(height: 72)
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

// MARK: - Preview
#Preview {
    ItemRow(
        item: ChecklistItem(
            title: "Morning Run",
            subtitle: "Riverside Park",
            icon: "sunrise",
            date: Date(),
            duration: "45 min"
        ),
        onTap: {},
        onToggle: {}
    )
}

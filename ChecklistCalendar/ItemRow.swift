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
    /// The day this row is being rendered on — repeating items show
    /// completion for this occurrence, not globally.
    let displayDate: Date
    let corner: CGFloat = 12
    let fontSize: Font = .title2
    let onTap: () -> Void
    let onToggle: () -> Void

    private var isCompleted: Bool {
        item.isCompleted(on: displayDate)
    }

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
        Calendar.current.component(.hour, from: date) >= 12
    }

    private var timeLabel: String {
        var label: String

        switch item.scheduleMode {
        case .atTime:
            if let endDate = item.endDate {
                let startIsPM = isPM(item.date)
                let endIsPM = isPM(endDate)

                // Only show AM/PM on start time if it differs from end time
                let startTime = formatTime(item.date, showPeriod: startIsPM != endIsPM)
                let endTime = formatTime(endDate, showPeriod: true)

                label = "\(startTime) - \(endTime)"
            } else {
                label = Self.timeFormatter.string(from: item.date)
            }

        case .allDay:
            label = "All day"

        case .todo:
            label = "To-do"

        default:
            // Fuzzy modes: "Morning • 45 min"
            label = item.scheduleMode.rawValue
            if !item.durationLabel.isEmpty {
                label += " • \(item.durationLabel)"
            }
        }

        if item.isRepeating {
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
                        .fill(isCompleted ? Color(.systemGray) : .white)
                        .frame(width: 28, height: 28)

                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(.systemGray), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isCompleted {
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
            durationMinutes: 45
        ),
        displayDate: Date(),
        onTap: {},
        onToggle: {}
    )
}

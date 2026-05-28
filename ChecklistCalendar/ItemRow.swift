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
                    .font(.title)
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

//
//  Models.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 6/10/26.
//

//
//  Models.swift
//  ChecklistCalendar
//
//  Data models, schedule enums, and color/duration helpers.
//

import SwiftUI
import SwiftData
import CoreLocation

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

    /// Minutes-from-midnight key used to order items within a day.
    /// `.atTime` items override this with their actual time.
    var defaultSortMinutes: Int {
        switch self {
        case .allDay:    return -1          // pinned to top
        case .morning:   return 8 * 60
        case .anytime:   return 12 * 60
        case .afternoon: return 13 * 60
        case .evening:   return 18 * 60
        case .atTime:    return 0           // unused; actual time wins
        case .todo:      return 24 * 60     // pinned to bottom
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

// MARK: - Duration

/// Durations are stored as minutes (`Int?`) on the model and only
/// converted to/from strings at the UI boundary.
enum DurationFormat {

    static func string(from minutes: Int?) -> String {
        guard let minutes, minutes > 0 else { return "" }
        if minutes < 60 { return "\(minutes) min" }
        let hrs = minutes / 60
        let rem = minutes % 60
        return rem == 0 ? "\(hrs) hr" : "\(hrs) hr \(rem) min"
    }

    /// Parses "30 min", "1 hr", "1 hr 30 min", "1h 30m", or a bare number (minutes).
    static func minutes(from string: String) -> Int? {
        let trimmed = string.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // A bare number is treated as minutes.
        if let value = Int(trimmed) { return value > 0 ? value : nil }

        var total = 0
        let components = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
        var i = 0
        while i < components.count {
            if let value = Int(components[i]), i + 1 < components.count {
                let unit = components[i + 1]
                if unit.hasPrefix("h") {
                    total += value * 60
                } else if unit.hasPrefix("m") {
                    total += value
                }
                i += 2
            } else {
                i += 1
            }
        }
        return total > 0 ? total : nil
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        let components = UIColor(self).cgColor.components
        let r = components?[0] ?? 0
        let g = components?[1] ?? 0
        let b = components?[2] ?? 0
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(r * 255)),
                      lroundf(Float(g * 255)),
                      lroundf(Float(b * 255)))
    }
}

// MARK: - Color Pair

struct ColorPair {
    let background: Color
    let icon: Color

    init(background: String, icon: String) {
        self.background = Color(hex: background) ?? .gray
        self.icon = Color(hex: icon) ?? .white
    }

    /// The single source of truth for item colors. The color picker offers
    /// exactly these backgrounds, so `forColor(_:)` always finds a match.
    static let colorPairs: [ColorPair] = [
        ColorPair(background: "E63946", icon: "FF6B7A"),  // vibrant red/bright coral
        ColorPair(background: "F77F00", icon: "FFB347"),  // bright orange/golden peach
        ColorPair(background: "FFB703", icon: "FFD966"),  // golden yellow/light yellow
        ColorPair(background: "06A77D", icon: "4ECDC4"),  // emerald/bright teal
        ColorPair(background: "00B4D8", icon: "90E0EF"),  // bright cyan/sky blue
        ColorPair(background: "4895EF", icon: "A9D6E5"),  // bright blue/light blue
        ColorPair(background: "7209B7", icon: "C77DFF"),  // purple/lavender
        ColorPair(background: "E91E63", icon: "F48FB1"),  // magenta/pink
        ColorPair(background: "FB8500", icon: "FFAA4D"),  // tangerine/light orange
        ColorPair(background: "495057", icon: "ADB5BD"),  // slate/light gray
    ]

    static func forColor(_ color: Color) -> ColorPair {
        let hexColor = color.toHex().uppercased().replacingOccurrences(of: "#", with: "")

        if let match = colorPairs.first(where: {
            $0.background.toHex().uppercased().replacingOccurrences(of: "#", with: "") == hexColor
        }) {
            return match
        }

        return colorPairs[0]
    }
}

// MARK: - Checklist Entry

@Model
class ChecklistEntry {
    var id: UUID
    var text: String
    var isComplete: Bool
    /// Explicit ordering — SwiftData does not guarantee relationship
    /// array order across launches.
    var sortOrder: Int = 0

    init(id: UUID = UUID(), text: String, isComplete: Bool = false, sortOrder: Int = 0) {
        self.id = id
        self.text = text
        self.isComplete = isComplete
        self.sortOrder = sortOrder
    }
}

// MARK: - Checklist Item

@Model
class ChecklistItem {
    var id: UUID
    var title: String
    var subtitle: String
    var icon: String
    var color: String = "#E63946"
    var date: Date
    /// Stored as minutes; formatted only at the UI boundary.
    var durationMinutes: Int?
    var scheduleModeRaw: String = ScheduleMode.atTime.rawValue
    var repeatOption: String = RepeatOption.noRepeat.rawValue
    /// Completion for non-repeating items (and to-dos).
    var isComplete: Bool
    /// Day the item was completed — lets finished to-dos stay visible
    /// on the day they were checked off.
    var completedAt: Date?
    /// Per-occurrence completion for repeating items (start-of-day dates).
    var completedDays: [Date] = []
    var notes: String
    var locationLatitude: Double?
    var locationLongitude: Double?
    @Relationship(deleteRule: .cascade) var checklist: [ChecklistEntry]

    init(id: UUID = UUID(),
         title: String,
         subtitle: String = "",
         icon: String,
         color: String = "#E63946",
         date: Date,
         durationMinutes: Int? = nil,
         scheduleMode: ScheduleMode = .atTime,
         repeatOption: RepeatOption = .noRepeat,
         isComplete: Bool = false,
         notes: String = "",
         locationLatitude: Double? = nil,
         locationLongitude: Double? = nil,
         checklist: [ChecklistEntry] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.date = date
        self.durationMinutes = durationMinutes
        self.scheduleModeRaw = scheduleMode.rawValue
        self.repeatOption = repeatOption.rawValue
        self.isComplete = isComplete
        self.notes = notes
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.checklist = checklist
    }

    // MARK: Typed accessors

    var scheduleMode: ScheduleMode {
        get { ScheduleMode(rawValue: scheduleModeRaw) ?? .atTime }
        set { scheduleModeRaw = newValue.rawValue }
    }

    var repeatRule: RepeatOption {
        get { RepeatOption(rawValue: repeatOption) ?? .noRepeat }
        set { repeatOption = newValue.rawValue }
    }

    var isRepeating: Bool { repeatRule != .noRepeat }

    // MARK: Colors

    var uiColor: Color { Color(hex: color) ?? .blue }
    var colorPair: ColorPair { ColorPair.forColor(uiColor) }

    // MARK: Location

    var hasLocation: Bool { locationLatitude != nil && locationLongitude != nil }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = locationLatitude, let lon = locationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // MARK: Duration / time

    var durationLabel: String { DurationFormat.string(from: durationMinutes) }

    /// End time derived from `date + durationMinutes` (for `.atTime` items).
    var endDate: Date? {
        guard let durationMinutes, durationMinutes > 0 else { return nil }
        return Calendar.current.date(byAdding: .minute, value: durationMinutes, to: date)
    }

    /// Sort key within a day (minutes from midnight).
    var sortMinutes: Int {
        if scheduleMode == .atTime {
            let cal = Calendar.current
            return cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
        }
        return scheduleMode.defaultSortMinutes
    }

    // MARK: Checklist ordering

    var sortedChecklist: [ChecklistEntry] {
        checklist.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: Per-occurrence completion

    /// Repeating items track completion per day; everything else uses `isComplete`.
    func isCompleted(on day: Date) -> Bool {
        guard isRepeating else { return isComplete }
        let d = Calendar.current.startOfDay(for: day)
        return completedDays.contains(d)
    }

    func toggleCompletion(on day: Date) {
        let d = Calendar.current.startOfDay(for: day)
        if isRepeating {
            if let index = completedDays.firstIndex(of: d) {
                completedDays.remove(at: index)
            } else {
                completedDays.append(d)
            }
        } else {
            isComplete.toggle()
            completedAt = isComplete ? d : nil
        }
    }
}

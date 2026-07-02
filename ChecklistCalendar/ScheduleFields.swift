//
//  ScheduleFields.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 6/10/26.
//

//
//  ScheduleFields.swift
//  ChecklistCalendar
//
//  Shared schedule-editing rows used by AddItemView and ItemDetailView.
//  Drop inside a Form Section; the rows flatten into the section.
//

import SwiftUI

struct ScheduleFields: View {
    @Binding var scheduleMode: ScheduleMode
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var fuzzyDate: Date
    @Binding var durationText: String
    @Binding var repeatOption: RepeatOption

    @State private var showTimeOfDayPicker = false
    @State private var showRepeatPicker = false

    var body: some View {
        // --- Time of Day row ---
        HStack {
            Text("Time of day")
            Spacer()
            Button {
                withAnimation { showTimeOfDayPicker.toggle() }
            } label: {
                Label(scheduleMode.rawValue, systemImage: scheduleMode.icon)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(timeOfDayBadgeColor()))
                    .foregroundColor(timeOfDayBadgeForeground())
            }
            .buttonStyle(.plain)
        }

        if showTimeOfDayPicker {
            timeOfDayPickerContent
                .transition(.opacity.combined(with: .move(edge: .top)))
        }

        // --- Date / Starts / Ends rows (conditional) ---
        if scheduleMode == .atTime {
            DatePicker("Starts",
                       selection: $startDate,
                       displayedComponents: [.date, .hourAndMinute])
                .onChange(of: startDate) { _, newValue in
                    // Keep the end after the start.
                    if endDate <= newValue {
                        endDate = Calendar.current.date(byAdding: .minute, value: 30, to: newValue) ?? newValue
                    }
                }
            DatePicker("Ends",
                       selection: $endDate,
                       in: startDate...,
                       displayedComponents: [.date, .hourAndMinute])
        } else if scheduleMode.needsDate {
            DatePicker("Date",
                       selection: $fuzzyDate,
                       displayedComponents: [.date])
            // Duration for fuzzy modes (morning / afternoon / evening / anytime)
            if scheduleMode != .allDay {
                HStack {
                    Text("Duration").foregroundColor(.secondary)
                    TextField("e.g. 30 min, 1 hr", text: $durationText)
                        .multilineTextAlignment(.trailing)
                }
            }
        }

        // --- Repeat row ---
        HStack {
            Text("Repeat")
            Spacer()
            Button {
                withAnimation { showRepeatPicker.toggle() }
            } label: {
                Label(repeatOption.rawValue, systemImage: "repeat")
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(.systemGray5)))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }

        if showRepeatPicker {
            repeatPickerContent
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Time of Day Picker (inline dropdown)

    private var timeOfDayPickerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            pickerGroupLabel("Time of day")
            ForEach([ScheduleMode.anytime, .morning, .afternoon, .evening], id: \.self) { mode in
                pickerRow(mode: mode)
            }
            Divider().padding(.vertical, 4)
            pickerGroupLabel("Event")
            ForEach([ScheduleMode.atTime, .allDay], id: \.self) { mode in
                pickerRow(mode: mode)
            }
            Divider().padding(.vertical, 4)
            pickerRow(mode: .todo)
        }
        .padding(.vertical, 4)
    }

    private func pickerGroupLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.leading, 4)
            .padding(.bottom, 2)
    }

    private func pickerRow(mode: ScheduleMode) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            scheduleMode = mode
            showTimeOfDayPicker = false
        } label: {
            HStack {
                if scheduleMode == mode {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .frame(width: 20)
                } else {
                    Spacer().frame(width: 20)
                }
                Image(systemName: mode.icon)
                    .frame(width: 20)
                Text(mode.rawValue)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    // MARK: - Repeat Picker (inline)

    private var repeatPickerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(RepeatOption.allCases, id: \.self) { option in
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    repeatOption = option
                    showRepeatPicker = false
                } label: {
                    HStack {
                        if repeatOption == option {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.semibold))
                                .frame(width: 20)
                        } else {
                            Spacer().frame(width: 20)
                        }
                        Text(option.rawValue)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Badge styling helpers

    private func timeOfDayBadgeColor() -> Color {
        switch scheduleMode {
        case .morning: return Color(red: 0.75, green: 0.70, blue: 0.45) // warm gold
        default:       return Color(.systemGray5)
        }
    }

    private func timeOfDayBadgeForeground() -> Color {
        switch scheduleMode {
        case .morning: return .white
        default:       return .primary
        }
    }
}

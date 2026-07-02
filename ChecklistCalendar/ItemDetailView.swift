//
//  ItemDetailView.swift
//  ChecklistCalendar
//
//  Item detail / edit sheet. Reads the persisted schedule mode, writes
//  schedule changes back to the model, and tracks completion per occurrence
//  for repeating items.
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import Combine
import UIKit

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            DispatchQueue.main.async {
                self.userLocation = location.coordinate
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently handle location errors
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}

// MARK: - Item Detail Modal

struct ItemDetailView: View {
    var item: ChecklistItem
    /// The day this sheet was opened from — completion for repeating items
    /// applies to this occurrence only.
    let occurrenceDate: Date
    var onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) private var editMode
    @Environment(\.modelContext) private var modelContext

    @StateObject private var locationManager = LocationManager()
    @State private var showDeleteConfirmation = false
    @State private var newEntryText: String = ""
    @FocusState private var newEntryFocused: Bool

    // Schedule-related state (initialized from the item, written back on change)
    @State private var scheduleMode: ScheduleMode
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var fuzzyDate: Date
    @State private var durationText: String
    @State private var repeatOption: RepeatOption
    @State private var showIconColorPicker = false
    @State private var isScheduleExpanded = false

    // Location search state
    @State private var locationSearchText = ""
    @State private var locationSearchResults: [MKMapItem] = []
    @FocusState private var locationFieldFocused: Bool
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var showMapChoice = false

    init(item: ChecklistItem, occurrenceDate: Date, onDelete: @escaping () -> Void) {
        self.item = item
        self.occurrenceDate = occurrenceDate
        self.onDelete = onDelete

        // Restore the persisted schedule mode instead of assuming .atTime
        let mode = item.scheduleMode
        _scheduleMode = State(initialValue: mode)
        _startDate = State(initialValue: item.date)

        let end = item.endDate
            ?? Calendar.current.date(byAdding: .minute, value: 30, to: item.date)
            ?? item.date
        _endDate = State(initialValue: end)
        _fuzzyDate = State(initialValue: Calendar.current.startOfDay(for: item.date))
        _durationText = State(initialValue: DurationFormat.string(from: item.durationMinutes))
        _repeatOption = State(initialValue: item.repeatRule)
    }

    /// Write the current schedule state back to the model.
    private func applyScheduleChanges() {
        item.scheduleMode = scheduleMode
        item.repeatRule = repeatOption

        switch scheduleMode {
        case .atTime:
            item.date = startDate
            let mins = Int(endDate.timeIntervalSince(startDate) / 60)
            item.durationMinutes = mins > 0 ? mins : nil
        case .allDay:
            item.date = Calendar.current.startOfDay(for: fuzzyDate)
            item.durationMinutes = nil
        case .todo:
            // Keep the original creation date — don't reset it on every edit.
            item.durationMinutes = nil
        default:
            item.date = Calendar.current.startOfDay(for: fuzzyDate)
            item.durationMinutes = DurationFormat.minutes(from: durationText)
        }
    }

    // Schedule summary for collapsed state
    private var scheduleSummary: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        let dateStr = dateFormatter.string(from: item.date)
        let duration = item.durationLabel.isEmpty ? "" : " • \(item.durationLabel)"

        switch scheduleMode {
        case .atTime:
            let startTime = timeFormatter.string(from: startDate)
            let endTime = timeFormatter.string(from: endDate)
            return "\(dateStr) • \(startTime) - \(endTime)\(duration)"
        case .allDay:
            return "\(dateStr) • All day"
        case .todo:
            return "To-do"
        default:
            return "\(dateStr) • \(scheduleMode.rawValue)\(duration)"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Title & Icon Header
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 16) {
                        // Icon picker button with pale background and bold circle
                        let colorPair = item.colorPair
                        
                        // Determine if we should use white or black for the icon based on color luminance
                        let iconColor: Color = {
                            let uiColor = UIColor(item.uiColor)
                            var red: CGFloat = 0
                            var green: CGFloat = 0
                            var blue: CGFloat = 0
                            var alpha: CGFloat = 0
                            if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                                let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
                                return luminance > 0.5 ? Color.black : Color.white
                            } else if let cgColor = uiColor.cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .relativeColorimetric, options: nil),
                                      let components = cgColor.components, components.count >= 3 {
                                let r = components[0]
                                let g = components[1]
                                let b = components[2]
                                let luminance = 0.299 * r + 0.587 * g + 0.114 * b
                                return luminance > 0.5 ? Color.black : Color.white
                            } else {
                                return Color.white
                            }
                        }()

                        Button {
                            showIconColorPicker = true
                        } label: {
                            ZStack {
                                // Pale/translucent rounded rectangle background
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorPair.icon.opacity(0.15))
                                    .frame(width: 72, height: 72)
                                
                                // Bold colored circle
                                Circle()
                                    .fill(colorPair.icon)
                                    .frame(width: 56, height: 56)

                                // Icon with context-aware color
                                Image(systemName: item.icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(iconColor)
                            }
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 8) {
                            // Title with underline
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 12) {
                                    TextField("Title", text: Binding(
                                        get: { item.title },
                                        set: { item.title = $0 }
                                    ))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                    // Completion checkbox (per-occurrence for repeating items)
                                    Button {
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                        item.toggleCompletion(on: occurrenceDate)
                                    } label: {
                                        Image(systemName: item.isCompleted(on: occurrenceDate) ? "checkmark.circle.fill" : "circle")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Rectangle()
                                    .fill(.white.opacity(0.5))
                                    .frame(height: 2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(item.uiColor)

                Form {
                    // MARK: Location
                    Section {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Image(systemName: "location")
                                    .font(.body)
                                    .foregroundColor(.secondary)

                                if item.hasLocation && !locationFieldFocused {
                                    Button {
                                        showMapChoice = true
                                    } label: {
                                        HStack {
                                            Text(item.subtitle)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .font(.caption)
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            locationSearchText = item.subtitle
                                            locationFieldFocused = true
                                        } label: {
                                            Label("Change Location", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            item.subtitle = ""
                                            item.locationLatitude = nil
                                            item.locationLongitude = nil
                                            locationSearchText = ""
                                            locationSearchResults = []
                                        } label: {
                                            Label("Remove Location", systemImage: "trash")
                                        }
                                    }
                                } else {
                                    TextField("Add location", text: $locationSearchText)
                                        .font(.body)
                                        .focused($locationFieldFocused)
                                        .onChange(of: locationSearchText) { _, newValue in
                                            searchTask?.cancel()
                                            searchTask = Task {
                                                try? await Task.sleep(for: .milliseconds(300))  // 300ms debounce
                                                guard !Task.isCancelled else { return }

                                                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                    searchNearbyLocations()
                                                } else {
                                                    searchLocations(query: newValue)
                                                }
                                            }
                                        }
                                        .onChange(of: locationFieldFocused) { _, isFocused in
                                            if isFocused && locationSearchText.isEmpty {
                                                // Show nearby suggestions when focusing on empty field
                                                searchNearbyLocations()
                                            }
                                        }
                                        .onSubmit {
                                            locationFieldFocused = false
                                        }
                                }
                            }

                            // Dropdown suggestions
                            if locationFieldFocused && !locationSearchResults.isEmpty {
                                Divider()
                                    .padding(.vertical, 8)

                                ForEach(locationSearchResults, id: \.self) { mapItem in
                                    Button {
                                        selectLocation(mapItem)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(mapItem.name ?? "Unknown")
                                                .font(.body)
                                                .foregroundColor(.primary)

                                            if let address = formatAddress(for: mapItem) {
                                                Text(address)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    if mapItem != locationSearchResults.last {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Schedule
                    Section("Schedule") {

                        // Collapsed view - tap to expand
                        if !isScheduleExpanded {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isScheduleExpanded = true
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(scheduleSummary)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)

                                        if repeatOption != .noRepeat {
                                            Text("Repeats \(repeatOption.rawValue.lowercased())")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        // Expanded view - full editing controls
                        if isScheduleExpanded {

                            // Collapse button
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isScheduleExpanded = false
                                }
                            } label: {
                                HStack {
                                    Text("Collapse")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                    Spacer()
                                    Image(systemName: "chevron.up")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            // Shared schedule rows (same component as AddItemView)
                            ScheduleFields(
                                scheduleMode: $scheduleMode,
                                startDate: $startDate,
                                endDate: $endDate,
                                fuzzyDate: $fuzzyDate,
                                durationText: $durationText,
                                repeatOption: $repeatOption
                            )
                        }
                    }
                    // Write any schedule edit back to the model
                    .onChange(of: scheduleMode) { _, _ in applyScheduleChanges() }
                    .onChange(of: startDate) { _, _ in applyScheduleChanges() }
                    .onChange(of: endDate) { _, _ in applyScheduleChanges() }
                    .onChange(of: fuzzyDate) { _, _ in applyScheduleChanges() }
                    .onChange(of: durationText) { _, _ in applyScheduleChanges() }
                    .onChange(of: repeatOption) { _, _ in applyScheduleChanges() }

                    // MARK: Checklist
                    Section {
                        ForEach(item.sortedChecklist) { entry in
                            HStack {
                                TextField("Item", text: Binding(
                                    get: { entry.text },
                                    set: { entry.text = $0 }
                                ))
                                    .strikethrough(entry.isComplete, color: .secondary)
                                    .foregroundColor(entry.isComplete ? .secondary : .primary)
                                    .disabled(editMode?.wrappedValue != .active)

                                Spacer()

                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    entry.isComplete.toggle()
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(entry.isComplete ? Color("GrayColor") : .white)
                                            .frame(width: 22, height: 22)

                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(Color("GrayColor"), lineWidth: 2)
                                            .frame(width: 22, height: 22)

                                        if entry.isComplete {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(editMode?.wrappedValue == .active)
                            }
                            .contentShape(Rectangle())
                        }
                        .onDelete { indexSet in
                            let sorted = item.sortedChecklist
                            for index in indexSet {
                                let entry = sorted[index]
                                item.checklist.removeAll { $0.id == entry.id }
                                modelContext.delete(entry)
                            }
                        }
                        .onMove { from, to in
                            var sorted = item.sortedChecklist
                            sorted.move(fromOffsets: from, toOffset: to)
                            // Persist the new order explicitly
                            for (index, entry) in sorted.enumerated() {
                                entry.sortOrder = index
                            }
                        }

                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                            TextField("Add item...", text: $newEntryText)
                                .focused($newEntryFocused)
                                .onSubmit {
                                    commitNewEntry()
                                }
                        }
                    } header: {
                        HStack {
                            Text("Checklist")
                            Spacer()
                            EditButton()
                                .font(.caption)
                        }
                    }

                    // MARK: Notes
                    Section("Notes") {
                        TextEditor(text: Binding(
                            get: { item.notes },
                            set: { item.notes = $0 }
                        ))
                            .frame(minHeight: 100)
                    }

                    // MARK: Delete
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Item")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color("BackgroundColor"))
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            commitNewEntry()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                item.toggleCompletion(on: occurrenceDate)
                            } label: {
                                Label(
                                    item.isCompleted(on: occurrenceDate) ? "Mark as Incomplete" : "Mark as Complete",
                                    systemImage: item.isCompleted(on: occurrenceDate) ? "circle" : "checkmark.circle"
                                )
                            }

                            Divider()

                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete Item", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .toolbarBackground(item.uiColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .confirmationDialog(
                    "Are you sure you want to delete this item?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .sheet(isPresented: $showIconColorPicker) {
                    IconColorPickerView(
                        selectedIcon: Binding(
                            get: { item.icon },
                            set: {
                                item.icon = $0
                                try? modelContext.save()
                            }
                        ),
                        selectedColor: Binding(
                            get: { item.uiColor },
                            set: {
                                item.color = $0.toHex()
                                try? modelContext.save()
                            }
                        )
                    )
                }
                .confirmationDialog(
                    "Open location in",
                    isPresented: $showMapChoice,
                    titleVisibility: .visible
                ) {
                    Button {
                        openInAppleMaps()
                    } label: {
                        Text("Apple Maps")
                    }

                    Button {
                        openInGoogleMaps()
                    } label: {
                        Text("Google Maps")
                    }

                    Button("Cancel", role: .cancel) { }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func openInAppleMaps() {
        guard let coordinate = item.coordinate else { return }

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = item.subtitle

        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func openInGoogleMaps() {
        guard let coordinate = item.coordinate else { return }

        let googleMapsURLString = "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving"

        if let url = URL(string: googleMapsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            let webURLString = "https://www.google.com/maps/dir/?api=1&destination=\(coordinate.latitude),\(coordinate.longitude)&travelmode=driving"
            if let webURL = URL(string: webURLString) {
                UIApplication.shared.open(webURL)
            }
        }
    }

    private func searchLocations(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchNearbyLocations()
            return
        }

        if locationManager.userLocation == nil {
            locationManager.requestLocation()
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmedQuery
        request.resultTypes = [.pointOfInterest, .address]

        if let userLocation = locationManager.userLocation {
            request.region = MKCoordinateRegion(
                center: userLocation,
                latitudinalMeters: 50_000,
                longitudinalMeters: 50_000
            )
        } else {
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                latitudinalMeters: 500_000,
                longitudinalMeters: 500_000
            )
        }

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            var results = response?.mapItems ?? []
            if results.count > 15 {
                results = Array(results.prefix(15))
            }

            self.processFinalResults(results, query: trimmedQuery)
        }
    }

    private func processFinalResults(_ results: [MKMapItem], query: String) {
        let queryLower = query.lowercased().trimmingCharacters(in: .whitespaces)

        var scored = results.map { item -> (item: MKMapItem, score: Double) in
            let name = (item.name ?? "").lowercased()
            let address = (self.formatAddress(for: item) ?? "").lowercased()
            let full = name + " " + address

            var score: Double = 0.0

            if name.hasPrefix(queryLower) || full.hasPrefix(queryLower) {
                score += 100
            } else if name.contains(queryLower) || full.contains(queryLower) {
                score += 60
            } else {
                let queryWords = queryLower.split(separator: " ")
                let nameWords = name.split(separator: " ")

                for qWord in queryWords {
                    if nameWords.contains(where: { $0.hasPrefix(qWord) || $0.contains(qWord) }) {
                        score += 30
                    }
                }
            }

            if queryLower.count <= 6 {
                score += 15
            }

            return (item, score)
        }

        scored.sort {
            $0.score > $1.score ||
            ($0.score == $1.score && ($0.item.name ?? "") < ($1.item.name ?? ""))
        }

        self.locationSearchResults = Array(scored.map { $0.item }.prefix(10))
    }

    private func searchNearbyLocations() {
        if locationManager.userLocation == nil {
            locationManager.requestLocation()
        }

        // Purpose-built API for "what's around me"
        let request = MKLocalPointsOfInterestRequest(
            center: locationManager.userLocation ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 10_000
        )

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                locationSearchResults = Array(response.mapItems.prefix(8))
            } else {
                locationSearchResults = []
            }
        }
    }

    private func selectLocation(_ mapItem: MKMapItem) {
        item.subtitle = mapItem.name ?? ""
        let coordinate = mapItem.placemark.coordinate
        item.locationLatitude = coordinate.latitude
        item.locationLongitude = coordinate.longitude
        locationSearchText = mapItem.name ?? ""
        locationSearchResults = []
        locationFieldFocused = false
        try? modelContext.save()
    }

    private func formatAddress(for mapItem: MKMapItem) -> String? {
        // Build a short address from the placemark components
        let placemark = mapItem.placemark
        let components = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
         .filter { !$0.isEmpty }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    private func commitNewEntry() {
        let trimmed = newEntryText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (item.checklist.map(\.sortOrder).max() ?? -1) + 1
        let newEntry = ChecklistEntry(text: trimmed, sortOrder: nextOrder)
        item.checklist.append(newEntry)
        newEntryText = ""
    }
}


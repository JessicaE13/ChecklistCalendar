//
//  IconColorPickerView.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 5/28/26.
//

import SwiftUI

// MARK: - Icon Category
struct IconCategory: Identifiable {
    let id = UUID()
    let name: String
    let systemImage: String
    let icons: [String]
}

// MARK: - Icon Color Picker View
struct IconColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    @Binding var selectedColor: Color
    
    @State private var searchText: String = ""
    @State private var recentlyUsedIcons: [String] = UserDefaults.standard.stringArray(forKey: "recentlyUsedIcons") ?? []
    
    private let colors: [Color] = [
        Color(hex: "f13539") ?? .red,              // vibrant red (new default)
        Color(red: 0.85, green: 0.55, blue: 0.52),  // coral
        Color(red: 0.95, green: 0.63, blue: 0.42),  // peach
        Color(red: 0.96, green: 0.73, blue: 0.25),  // orange/yellow
        Color(red: 0.64, green: 0.73, blue: 0.47),  // sage green
        Color(red: 0.53, green: 0.62, blue: 0.71),  // steel blue
        Color(red: 0.43, green: 0.60, blue: 0.55),  // teal
        Color(red: 0.63, green: 0.47, blue: 0.52),  // mauve
        Color(red: 0.43, green: 0.48, blue: 0.57),  // slate
        Color(red: 0.27, green: 0.27, blue: 0.27),  // charcoal
    ]
    
    // Icon categories with SF Symbols
    private let iconCategories: [IconCategory] = [
        IconCategory(
            name: "Suggestions",
            systemImage: "sparkles",
            icons: ["sunrise", "sun.max", "fork.knife", "figure.run", "book", "pencil", "bed.double"]
        ),
        IconCategory(
            name: "Time & Productivity",
            systemImage: "clock",
            icons: ["clock", "alarm", "timer", "stopwatch", "calendar", "calendar.badge.clock", "checkmark", "checkmark.circle", "list.bullet", "square.and.pencil", "note.text", "doc.text"]
        ),
        IconCategory(
            name: "Communication",
            systemImage: "envelope",
            icons: ["envelope", "envelope.open", "phone", "phone.fill", "message", "message.fill", "bubble.left.and.bubble.right", "video", "video.fill", "paperplane", "paperplane.fill"]
        ),
        IconCategory(
            name: "Food & Drink",
            systemImage: "fork.knife",
            icons: ["fork.knife", "cup.and.saucer", "wineglass", "mug", "birthday.cake", "cart", "basket", "bag"]
        ),
        IconCategory(
            name: "Health & Fitness",
            systemImage: "figure.run",
            icons: ["figure.run", "figure.walk", "figure.yoga", "figure.strengthtraining.traditional", "heart", "heart.fill", "cross.case", "pills", "bed.double", "zzz", "leaf", "drop"]
        ),
        IconCategory(
            name: "Travel & Places",
            systemImage: "airplane",
            icons: ["airplane", "car", "bus", "tram", "bicycle", "figure.walk", "map", "mappin", "location", "location.fill", "globe", "globe.americas", "building.2", "house", "house.fill"]
        ),
        IconCategory(
            name: "Entertainment",
            systemImage: "tv",
            icons: ["tv", "music.note", "headphones", "hifispeaker", "guitars", "book", "book.fill", "gamecontroller", "paintbrush", "photo", "camera", "film", "theatermasks"]
        ),
        IconCategory(
            name: "Work & Education",
            systemImage: "briefcase",
            icons: ["briefcase", "laptopcomputer", "desktopcomputer", "book.closed", "graduationcap", "pencil", "pencil.circle", "highlighter", "scissors", "paperclip", "folder", "doc.on.doc", "chart.bar"]
        ),
        IconCategory(
            name: "Shopping",
            systemImage: "cart",
            icons: ["cart", "cart.fill", "bag", "bag.fill", "basket", "creditcard", "giftcard", "tag", "tag.fill", "storefront"]
        ),
        IconCategory(
            name: "Social",
            systemImage: "person.2",
            icons: ["person", "person.fill", "person.2", "person.2.fill", "person.3", "person.3.fill", "bubble.left.and.bubble.right", "heart.text.square", "hand.wave"]
        ),
        IconCategory(
            name: "Nature & Weather",
            systemImage: "leaf",
            icons: ["leaf", "leaf.fill", "tree", "flame", "drop", "drop.fill", "sun.max", "sun.min", "moon", "moon.stars", "cloud", "cloud.rain", "cloud.snow", "snowflake", "wind"]
        ),
        IconCategory(
            name: "Home & Garden",
            systemImage: "house",
            icons: ["house", "house.fill", "lightbulb", "lightbulb.fill", "lamp.desk", "lamp.floor", "fan", "trash", "trash.fill", "paintbrush.pointed", "hammer", "wrench", "screwdriver"]
        ),
        IconCategory(
            name: "Bathroom",
            systemImage: "shower",
            icons: ["shower", "shower.fill", "toilet", "sink", "comb", "eyeglasses", "theatermasks.fill"]
        ),
        IconCategory(
            name: "Pets",
            systemImage: "pawprint",
            icons: ["pawprint", "pawprint.fill", "hare", "hare.fill", "tortoise", "tortoise.fill", "bird", "fish"]
        ),
        IconCategory(
            name: "Symbols",
            systemImage: "star",
            icons: ["star", "star.fill", "heart", "heart.fill", "flag", "flag.fill", "bell", "bell.fill", "bolt", "bolt.fill", "exclamationmark.triangle", "questionmark.circle", "info.circle"]
        )
    ]
    
    // Computed properties for filtering
    private var filteredCategories: [IconCategory] {
        if searchText.isEmpty {
            return iconCategories
        }
        
        return iconCategories.compactMap { category in
            let filteredIcons = category.icons.filter { icon in
                icon.localizedCaseInsensitiveContains(searchText) ||
                category.name.localizedCaseInsensitiveContains(searchText)
            }
            
            if filteredIcons.isEmpty {
                return nil
            }
            
            return IconCategory(
                name: category.name,
                systemImage: category.systemImage,
                icons: filteredIcons
            )
        }
    }
    
    private var shouldShowSuggestions: Bool {
        searchText.isEmpty
    }
    
    private var shouldShowRecentlyUsed: Bool {
        searchText.isEmpty && !recentlyUsedIcons.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Color Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                selectedColor = color
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 48, height: 48)
                                    
                                    if colorsAreEqual(selectedColor, color) {
                                        Circle()
                                            .strokeBorder(.black, lineWidth: 3)
                                            .frame(width: 48, height: 48)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color(.systemGray6))
                
                Divider()
                
                // MARK: Icon Grid with Categories
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        
                        // Recently Used Section
                        if shouldShowRecentlyUsed {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Recently Used")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                
                                IconGrid(
                                    icons: recentlyUsedIcons,
                                    selectedIcon: $selectedIcon,
                                    onSelect: { icon in
                                        selectIcon(icon)
                                    }
                                )
                            }
                        }
                        
                        // Icon Categories
                        ForEach(filteredCategories) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: category.systemImage)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(category.name)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                
                                IconGrid(
                                    icons: category.icons,
                                    selectedIcon: $selectedIcon,
                                    onSelect: { icon in
                                        selectIcon(icon)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(Color(.systemBackground))
                
                // MARK: Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Color & Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Reset to Default") {
                            selectedIcon = "checkmark"
                            selectedColor = ColorPair.colorPairs[0].background  // Default to vibrant red background
                        }
                        Button("Clear Recently Used") {
                            recentlyUsedIcons.removeAll()
                            UserDefaults.standard.set([], forKey: "recentlyUsedIcons")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func selectIcon(_ icon: String) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        selectedIcon = icon
        
        // Update recently used
        if let index = recentlyUsedIcons.firstIndex(of: icon) {
            recentlyUsedIcons.remove(at: index)
        }
        recentlyUsedIcons.insert(icon, at: 0)
        
        // Keep only last 10
        if recentlyUsedIcons.count > 10 {
            recentlyUsedIcons = Array(recentlyUsedIcons.prefix(10))
        }
        
        UserDefaults.standard.set(recentlyUsedIcons, forKey: "recentlyUsedIcons")
        
        dismiss()
    }
    
    private func colorsAreEqual(_ color1: Color, _ color2: Color) -> Bool {
        let uiColor1 = UIColor(color1)
        let uiColor2 = UIColor(color2)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01
    }
}

// MARK: - Icon Grid
struct IconGrid: View {
    let icons: [String]
    @Binding var selectedIcon: String
    let onSelect: (String) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 64, maximum: 80), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(icons, id: \.self) { icon in
                Button {
                    onSelect(icon)
                } label: {
                    ZStack {
                        Circle()
                            .fill(selectedIcon == icon ? Color.primary : Color(.systemGray5))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(selectedIcon == icon ? Color(.systemBackground) : .primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview
#Preview {
    IconColorPickerView(
        selectedIcon: .constant("sunrise"),
        selectedColor: .constant(Color(hex: "E63946") ?? .red)  // Default vibrant red background
    )
}

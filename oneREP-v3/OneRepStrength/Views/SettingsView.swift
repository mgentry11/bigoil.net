
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var audioManager: AudioManager
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // V3 Header
            HStack {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 60)
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 24) {
                    // Color Theme Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color Theme")
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.text)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(AppTheme.allCases) { theme in
                                ThemeCard(
                                    theme: theme,
                                    isSelected: themeManager.currentTheme == theme
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        themeManager.currentTheme = theme
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Voice Options Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Voice Options")
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.text)
                            .padding(.horizontal)

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Standard Voices")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                HStack(spacing: 8) {
                                    VoiceButton(style: .male, currentStyle: audioManager.voiceStyle) {
                                        audioManager.voiceStyle = .male
                                    }
                                    VoiceButton(style: .female, currentStyle: audioManager.voiceStyle) {
                                        audioManager.voiceStyle = .female
                                    }
                                    VoiceButton(style: .digital, currentStyle: audioManager.voiceStyle) {
                                        audioManager.voiceStyle = .digital
                                    }
                                    Spacer()
                                }
                            }

                            Divider().background(Color.gray.opacity(0.3))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pro Voices")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Button(action: { audioManager.voiceStyle = .commander }) {
                                    HStack {
                                        Text("PRO")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(ThemeManager.shared.primary)
                                            .cornerRadius(4)

                                        Text("Commander")
                                            .font(.headline)
                                            .foregroundColor(ThemeManager.shared.text)
                                        
                                        Spacer()
                                        
                                        if audioManager.voiceStyle == .commander {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(ThemeManager.shared.primary)
                                        }
                                    }
                                    .padding(12)
                                    .background(audioManager.voiceStyle == .commander ? ThemeManager.shared.primary.opacity(0.1) : Color(white: 0.2))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(audioManager.voiceStyle == .commander ? ThemeManager.shared.primary : Color.clear, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding()
                        .glassCardBackground()
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    // Commander Sound Mapping
                    if audioManager.voiceStyle == .commander {
                        NavigationLink(destination: SoundMappingView()) {
                            HStack {
                                Image(systemName: "waveform")
                                    .foregroundColor(ThemeManager.shared.primary)
                                Text("Map Commander Sounds")
                                    .fontWeight(.medium)
                                    .foregroundColor(ThemeManager.shared.text)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .glassCardBackground()
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    // Phase Timing Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Phase Timing")
                                .font(.headline)
                                .foregroundColor(ThemeManager.shared.text)
                            Spacer()
                            Button(action: {
                                workoutManager.phaseSettings = PhaseSettings()
                                UserDefaults.standard.removeObject(forKey: "phaseSettings")
                            }) {
                                Text("Reset")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal)

                        VStack(spacing: 0) {
                            PhaseTimingRow(
                                title: "Prep",
                                value: $workoutManager.phaseSettings.prepDuration,
                                range: 0...30
                            )
                            Divider().background(Color.gray.opacity(0.2))
                            PhaseTimingRow(
                                title: "Positioning",
                                value: $workoutManager.phaseSettings.positioningDuration,
                                range: 0...15
                            )
                            Divider().background(Color.gray.opacity(0.2))
                            PhaseTimingRow(
                                title: "Eccentric",
                                value: $workoutManager.phaseSettings.eccentricDuration,
                                range: 10...60
                            )
                            Divider().background(Color.gray.opacity(0.2))
                            PhaseTimingRow(
                                title: "Concentric",
                                value: $workoutManager.phaseSettings.concentricDuration,
                                range: 10...60
                            )
                            Divider().background(Color.gray.opacity(0.2))
                            PhaseTimingRow(
                                title: "Final Eccentric",
                                value: $workoutManager.phaseSettings.finalEccentricDuration,
                                range: 20...90
                            )
                            Divider().background(Color.gray.opacity(0.2))
                            PhaseTimingRow(
                                title: "Rest",
                                value: $workoutManager.phaseSettings.restDuration,
                                range: 30...180
                            )
                        }
                        .padding(.vertical, 8)
                        .glassCardBackground()
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    // Sync Exercises
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sync & Tools")
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.text)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            NavigationLink(destination: ScheduleView()) {
                                SettingsRow(icon: "calendar", title: "Workout Schedule")
                            }
                            
                            Divider().background(Color.gray.opacity(0.2))

                            NavigationLink(destination: SyncCodeView()) {
                                SettingsRow(icon: "arrow.triangle.2.circlepath", title: "Import from Website")
                            }
                            
                            if let exerciseLibraryURL = URL(string: "https://onerepstrength.com/exercises.html") {
                                Divider().background(Color.gray.opacity(0.2))
                                Link(destination: exerciseLibraryURL) {
                                    SettingsRow(icon: "globe", title: "Browse Exercise Library", showChevron: false, extraIcon: "arrow.up.right.square")
                                }
                            }
                        }
                        .glassCardBackground()
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }



                    // About
                    VStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.gray)
                        Text("OneRepStrength v1.0.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 120) // Floating menu spacing
                }
            }
        }
        .background(ThemeManager.shared.background)
    }
}

// MARK: - Helper Views

struct PhaseTimingRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(ThemeManager.shared.text)
            Spacer()
            Text("\(value)s")
                .foregroundColor(ThemeManager.shared.primary)
                .frame(width: 40, alignment: .trailing)
            
            Stepper("", value: $value, in: range)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var showChevron: Bool = true
    var extraIcon: String? = nil
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ThemeManager.shared.primary)
                .frame(width: 24)
            Text(title)
                .foregroundColor(ThemeManager.shared.text)
            Spacer()
            if let extra = extraIcon {
                Image(systemName: extra)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ThemeManager.shared.primary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(ThemeManager.shared.text)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(ThemeManager.shared.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Voice Button
struct VoiceButton: View {
    let style: AudioManager.VoiceStyle
    let currentStyle: AudioManager.VoiceStyle
    let action: () -> Void

    var label: String {
        switch style {
        case .male: return "M"
        case .female: return "F"
        case .digital: return "D"
        case .commander: return "C"
        case .elevenLabs: return "AI"
        }
    }

    var isSelected: Bool {
        style == currentStyle
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .black : .white)
                .frame(width: 44, height: 44)
                .background(isSelected ? ThemeManager.shared.primary : Color(white: 0.2))
                .cornerRadius(10)
        }
    }
}

// MARK: - Theme Card
struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Color preview grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 0),
                    GridItem(.flexible(), spacing: 0)
                ], spacing: 0) {
                    ForEach(0..<4, id: \.self) { index in
                        theme.previewColors[index]
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)

                Text(theme.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.text)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(ThemeManager.shared.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? theme.primaryColor.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sync Code View
struct SyncCodeView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var syncCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            // Instructions
            VStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 50))
                    .foregroundColor(ThemeManager.shared.primary)

                Text("Import Exercises")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)

                Text("Enter the 6-character code from the website to import your selected exercises.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

            // Code Input
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    let char = index < syncCode.count ? String(syncCode[syncCode.index(syncCode.startIndex, offsetBy: index)]) : ""
                    Text(char)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .frame(width: 44, height: 56)
                        .background(ThemeManager.shared.card)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(index < syncCode.count ? ThemeManager.shared.primary : Color(white: 0.3), lineWidth: 2)
                        )
                }
            }

            // Hidden text field for input
            TextField("", text: $syncCode)
                .keyboardType(.asciiCapable)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .focused($isInputFocused)
                .onChange(of: syncCode) { oldValue, newValue in
                    // Limit to 6 characters, uppercase only
                    let filtered = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
                    if filtered != syncCode {
                        syncCode = filtered
                    }
                }

            // Tap to edit hint
            Button(action: { isInputFocused = true }) {
                Text("Tap to enter code")
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.primary)
            }

            // Error/Success messages
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            if let success = successMessage {
                Text(success)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal)
            }

            Spacer()

            // Import button
            Button(action: importExercises) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Text("Import Exercises")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(syncCode.count == 6 ? ThemeManager.shared.primary : Color.gray)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .disabled(syncCode.count != 6 || isLoading)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(ThemeManager.shared.background)
        .navigationTitle("Import from Website")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    @FocusState private var isInputFocused: Bool

    private func importExercises() {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            successMessage = "Sync codes require server storage. For now, use the 'Add Exercise' button in the app to add exercises from the suggested list."
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        }
    }
}

// MARK: - Schedule View

struct ScheduleView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var scheduler = WorkoutScheduler.shared
    @ObservedObject var logManager = WorkoutLogManager.shared
    
    @State private var selectedDate: Date = Date()
    @State private var showingTimePicker = false
    
    private let calendar = Calendar.current
    
    // Get workout dates from logs for the current profile
    private var workoutDates: Set<Date> {
        let logs = logManager.getLogs(for: workoutManager.currentProfile)
        return Set(logs.map { calendar.startOfDay(for: $0.date) })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // V3 Header
            HStack {
                Text("Schedule")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)
                Spacer()
                
                Button(action: {
                    scheduler.requestNotificationPermission { _ in }
                }) {
                    Image(systemName: scheduler.notificationsEnabled ? "bell.fill" : "bell.slash")
                        .font(.title2)
                        .foregroundColor(scheduler.notificationsEnabled ? ThemeManager.shared.primary : .gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 60)
            .padding(.bottom, 10)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Week Calendar Strip
                    WeekCalendarView(
                        selectedDate: $selectedDate,
                        workoutDates: workoutDates,
                        scheduledDate: scheduler.nextWorkoutDate
                    ) { date in
                        // Tap on day to reschedule
                        let today = calendar.startOfDay(for: Date())
                        if calendar.startOfDay(for: date) >= today {
                            scheduler.setNextWorkoutDate(date, profile: workoutManager.currentProfile)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Next Workout Card
                    SchedulerCard(
                        nextDate: scheduler.nextWorkoutDate,
                        formattedDate: scheduler.formattedNextWorkoutDate(),
                        daysUntil: scheduler.daysUntilNextWorkout()
                    )
                    .padding(.horizontal)
                    
                    // Notification Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reminders")
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.text)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            // Notification Toggle
                            HStack {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(ThemeManager.shared.primary)
                                    .frame(width: 24)
                                Text("Workout Reminders")
                                    .foregroundColor(ThemeManager.shared.text)
                                Spacer()
                                Toggle("", isOn: $scheduler.notificationsEnabled)
                                    .labelsHidden()
                                    .tint(ThemeManager.shared.primary)
                                    .onChange(of: scheduler.notificationsEnabled) { _, enabled in
                                        if enabled {
                                            scheduler.requestNotificationPermission { granted in
                                                if granted, let nextDate = scheduler.nextWorkoutDate {
                                                    scheduler.scheduleWorkoutNotification(for: nextDate, profile: workoutManager.currentProfile)
                                                }
                                            }
                                        } else {
                                            scheduler.cancelAllNotifications(for: workoutManager.currentProfile)
                                        }
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
                            if scheduler.notificationsEnabled {
                                Divider().background(Color.gray.opacity(0.2))
                                
                                // Reminder Time
                                Button(action: { showingTimePicker = true }) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(ThemeManager.shared.primary)
                                            .frame(width: 24)
                                        Text("Reminder Time")
                                            .foregroundColor(ThemeManager.shared.text)
                                        Spacer()
                                        Text(formattedTime)
                                            .foregroundColor(.gray)
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                            }
                        }
                        .glassCardBackground()
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.text)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            QuickActionButton(
                                icon: "arrow.clockwise",
                                title: "Reschedule",
                                color: .blue
                            ) {
                                // Move to tomorrow
                                if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
                                    scheduler.setNextWorkoutDate(tomorrow, profile: workoutManager.currentProfile)
                                }
                            }
                            
                            QuickActionButton(
                                icon: "calendar.badge.plus",
                                title: "Add Rest Day",
                                color: .green
                            ) {
                                // Add 1 day to current schedule
                                if let nextDate = scheduler.nextWorkoutDate,
                                   let newDate = calendar.date(byAdding: .day, value: 1, to: nextDate) {
                                    scheduler.setNextWorkoutDate(newDate, profile: workoutManager.currentProfile)
                                }
                            }
                            
                            QuickActionButton(
                                icon: "bolt.fill",
                                title: "Today",
                                color: ThemeManager.shared.primary
                            ) {
                                scheduler.setNextWorkoutDate(Date(), profile: workoutManager.currentProfile)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 120)
                }
            }
        }
        .background(ThemeManager.shared.background)
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheet(preferredTime: $scheduler.preferredWorkoutTime)
        }
    }
    
    var formattedTime: String {
        let hour = scheduler.preferredWorkoutTime.hour ?? 9
        let minute = scheduler.preferredWorkoutTime.minute ?? 0
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "9:00 AM"
    }
}

// MARK: - Week Calendar View

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    let workoutDates: Set<Date>
    let scheduledDate: Date?
    let onDateTap: (Date) -> Void
    
    private let calendar = Calendar.current
    @State private var weekOffset: Int = 0
    
    private var weekDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        let startOfWeek = calendar.date(byAdding: .day, value: weekOffset * 7, to: today) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Week Navigation
            HStack {
                Button(action: { weekOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(ThemeManager.shared.primary)
                }
                
                Spacer()
                
                Text(weekTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.text)
                
                Spacer()
                
                Button(action: { weekOffset += 1 }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(ThemeManager.shared.primary)
                }
            }
            .padding(.horizontal, 8)
            
            // Days Row
            HStack(spacing: 6) {
                ForEach(weekDays, id: \.self) { date in
                    DayCell(
                        date: date,
                        isToday: calendar.isDateInToday(date),
                        hasWorkout: workoutDates.contains(calendar.startOfDay(for: date)),
                        isScheduled: scheduledDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                    ) {
                        selectedDate = date
                        onDateTap(date)
                    }
                }
            }
        }
        .padding(12) // Compact padding
        .glassCardBackground()
        .cornerRadius(12)
    }
    
    var weekTitle: String {
        if weekOffset == 0 {
            return "This Week"
        } else if weekOffset == 1 {
            return "Next Week"
        } else if weekOffset == -1 {
            return "Last Week"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            if let first = weekDays.first, let last = weekDays.last {
                return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
            }
            return ""
        }
    }
}

struct DayCell: View {
    let date: Date
    let isToday: Bool
    let hasWorkout: Bool
    let isScheduled: Bool
    let isSelected: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) { // Compact spacing
                Text(dayName)
                    .font(.system(size: 10, weight: .bold)) // Smaller font
                    .foregroundColor(.gray)
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .medium))
                    .foregroundColor(isToday ? ThemeManager.shared.primary : ThemeManager.shared.text)
                
                // Indicator
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 4, height: 4) // Smaller dot
                    .opacity(hasWorkout || isScheduled ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? ThemeManager.shared.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }
    
    var indicatorColor: Color {
        if isScheduled && !hasWorkout {
            return ThemeManager.shared.primary
        } else if hasWorkout {
            return .green
        }
        return .clear
    }
}

// MARK: - Helper Views

struct SiriPhraseRow: View {
    let phrase: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(phrase)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ThemeManager.shared.text)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "mic.fill")
                .font(.caption)
                .foregroundColor(.blue.opacity(0.6))
        }
    }
}

// MARK: - Next Workout Card

struct SchedulerCard: View {
    let nextDate: Date?
    let formattedDate: String
    let daysUntil: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT WORKOUT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    Text(formattedDate)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.text)
                }
                
                Spacer()
                
                // Countdown Circle
                ZStack {
                    Circle()
                        .stroke(ThemeManager.shared.primary.opacity(0.2), lineWidth: 4)
                    
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(ThemeManager.shared.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(daysUntil)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(ThemeManager.shared.primary)
                        Text("days")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 60, height: 60)
            }
            
            if daysUntil == 0 {
                Text("🔥 Today is workout day!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(ThemeManager.shared.primary.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding()
        .glassCardBackground()
        .cornerRadius(16)
    }
    
    var progressValue: CGFloat {
        // Show progress based on days (max 7 day cycle)
        let maxDays: CGFloat = 7
        return CGFloat(max(0, min(daysUntil, 7))) / maxDays
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassCardBackground()
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Binding var preferredTime: DateComponents
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTime: Date = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Reminder Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        preferredTime.hour = calendar.component(.hour, from: selectedTime)
                        preferredTime.minute = calendar.component(.minute, from: selectedTime)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.primary)
                }
            }
        }
        .onAppear {
            var components = DateComponents()
            components.hour = preferredTime.hour ?? 9
            components.minute = preferredTime.minute ?? 0
            if let date = calendar.date(from: components) {
                selectedTime = date
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(WorkoutManager())
        .environmentObject(AudioManager())
        .preferredColorScheme(.light)
}

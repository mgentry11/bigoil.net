import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var selectedTab: Tab = .workouts

    enum Tab {
        case workouts, routines, stats, log
    }

    var body: some View {
        ZStack {
            // Background
            ThemeManager.shared.background.ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Tab content
                switch selectedTab {
                case .workouts:
                    WorkoutListView()
                case .routines:
                    RoutinesView()
                case .stats:
                    StatsView()
                case .log:
                    LogView()
                }

                // Tab bar
                TabBarView(selectedTab: $selectedTab)
            }

            // Overlays
            if workoutManager.showingTimer {
                TimerView()
                    .transition(.move(edge: .bottom))
            }

            if workoutManager.showingRest {
                RestView()
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: workoutManager.showingTimer)
        .animation(.easeInOut, value: workoutManager.showingRest)
        .sheet(isPresented: $workoutManager.showingProfile) {
            ProfileView()
        }
    }
}

// MARK: - Tab Bar
struct TabBarView: View {
    @Binding var selectedTab: ContentView.Tab

    var body: some View {
        HStack {
            TabButton(
                icon: "dumbbell.fill",
                title: "Workouts",
                isSelected: selectedTab == .workouts
            ) {
                selectedTab = .workouts
            }

            TabButton(
                icon: "folder.fill",
                title: "Routines",
                isSelected: selectedTab == .routines
            ) {
                selectedTab = .routines
            }

            TabButton(
                icon: "chart.line.uptrend.xyaxis",
                title: "Stats",
                isSelected: selectedTab == .stats
            ) {
                selectedTab = .stats
            }

            TabButton(
                icon: "list.bullet.rectangle.portrait",
                title: "Log",
                isSelected: selectedTab == .log
            ) {
                selectedTab = .log
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .glassCardBackground()
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? themeManager.primary : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Stats View
struct StatsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var logManager = WorkoutLogManager.shared
    @ObservedObject var bodyManager = BodyMeasurementsManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var selectedSection: StatsSection = .overview
    @State private var showingExport = false
    @State private var showingBodyMeasurement = false

    enum StatsSection: String, CaseIterable {
        case overview = "Overview"
        case charts = "Charts"
        case tools = "Tools"
        case body = "Body"
    }

    private var profileLogs: [WorkoutLogEntry] {
        logManager.getLogs(for: workoutManager.currentProfile)
    }

    private var totalSets: Int {
        logManager.getTotalSets(for: workoutManager.currentProfile)
    }

    private var todaySets: Int {
        logManager.getTotalSetsToday(for: workoutManager.currentProfile)
    }

    private var uniqueExercises: Int {
        Set(profileLogs.map { $0.exerciseName }).count
    }

    private var workoutDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(profileLogs.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    private var currentStreak: Int {
        guard !profileLogs.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        for _ in 0..<30 {
            let dayLogs = profileLogs.filter {
                calendar.isDate($0.date, inSameDayAs: checkDate)
            }
            if !dayLogs.isEmpty {
                streak += 1
            } else if streak > 0 {
                break
            }
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        return streak
    }

    private var totalVolume: Double {
        logManager.getTotalVolume(for: workoutManager.currentProfile, days: 7)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(StatsSection.allCases, id: \.self) { section in
                        Button(action: { selectedSection = section }) {
                            Text(section.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedSection == section ? .white : .gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedSection == section ? themeManager.primary : ThemeManager.shared.card)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }

            ScrollView {
                switch selectedSection {
                case .overview:
                    overviewSection
                case .charts:
                    ProgressChartsView()
                case .tools:
                    toolsSection
                case .body:
                    bodySection
                }
            }
        }
    }

    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(spacing: 20) {
            // Main stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatTile(title: "Total Sets", value: "\(totalSets)", icon: "dumbbell.fill", color: themeManager.primary)
                StatTile(title: "Today", value: "\(todaySets)", icon: "calendar", color: .green)
                StatTile(title: "Exercises", value: "\(uniqueExercises)", icon: "list.bullet", color: .blue)
                StatTile(title: "Workout Days", value: "\(workoutDays)", icon: "flame.fill", color: .orange)
            }
            .padding(.horizontal)

            // Streak and Volume cards
            HStack(spacing: 12) {
                // Streak
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(themeManager.primary)
                        Text("Streak")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text("\(currentStreak) days")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .glassCardBackground()
                .cornerRadius(12)

                // Weekly Volume
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.blue)
                        Text("This Week")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(formatVolume(totalVolume))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .glassCardBackground()
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // Personal Records
            PRsCard(profile: workoutManager.currentProfile)
                .padding(.horizontal)

            // Export button
            Button(action: { showingExport = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Data (CSV)")
                }
                .font(.subheadline)
                .foregroundColor(ThemeManager.shared.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .glassCardBackground()
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .sheet(isPresented: $showingExport) {
                ExportSheet(profile: workoutManager.currentProfile)
            }

            Spacer(minLength: 40)
        }
        .padding(.top)
    }

    // MARK: - Tools Section
    private var toolsSection: some View {
        VStack(spacing: 16) {
            OneRMCalculatorView()
                .padding(.horizontal)

            WarmupCalculatorView()
                .padding(.horizontal)

            Spacer(minLength: 40)
        }
        .padding(.top)
    }

    // MARK: - Body Section
    private var bodySection: some View {
        VStack(spacing: 16) {
            // Latest measurements
            if let latest = bodyManager.getLatestMeasurement(for: workoutManager.currentProfile) {
                LatestMeasurementCard(measurement: latest)
                    .padding(.horizontal)
            }

            // Weight chart
            WeightChartCard(profile: workoutManager.currentProfile)
                .padding(.horizontal)

            // Add measurement button
            Button(action: { showingBodyMeasurement = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Body Measurement")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(ThemeManager.shared.primary)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .sheet(isPresented: $showingBodyMeasurement) {
                AddBodyMeasurementSheet(profile: workoutManager.currentProfile)
            }

            Spacer(minLength: 40)
        }
        .padding(.top)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        }
        return "\(Int(volume)) lbs"
    }
}

// MARK: - PRs Card
struct PRsCard: View {
    let profile: Int
    @ObservedObject var logManager = WorkoutLogManager.shared

    private var prs: [String: Double] {
        logManager.getPersonalRecords(for: profile)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(ThemeManager.shared.primary)
                Text("Personal Records")
                    .font(.headline)
                    .foregroundColor(ThemeManager.shared.text)
            }

            if prs.isEmpty {
                Text("No PRs yet - complete some workouts!")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(prs.keys.sorted().prefix(6)), id: \.self) { exercise in
                        if let weight = prs[exercise] {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                    Text("\(Int(weight)) lbs")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(ThemeManager.shared.primary)
                                }
                                Spacer()
                            }
                            .padding(8)
                            .background(ThemeManager.shared.background)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .glassCardBackground()
        .cornerRadius(16)
    }
}

// MARK: - Weight Chart Card
struct WeightChartCard: View {
    let profile: Int
    @ObservedObject var bodyManager = BodyMeasurementsManager.shared

    private var weightHistory: [(date: Date, weight: Double)] {
        bodyManager.getWeightHistory(for: profile, last: 10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body Weight")
                .font(.headline)
                .foregroundColor(ThemeManager.shared.text)

            if weightHistory.count >= 2 {
                // Mini chart would go here - simplified for now
                HStack {
                    ForEach(weightHistory.indices, id: \.self) { index in
                        let data = weightHistory[index]
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ThemeManager.shared.primary)
                                .frame(width: 20, height: CGFloat(data.weight) / 3)
                            Text("\(Int(data.weight))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(height: 100)
            } else {
                Text("Log body weight to see your trend")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
            }

            if let change = bodyManager.getWeightChange(for: profile, days: 30) {
                HStack {
                    Text("30-day change:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(change >= 0 ? "+\(String(format: "%.1f", change)) lbs" : "\(String(format: "%.1f", change)) lbs")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(change >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .glassCardBackground()
        .cornerRadius(16)
    }
}

// MARK: - Latest Measurement Card
struct LatestMeasurementCard: View {
    let measurement: BodyMeasurement

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Latest Measurements")
                    .font(.headline)
                    .foregroundColor(ThemeManager.shared.text)
                Spacer()
                Text(measurement.date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                if let weight = measurement.bodyWeight {
                    MeasurementItem(label: "Weight", value: "\(Int(weight)) lbs")
                }
                if let bf = measurement.bodyFat {
                    MeasurementItem(label: "Body Fat", value: "\(String(format: "%.1f", bf))%")
                }
                if let chest = measurement.chest {
                    MeasurementItem(label: "Chest", value: "\(String(format: "%.1f", chest))\"")
                }
                if let waist = measurement.waist {
                    MeasurementItem(label: "Waist", value: "\(String(format: "%.1f", waist))\"")
                }
                if let biceps = measurement.bicepsRight {
                    MeasurementItem(label: "Bicep", value: "\(String(format: "%.1f", biceps))\"")
                }
                if let thigh = measurement.thighRight {
                    MeasurementItem(label: "Thigh", value: "\(String(format: "%.1f", thigh))\"")
                }
            }
        }
        .padding()
        .glassCardBackground()
        .cornerRadius(16)
    }
}

struct MeasurementItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(ThemeManager.shared.background)
        .cornerRadius(8)
    }
}

// MARK: - Add Body Measurement Sheet
struct AddBodyMeasurementSheet: View {
    let profile: Int
    @Environment(\.dismiss) var dismiss
    @ObservedObject var bodyManager = BodyMeasurementsManager.shared

    @State private var bodyWeight: String = ""
    @State private var bodyFat: String = ""
    @State private var chest: String = ""
    @State private var waist: String = ""
    @State private var hips: String = ""
    @State private var biceps: String = ""
    @State private var thigh: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Weight") {
                    HStack {
                        Text("Body Weight")
                        Spacer()
                        TextField("lbs", text: $bodyWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Body Fat %")
                        Spacer()
                        TextField("%", text: $bodyFat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section("Measurements (inches)") {
                    MeasurementField(label: "Chest", value: $chest)
                    MeasurementField(label: "Waist", value: $waist)
                    MeasurementField(label: "Hips", value: $hips)
                    MeasurementField(label: "Bicep", value: $biceps)
                    MeasurementField(label: "Thigh", value: $thigh)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes)
                }
            }
            .navigationTitle("Log Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMeasurement()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.primary)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func saveMeasurement() {
        let measurement = BodyMeasurement(
            profile: profile,
            bodyWeight: Double(bodyWeight),
            bodyFat: Double(bodyFat),
            chest: Double(chest),
            waist: Double(waist),
            hips: Double(hips),
            bicepsLeft: Double(biceps),
            bicepsRight: Double(biceps),
            thighLeft: Double(thigh),
            thighRight: Double(thigh),
            notes: notes.isEmpty ? nil : notes
        )
        bodyManager.addMeasurement(measurement)
    }
}

struct MeasurementField: View {
    let label: String
    @Binding var value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("in", text: $value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }
}

// MARK: - Export Sheet
struct ExportSheet: View {
    let profile: Int
    @Environment(\.dismiss) var dismiss
    @ObservedObject var logManager = WorkoutLogManager.shared
    @State private var showingShareSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundColor(ThemeManager.shared.primary)
                    .padding(.top, 40)

                Text("Export Workout Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)

                Text("Export all your workout logs as a CSV file that can be opened in Excel, Google Sheets, or any spreadsheet app.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                let logCount = logManager.getLogs(for: profile).count
                Text("\(logCount) sets will be exported")
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.primary)

                Spacer()

                Button(action: shareCSV) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export CSV")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(ThemeManager.shared.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(ThemeManager.shared.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(ThemeManager.shared.primary)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func shareCSV() {
        let csv = logManager.exportToCSV(for: profile)
        let filename = "OneRepStrength_Export_\(Date().formatted(.dateTime.year().month().day())).csv"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(ThemeManager.shared.text)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassCardBackground()
        .cornerRadius(12)
    }
}

// MARK: - Log View
struct LogView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var logManager = WorkoutLogManager.shared
    @State private var selectedDateForSave: Date?
    @State private var selectedEntriesForSave: [WorkoutLogEntry] = []
    @State private var showingSaveSheet = false

    private var profileLogs: [WorkoutLogEntry] {
        logManager.getLogs(for: workoutManager.currentProfile)
    }

    private var groupedByDate: [Date: [WorkoutLogEntry]] {
        let calendar = Calendar.current
        return Dictionary(grouping: profileLogs) { log in
            calendar.startOfDay(for: log.date)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Workout Log")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)
                Spacer()
                Text("\(profileLogs.count) sets")
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.shared.primary)
            }
            .padding()

            if profileLogs.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Sets Logged Yet")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.text)
                    Text("Complete exercises and tap \"Log Set\" to track your progress")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                // Log list
                List {
                    ForEach(groupedByDate.keys.sorted(by: >), id: \.self) { date in
                        Section {
                            // Action buttons for this day's workout
                            LogDayActionsRow(
                                date: date,
                                entries: groupedByDate[date] ?? [],
                                onRepeat: {
                                    workoutManager.loadFromLogEntries(groupedByDate[date] ?? [])
                                },
                                onSave: {
                                    selectedDateForSave = date
                                    selectedEntriesForSave = groupedByDate[date] ?? []
                                    showingSaveSheet = true
                                }
                            )

                            ForEach(groupedByDate[date] ?? []) { log in
                                LogEntryRow(log: log)
                            }
                        } header: {
                            Text(formatDate(date))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(ThemeManager.shared.primary)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            if let date = selectedDateForSave {
                SaveLogAsTemplateSheet(
                    entries: selectedEntriesForSave,
                    date: date,
                    profile: workoutManager.currentProfile
                )
            } else {
                // Fallback - should not happen but prevents black screen
                VStack {
                    Text("No workout selected")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Log Day Actions Row
struct LogDayActionsRow: View {
    let date: Date
    let entries: [WorkoutLogEntry]
    let onRepeat: () -> Void
    let onSave: () -> Void

    private var uniqueExerciseCount: Int {
        Set(entries.map { $0.exerciseName }).count
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onRepeat) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption2)
                    Text("Repeat")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ThemeManager.shared.primary)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            Button(action: onSave) {
                HStack(spacing: 4) {
                    Image(systemName: "bookmark")
                        .font(.caption2)
                    Text("Save")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(ThemeManager.shared.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .glassCardBackground()
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(uniqueExerciseCount) exercises")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .listRowBackground(Color.clear.background(.thickMaterial))
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

struct LogEntryRow: View {
    let log: WorkoutLogEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(log.exerciseName)
                        .font(.headline)
                        .foregroundColor(ThemeManager.shared.text)

                    Text("(\(log.workoutType))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text(formatTime(log.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(log.weight)) lbs")
                    .font(.headline)
                    .foregroundColor(ThemeManager.shared.primary)

                if log.reachedFailure {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("Failure")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.clear.background(.thickMaterial))
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutManager())
        .environmentObject(AudioManager())
}

//
//  WorkoutListView.swift
//  OneRepStrength v4
//
//  Redesigned workout list with orange cards based on mockups (pages 12, 22)
//
//  v2 Changes:
//  - Added "Negative Resistance Only" toggle to ExerciseDetailSheet for bodyweight exercises
//    (lines 703-730) - allows editing negative-only setting when tapping exercise card
//

import SwiftUI
import Foundation

struct WorkoutListView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var scheduler = WorkoutScheduler.shared
    @ObservedObject var logManager = WorkoutLogManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var partnerManager = PartnerWorkoutManager.shared

    @State private var exerciseToEdit: Exercise?
    @State private var showingAddExercise = false
    @State private var showingResetConfirm = false
    @State private var showingSaveAsTemplate = false
    @State private var showingFinishOptions = false
    @State private var isEditMode = false
    @State private var showingPartnerSetup = false
    @State private var showingPartnerOptions = false
    @State private var showingSchedule = false

    var body: some View {
        ZStack {
            // Dark background
            Color(hex: "0D0D0F")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // V4 Header
                headerView
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                // Exercise List
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(workoutManager.currentWorkout.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseCardV4(
                                exercise: exercise,
                                onTap: {
                                    if !isEditMode { exerciseToEdit = exercise }
                                },
                                onStart: {
                                    if !isEditMode { workoutManager.startExercise(exercise) }
                                },
                                onWeightChange: { newWeight in
                                    workoutManager.updateExerciseWeight(exercise, weight: newWeight)
                                },
                                onNegativeOnlyChange: { isNegativeOnly in
                                    workoutManager.updateExerciseNegativeOnly(exercise, isNegativeOnly: isNegativeOnly)
                                },
                                onLog: {
                                    workoutManager.logExercise(exercise)
                                }
                            )
                        }

                        // Add Exercise Button
                        addExerciseButton
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }

                Spacer(minLength: 0)
            }

            // Floating Action Button
            VStack {
                Spacer()
                floatingActionButton
                    .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingPartnerSetup) {
            PartnerWorkoutSetupSheet()
        }
        .sheet(item: $exerciseToEdit) { exercise in
            ExerciseDetailSheet(
                exercise: exercise,
                onSave: { value, reachedFailure, isNegativeOnly, isBodyweight, youtubeURL in
                    if let index = workoutManager.currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) {
                        // Update bodyweight setting
                        workoutManager.currentWorkout.exercises[index].isBodyweight = isBodyweight
                        let bodyweightKey = "exerciseBodyweight_\(workoutManager.currentProfile)_\(exercise.name)"
                        UserDefaults.standard.set(isBodyweight, forKey: bodyweightKey)

                        if isBodyweight {
                            workoutManager.currentWorkout.exercises[index].lastDuration = Int(value)
                            let durationKey = "exerciseDuration_\(workoutManager.currentProfile)_\(exercise.name)"
                            UserDefaults.standard.set(Int(value), forKey: durationKey)
                            workoutManager.currentWorkout.exercises[index].isNegativeOnly = isNegativeOnly
                            let negKey = "exerciseNegative_\(workoutManager.currentProfile)_\(exercise.name)"
                            UserDefaults.standard.set(isNegativeOnly, forKey: negKey)
                        } else {
                            workoutManager.currentWorkout.exercises[index].lastWeight = value
                            let key = "exerciseWeight_\(workoutManager.currentProfile)_\(exercise.name)"
                            UserDefaults.standard.set(value, forKey: key)
                        }
                        workoutManager.currentWorkout.exercises[index].reachedFailure = reachedFailure
                        let failureKey = "exerciseFailure_\(workoutManager.currentProfile)_\(exercise.name)"
                        UserDefaults.standard.set(reachedFailure, forKey: failureKey)

                        // Save YouTube URL
                        workoutManager.currentWorkout.exercises[index].youtubeURL = youtubeURL
                        let youtubeKey = "exerciseYouTube_\(workoutManager.currentProfile)_\(exercise.name)"
                        if let url = youtubeURL {
                            UserDefaults.standard.set(url, forKey: youtubeKey)
                        } else {
                            UserDefaults.standard.removeObject(forKey: youtubeKey)
                        }
                    }
                },
                onDelete: {
                    workoutManager.deleteExercise(exercise)
                }
            )
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseSheet(
                onAdd: { exerciseName, isBodyweight, weight, isNegativeOnly in
                    workoutManager.addExercise(name: exerciseName, isBodyweight: isBodyweight, weight: weight, isNegativeOnly: isNegativeOnly)
                }
            )
        }
        .sheet(item: $exerciseToEdit) { exercise in
            EditExerciseSheet(
                exercise: exercise,
                onSave: { name, weight, isBodyweight, isNegativeOnly, youtubeURL in
                    workoutManager.updateExercise(exercise, name: name, weight: weight, isBodyweight: isBodyweight, isNegativeOnly: isNegativeOnly, youtubeURL: youtubeURL)
                },
                onDelete: {
                    workoutManager.deleteExercise(exercise)
                }
            )
        }
        .alert("Reset Workout?", isPresented: $showingResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                workoutManager.resetWorkout()
            }
        } message: {
            Text("This will clear all weights, completion status, and custom exercises for this workout.")
        }
        .sheet(isPresented: $showingSaveAsTemplate) {
            SaveAsTemplateSheet(
                exercises: workoutManager.currentWorkout.exercises,
                profile: workoutManager.currentProfile
            )
        }
        .confirmationDialog("Finish Workout", isPresented: $showingFinishOptions) {
            Button("Finish") {
                workoutManager.finishWorkout()
            }
            Button("Save as Routine & Finish") {
                showingSaveAsTemplate = true
                workoutManager.finishWorkout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Would you like to save this workout as a reusable routine?")
        }
        .onAppear {
            updateSchedule()
        }
        .onChange(of: logManager.logs.count) { _, _ in
            updateSchedule()
        }
        .sheet(isPresented: $showingSchedule) {
            ScheduleViewV4()
        }
        .confirmationDialog("Partner Options", isPresented: $showingPartnerOptions) {
            Button("Switch Partner") {
                partnerManager.switchPartner(workoutManager: workoutManager)
            }
            Button("End Partner Workout", role: .destructive) {
                partnerManager.endPartnerWorkout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Current Turn: Partner \(partnerManager.currentPartner)")
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // App Logo
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.primary)
                        .frame(width: 36, height: 36)

                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }

                Text("OneRep")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                + Text("Strength")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(themeManager.primary)
            }

            Spacer()

            // Profile/Partner Button
            Button(action: {
                if partnerManager.isPartnerModeActive {
                    showingPartnerOptions = true
                } else {
                    showingPartnerSetup = true
                }
            }) {
                if partnerManager.isPartnerModeActive {
                    Text(getPartnerInitials(for: partnerManager.currentPartner == 1 ? partnerManager.partner1Profile : partnerManager.partner2Profile))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(themeManager.primary)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Add Exercise Button
    private var addExerciseButton: some View {
        Button(action: { showingAddExercise = true }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.primary)

                Text("Add Exercise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [8]))
                    )
            )
        }
    }

    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        Button(action: {
            // Show menu with options
            if workoutManager.completedExercises > 0 {
                showingFinishOptions = true
            }
        }) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(themeManager.primary)
                        .shadow(color: themeManager.primary.opacity(0.5), radius: 15, y: 5)
                )
        }
    }

    // MARK: - Helper Functions
    private func updateSchedule() {
        let profileLogs = logManager.getLogs(for: workoutManager.currentProfile)
        let lastLog = profileLogs.first

        let profileKey = "userProfile_P\(workoutManager.currentProfile)"
        var experienceLevel: UserProfile.ExperienceLevel = .beginner
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            experienceLevel = profile.experienceLevel
        }

        scheduler.calculateNextWorkout(
            experienceLevel: experienceLevel,
            lastWorkoutDate: lastLog?.date,
            profile: workoutManager.currentProfile
        )
    }

    private func getPartnerInitials(for profileId: Int) -> String {
        if let data = AppGroup.defaults.data(forKey: "userProfile_\(profileId)"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data),
           !profile.name.isEmpty {
            return String(profile.name.prefix(2)).uppercased()
        }
        return "P\(profileId)"
    }
}

// MARK: - Exercise Card V4
struct ExerciseCardV4: View {
    let exercise: Exercise
    let onTap: () -> Void
    let onStart: () -> Void
    var onWeightChange: ((Double) -> Void)? = nil
    var onNegativeOnlyChange: ((Bool) -> Void)? = nil
    var onLog: (() -> Void)? = nil

    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var logManager = WorkoutLogManager.shared
    @State private var displayWeight: Double = 0
    @State private var showingYouTubeVideo = false

    private var lastWorkoutDate: String {
        // Get last logged date for this exercise
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return dateFormatter.string(from: Date()).uppercased()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Left side - Exercise info
                VStack(alignment: .leading, spacing: 8) {
                    // Exercise name
                    Text(exercise.name.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)

                    // Weight display
                    if exercise.isBodyweight {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BODYWEIGHT")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primary)

                            // Negative Only Toggle
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onNegativeOnlyChange?(!exercise.isNegativeOnly)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: exercise.isNegativeOnly ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 14))
                                    Text("Negative Only")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(exercise.isNegativeOnly ? .purple : .gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background {
                                    GlassBackground(isActive: exercise.isNegativeOnly, tintColor: .purple, cornerRadius: 8)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(displayWeight))")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primary)
                            Text("LBS")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(themeManager.primary.opacity(0.7))
                        }
                    }

                    // Last weight info
                    if !exercise.isBodyweight {
                        Text("LAST WEIGHT")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                        + Text(" \(lastWorkoutDate)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(themeManager.primary)
                    }
                }

                Spacer()

                // Right side - Icon and action
                VStack(spacing: 12) {
                    // Exercise icon
                    ExerciseIconView(iconName: exercise.iconName, size: 50)

                    // Completion indicator, log button, or play button
                    if exercise.isCompleted && exercise.isLogged {
                        // Fully complete and logged
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.green)
                    } else if exercise.isCompleted && !exercise.isLogged {
                        // Completed but needs logging
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onLog?()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 24))
                                Text("LOG")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(themeManager.primary)
                            )
                        }
                    } else {
                        // Not started
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onStart()
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(themeManager.primary)
                        }
                    }
                }
            }

            // YouTube thumbnail preview
            if let urlString = exercise.youtubeURL,
               let videoId = extractYouTubeVideoIdFromCard(from: urlString) {
                Button(action: { showingYouTubeVideo = true }) {
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoId)/mqdefault.jpg")) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 80)
                                    .overlay(ProgressView().tint(.white))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(16/9, contentMode: .fill)
                                    .frame(height: 80)
                                    .clipped()
                                    .cornerRadius(8)
                            case .failure:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 80)
                            @unknown default:
                                EmptyView()
                            }
                        }

                        // Play button overlay
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                            Text("Watch Demo")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(6)
                        .padding(8)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }

            // Orange progress bar at bottom
            if !exercise.isCompleted {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(themeManager.primary)
                        .frame(height: 3)
                }
                .padding(.top, 16)
            }
        }
        .padding(20)
        .background {
            GlassBackground(isActive: exercise.isCompleted, tintColor: themeManager.primary)
        }
        .shadow(color: themeManager.primary.opacity(exercise.isCompleted ? themeManager.glassShadowOpacity : 0.1), radius: 10, y: 5)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onStart()
        }
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Edit Details", systemImage: "pencil")
            }

            Button {
                onStart()
            } label: {
                Label("Start Timer", systemImage: "play.fill")
            }

            if exercise.youtubeURL != nil {
                Button {
                    showingYouTubeVideo = true
                } label: {
                    Label("Watch Demo", systemImage: "play.rectangle.fill")
                }
            }
        }
        .sheet(isPresented: $showingYouTubeVideo) {
            if let urlString = exercise.youtubeURL, let url = URL(string: urlString) {
                YouTubeVideoSheet(url: url, exerciseName: exercise.name)
            }
        }
        .onAppear {
            displayWeight = exercise.lastWeight ?? 0
        }
        .onChange(of: exercise.lastWeight) { _, newValue in
            displayWeight = newValue ?? 0
        }
    }

    private func extractYouTubeVideoIdFromCard(from urlString: String) -> String? {
        let patterns = [
            "(?:youtube\\.com/watch\\?v=|youtu\\.be/|youtube\\.com/embed/|youtube\\.com/v/)([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(urlString.startIndex..., in: urlString)
                if let match = regex.firstMatch(in: urlString, options: [], range: range),
                   let videoIdRange = Range(match.range(at: 1), in: urlString) {
                    return String(urlString[videoIdRange])
                }
            }
        }
        return nil
    }
}

// MARK: - Profile Button
struct ProfileButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? ThemeManager.shared.primary : Color(white: 0.25))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? ThemeManager.shared.primary : Color.gray.opacity(0.5), lineWidth: isSelected ? 0 : 1)
            )
        }
        .accessibilityLabel("Profile \(title)")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to switch profile")
    }
}

// MARK: - Exercise Icon View
struct ExerciseIconView: View {
    let iconName: String
    var size: CGFloat = 52

    var body: some View {
        if let iconImage = loadIconImage() {
            Image(uiImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ThemeManager.shared.primary)
                    .frame(width: size, height: size)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundColor(.black)
            }
        }
    }

    private func loadIconImage() -> UIImage? {
        let bundlePath = Bundle.main.bundlePath
        let iconPath = "\(bundlePath)/Icons/\(iconName)"

        if FileManager.default.fileExists(atPath: iconPath) {
            return UIImage(contentsOfFile: iconPath)
        }

        let withoutExt = iconName.replacingOccurrences(of: ".png", with: "")
        let altPath = "\(bundlePath)/Icons/\(withoutExt).png"
        if FileManager.default.fileExists(atPath: altPath) {
            return UIImage(contentsOfFile: altPath)
        }

        return nil
    }
}

// MARK: - Exercise Detail Sheet
struct ExerciseDetailSheet: View {
    let exercise: Exercise
    let onSave: (Double, Bool, Bool, Bool, String?) -> Void  // weight/duration, reachedFailure, isNegativeOnly, isBodyweight, youtubeURL
    let onDelete: () -> Void

    @Environment(\.dismiss) var dismiss
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var currentWeight: Double = 0
    @State private var currentDuration: Int = 60
    @State private var reachedFailure: Bool = true
    @State private var isNegativeOnly: Bool = false
    @State private var isBodyweight: Bool = false
    @State private var showingDeleteConfirm: Bool = false
    @State private var youtubeURL: String = ""
    @State private var showingYouTubePreview: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0D0D0F").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Exercise Icon and Name
                        VStack(spacing: 12) {
                            ExerciseIconView(iconName: exercise.iconName, size: 80)

                            Text(exercise.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)

                        // Bodyweight Toggle
                        Button(action: { isBodyweight.toggle() }) {
                            HStack {
                                Image(systemName: isBodyweight ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(isBodyweight ? themeManager.primary : .gray)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bodyweight Exercise")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Track time instead of weight")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // Weight/Time Input Section
                        VStack(spacing: 20) {
                            Text(isBodyweight ? "Time Completed" : "Log Weight")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            if isBodyweight {
                                // Time input
                                HStack(spacing: 24) {
                                    Button(action: { adjustDuration(-15) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(themeManager.primary)
                                    }

                                    VStack(spacing: 4) {
                                        Text(formatDuration(currentDuration))
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("min:sec")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: 140)

                                    Button(action: { adjustDuration(15) }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(themeManager.primary)
                                    }
                                }
                            } else {
                                // Weight input
                                HStack(spacing: 24) {
                                    Button(action: { adjustWeight(-5) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(themeManager.primary)
                                    }

                                    VStack(spacing: 4) {
                                        Text("\(Int(currentWeight))")
                                            .font(.system(size: 56, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("lbs")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: 120)

                                    Button(action: { adjustWeight(5) }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(themeManager.primary)
                                    }
                                }

                                // Fine adjustment
                                HStack(spacing: 16) {
                                    Button(action: { adjustWeight(-2.5) }) {
                                        Text("-2.5")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(10)
                                    }
                                    Button(action: { adjustWeight(2.5) }) {
                                        Text("+2.5")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .padding(.horizontal)

                        // Reached Failure Toggle
                        Button(action: { reachedFailure.toggle() }) {
                            HStack {
                                Image(systemName: reachedFailure ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(reachedFailure ? .green : .gray)
                                Text("Reached Failure")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // v2: Negative Only toggle (only for bodyweight exercises)
                        if isBodyweight {
                            Button(action: { isNegativeOnly.toggle() }) {
                                HStack {
                                    Image(systemName: isNegativeOnly ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(isNegativeOnly ? Color.purple : .gray)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Negative Resistance Only")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Position → Slow Lowering → Done")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(16)
                                .background {
                                    GlassBackground(
                                        isActive: isNegativeOnly,
                                        tintColor: .purple
                                    )
                                }
                                .shadow(color: Color.purple.opacity(isNegativeOnly ? themeManager.glassShadowOpacity : 0.1), radius: 12, y: 6)
                            }
                            .padding(.horizontal)
                        }

                        // YouTube Video Link Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundColor(.red)
                                Text("Demo Video")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            // YouTube URL input or thumbnail preview
                            if !youtubeURL.isEmpty, let videoId = extractYouTubeVideoId(from: youtubeURL) {
                                // Show thumbnail with play button
                                Button(action: { showingYouTubePreview = true }) {
                                    ZStack {
                                        AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoId)/mqdefault.jpg")) { phase in
                                            switch phase {
                                            case .empty:
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white.opacity(0.1))
                                                    .frame(height: 120)
                                                    .overlay(ProgressView().tint(.white))
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(16/9, contentMode: .fill)
                                                    .frame(height: 120)
                                                    .clipped()
                                                    .cornerRadius(12)
                                            case .failure:
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white.opacity(0.1))
                                                    .frame(height: 120)
                                                    .overlay(
                                                        Image(systemName: "exclamationmark.triangle")
                                                            .foregroundColor(.gray)
                                                    )
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }

                                        // Play button overlay
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Image(systemName: "play.fill")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 20))
                                            )
                                    }
                                }

                                // Clear button
                                Button(action: { youtubeURL = "" }) {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Remove video")
                                    }
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                }
                            } else {
                                // URL input field
                                TextField("Paste YouTube link here", text: $youtubeURL)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                        .padding(.horizontal)

                        Spacer(minLength: 120)
                    }
                }

                // Floating Buttons
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Button(action: { showingDeleteConfirm = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(12)
                        }

                        Button(action: {
                            let valueToSave = isBodyweight ? Double(currentDuration) : currentWeight
                            let urlToSave = youtubeURL.isEmpty ? nil : youtubeURL
                            onSave(valueToSave, reachedFailure, isNegativeOnly, isBodyweight, urlToSave)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeManager.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .alert("Delete Exercise?", isPresented: $showingDeleteConfirm) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                } message: {
                    Text("Remove \(exercise.name) from this workout?")
                }
            }
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            currentWeight = exercise.lastWeight ?? 0
            currentDuration = exercise.lastDuration ?? 60
            reachedFailure = exercise.reachedFailure
            isNegativeOnly = exercise.isNegativeOnly
            isBodyweight = exercise.isBodyweight
            youtubeURL = exercise.youtubeURL ?? ""
        }
        .sheet(isPresented: $showingYouTubePreview) {
            if let url = URL(string: youtubeURL), !youtubeURL.isEmpty {
                YouTubeVideoSheet(url: url, exerciseName: exercise.name)
            }
        }
    }

    private func adjustWeight(_ amount: Double) {
        currentWeight = max(0, currentWeight + amount)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func adjustDuration(_ amount: Int) {
        currentDuration = max(5, currentDuration + amount)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func extractYouTubeVideoId(from urlString: String) -> String? {
        // Handle various YouTube URL formats
        // youtube.com/watch?v=VIDEO_ID
        // youtu.be/VIDEO_ID
        // youtube.com/embed/VIDEO_ID
        // youtube.com/v/VIDEO_ID

        let patterns = [
            "(?:youtube\\.com/watch\\?v=|youtu\\.be/|youtube\\.com/embed/|youtube\\.com/v/)([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(urlString.startIndex..., in: urlString)
                if let match = regex.firstMatch(in: urlString, options: [], range: range),
                   let videoIdRange = Range(match.range(at: 1), in: urlString) {
                    return String(urlString[videoIdRange])
                }
            }
        }

        return nil
    }
}

// MARK: - Add Exercise Sheet
struct AddExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var themeManager = ThemeManager.shared
    let onAdd: (String, Bool, Double?, Bool) -> Void  // name, isBodyweight, weight, isNegativeOnly

    @State private var exerciseName = ""
    @State private var isBodyweight = false
    @State private var isNegativeOnly = false
    @State private var startingWeight: String = ""
    @FocusState private var isNameFocused: Bool

    let suggestedExercises = [
        "Chest Press", "Incline Press", "Decline Press", "Bench Press", "Pec Deck", "Chest Fly",
        "Lat Pulldown", "Pulldown", "Seated Row", "Cable Row", "Pull Up", "Chin Up",
        "Shoulder Press", "Overhead Press", "Lateral Raise", "Front Raise", "Rear Delt",
        "Bicep Curl", "Hammer Curl", "Preacher Curl", "Tricep Extension", "Tricep Pushdown",
        "Leg Press", "Squat", "Hack Squat", "Leg Extension", "Leg Curl", "Lunges",
        "Calf Raise", "Hip Adduction", "Hip Abduction", "Glute Kickback",
        "Ab Crunch", "Leg Raise", "Plank", "Russian Twist",
        "Deadlift", "Barbell Row"
    ]

    let bodyweightExercises: Set<String> = [
        "Pull Up", "Chin Up", "Dips", "Push Up", "Plank", "Hanging Leg Raise",
        "Leg Raise", "Lunges", "Russian Twist"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0D0D0F").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Exercise name input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Exercise Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            TextField("Enter exercise name", text: $exerciseName)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .focused($isNameFocused)
                        }

                        // Bodyweight toggle
                        Button(action: {
                            isBodyweight.toggle()
                            if !isBodyweight {
                                isNegativeOnly = false
                            }
                        }) {
                            HStack {
                                Image(systemName: isBodyweight ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(isBodyweight ? themeManager.primary : .gray)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bodyweight Exercise")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Track time instead of weight (pull-ups, dips)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background {
                                GlassBackground(
                                    isActive: isBodyweight,
                                    tintColor: themeManager.primary
                                )
                            }
                            .shadow(color: isBodyweight ? themeManager.primary.opacity(themeManager.glassShadowOpacity) : Color.black.opacity(0.1), radius: 10, y: 5)
                        }

                        // Negative Only toggle (only for bodyweight)
                        if isBodyweight {
                            Button(action: { isNegativeOnly.toggle() }) {
                                HStack {
                                    Image(systemName: isNegativeOnly ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(isNegativeOnly ? Color.purple : .gray)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Negative Resistance Only")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Position → Slow Lowering → Done & Log")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        Text("Duration set in Settings > Phase Timings")
                                            .font(.system(size: 10))
                                            .foregroundColor(.purple.opacity(0.8))
                                    }
                                    Spacer()
                                }
                                .padding(16)
                                .background {
                                    GlassBackground(
                                        isActive: isNegativeOnly,
                                        tintColor: .purple
                                    )
                                }
                                .shadow(color: Color.purple.opacity(isNegativeOnly ? themeManager.glassShadowOpacity : 0.1), radius: 12, y: 6)
                            }
                        }

                        // Starting weight (only for weighted exercises)
                        if !isBodyweight {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Starting Weight (optional)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)

                                HStack {
                                    TextField("0", text: $startingWeight)
                                        .textFieldStyle(.plain)
                                        .keyboardType(.decimalPad)
                                        .padding(16)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)

                                    Text("lbs")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        // Suggested exercises
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(suggestedExercises, id: \.self) { exercise in
                                    Text(exercise)
                                        .font(.system(size: 14))
                                        .foregroundColor(exerciseName == exercise ? .black : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(exerciseName == exercise ? themeManager.primary : Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                        .onTapGesture(count: 2) {
                                            let isBW = bodyweightExercises.contains(exercise)
                                            let weight = Double(startingWeight)
                                            onAdd(exercise, isBW, isBW ? nil : weight, false)
                                            dismiss()
                                        }
                                        .onTapGesture(count: 1) {
                                            exerciseName = exercise
                                            isBodyweight = bodyweightExercises.contains(exercise)
                                            if isBodyweight {
                                                isNegativeOnly = false
                                            }
                                        }
                                }
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding()
                }

                // Add button
                VStack {
                    Spacer()
                    Button(action: {
                        if !exerciseName.isEmpty {
                            let weight = Double(startingWeight)
                            onAdd(exerciseName, isBodyweight, isBodyweight ? nil : weight, isNegativeOnly)
                            dismiss()
                        }
                    }) {
                        Text("Add Exercise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(exerciseName.isEmpty ? Color.gray : themeManager.primary)
                            .cornerRadius(12)
                    }
                    .disabled(exerciseName.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isNameFocused = true
        }
    }
}

// MARK: - Edit Exercise Sheet
struct EditExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var themeManager = ThemeManager.shared
    let exercise: Exercise
    let onSave: (String, Double?, Bool, Bool, String?) -> Void  // name, weight, isBodyweight, isNegativeOnly, youtubeURL
    let onDelete: () -> Void

    @State private var exerciseName: String = ""
    @State private var isBodyweight: Bool = false
    @State private var isNegativeOnly: Bool = false
    @State private var weightText: String = ""
    @State private var youtubeURL: String = ""
    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0D0D0F").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Exercise name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Exercise Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            TextField("Exercise name", text: $exerciseName)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }

                        // Bodyweight toggle
                        Button(action: {
                            isBodyweight.toggle()
                            if !isBodyweight {
                                isNegativeOnly = false
                            }
                        }) {
                            HStack {
                                Image(systemName: isBodyweight ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(isBodyweight ? themeManager.primary : .gray)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bodyweight Exercise")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Track time instead of weight (pull-ups, dips)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background {
                                GlassBackground(
                                    isActive: isBodyweight,
                                    tintColor: themeManager.primary
                                )
                            }
                            .shadow(color: isBodyweight ? themeManager.primary.opacity(themeManager.glassShadowOpacity) : Color.black.opacity(0.1), radius: 10, y: 5)
                        }

                        // Negative Only toggle (only for bodyweight)
                        if isBodyweight {
                            Button(action: { isNegativeOnly.toggle() }) {
                                HStack {
                                    Image(systemName: isNegativeOnly ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(isNegativeOnly ? Color.purple : .gray)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Negative Resistance Only")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Position → Slow Lowering → Done & Log")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        Text("Duration set in Settings > Phase Timings")
                                            .font(.system(size: 10))
                                            .foregroundColor(.purple.opacity(0.8))
                                    }
                                    Spacer()
                                }
                                .padding(16)
                                .background {
                                    GlassBackground(
                                        isActive: isNegativeOnly,
                                        tintColor: .purple
                                    )
                                }
                                .shadow(color: Color.purple.opacity(isNegativeOnly ? themeManager.glassShadowOpacity : 0.1), radius: 12, y: 6)
                            }
                        }

                        // Weight input (only for weighted exercises)
                        if !isBodyweight {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Weight")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)

                                HStack {
                                    TextField("0", text: $weightText)
                                        .textFieldStyle(.plain)
                                        .keyboardType(.decimalPad)
                                        .padding(16)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)

                                    Text("lbs")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        // YouTube video URL
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundColor(.red)
                                Text("Demo Video (YouTube)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }

                            TextField("YouTube URL", text: $youtubeURL)
                                .textFieldStyle(.plain)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                                .padding(16)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)

                            Text("Paste a YouTube link to show how this exercise is performed")
                                .font(.system(size: 11))
                                .foregroundColor(.gray.opacity(0.7))
                        }

                        Spacer(minLength: 40)

                        // Delete button
                        Button(action: { showingDeleteConfirm = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Exercise")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }

                // Save button
                VStack {
                    Spacer()
                    Button(action: {
                        let weight = Double(weightText)
                        let urlToSave = youtubeURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : youtubeURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(exerciseName, isBodyweight ? nil : weight, isBodyweight, isNegativeOnly, urlToSave)
                        dismiss()
                    }) {
                        Text("Save Changes")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(exerciseName.isEmpty ? Color.gray : themeManager.primary)
                            .cornerRadius(12)
                    }
                    .disabled(exerciseName.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            exerciseName = exercise.name
            isBodyweight = exercise.isBodyweight
            isNegativeOnly = exercise.isNegativeOnly
            if let weight = exercise.lastWeight {
                weightText = "\(Int(weight))"
            }
            youtubeURL = exercise.youtubeURL ?? ""
        }
        .confirmationDialog("Delete Exercise", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(exercise.name)?")
        }
    }
}

// MARK: - YouTube Video Sheet
struct YouTubeVideoSheet: View {
    let url: URL
    let exerciseName: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0D0D0F").ignoresSafeArea()

                VStack(spacing: 20) {
                    // Video preview placeholder with link
                    VStack(spacing: 16) {
                        // YouTube thumbnail area
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "1A1A1F"))
                                .frame(height: 200)

                            VStack(spacing: 12) {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.red)

                                Text("Tap to watch on YouTube")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        .onTapGesture {
                            UIApplication.shared.open(url)
                        }

                        // Exercise name
                        Text(exerciseName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        // URL display
                        Text(url.absoluteString)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Open in YouTube button
                    Button(action: {
                        UIApplication.shared.open(url)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 18))
                            Text("Open in YouTube")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Exercise Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.primary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Reschedule Workout Sheet
struct RescheduleWorkoutSheet: View {
    @ObservedObject var scheduler: WorkoutScheduler
    let profile: Int
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0D0D0F").ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(ThemeManager.shared.primary)

                        Text("Reschedule Workout")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("Pick a new date")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)

                    DatePicker(
                        "Workout Date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(ThemeManager.shared.primary)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Spacer()

                    Button(action: {
                        scheduler.setNextWorkoutDate(selectedDate, profile: profile)
                        dismiss()
                    }) {
                        Text("Set Date")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(ThemeManager.shared.primary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let date = scheduler.nextWorkoutDate {
                selectedDate = date
            }
        }
    }
}

#Preview {
    WorkoutListView()
        .environmentObject(WorkoutManager())
        .preferredColorScheme(.dark)
}

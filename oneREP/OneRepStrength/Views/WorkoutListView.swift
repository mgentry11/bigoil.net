import SwiftUI

struct WorkoutListView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var scheduler = WorkoutScheduler.shared
    @ObservedObject var logManager = WorkoutLogManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var partnerManager = PartnerWorkoutManager.shared
    @State private var showingSettings = false
    @State private var exerciseToEdit: Exercise?
    @State private var showingAddExercise = false
    @State private var showingResetConfirm = false
    @State private var showingHistory = false
    @State private var showingSaveAsTemplate = false
    @State private var showingFinishOptions = false
    @State private var isEditMode = false
    @State private var showingPartnerSetup = false

    var body: some View {
        VStack(spacing: 0) {
        // Header
            HStack {
                Button(action: { showingPartnerSetup = true }) {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                        .foregroundColor(partnerManager.isPartnerModeActive ? themeManager.primary : .gray)
                }

                Spacer()

                Text("Full Body HIT")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.text)

                Spacer()

                Button(action: { showingHistory = true }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundColor(themeManager.primary)
                }

                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .glassCardBackground()

            // Partner Mode Indicator
            PartnerModeIndicator(onEndPartnerMode: {
                partnerManager.endPartnerWorkout()
            })

            // Next Workout Card
            NextWorkoutCard(scheduler: scheduler)
                .padding(.horizontal)
                .padding(.bottom, 8)

            VStack(spacing: 8) {
                HStack {
                    Text("\(workoutManager.completedExercises)/\(workoutManager.currentWorkout.exercises.count) Completed")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if workoutManager.currentWorkout.exercises.count > 0 {
                        let progress = Double(workoutManager.completedExercises) / Double(workoutManager.currentWorkout.exercises.count)
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.primary)
                    }
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        if workoutManager.currentWorkout.exercises.count > 0 {
                            let progress = Double(workoutManager.completedExercises) / Double(workoutManager.currentWorkout.exercises.count)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.primary)
                                .frame(width: geometry.size.width * progress, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: workoutManager.completedExercises)
                        }
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            HStack {
                Button(action: {
                    withAnimation { isEditMode.toggle() }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isEditMode ? "checkmark" : "arrow.up.arrow.down")
                            .font(.caption)
                        Text(isEditMode ? "Done" : "Reorder")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(isEditMode ? .black : ThemeManager.shared.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isEditMode ? ThemeManager.shared.primary : ThemeManager.shared.card)
                    .cornerRadius(16)
                }
                
                Spacer()

                if workoutManager.completedExercises > 0 {
                    Button(action: {
                        showingFinishOptions = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                                .font(.caption)
                            Text("Finish")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(16)
                    }
                }

                Button(action: {
                    showingResetConfirm = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                        Text("Reset")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(ThemeManager.shared.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassCardBackground()
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Siri Tips - collapsible, shows users what to say
            QuickSiriTips()
                .padding(.bottom, 8)

            ZStack {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(workoutManager.currentWorkout.exercises.enumerated()), id: \.element.id) { index, exercise in
                            HStack(spacing: 0) {
                                if isEditMode {
                                    VStack(spacing: 8) {
                                        Button(action: { moveExercise(from: index, direction: -1) }) {
                                            Image(systemName: "chevron.up")
                                                .font(.caption)
                                                .foregroundColor(index == 0 ? .gray.opacity(0.3) : themeManager.primary)
                                        }
                                        .disabled(index == 0)
                                        
                                        Image(systemName: "line.3.horizontal")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Button(action: { moveExercise(from: index, direction: 1) }) {
                                            Image(systemName: "chevron.down")
                                                .font(.caption)
                                                .foregroundColor(index == workoutManager.currentWorkout.exercises.count - 1 ? .gray.opacity(0.3) : themeManager.primary)
                                        }
                                        .disabled(index == workoutManager.currentWorkout.exercises.count - 1)
                                    }
                                    .frame(width: 36)
                                    .padding(.vertical, 8)
                                }
                                
                                ExerciseCard(
                                    exercise: exercise,
                                    onTap: {
                                        if !isEditMode { exerciseToEdit = exercise }
                                    },
                                    onStart: {
                                        if !isEditMode { workoutManager.startExercise(exercise) }
                                    },
                                    onSkip: {
                                        if !isEditMode { workoutManager.skipExercise(exercise) }
                                    },
                                    onWeightChange: { newWeight in
                                        workoutManager.updateExerciseWeight(exercise, weight: newWeight)
                                    }
                                )
                                .opacity(isEditMode ? 0.9 : 1.0)
                            }
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }

                // Floating Add Exercise Button - small FAB in corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddExercise = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(width: 56, height: 56)
                                .background(themeManager.primary)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPartnerSetup) {
            PartnerWorkoutSetupSheet()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(item: $exerciseToEdit) { exercise in
            ExerciseDetailSheet(
                exercise: exercise,
                onSave: { value, reachedFailure in
                    // Save weight or duration depending on exercise type
                    if let index = workoutManager.currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) {
                        if exercise.isBodyweight {
                            // Save duration for bodyweight exercises
                            workoutManager.currentWorkout.exercises[index].lastDuration = Int(value)
                            let durationKey = "exerciseDuration_\(workoutManager.currentProfile)_\(exercise.name)"
                            UserDefaults.standard.set(Int(value), forKey: durationKey)
                        } else {
                            // Save weight for regular exercises
                            workoutManager.currentWorkout.exercises[index].lastWeight = value
                            let key = "exerciseWeight_\(workoutManager.currentProfile)_\(exercise.name)"
                            UserDefaults.standard.set(value, forKey: key)
                        }
                        workoutManager.currentWorkout.exercises[index].reachedFailure = reachedFailure
                        let failureKey = "exerciseFailure_\(workoutManager.currentProfile)_\(exercise.name)"
                        UserDefaults.standard.set(reachedFailure, forKey: failureKey)
                    }
                },
                onDelete: {
                    workoutManager.deleteExercise(exercise)
                }
            )
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseSheet(
                onAdd: { exerciseName, isBodyweight in
                    workoutManager.addExercise(name: exerciseName, isBodyweight: isBodyweight)
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
        .sheet(isPresented: $showingHistory) {
            HistoryView()
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
    }

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
    
    private func moveExercise(from index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < workoutManager.currentWorkout.exercises.count else { return }
        workoutManager.moveExercise(from: index, to: newIndex)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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



// MARK: - Exercise Card
struct ExerciseCard: View {
    let exercise: Exercise
    let onTap: () -> Void
    let onStart: () -> Void
    var onSkip: (() -> Void)? = nil
    var onWeightChange: ((Double) -> Void)? = nil
    
    @State private var displayWeight: Double = 0
    @State private var displayDuration: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ExerciseIconView(iconName: exercise.iconName, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.text)

                    if exercise.isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Completed")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }

                Spacer()

                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onStart()
                }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(ThemeManager.shared.primary)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Start \(exercise.name)")
                .accessibilityHint("Double tap to start timer for this exercise")
            }
            
            if !exercise.isCompleted {
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.vertical, 10)
                
                if exercise.isBodyweight {
                    HStack {
                        Text("Duration:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(formatDuration(displayDuration))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(ThemeManager.shared.primary)
                    }
                } else {
                    HStack(spacing: 12) {
                        Button(action: { adjustWeight(-5) }) {
                            Text("-5")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 40)
                                .background(Color(white: 0.35))
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Decrease weight by 5 pounds")
                        
                        Spacer()
                        
                        VStack(spacing: 0) {
                            Text("\(Int(displayWeight))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(ThemeManager.shared.primary)
                            Text("lbs")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .accessibilityLabel("\(Int(displayWeight)) pounds")
                        
                        Spacer()
                        
                        Button(action: { adjustWeight(5) }) {
                            Text("+5")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 40)
                                .background(Color(white: 0.35))
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Increase weight by 5 pounds")
                    }
                }
            }
        }
        .padding(14)
        .glassCardBackground()
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onStart()
        }
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Edit Details", systemImage: "pencil")
            }
            
            if let skip = onSkip {
                Button {
                    skip()
                } label: {
                    Label("Skip Exercise", systemImage: "forward.fill")
                }
            }
            
            Button {
                onStart()
            } label: {
                Label("Start Timer", systemImage: "play.fill")
            }
        }
        .onAppear {
            displayWeight = exercise.lastWeight ?? 0
            displayDuration = exercise.lastDuration ?? 60
        }
        .onChange(of: exercise.lastWeight) { _, newValue in
            displayWeight = newValue ?? 0
        }
    }
    
    private func adjustWeight(_ amount: Double) {
        let newWeight = max(0, displayWeight + amount)
        displayWeight = newWeight
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        onWeightChange?(newWeight)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Add Exercise Card
struct AddExerciseCard: View {
    var body: some View {
        HStack(spacing: 14) {
            // Plus icon - square to match exercise icons
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ThemeManager.shared.primary, lineWidth: 2)
                    .frame(width: 52, height: 52)

                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(ThemeManager.shared.primary)
            }

            Text("Add Exercise")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(ThemeManager.shared.primary)

            Spacer()
        }
        .padding(14)
        .glassCardBackground()
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ThemeManager.shared.primary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Exercise Icon View
struct ExerciseIconView: View {
    let iconName: String
    var size: CGFloat = 52

    var body: some View {
        // Display square PNG icon directly
        if let iconImage = loadIconImage() {
            Image(uiImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            // Fallback - themed square with dumbbell
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

        // Try without .png extension
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
    let onSave: (Double, Bool) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var currentWeight: Double = 0
    @State private var currentDuration: Int = 60  // Duration in seconds for bodyweight exercises
    @State private var reachedFailure: Bool = true
    @State private var showingDeleteConfirm: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        // Exercise Icon and Name
                        VStack(spacing: 12) {
                            ExerciseIconView(iconName: exercise.iconName, size: 80)

                            Text(exercise.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(ThemeManager.shared.text)
                        }
                        .padding(.top, 20)

                        // Weight/Time Input Section
                        VStack(spacing: 16) {
                            Text(exercise.isBodyweight ? "Time Completed" : "Log Weight")
                                .font(.headline)
                                .foregroundColor(ThemeManager.shared.text)

                            if exercise.isBodyweight {
                                // Time input for bodyweight exercises
                                HStack(spacing: 20) {
                                    // Decrease time
                                    Button(action: { adjustDuration(-15) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(ThemeManager.shared.primary)
                                    }

                                    // Time display (minutes:seconds)
                                    VStack(spacing: 4) {
                                        Text(formatDuration(currentDuration))
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                            .foregroundColor(ThemeManager.shared.text)
                                        Text("min:sec")
                                            .font(.title3)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: 140)

                                    // Increase time
                                    Button(action: { adjustDuration(15) }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(ThemeManager.shared.primary)
                                    }
                                }

                                // Fine adjustment buttons for time
                                HStack(spacing: 16) {
                                    Button(action: { adjustDuration(-5) }) {
                                        Text("-5s")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(ThemeManager.shared.text)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .glassCardBackground()
                                            .cornerRadius(10)
                                    }
                                    Button(action: { adjustDuration(5) }) {
                                        Text("+5s")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(ThemeManager.shared.text)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .glassCardBackground()
                                            .cornerRadius(10)
                                    }
                                }
                            } else {
                                // Weight input for regular exercises
                                HStack(spacing: 20) {
                                    // Decrease weight
                                    Button(action: { adjustWeight(-5) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(ThemeManager.shared.primary)
                                    }

                                    // Weight display
                                    VStack(spacing: 4) {
                                        Text("\(Int(currentWeight))")
                                            .font(.system(size: 56, weight: .bold, design: .rounded))
                                            .foregroundColor(ThemeManager.shared.text)
                                        Text("lbs")
                                            .font(.title3)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: 120)

                                    // Increase weight
                                    Button(action: { adjustWeight(5) }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(ThemeManager.shared.primary)
                                    }
                                }

                                // Fine adjustment buttons for weight
                                HStack(spacing: 16) {
                                    Button(action: { adjustWeight(-2.5) }) {
                                        Text("-2.5")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(ThemeManager.shared.text)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .glassCardBackground()
                                            .cornerRadius(10)
                                    }
                                    Button(action: { adjustWeight(2.5) }) {
                                        Text("+2.5")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(ThemeManager.shared.text)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .glassCardBackground()
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        .padding()
                        .glassCardBackground()
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Reached Failure Toggle
                        Button(action: { reachedFailure.toggle() }) {
                            HStack {
                                Image(systemName: reachedFailure ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(reachedFailure ? .green : .gray)
                                Text("Reached Failure")
                                    .font(.headline)
                                    .foregroundColor(ThemeManager.shared.text)
                                Spacer()
                            }
                            .padding()
                            .glassCardBackground()
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // Siri Shortcut Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "waveform.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("Siri Voice Command")
                                    .font(.headline)
                                    .foregroundColor(ThemeManager.shared.text)
                            }

                            Text("Say to Siri:")
                                .font(.caption)
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 8) {
                                SiriCommandRow(phrase: "Start \(exercise.name)")


                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .glassCardBackground()
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Extra space for floating buttons
                        Spacer(minLength: 100)
                    }
                }

                // Floating Buttons at bottom - Delete and Save side by side
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        // Delete Button
                        Button(action: {
                            showingDeleteConfirm = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.title3)
                                Text("Delete")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }

                        // Save Button
                        Button(action: {
                            let valueToSave = exercise.isBodyweight ? Double(currentDuration) : currentWeight
                            onSave(valueToSave, reachedFailure)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text(exercise.isBodyweight ? "Save Time" : "Save Weight")
                                    .font(.headline)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ThemeManager.shared.primary)
                            .cornerRadius(12)
                        }
                    }
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .alert("Delete Exercise?", isPresented: $showingDeleteConfirm) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                } message: {
                    Text("Are you sure you want to remove \(exercise.name) from this workout?")
                }
            }
            .background(ThemeManager.shared.backgroundView)
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let valueToSave = exercise.isBodyweight ? Double(currentDuration) : currentWeight
                        onSave(valueToSave, reachedFailure)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.primary)
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            currentWeight = exercise.lastWeight ?? 0
            currentDuration = exercise.lastDuration ?? 60
        }
    }

    private func adjustWeight(_ amount: Double) {
        currentWeight = max(0, currentWeight + amount)
    }

    private func adjustDuration(_ amount: Int) {
        currentDuration = max(5, currentDuration + amount)  // Minimum 5 seconds
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Siri Command Row
struct SiriCommandRow: View {
    let phrase: String

    var body: some View {
        HStack {
            Image(systemName: "mic.fill")
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text("\"Hey Siri, \(phrase)\"")
                .font(.subheadline)
                .foregroundColor(ThemeManager.shared.text)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .glassCardBackground()
        .cornerRadius(8)
    }
}

// MARK: - Add Exercise Sheet
struct AddExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    let onAdd: (String, Bool) -> Void  // (name, isBodyweight)

    @State private var exerciseName = ""
    @State private var isBodyweight = false
    @FocusState private var isNameFocused: Bool

    // Comprehensive list of gym machine and weight training exercises (organized by muscle group)
    let suggestedExercises = [
        // Chest
        "Chest Press", "Incline Press", "Decline Press", "Bench Press", "Pec Deck", "Chest Fly", "Cable Crossover", "Dips", "Push Up",
        // Back
        "Lat Pulldown", "Pulldown", "Seated Row", "Cable Row", "Machine Row", "T-Bar Row", "Pull Up", "Chin Up", "Straight Arm Pulldown", "Back Extension", "Hyperextension",
        // Shoulders
        "Shoulder Press", "Overhead Press", "Military Press", "Lateral Raise", "Front Raise", "Rear Delt", "Rear Delt Fly", "Face Pull", "Reverse Pec Deck", "Arnold Press", "Upright Row", "Shrug",
        // Arms
        "Bicep Curl", "Hammer Curl", "Preacher Curl", "Cable Curl", "Concentration Curl", "Tricep Extension", "Tricep Pushdown", "Skull Crusher", "Close Grip Bench Press", "Wrist Curl",
        // Legs
        "Leg Press", "Squat", "Hack Squat", "Front Squat", "Goblet Squat", "Leg Extension", "Leg Curl", "Seated Leg Curl", "Lying Leg Curl", "Romanian Deadlift", "Hip Thrust", "Lunges", "Bulgarian Split Squat", "Step Up",
        // Calves
        "Calf Raise", "Seated Calf Raise", "Standing Calf Raise",
        // Hip/Glutes
        "Hip Adduction", "Hip Abduction", "Inner Thigh", "Outer Thigh", "Glute Kickback", "Glute Bridge",
        // Core
        "Ab Crunch", "Cable Crunch", "Leg Raise", "Hanging Leg Raise", "Captain's Chair", "Plank", "Russian Twist", "Wood Chop", "Torso Rotation", "Oblique Crunch",
        // Compound
        "Deadlift", "Sumo Deadlift", "Trap Bar Deadlift", "Barbell Row", "Clean and Press", "Farmer's Walk",
        // Smith Machine
        "Smith Machine Squat", "Smith Machine Bench Press", "Smith Machine Shoulder Press",
        // Assisted
        "Assisted Pull Up", "Assisted Dip"
    ]

    // Known bodyweight exercises - auto-detected when selected
    let bodyweightExercises: Set<String> = [
        "Pull Up", "Chin Up", "Dips", "Push Up", "Plank", "Hanging Leg Raise",
        "Leg Raise", "Back Extension", "Hyperextension", "Glute Bridge",
        "Lunges", "Bulgarian Split Squat", "Step Up", "Russian Twist"
    ]

    func isBodyweightExercise(_ name: String) -> Bool {
        bodyweightExercises.contains(name)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercise Name")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextField("Enter exercise name", text: $exerciseName)
                            .textFieldStyle(.plain)
                            .padding()
                            .glassCardBackground()
                            .cornerRadius(12)
                            .foregroundColor(ThemeManager.shared.text)
                            .focused($isNameFocused)
                    }

                    // Bodyweight toggle
                    Button(action: { isBodyweight.toggle() }) {
                        HStack {
                            Image(systemName: isBodyweight ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundColor(isBodyweight ? ThemeManager.shared.primary : .gray)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bodyweight Exercise")
                                    .font(.headline)
                                    .foregroundColor(ThemeManager.shared.text)
                                Text("Track time only (no weight)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding()
                        .glassCardBackground()
                        .cornerRadius(12)
                    }

                    // Suggested exercises
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Suggested Exercises")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Double-tap to add")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.6))
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(suggestedExercises, id: \.self) { exercise in
                                Text(exercise)
                                    .font(.subheadline)
                                    .foregroundColor(exerciseName == exercise ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(exerciseName == exercise ? ThemeManager.shared.primary : Color(white: 0.15))
                                    .cornerRadius(8)
                                    .onTapGesture(count: 2) {
                                        // Double-tap to add immediately (auto-detect bodyweight)
                                        let isBW = isBodyweightExercise(exercise)
                                        onAdd(exercise, isBW)
                                        dismiss()
                                    }
                                    .onTapGesture(count: 1) {
                                        // Single tap to select (auto-toggle bodyweight)
                                        exerciseName = exercise
                                        isBodyweight = isBodyweightExercise(exercise)
                                    }
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    // Add button
                    Button(action: {
                        if !exerciseName.isEmpty {
                            onAdd(exerciseName, isBodyweight)
                            dismiss()
                        }
                    }) {
                        Text("Add Exercise")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(exerciseName.isEmpty ? Color.gray : ThemeManager.shared.primary)
                            .cornerRadius(12)
                    }
                    .disabled(exerciseName.isEmpty)
                }
                .padding()
            }
            .background(ThemeManager.shared.backgroundView)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.6))
                            .cornerRadius(8)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if !exerciseName.isEmpty {
                            onAdd(exerciseName, isBodyweight)
                            dismiss()
                        }
                    }) {
                        Text("Add")
                            .fontWeight(.semibold)
                            .foregroundColor(exerciseName.isEmpty ? .gray : .black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(exerciseName.isEmpty ? Color.gray.opacity(0.3) : ThemeManager.shared.primary)
                            .cornerRadius(8)
                    }
                    .disabled(exerciseName.isEmpty)
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            isNameFocused = true
        }
    }
}

// MARK: - Next Workout Card
struct NextWorkoutCard: View {
    @ObservedObject var scheduler: WorkoutScheduler
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingNotificationAlert = false
    @State private var showingReschedule = false
    @State private var selectedDate = Date()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Calendar icon - tappable to reschedule
                Button(action: { showingReschedule = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ThemeManager.shared.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ThemeManager.shared.primary, lineWidth: 1)
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "calendar.badge.clock")
                            .font(.title3)
                            .foregroundColor(ThemeManager.shared.primary)
                    }
                }

                // Next workout info
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Workout")
                        .font(.caption)
                        .foregroundColor(.gray)

                    HStack(spacing: 6) {
                        Text(scheduler.formattedNextWorkoutDate())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ThemeManager.shared.text)
                    }
                }

                Spacer()

                // Reschedule button
                Button(action: { showingReschedule = true }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // Notification toggle
                Button(action: {
                    if scheduler.notificationsEnabled {
                        scheduler.notificationsEnabled = false
                    } else {
                        scheduler.requestNotificationPermission { granted in
                            if !granted {
                                showingNotificationAlert = true
                            }
                        }
                    }
                }) {
                    Image(systemName: scheduler.notificationsEnabled ? "bell.fill" : "bell.slash")
                        .font(.title3)
                        .foregroundColor(scheduler.notificationsEnabled ? ThemeManager.shared.primary : .gray)
                }
            }
            .padding(12)
        }
        .glassCardBackground()
        .cornerRadius(12)
        .alert("Enable Notifications", isPresented: $showingNotificationAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive workout reminders, please enable notifications in Settings.")
        }
        .sheet(isPresented: $showingReschedule) {
            RescheduleWorkoutSheet(
                scheduler: scheduler,
                profile: workoutManager.currentProfile,
                selectedDate: $selectedDate
            )
        }
        .onAppear {
            selectedDate = scheduler.nextWorkoutDate ?? Date()
        }
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
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 50))
                        .foregroundColor(ThemeManager.shared.primary)

                    Text("Reschedule Workout")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.text)

                    Text("Can't make it today? Pick a new date.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)

                // Date Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Date")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    DatePicker(
                        "Workout Date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(ThemeManager.shared.primary)
                    .glassCardBackground()
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    scheduler.setNextWorkoutDate(selectedDate, profile: profile)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Set Workout Date")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ThemeManager.shared.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(ThemeManager.shared.backgroundView)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.shared.primary)
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            if let date = scheduler.nextWorkoutDate {
                selectedDate = date
            }
        }
    }
}

struct WorkoutTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? ThemeManager.shared.primary : Color(white: 0.15))
                .cornerRadius(10)
        }
    }
}

#Preview {
    WorkoutListView()
        .environmentObject(WorkoutManager())
        .preferredColorScheme(.light)
}

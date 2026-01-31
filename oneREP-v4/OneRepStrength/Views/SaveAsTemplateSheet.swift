//
//  SaveAsTemplateSheet.swift
//  HITCoachPro
//
//  Sheet for saving current workout exercises as a reusable template
//
//  v2 Changes:
//  - Made exercises editable before saving (tap to edit weight)
//  - Uses @State to allow modifications before save
//

import SwiftUI

// MARK: - Editable Exercise for Template
struct EditableTemplateExercise: Identifiable {
    let id: UUID
    var name: String
    var targetWeight: Double
    var iconName: String
    var audioFileName: String

    init(from exercise: Exercise) {
        self.id = exercise.id
        self.name = exercise.name
        self.targetWeight = exercise.lastWeight ?? 0
        self.iconName = exercise.iconName
        self.audioFileName = exercise.audioFileName
    }

    init(from entry: WorkoutLogEntry) {
        self.id = UUID()
        self.name = entry.exerciseName
        self.targetWeight = entry.weight
        self.iconName = "dumbbell.png"
        self.audioFileName = "exercise_custom"
    }

    init(name: String, weight: Double) {
        self.id = UUID()
        self.name = name
        self.targetWeight = weight
        self.iconName = "dumbbell.png"
        self.audioFileName = "exercise_custom"
    }

    func toTemplateExercise() -> TemplateExercise {
        TemplateExercise(
            id: id,
            name: name,
            targetWeight: targetWeight > 0 ? targetWeight : nil,
            iconName: iconName,
            audioFileName: audioFileName
        )
    }
}

struct SaveAsTemplateSheet: View {
    let exercises: [Exercise]
    let profile: Int
    var logEntries: [WorkoutLogEntry]? = nil  // Optional: if saving from history

    @Environment(\.dismiss) var dismiss
    @ObservedObject var templateManager = WorkoutTemplateManager.shared
    @State private var templateName: String = ""
    @State private var editableExercises: [EditableTemplateExercise] = []
    @State private var exerciseToEdit: EditableTemplateExercise?
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "bookmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(ThemeManager.shared.primary)

                            Text("Save as Routine")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(ThemeManager.shared.text)

                            Text("Tap an exercise to edit weight before saving")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Routine Name")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            TextField("e.g., Upper Body Push", text: $templateName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(ThemeManager.shared.card)
                                .cornerRadius(12)
                                .foregroundColor(ThemeManager.shared.text)
                                .focused($isNameFocused)
                        }
                        .padding(.horizontal)

                        // Editable Exercise List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Exercises (\(editableExercises.count))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("Tap to edit")
                                    .font(.caption)
                                    .foregroundColor(ThemeManager.shared.primary)
                            }

                            VStack(spacing: 8) {
                                ForEach(editableExercises) { exercise in
                                    Button(action: {
                                        exerciseToEdit = exercise
                                    }) {
                                        HStack {
                                            Image(systemName: "dumbbell.fill")
                                                .font(.caption)
                                                .foregroundColor(ThemeManager.shared.primary)
                                                .frame(width: 24)

                                            Text(exercise.name)
                                                .font(.subheadline)
                                                .foregroundColor(ThemeManager.shared.text)

                                            Spacer()

                                            if exercise.targetWeight > 0 {
                                                Text("\(Int(exercise.targetWeight)) lbs")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(ThemeManager.shared.primary)
                                            } else {
                                                Text("Set weight")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                            }

                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(ThemeManager.shared.primary.opacity(0.6))
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                        .background(ThemeManager.shared.card)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 20)
                    }
                }

                // Save Button
                VStack(spacing: 0) {
                    Divider()
                        .background(ThemeManager.shared.card)

                    Button(action: saveTemplate) {
                        HStack {
                            Image(systemName: "bookmark.fill")
                            Text("Save Routine")
                        }
                        .font(.headline)
                        .foregroundColor(templateName.isEmpty ? .gray : .black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(templateName.isEmpty ? Color(white: 0.3) : ThemeManager.shared.primary)
                        .cornerRadius(12)
                    }
                    .disabled(templateName.isEmpty)
                    .padding()
                }
            }
            .background(ThemeManager.shared.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.shared.primary)
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            // Initialize editable exercises
            if let entries = logEntries {
                // Creating from log entries - use max weight for each exercise
                var exerciseDict: [String: Double] = [:]
                for entry in entries {
                    let currentMax = exerciseDict[entry.exerciseName] ?? 0
                    exerciseDict[entry.exerciseName] = max(currentMax, entry.weight)
                }
                editableExercises = exerciseDict.map { EditableTemplateExercise(name: $0.key, weight: $0.value) }
                    .sorted { $0.name < $1.name }
            } else {
                editableExercises = exercises.map { EditableTemplateExercise(from: $0) }
            }

            // Suggest a default name
            if templateName.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                templateName = "Workout - \(formatter.string(from: Date()))"
            }
            isNameFocused = true
        }
        .sheet(item: $exerciseToEdit) { exercise in
            EditTemplateExerciseSheet(
                exercise: exercise,
                onSave: { updatedExercise in
                    if let index = editableExercises.firstIndex(where: { $0.id == updatedExercise.id }) {
                        editableExercises[index] = updatedExercise
                    }
                }
            )
        }
    }

    private func saveTemplate() {
        guard !templateName.isEmpty else { return }

        let templateExercises = editableExercises.map { $0.toTemplateExercise() }
        let template = WorkoutTemplate(
            name: templateName,
            exercises: templateExercises,
            profile: profile
        )

        templateManager.saveTemplate(template)
        dismiss()
    }
}

// MARK: - Edit Template Exercise Sheet
struct EditTemplateExerciseSheet: View {
    let exercise: EditableTemplateExercise
    let onSave: (EditableTemplateExercise) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var weight: Double = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Exercise name
                Text(exercise.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)
                    .padding(.top, 20)

                // Weight input
                VStack(spacing: 16) {
                    Text("Target Weight")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    HStack(spacing: 24) {
                        Button(action: { adjustWeight(-5) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(ThemeManager.shared.primary)
                        }

                        VStack(spacing: 4) {
                            Text("\(Int(weight))")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(ThemeManager.shared.text)
                            Text("lbs")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 120)

                        Button(action: { adjustWeight(5) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(ThemeManager.shared.primary)
                        }
                    }

                    // Fine adjustment
                    HStack(spacing: 16) {
                        Button(action: { adjustWeight(-2.5) }) {
                            Text("-2.5")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ThemeManager.shared.text)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(ThemeManager.shared.card)
                                .cornerRadius(10)
                        }
                        Button(action: { adjustWeight(2.5) }) {
                            Text("+2.5")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ThemeManager.shared.text)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(ThemeManager.shared.card)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(24)
                .background(ThemeManager.shared.card)
                .cornerRadius(20)
                .padding(.horizontal)

                Spacer()

                // Save button
                Button(action: {
                    var updated = exercise
                    updated.targetWeight = weight
                    onSave(updated)
                    dismiss()
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ThemeManager.shared.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(ThemeManager.shared.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.shared.primary)
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            weight = exercise.targetWeight
        }
    }

    private func adjustWeight(_ amount: Double) {
        weight = max(0, weight + amount)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Save from Log Entries Sheet
struct SaveLogAsTemplateSheet: View {
    let entries: [WorkoutLogEntry]
    let date: Date
    let profile: Int

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var templateManager = WorkoutTemplateManager.shared
    @State private var templateName: String
    @State private var editableExercises: [EditableTemplateExercise]
    @State private var exerciseToEdit: EditableTemplateExercise?
    @FocusState private var isNameFocused: Bool

    // Use dark theme to match app style
    @ObservedObject var themeManager = ThemeManager.shared

    init(entries: [WorkoutLogEntry], date: Date, profile: Int) {
        self.entries = entries
        self.date = date
        self.profile = profile

        // Initialize editable exercises from entries using max weight
        var exerciseDict: [String: Double] = [:]
        for entry in entries {
            let currentMax = exerciseDict[entry.exerciseName] ?? 0
            exerciseDict[entry.exerciseName] = max(currentMax, entry.weight)
        }
        let exercises = exerciseDict.map { EditableTemplateExercise(name: $0.key, weight: $0.value) }
            .sorted { $0.name < $1.name }
        _editableExercises = State(initialValue: exercises)

        // Initialize template name
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: date)
        _templateName = State(initialValue: "\(dayName) Workout")
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "bookmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(themeManager.primary)

                            Text("Save as Routine")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("Save this workout from \(formatDate(date))")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text("Tap an exercise to edit weight")
                                .font(.caption)
                                .foregroundColor(themeManager.primary)
                        }
                        .padding(.top, 20)

                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Routine Name")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            TextField("e.g., Full Body", text: $templateName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .focused($isNameFocused)
                        }
                        .padding(.horizontal)

                        // Editable Exercise List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Exercises (\(editableExercises.count))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }

                            VStack(spacing: 8) {
                                ForEach(editableExercises) { exercise in
                                    Button(action: {
                                        exerciseToEdit = exercise
                                    }) {
                                        HStack {
                                            Image(systemName: "dumbbell.fill")
                                                .font(.caption)
                                                .foregroundColor(themeManager.primary)
                                                .frame(width: 24)

                                            Text(exercise.name)
                                                .font(.subheadline)
                                                .foregroundColor(.white)

                                            Spacer()

                                            if exercise.targetWeight > 0 {
                                                Text("\(Int(exercise.targetWeight)) lbs")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(themeManager.primary)
                                            } else {
                                                Text("Set weight")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                            }

                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(themeManager.primary.opacity(0.6))
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 20)
                    }
                }

                // Save Button
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    Button(action: saveTemplate) {
                        HStack {
                            Image(systemName: "bookmark.fill")
                            Text("Save Routine")
                        }
                        .font(.headline)
                        .foregroundColor(templateName.isEmpty ? .gray : .black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(templateName.isEmpty ? Color(white: 0.3) : themeManager.primary)
                        .cornerRadius(12)
                    }
                    .disabled(templateName.isEmpty)
                    .padding()
                }
            }
            .background(Color(hex: "0D0D0F"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isNameFocused = true
        }
        .sheet(item: $exerciseToEdit) { exercise in
            EditTemplateExerciseSheet(
                exercise: exercise,
                onSave: { updatedExercise in
                    if let index = editableExercises.firstIndex(where: { $0.id == updatedExercise.id }) {
                        editableExercises[index] = updatedExercise
                    }
                }
            )
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func saveTemplate() {
        guard !templateName.isEmpty else { return }

        let templateExercises = editableExercises.map { $0.toTemplateExercise() }
        let template = WorkoutTemplate(
            name: templateName,
            exercises: templateExercises,
            profile: profile
        )

        templateManager.saveTemplate(template)

        // Auto-load the saved template so user can start immediately
        workoutManager.loadTemplate(template)

        dismiss()
    }
}

#Preview {
    SaveAsTemplateSheet(
        exercises: Workout.defaultWorkout.exercises,
        profile: 1
    )
}

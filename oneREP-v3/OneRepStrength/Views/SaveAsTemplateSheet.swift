//
//  SaveAsTemplateSheet.swift
//  HITCoachPro
//
//  Sheet for saving current workout exercises as a reusable template
//

import SwiftUI

struct SaveAsTemplateSheet: View {
    let exercises: [Exercise]
    let profile: Int
    var logEntries: [WorkoutLogEntry]? = nil  // Optional: if saving from history

    @Environment(\.dismiss) var dismiss
    @ObservedObject var templateManager = WorkoutTemplateManager.shared
    @State private var templateName: String = ""
    @FocusState private var isNameFocused: Bool

    private var exercisesToSave: [TemplateExercise] {
        if let entries = logEntries {
            // Creating from log entries
            var exerciseDict: [String: WorkoutLogEntry] = [:]
            for entry in entries {
                exerciseDict[entry.exerciseName] = entry
            }
            return exerciseDict.values.map { entry in
                TemplateExercise(
                    name: entry.exerciseName,
                    targetWeight: entry.weight,
                    iconName: "dumbbell.png",
                    audioFileName: "exercise_custom"
                )
            }
        } else {
            // Creating from current exercises
            return exercises.map { exercise in
                TemplateExercise(
                    name: exercise.name,
                    targetWeight: exercise.lastWeight,
                    iconName: exercise.iconName,
                    audioFileName: exercise.audioFileName
                )
            }
        }
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
                                .foregroundColor(ThemeManager.shared.primary)

                            Text("Save as Routine")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(ThemeManager.shared.text)

                            Text("Create a reusable routine from these exercises")
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

                        // Exercise Preview
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Exercises (\(exercisesToSave.count))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }

                            VStack(spacing: 8) {
                                ForEach(exercisesToSave) { exercise in
                                    HStack {
                                        Image(systemName: "dumbbell.fill")
                                            .font(.caption)
                                            .foregroundColor(ThemeManager.shared.primary)
                                            .frame(width: 24)

                                        Text(exercise.name)
                                            .font(.subheadline)
                                            .foregroundColor(ThemeManager.shared.text)

                                        Spacer()

                                        if let weight = exercise.targetWeight, weight > 0 {
                                            Text("\(Int(weight)) lbs")
                                                .font(.caption)
                                                .foregroundColor(ThemeManager.shared.primary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(ThemeManager.shared.card)
                                    .cornerRadius(8)
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
            // Suggest a default name
            if templateName.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                templateName = "Workout - \(formatter.string(from: Date()))"
            }
            isNameFocused = true
        }
    }

    private func saveTemplate() {
        guard !templateName.isEmpty else { return }

        let template = WorkoutTemplate(
            name: templateName,
            exercises: exercisesToSave,
            profile: profile
        )

        templateManager.saveTemplate(template)
        dismiss()
    }
}

// MARK: - Save from Log Entries Sheet
struct SaveLogAsTemplateSheet: View {
    let entries: [WorkoutLogEntry]
    let date: Date
    let profile: Int

    @Environment(\.dismiss) var dismiss
    @ObservedObject var templateManager = WorkoutTemplateManager.shared
    @State private var templateName: String = ""
    @FocusState private var isNameFocused: Bool

    // Fallback colors in case assets aren't loaded
    private let bgColor = Color(red: 0.98, green: 0.976, blue: 0.976)
    private let cardColor = Color.white
    private let textColor = Color(red: 0.427, green: 0.157, blue: 0.851)
    private let accentColor = Color(red: 0.055, green: 0.647, blue: 0.913)

    private var uniqueExercises: [(name: String, weight: Double)] {
        var exerciseDict: [String: Double] = [:]
        for entry in entries {
            exerciseDict[entry.exerciseName] = entry.weight
        }
        return exerciseDict.map { (name: $0.key, weight: $0.value) }.sorted { $0.name < $1.name }
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
                                .foregroundColor(accentColor)

                            Text("Save as Routine")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(textColor)

                            Text("Save this workout from \(formatDate(date))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
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
                                .background(cardColor)
                                .cornerRadius(12)
                                .foregroundColor(textColor)
                                .focused($isNameFocused)
                        }
                        .padding(.horizontal)

                        // Exercise Preview
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Exercises (\(uniqueExercises.count))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }

                            VStack(spacing: 8) {
                                ForEach(uniqueExercises, id: \.name) { exercise in
                                    HStack {
                                        Image(systemName: "dumbbell.fill")
                                            .font(.caption)
                                            .foregroundColor(accentColor)
                                            .frame(width: 24)

                                        Text(exercise.name)
                                            .font(.subheadline)
                                            .foregroundColor(textColor)

                                        Spacer()

                                        Text("\(Int(exercise.weight)) lbs")
                                            .font(.caption)
                                            .foregroundColor(accentColor)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(cardColor)
                                    .cornerRadius(8)
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
                        .background(cardColor)

                    Button(action: saveTemplate) {
                        HStack {
                            Image(systemName: "bookmark.fill")
                            Text("Save Routine")
                        }
                        .font(.headline)
                        .foregroundColor(templateName.isEmpty ? .gray : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(templateName.isEmpty ? Color(white: 0.7) : accentColor)
                        .cornerRadius(12)
                    }
                    .disabled(templateName.isEmpty)
                    .padding()
                }
            }
            .background(bgColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            templateName = templateManager.suggestedName(for: date)
            isNameFocused = true
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func saveTemplate() {
        guard !templateName.isEmpty else { return }

        let template = WorkoutTemplate.fromLogEntries(entries, name: templateName, profile: profile)
        templateManager.saveTemplate(template)
        dismiss()
    }
}

#Preview {
    SaveAsTemplateSheet(
        exercises: Workout.defaultWorkout.exercises,
        profile: 1
    )
}

//
//  RoutineDetailView.swift
//  HITCoachPro
//
//  Detailed view for a workout template - view, edit, load, share, delete
//

import SwiftUI

struct RoutineDetailView: View {
    let template: WorkoutTemplate

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var templateManager = WorkoutTemplateManager.shared
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(ThemeManager.shared.primary.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(ThemeManager.shared.primary)
                            }

                            if isEditing {
                                TextField("Routine Name", text: $editedName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(ThemeManager.shared.text)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 8)
                                    .glassCardBackground()
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            } else {
                                Text(template.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(ThemeManager.shared.text)
                            }

                            // Stats
                            HStack(spacing: 16) {
                                StatBadge(
                                    icon: "dumbbell.fill",
                                    value: "\(template.exercises.count)",
                                    label: "exercises"
                                )

                                if let lastUsed = template.lastUsedAt {
                                    StatBadge(
                                        icon: "clock.fill",
                                        value: formatRelativeDate(lastUsed),
                                        label: "last used"
                                    )
                                }

                                StatBadge(
                                    icon: "calendar",
                                    value: formatDate(template.createdAt),
                                    label: "created"
                                )
                            }
                        }
                        .padding(.top, 20)

                        // Exercise List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Exercises")
                                    .font(.headline)
                                    .foregroundColor(ThemeManager.shared.text)
                                Spacer()
                            }
                            .padding(.horizontal)

                            VStack(spacing: 8) {
                                ForEach(Array(template.exercises.enumerated()), id: \.element.id) { index, exercise in
                                    TemplateExerciseRow(
                                        index: index + 1,
                                        exercise: exercise
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Action Buttons
                        VStack(spacing: 12) {
                            // Start Workout Button
                            Button(action: loadAndStart) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start This Workout")
                                }
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(ThemeManager.shared.primary)
                                .cornerRadius(12)
                            }

                            // Share Button
                            Button(action: { showingShareSheet = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Routine")
                                }
                                .font(.headline)
                                .foregroundColor(ThemeManager.shared.text)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .glassCardBackground()
                                .cornerRadius(12)
                            }

                            // Delete Button
                            Button(action: { showingDeleteAlert = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Routine")
                                }
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .glassCardBackground()
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                }
            }
            .background(ThemeManager.shared.background)
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
                    if isEditing {
                        Button("Done") {
                            saveEdit()
                        }
                        .foregroundColor(ThemeManager.shared.primary)
                        .fontWeight(.semibold)
                    } else {
                        Button(action: { startEditing() }) {
                            Text("Edit")
                                .foregroundColor(ThemeManager.shared.primary)
                        }
                    }
                }
            }
            .alert("Delete Routine?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTemplate()
                }
            } message: {
                Text("Are you sure you want to delete \"\(template.name)\"? This action cannot be undone.")
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(template: template)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            editedName = template.name
        }
    }

    private func startEditing() {
        editedName = template.name
        isEditing = true
    }

    private func saveEdit() {
        if !editedName.isEmpty && editedName != template.name {
            templateManager.renameTemplate(template, to: editedName)
        }
        isEditing = false
    }

    private func loadAndStart() {
        workoutManager.loadTemplate(template)
        dismiss()
    }

    private func deleteTemplate() {
        templateManager.deleteTemplate(template)
        dismiss()
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            if days < 7 {
                return "\(days)d ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(ThemeManager.shared.primary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(ThemeManager.shared.text)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCardBackground()
        .cornerRadius(10)
    }
}

// MARK: - Template Exercise Row
struct TemplateExerciseRow: View {
    let index: Int
    let exercise: TemplateExercise

    var body: some View {
        HStack(spacing: 12) {
            // Index number
            Text("\(index)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.primary)
                .frame(width: 24)

            // Exercise name
            Text(exercise.name)
                .font(.subheadline)
                .foregroundColor(ThemeManager.shared.text)

            Spacer()

            // Weight
            if let weight = exercise.targetWeight, weight > 0 {
                Text("\(Int(weight)) lbs")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ThemeManager.shared.primary)
            } else {
                Text("No weight")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .glassCardBackground()
        .cornerRadius(10)
    }
}

// MARK: - Share Sheet
struct ShareSheet: View {
    let template: WorkoutTemplate

    @Environment(\.dismiss) var dismiss
    @ObservedObject var templateManager = WorkoutTemplateManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(ThemeManager.shared.primary.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 40))
                        .foregroundColor(ThemeManager.shared.primary)
                }

                // Title
                Text("Share \"\(template.name)\"")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)

                Text("Share this routine with friends via AirDrop, Messages, or any other app")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Exercise count
                Text("\(template.exercises.count) exercises included")
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.primary)

                Spacer()

                // Share Button
                Button(action: shareTemplate) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
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
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.shared.primary)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func shareTemplate() {
        guard let url = templateManager.exportTemplateToURL(template) else { return }

        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    RoutineDetailView(
        template: WorkoutTemplate(
            name: "Upper Body Push",
            exercises: [
                TemplateExercise(name: "Chest Press", targetWeight: 150),
                TemplateExercise(name: "Shoulder Press", targetWeight: 80),
                TemplateExercise(name: "Tricep Extension", targetWeight: 50)
            ],
            profile: 1
        )
    )
    .environmentObject(WorkoutManager())
}

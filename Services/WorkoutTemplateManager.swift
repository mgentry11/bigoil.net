//
//  WorkoutTemplateManager.swift
//  HITCoachPro
//
//  Manages workout templates - save, load, organize, and share routines
//

import Foundation
import SwiftUI

class WorkoutTemplateManager: ObservableObject {
    static let shared = WorkoutTemplateManager()

    @Published var templates: [WorkoutTemplate] = []

    private let storageKeyPrefix = "workoutTemplates_"

    init() {
        // Load templates for profile 1 by default
        loadTemplates(for: 1)
    }

    // MARK: - CRUD Operations

    func saveTemplate(_ template: WorkoutTemplate) {
        // Check if updating existing template
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.insert(template, at: 0)
        }
        persistTemplates(for: template.profile)
    }

    func createTemplate(name: String, exercises: [Exercise], profile: Int) -> WorkoutTemplate {
        let template = WorkoutTemplate.fromExercises(exercises, name: name, profile: profile)
        saveTemplate(template)
        return template
    }

    func createTemplateFromLogs(_ entries: [WorkoutLogEntry], name: String, profile: Int) -> WorkoutTemplate {
        let template = WorkoutTemplate.fromLogEntries(entries, name: name, profile: profile)
        saveTemplate(template)
        return template
    }

    func deleteTemplate(_ template: WorkoutTemplate) {
        templates.removeAll { $0.id == template.id }
        persistTemplates(for: template.profile)
    }

    func deleteTemplate(at offsets: IndexSet, profile: Int) {
        templates.remove(atOffsets: offsets)
        persistTemplates(for: profile)
    }

    func updateTemplateLastUsed(_ template: WorkoutTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].lastUsedAt = Date()
            persistTemplates(for: template.profile)
        }
    }

    func renameTemplate(_ template: WorkoutTemplate, to newName: String) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].name = newName
            persistTemplates(for: template.profile)
        }
    }

    // MARK: - Query Methods

    func getTemplates(for profile: Int) -> [WorkoutTemplate] {
        return templates.filter { $0.profile == profile }
    }

    func getRecentTemplates(for profile: Int, limit: Int = 5) -> [WorkoutTemplate] {
        return templates
            .filter { $0.profile == profile && $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }

    func getSavedTemplates(for profile: Int) -> [WorkoutTemplate] {
        return templates
            .filter { $0.profile == profile && !$0.isBuiltIn }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Profile Management

    func loadTemplates(for profile: Int) {
        let key = storageKeyPrefix + String(profile)
        if let data = UserDefaults.standard.data(forKey: key),
           let savedTemplates = try? JSONDecoder().decode([WorkoutTemplate].self, from: data) {
            templates.removeAll { $0.profile == profile }
            templates.append(contentsOf: savedTemplates)
        }
    }

    func switchProfile(to profile: Int) {
        loadTemplates(for: profile)
    }

    // MARK: - Persistence

    private func persistTemplates(for profile: Int) {
        let key = storageKeyPrefix + String(profile)
        let profileTemplates = templates.filter { $0.profile == profile }
        if let data = try? JSONEncoder().encode(profileTemplates) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Export/Import (Sharing)

    func exportTemplate(_ template: WorkoutTemplate) -> Data? {
        let shareable = ShareableTemplate(from: template)
        return try? JSONEncoder().encode(shareable)
    }

    func exportTemplateToURL(_ template: WorkoutTemplate) -> URL? {
        guard let data = exportTemplate(template) else { return nil }

        let filename = "\(template.name.replacingOccurrences(of: " ", with: "_")).onerepstrength"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }

    func importTemplate(from data: Data, profile: Int) -> WorkoutTemplate? {
        guard let shareable = try? JSONDecoder().decode(ShareableTemplate.self, from: data) else {
            return nil
        }

        let template = shareable.toTemplate(profile: profile)
        saveTemplate(template)
        return template
    }

    func importTemplate(from url: URL, profile: Int) -> WorkoutTemplate? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return importTemplate(from: data, profile: profile)
    }

    // MARK: - Recent Workouts (from Log)

    /// Get workouts grouped by date from the workout log
    func getRecentWorkoutsFromLog(for profile: Int, limit: Int = 10) -> [(date: Date, entries: [WorkoutLogEntry])] {
        let logs = WorkoutLogManager.shared.getLogs(for: profile)
        let calendar = Calendar.current

        // Group by date
        let grouped = Dictionary(grouping: logs) { entry in
            calendar.startOfDay(for: entry.date)
        }

        // Sort by date descending and limit
        return grouped
            .sorted { $0.key > $1.key }
            .prefix(limit)
            .map { (date: $0.key, entries: $0.value) }
    }

    /// Create a template name from a date
    func suggestedName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Workout - \(formatter.string(from: date))"
    }
}

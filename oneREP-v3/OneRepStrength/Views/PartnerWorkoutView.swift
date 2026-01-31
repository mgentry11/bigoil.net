// PartnerWorkoutView.swift
// UI for starting and managing partner workouts

import SwiftUI

struct PartnerWorkoutSetupSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var partnerManager = PartnerWorkoutManager.shared
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State private var partner1Name = "Partner 1"
    @State private var partner2Name = "Partner 2"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 50))
                        .foregroundColor(ThemeManager.shared.primary)
                    
                    Text("Partner Workout")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.text)
                    
                    Text("Train together with separate routines")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // Partner Setup
                VStack(spacing: 16) {
                    PartnerCard(
                        number: 1,
                        name: $partner1Name,
                        profileId: partnerManager.partner1Profile
                    )
                    
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title2)
                        .foregroundColor(ThemeManager.shared.primary)
                    
                    PartnerCard(
                        number: 2,
                        name: $partner2Name,
                        profileId: partnerManager.partner2Profile
                    )
                }
                .padding(.horizontal)
                
                // How it works
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it works:")
                        .font(.headline)
                        .foregroundColor(ThemeManager.shared.text)
                    
                    HowItWorksRow(icon: "1.circle.fill", text: "Each partner has their own routine & weights")
                    HowItWorksRow(icon: "2.circle.fill", text: "Work out at the same time on different exercises")
                    HowItWorksRow(icon: "3.circle.fill", text: "Progress is tracked separately")
                }
                .padding()
                .glassCardBackground()
                .padding(.horizontal)
                
                Spacer()
                
                // Start Button
                Button(action: {
                    partnerManager.startPartnerWorkout(
                        partner1: 1,
                        partner2: 2,
                        initialWorkout: workoutManager.currentWorkout
                    )
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Partner Workout")
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct PartnerCard: View {
    let number: Int
    @Binding var name: String
    let profileId: Int
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ThemeManager.shared.primary.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text("P\(number)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Partner \(number)", text: $name)
                    .font(.headline)
                    .foregroundColor(ThemeManager.shared.text)
                
                Text("Profile \(profileId) • Own routine & weights")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .glassCardBackground()
    }
}

struct HowItWorksRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ThemeManager.shared.primary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(ThemeManager.shared.text)
        }
    }
}

// MARK: - Partner Mode Indicator
struct PartnerModeIndicator: View {
    @ObservedObject var partnerManager = PartnerWorkoutManager.shared
    @EnvironmentObject var workoutManager: WorkoutManager
    let onEndPartnerMode: () -> Void
    
    var body: some View {
        if partnerManager.isPartnerModeActive {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(ThemeManager.shared.primary)
                
                Text("Partner Mode")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.text)
                
                Text("• P\(partnerManager.currentPartner)'s turn")
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.primary)
                
                Spacer()
                
                Button(action: {
                    partnerManager.switchPartner(workoutManager: workoutManager)
                }) {
                    Text("Switch")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(ThemeManager.shared.primary)
                        .cornerRadius(8)
                }
                
                Button(action: onEndPartnerMode) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .glassCardBackground()
        }
    }
}

#Preview {
    PartnerWorkoutSetupSheet()
        .environmentObject(WorkoutManager())
}

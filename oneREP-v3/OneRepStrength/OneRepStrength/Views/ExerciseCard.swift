//
//  ExerciseCard.swift
//  OneRepStrength
//
//  Modern exercise card with glassmorphism
//

import SwiftUI

struct ExerciseCard: View {
    let exercise: Exercise
    let onStart: () -> Void
    
    var body: some View {
        HStack(spacing: DS.l) {
            // Icon
            ZStack {
                Circle()
                    .fill(exercise.isCompleted ? Color.brandGreen : Color.background)
                    .frame(width: 52, height: 52)
                
                Image(systemName: exercise.isCompleted ? "checkmark" : exercise.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(exercise.isCompleted ? .white : .brandGreen)
            }
            
            // Info
            VStack(alignment: .leading, spacing: DS.xs) {
                Text(exercise.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryText)
                
                if let weight = exercise.lastWeight {
                    HStack(spacing: DS.xs) {
                        Text("\(Int(weight)) lbs")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        if exercise.isCompleted {
                            Text("✓")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.brandGreen)
                        }
                    }
                } else {
                    Text("No weight set")
                        .font(.system(size: 14))
                        .foregroundColor(.tertiaryText)
                }
            }
            
            Spacer()
            
            // Start Button
            Button(action: onStart) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.brandGreen.gradient)
                            .shadow(color: Color.brandGreen.opacity(0.4), radius: 8, y: 4)
                    )
            }
        }
        .padding(DS.l)
        .background(
            RoundedRectangle(cornerRadius: DSRadius.card)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
        )
        .opacity(exercise.isCompleted ? 0.7 : 1.0)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DS.l) {
        ExerciseCard(
            exercise: Exercise(name: "Leg Press", iconName: "figure.strengthtraining.traditional", lastWeight: 180),
            onStart: {}
        )
        ExerciseCard(
            exercise: Exercise(name: "Pulldown", iconName: "figure.climbing", lastWeight: 120, isCompleted: true),
            onStart: {}
        )
        ExerciseCard(
            exercise: Exercise(name: "Chest Press", iconName: "figure.boxing"),
            onStart: {}
        )
    }
    .padding()
    .background(GradientBackground())
}

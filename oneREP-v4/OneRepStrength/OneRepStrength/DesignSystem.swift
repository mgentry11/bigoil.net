//
//  DesignSystem.swift
//  OneRepStrength
//
//  Modern iOS 17+ Design System with Glassmorphism and Bold Gradients
//

import SwiftUI

// MARK: - Spacing System
enum DS {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius
enum DSRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let card: CGFloat = 20
    static let button: CGFloat = 14
}

// MARK: - Modern Color Palette
extension Color {
    // Primary Brand Colors
    static let brandGreen = Color(red: 0.2, green: 0.84, blue: 0.65) // Vibrant mint
    static let brandPurple = Color(red: 0.56, green: 0.35, blue: 0.97) // Electric purple
    static let brandOrange = Color(red: 1.0, green: 0.58, blue: 0.25) // Warm orange
    
    // Phase Colors with modern vibrancy
    static let phasePrep = Color(red: 1.0, green: 0.8, blue: 0.3) // Golden yellow
    static let phasePositive = Color(red: 0.3, green: 0.85, blue: 0.55) // Fresh green
    static let phaseStatic = Color(red: 0.35, green: 0.6, blue: 1.0) // Sky blue
    static let phaseNegative = Color(red: 1.0, green: 0.5, blue: 0.3) // Sunset orange
    static let phaseComplete = Color(red: 0.56, green: 0.35, blue: 0.97) // Purple
    
    // Neutral Palette
    static let background = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let cardBackground = Color.white
    static let primaryText = Color(red: 0.1, green: 0.1, blue: 0.15)
    static let secondaryText = Color(red: 0.45, green: 0.45, blue: 0.5)
    static let tertiaryText = Color(red: 0.7, green: 0.7, blue: 0.75)
    
    // Glass effect
    static let glassBackground = Color.white.opacity(0.7)
    static let glassBorder = Color.white.opacity(0.5)
}

// MARK: - Modern Gradient Backgrounds
struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.96, blue: 0.98),
                Color(red: 0.92, green: 0.94, blue: 0.98),
                Color(red: 0.96, green: 0.95, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Phase Gradient
struct PhaseGradient: View {
    let phase: TimerPhase
    
    var colors: [Color] {
        switch phase {
        case .prep:
            return [Color.phasePrep, Color.phasePrep.opacity(0.7)]
        case .positive:
            return [Color.phasePositive, Color(red: 0.2, green: 0.75, blue: 0.45)]
        case .hold:
            return [Color.phaseStatic, Color(red: 0.25, green: 0.5, blue: 0.9)]
        case .negative:
            return [Color.phaseNegative, Color(red: 0.95, green: 0.4, blue: 0.25)]
        case .complete:
            return [Color.phaseComplete, Color(red: 0.45, green: 0.25, blue: 0.85)]
        case .rest:
            return [Color(red: 0.3, green: 0.35, blue: 0.45), Color(red: 0.2, green: 0.25, blue: 0.35)]
        }
    }
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Glass Card Modifier
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .stroke(Color.glassBorder, lineWidth: 1)
            )
    }
}

// MARK: - Solid Card Modifier
struct SolidCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
    
    func solidCard() -> some View {
        modifier(SolidCard())
    }
}

// MARK: - Modern Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, DS.xl)
            .padding(.vertical, DS.m)
            .background(
                LinearGradient(
                    colors: [Color.brandGreen, Color.brandGreen.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.button))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(.brandGreen)
            .padding(.horizontal, DS.l)
            .padding(.vertical, DS.s)
            .background(Color.brandGreen.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.button))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Circular Timer Button
struct TimerControlButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(color.gradient)
                        .shadow(color: color.opacity(0.4), radius: 12, y: 6)
                )
        }
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color.gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.3), value: progress)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.s) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primaryText)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondaryText)
        }
        .padding(DS.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCard()
    }
}

// MARK: - Profile Switcher
struct ProfileSwitcher: View {
    @Binding var selectedProfile: Int
    let profileNames: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<profileNames.count, id: \.self) { index in
                Button(action: { 
                    withAnimation(.spring(response: 0.3)) {
                        selectedProfile = index 
                    }
                }) {
                    Text(profileNames[index])
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedProfile == index ? .white : .secondaryText)
                        .padding(.horizontal, DS.l)
                        .padding(.vertical, DS.s)
                        .background(
                            Capsule()
                                .fill(selectedProfile == index ? Color.brandGreen : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

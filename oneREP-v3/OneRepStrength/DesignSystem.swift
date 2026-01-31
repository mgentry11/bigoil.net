//
//  DesignSystem.swift
//  OneRepStrength
//
//  UI UX Pro Max Design System Components
//  Reusable UI components following fitness app best practices
//

import SwiftUI

// MARK: - Primary Button (CTA)
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(DesignTypography.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Spacing.touchTarget)
            .padding(.horizontal, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.success)
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1)
        .animation(.easeInOut(duration: AnimationDuration.fast), value: isLoading)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(DesignTypography.headline)
            }
            .foregroundColor(theme.primary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Spacing.touchTarget)
            .padding(.horizontal, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.primary, lineWidth: 2)
            )
        }
    }
}

// MARK: - Icon Button (44x44 minimum)
struct IconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = Spacing.touchTarget

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(theme.primary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(theme.surface)
                )
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let trend: Trend?

    @ObservedObject private var theme = ThemeManager.shared

    enum Trend {
        case up(String)
        case down(String)
        case neutral
    }

    init(title: String, value: String, icon: String, trend: Trend? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.primary)
                Spacer()
                if let trend = trend {
                    trendBadge(trend)
                }
            }

            Text(value)
                .font(DesignTypography.statMedium)
                .foregroundColor(theme.text)

            Text(title)
                .font(DesignTypography.caption)
                .foregroundColor(theme.textDim)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardBackground()
    }

    @ViewBuilder
    private func trendBadge(_ trend: Trend) -> some View {
        switch trend {
        case .up(let value):
            HStack(spacing: 2) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                Text(value)
                    .font(DesignTypography.caption2)
            }
            .foregroundColor(theme.up)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(theme.up.opacity(0.15))
            .cornerRadius(4)

        case .down(let value):
            HStack(spacing: 2) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                Text(value)
                    .font(DesignTypography.caption2)
            }
            .foregroundColor(theme.down)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(theme.down.opacity(0.15))
            .cornerRadius(4)

        case .neutral:
            EmptyView()
        }
    }
}

// MARK: - Progress Ring (Gamification)
struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    let lineWidth: CGFloat
    let label: String?

    @ObservedObject private var theme = ThemeManager.shared

    init(progress: Double, size: CGFloat = 80, lineWidth: CGFloat = 8, label: String? = nil) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.lineWidth = lineWidth
        self.label = label
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(theme.surface, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [theme.primary, theme.accent, theme.primary],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            // Center content
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(DesignTypography.statSmall)
                    .foregroundColor(theme.text)

                if let label = label {
                    Text(label)
                        .font(DesignTypography.caption2)
                        .foregroundColor(theme.textDim)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Streak Badge
struct StreakBadge: View {
    let days: Int
    let isActive: Bool

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: isActive ? "flame.fill" : "flame")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isActive ? .orange : theme.textDim)

            Text("\(days)")
                .font(DesignTypography.headline)
                .foregroundColor(isActive ? theme.text : theme.textDim)

            Text("day streak")
                .font(DesignTypography.caption)
                .foregroundColor(theme.textDim)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(isActive ? Color.orange.opacity(0.15) : theme.surface)
        )
        .overlay(
            Capsule()
                .stroke(isActive ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let icon: String
    let title: String
    let isUnlocked: Bool

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? theme.primary.opacity(0.15) : theme.surface)
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isUnlocked ? theme.primary : theme.textDim)
            }

            Text(title)
                .font(DesignTypography.caption)
                .foregroundColor(isUnlocked ? theme.text : theme.textDim)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
        .opacity(isUnlocked ? 1 : 0.5)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionLabel: String?

    @ObservedObject private var theme = ThemeManager.shared

    init(_ title: String, action: (() -> Void)? = nil, actionLabel: String? = "See All") {
        self.title = title
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        HStack {
            Text(title)
                .font(DesignTypography.title3)
                .foregroundColor(theme.text)

            Spacer()

            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(DesignTypography.subheadline)
                        .foregroundColor(theme.primary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @ObservedObject private var theme = ThemeManager.shared

    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(theme.textDim)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(DesignTypography.title3)
                    .foregroundColor(theme.text)

                Text(message)
                    .font(DesignTypography.subheadline)
                    .foregroundColor(theme.textDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
            }

            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Haptic Feedback Helper
enum HapticFeedback {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - Reduced Motion Preference
extension View {
    @ViewBuilder
    func reduceMotionAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self.animation(nil, value: value)
        } else {
            self.animation(animation, value: value)
        }
    }
}

// MARK: - Preview
#Preview("Design System") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            SectionHeader("Buttons")

            VStack(spacing: Spacing.md) {
                PrimaryButton("Log Set", icon: "checkmark.circle.fill") {}
                SecondaryButton("Cancel", icon: "xmark") {}

                HStack(spacing: Spacing.md) {
                    IconButton(icon: "plus") {}
                    IconButton(icon: "minus") {}
                    IconButton(icon: "gear") {}
                }
            }
            .padding(.horizontal, Spacing.md)

            SectionHeader("Stats")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                StatCard(title: "Total Sets", value: "247", icon: "dumbbell.fill", trend: .up("12%"))
                StatCard(title: "This Week", value: "32", icon: "calendar", trend: .down("5%"))
            }
            .padding(.horizontal, Spacing.md)

            SectionHeader("Gamification")

            HStack(spacing: Spacing.lg) {
                ProgressRing(progress: 0.75, label: "Goal")
                StreakBadge(days: 7, isActive: true)
            }
            .padding(.horizontal, Spacing.md)

            HStack(spacing: Spacing.sm) {
                AchievementBadge(icon: "trophy.fill", title: "First PR", isUnlocked: true)
                AchievementBadge(icon: "flame.fill", title: "7 Day Streak", isUnlocked: true)
                AchievementBadge(icon: "star.fill", title: "100 Sets", isUnlocked: false)
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.lg)
    }
    .background(ThemeManager.shared.background)
}

//
//  ThemeManager.swift
//  HITCoachPro
//
//  Manages color themes for the app
//

import SwiftUI

// MARK: - Design System Spacing (UI UX Pro Max)
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64

    // Touch target minimum (Apple HIG)
    static let touchTarget: CGFloat = 44
}

// MARK: - Design System Typography
enum DesignTypography {
    static let largeTitle: Font = .system(size: 34, weight: .bold, design: .rounded)
    static let title: Font = .system(size: 28, weight: .bold, design: .rounded)
    static let title2: Font = .system(size: 22, weight: .bold, design: .rounded)
    static let title3: Font = .system(size: 20, weight: .semibold, design: .rounded)
    static let headline: Font = .system(size: 17, weight: .semibold, design: .rounded)
    static let body: Font = .system(size: 17, weight: .regular, design: .default)
    static let callout: Font = .system(size: 16, weight: .regular, design: .default)
    static let subheadline: Font = .system(size: 15, weight: .regular, design: .default)
    static let footnote: Font = .system(size: 13, weight: .regular, design: .default)
    static let caption: Font = .system(size: 12, weight: .regular, design: .default)
    static let caption2: Font = .system(size: 11, weight: .regular, design: .default)

    // Athletic/Condensed style for stats and numbers
    static let statLarge: Font = .system(size: 48, weight: .heavy, design: .rounded)
    static let statMedium: Font = .system(size: 32, weight: .bold, design: .rounded)
    static let statSmall: Font = .system(size: 24, weight: .bold, design: .rounded)
}

// MARK: - Animation Durations
enum AnimationDuration {
    static let fast: Double = 0.15
    static let normal: Double = 0.25
    static let slow: Double = 0.35
}

enum AppTheme: String, CaseIterable, Identifiable {
    // Featured themes
    case `default` = "default"
    case orange = "orange"
    case charcoal = "charcoal"
    case fitness = "fitness"  // New UI UX Pro Max recommended theme

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .orange: return "Ember"
        case .charcoal: return "Charcoal"
        case .fitness: return "Power"
        }
    }

    // Preview colors for theme selector (4 colors for the grid preview)
    var previewColors: [Color] {
        switch self {
        case .default:
            return [Color(hex: "0ea5e9"), Color(hex: "6d28d9"), Color(hex: "059669"), Color(hex: "a78bfa")]
        case .orange:
            return [Color(hex: "DC540C"), Color(hex: "AC3D00"), Color(hex: "E96825"), Color(hex: "eb9268")]
        case .charcoal:
            return [Color(hex: "383838"), Color(hex: "999999"), Color(hex: "303641"), Color(hex: "5c5c5c")]
        case .fitness:
            return [Color(hex: "DC2626"), Color(hex: "F87171"), Color(hex: "16A34A"), Color(hex: "1F2937")]
        }
    }

    // Primary/accent color
    var primaryColor: Color {
        switch self {
        case .default: return Color(hex: "0ea5e9")
        case .orange: return Color(hex: "FF6B00")
        case .charcoal: return Color(hex: "999999")
        case .fitness: return Color(hex: "DC2626")  // Energetic red
        }
    }

    var accentColor: Color {
        switch self {
        case .default: return Color(hex: "059669")
        case .orange: return Color(hex: "DC540C")
        case .charcoal: return Color(hex: "5c5c5c")
        case .fitness: return Color(hex: "F87171")  // Soft red
        }
    }

    // Success/CTA color for positive actions
    var successColor: Color {
        switch self {
        case .default: return Color(hex: "22c55e")
        case .orange: return Color(hex: "16A34A")
        case .charcoal: return Color(hex: "22c55e")
        case .fitness: return Color(hex: "16A34A")  // Strong green CTA
        }
    }

    // Warning color for alerts
    var warningColor: Color {
        switch self {
        case .default: return Color(hex: "f59e0b")
        case .orange: return Color(hex: "f59e0b")
        case .charcoal: return Color(hex: "f59e0b")
        case .fitness: return Color(hex: "f59e0b")
        }
    }

    var textColor: Color {
        switch self {
        case .default: return Color(hex: "1F2937")
        case .orange: return Color(hex: "FFFFFF")
        case .charcoal: return Color(hex: "FFFFFF")
        case .fitness: return Color(hex: "FFFFFF")
        }
    }

    var textDimColor: Color {
        switch self {
        case .default: return Color(hex: "6B7280")
        case .orange: return Color(hex: "9CA3AF")
        case .charcoal: return Color(hex: "9CA3AF")
        case .fitness: return Color(hex: "9CA3AF")
        }
    }

    var downColor: Color {
        switch self {
        case .default: return Color(hex: "EF4444")
        case .orange: return Color(hex: "EF4444")
        case .charcoal: return Color(hex: "EF4444")
        case .fitness: return Color(hex: "EF4444")
        }
    }

    var upColor: Color {
        switch self {
        case .default: return Color(hex: "22c55e")
        case .orange: return Color(hex: "22c55e")
        case .charcoal: return Color(hex: "22c55e")
        case .fitness: return Color(hex: "16A34A")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .default:
            return Color(hex: "fafaf9")
        case .orange:
            return Color(hex: "121212")
        case .charcoal:
            return Color(hex: "1C1C1E")
        case .fitness:
            return Color(hex: "0A0A0A")  // Deep OLED black
        }
    }

    var cardBackground: Color {
        switch self {
        case .charcoal:
            return Color(hex: "2C2C2E")
        case .orange:
            return Color(hex: "1E1E1E")
        case .fitness:
            return Color(hex: "1A1A1A")
        default:
            return .white
        }
    }

    // Surface colors for layered UI
    var surfaceColor: Color {
        switch self {
        case .default: return Color(hex: "F3F4F6")
        case .orange: return Color(hex: "262626")
        case .charcoal: return Color(hex: "3A3A3C")
        case .fitness: return Color(hex: "262626")
        }
    }

    // Helper to determine if theme is dark (for text color adjustments)
    var isDark: Bool {
        switch self {
        case .charcoal, .orange, .fitness:
            return true
        default:
            return false
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    init() {
        // Load saved theme or default to fitness (Power) theme
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .fitness
        }
    }

    // Convenience accessors
    var primary: Color { currentTheme.primaryColor }
    var accent: Color { currentTheme.accentColor }
    var success: Color { currentTheme.successColor }
    var warning: Color { currentTheme.warningColor }
    var text: Color { currentTheme.textColor }
    var textDim: Color { currentTheme.textDimColor }
    var down: Color { currentTheme.downColor }
    var up: Color { currentTheme.upColor }
    var background: Color { currentTheme.backgroundColor }
    var card: Color { currentTheme.cardBackground }
    var surface: Color { currentTheme.surfaceColor }
    var isDark: Bool { currentTheme.isDark }
    
    // Glassmorphism support
    var isGlassEnabled: Bool {
        // Enable glass for dark themes per user request
        return isDark
    }
    
    // Dynamic background view (Gradient for glass themes, Solid for others)
    @ViewBuilder
    var backgroundView: some View {
        if isGlassEnabled {
            ZStack {
                // Deep dark base
                Color(hex: "030308").ignoresSafeArea()
                
                // VERY bright orbs for maximum glass effect
                GeometryReader { proxy in
                    let size = proxy.size
                    
                    // Top Left Orb - SUPER bright
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [self.primary, self.primary.opacity(0.6), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 250
                            )
                        )
                        .frame(width: 500, height: 500)
                        .blur(radius: 40)
                        .offset(x: -120, y: -80)
                        .opacity(0.8)
                    
                    // Center Right Orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [self.accent, self.accent.opacity(0.5), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .blur(radius: 35)
                        .offset(x: size.width - 60, y: size.height * 0.3)
                        .opacity(0.7)
                        
                    // Bottom Orb - Huge glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [self.primary, self.accent.opacity(0.5), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 300
                            )
                        )
                        .frame(width: 600, height: 600)
                        .blur(radius: 60)
                        .offset(x: size.width * 0.2, y: size.height - 20)
                        .opacity(0.6)
                    
                    // Top right accent
                    Circle()
                        .fill(self.accent)
                        .frame(width: 250, height: 250)
                        .blur(radius: 80)
                        .offset(x: size.width - 30, y: 30)
                        .opacity(0.5)
                    
                    // Mid-left subtle orb
                    Circle()
                        .fill(self.primary.opacity(0.7))
                        .frame(width: 300, height: 300)
                        .blur(radius: 100)
                        .offset(x: -80, y: size.height * 0.5)
                        .opacity(0.4)
                }
            }
            .ignoresSafeArea()
        } else {
            background.ignoresSafeArea()
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Environment Key for Theme
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemeManager = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Glassmorphism Modifier
struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 24
    
    func body(content: Content) -> some View {
        Group {
            if ThemeManager.shared.isGlassEnabled {
                content
                    .background(
                        ZStack {
                            // Maximum frosted glass - thickest material
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.thickMaterial)
                            
                            // Strong inner glow / tint layer
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            ThemeManager.shared.primary.opacity(0.15),
                                            ThemeManager.shared.accent.opacity(0.08),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    )
                    // Bold gradient border
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.6),
                                        .white.opacity(0.2),
                                        ThemeManager.shared.primary.opacity(0.4),
                                        ThemeManager.shared.accent.opacity(0.2),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    // Strong outer shadow
                    .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 10)
                    // Outer glow with primary color
                    .shadow(color: ThemeManager.shared.primary.opacity(0.15), radius: 30, x: 0, y: 0)
            } else {
                content
                    .background(ThemeManager.shared.card)
                    .cornerRadius(12)
            }
        }
    }
}

extension View {
    func glassCardBackground() -> some View {
        modifier(GlassCardStyle())
    }
}


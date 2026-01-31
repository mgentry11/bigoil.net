//
//  ThemeManager.swift
//  HITCoachPro
//
//  Manages color themes for the app
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    // Featured themes
    case `default` = "default"
    case orange = "orange"
    case charcoal = "charcoal"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .orange: return "Ember"
        case .charcoal: return "Charcoal"
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
        }
    }

    // Primary/accent color
    var primaryColor: Color {
        switch self {
        case .default: return Color(hex: "0ea5e9")
        case .orange: return Color(hex: "FF6B00")
        case .charcoal: return Color(hex: "999999")
        }
    }

    var accentColor: Color {
        switch self {
        case .default: return Color(hex: "059669")
        case .orange: return Color(hex: "DC540C")
        case .charcoal: return Color(hex: "5c5c5c")
        }
    }

    var textColor: Color {
        switch self {
        case .default: return Color(hex: "6d28d9")
        case .orange: return Color(hex: "FFFFFF")
        case .charcoal: return Color(hex: "303641")
        }
    }

    var textDimColor: Color {
        switch self {
        case .default: return Color(hex: "a78bfa")
        case .orange: return Color(hex: "eb9268")
        case .charcoal: return Color(hex: "5c5c5c")
        }
    }

    var downColor: Color {
        switch self {
        case .default: return Color(hex: "3b82f6")
        case .orange: return Color(hex: "DC540C")
        case .charcoal: return Color(hex: "5c5c5c")
        }
    }

    var upColor: Color {
        switch self {
        case .default: return Color(hex: "22c55e")
        case .orange: return Color(hex: "E96825")
        case .charcoal: return Color(hex: "999999")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .default:
            return Color(hex: "fafaf9")
        case .orange:
            return Color(hex: "121212")
        case .charcoal:
            return Color(hex: "323232")
        }
    }

    var cardBackground: Color {
        switch self {
        case .charcoal:
            return Color(hex: "2C2C2E")
        case .orange:
            return Color(hex: "1E1E1E")
        default:
            return .white
        }
    }

    // Helper to determine if theme is dark (for text color adjustments)
    var isDark: Bool {
        switch self {
        case .charcoal, .orange:
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
        // Force orange theme to match mockup colors
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
        self.currentTheme = .orange
    }

    // Convenience accessors
    var primary: Color { currentTheme.primaryColor }
    var accent: Color { currentTheme.accentColor }
    var text: Color { currentTheme.textColor }
    var textDim: Color { currentTheme.textDimColor }
    var down: Color { currentTheme.downColor }
    var up: Color { currentTheme.upColor }
    var background: Color { currentTheme.backgroundColor }
    var card: Color { currentTheme.cardBackground }
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


// ContentViewV3.swift
// Version 3 UI - Simplified navigation with hidden toolbar and expandable menu

import SwiftUI

struct ContentViewV3: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var currentView: AppView = .workouts
    @State private var isMenuExpanded = false
    
    enum AppView: String, CaseIterable {
        case workouts = "Workouts"
        case routines = "Routines"
        case stats = "Stats"
        case log = "Log"
        case settings = "Settings"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .workouts: return "dumbbell.fill"
            case .routines: return "folder.fill"
            case .stats: return "chart.line.uptrend.xyaxis"
            case .log: return "list.bullet.rectangle.portrait"
            case .settings: return "gearshape.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            ThemeManager.shared.background.ignoresSafeArea()
            
            // Main content - full screen, no tab bar
            VStack(spacing: 0) {
                // Content based on current view
                switch currentView {
                case .workouts:
                    WorkoutListView()
                case .routines:
                    RoutinesView()
                case .stats:
                    StatsView()
                case .log:
                    LogView()
                case .settings:
                    SettingsView()
                case .profile:
                    ProfileView()
                }
            }
            
            // Overlay dimmer when menu is expanded
            if isMenuExpanded {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isMenuExpanded = false
                        }
                    }
            }
            
            // Expandable Menu Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ExpandableMenuButton(
                        isExpanded: $isMenuExpanded,
                        currentView: $currentView
                    )
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                }
            }
            
            // Timer/Rest overlays
            if workoutManager.showingTimer {
                TimerView()
                    .transition(.move(edge: .bottom))
            }
            
            if workoutManager.showingRest {
                RestView()
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: workoutManager.showingTimer)
        .animation(.easeInOut, value: workoutManager.showingRest)
    }
}

// MARK: - Expandable Menu Button
struct ExpandableMenuButton: View {
    @Binding var isExpanded: Bool
    @Binding var currentView: ContentViewV3.AppView
    @ObservedObject var themeManager = ThemeManager.shared
    
    // Menu items (excluding current view)
    private var menuItems: [ContentViewV3.AppView] {
        ContentViewV3.AppView.allCases.filter { $0 != currentView }
    }
    
    var body: some View {
        ZStack {
            // Expanded menu items - fan out in arc
            if isExpanded {
                ForEach(Array(menuItems.enumerated()), id: \.element) { index, item in
                    MenuItemButton(item: item) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentView = item
                            isExpanded = false
                        }
                    }
                    .offset(getOffset(for: index, total: menuItems.count))
                    .opacity(isExpanded ? 1 : 0)
                    .scaleEffect(isExpanded ? 1 : 0.5)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                        .delay(Double(index) * 0.05),
                        value: isExpanded
                    )
                }
            }
            
            // Main button (shows current view icon)
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(themeManager.primary.opacity(0.3))
                        .frame(width: 70, height: 70)
                        .blur(radius: 10)
                    
                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeManager.primary, themeManager.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: themeManager.primary.opacity(0.5), radius: 10)
                    
                    // Icon
                    Image(systemName: isExpanded ? "xmark" : currentView.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
        }
    }
    
    // Calculate offset for each menu item in an arc
    private func getOffset(for index: Int, total: Int) -> CGSize {
        let angleStep: Double = 35 // degrees between items
        let startAngle: Double = 180 // start from left
        let radius: Double = 90
        
        let angle = startAngle + Double(index) * angleStep
        let radians = angle * .pi / 180
        
        return CGSize(
            width: cos(radians) * radius,
            height: sin(radians) * radius
        )
    }
}

// MARK: - Menu Item Button
struct MenuItemButton: View {
    let item: ContentViewV3.AppView
    let action: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Glass background
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(themeManager.primary.opacity(0.5), lineWidth: 1)
                        )
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.primary)
                }
                
                Text(item.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    ContentViewV3()
        .environmentObject(WorkoutManager())
        .environmentObject(AudioManager())
}

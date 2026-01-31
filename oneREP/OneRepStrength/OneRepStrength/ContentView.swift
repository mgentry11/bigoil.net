//
//  ContentView.swift
//  OneRepStrength
//
//  Main app view with tab navigation and timer overlay
//

import SwiftUI

struct ContentView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var timerManager = TimerManager()
    @State private var selectedTab: Tab = .workout
    
    enum Tab {
        case workout, history, settings
    }
    
    var body: some View {
        ZStack {
            // Tab Content
            TabView(selection: $selectedTab) {
                WorkoutListView(profileManager: profileManager, timerManager: timerManager)
                    .tag(Tab.workout)
                
                HistoryView(profileManager: profileManager)
                    .tag(Tab.history)
                
                SettingsView(profileManager: profileManager)
                    .tag(Tab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar
            VStack {
                Spacer()
                tabBar
            }
            
            // Timer Overlay
            if timerManager.showingTimer {
                TimerView(timerManager: timerManager, profileManager: profileManager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: timerManager.showingTimer)
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(icon: "dumbbell.fill", title: "Workout", tab: .workout)
            tabButton(icon: "clock.fill", title: "History", tab: .history)
            tabButton(icon: "gearshape.fill", title: "Settings", tab: .settings)
        }
        .padding(.horizontal, DS.xl)
        .padding(.vertical, DS.m)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        )
        .padding(.horizontal, DS.xl)
        .padding(.bottom, DS.s)
    }
    
    private func tabButton(icon: String, title: String, tab: Tab) -> some View {
        Button(action: { 
            withAnimation(.spring(response: 0.3)) {
                selectedTab = tab 
            }
        }) {
            VStack(spacing: DS.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(selectedTab == tab ? .brandGreen : .secondaryText)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

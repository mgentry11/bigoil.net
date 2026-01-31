//
//  OneRepStrengthWatchApp.swift
//  OneRepStrength Watch App
//
//  Entry point for the Apple Watch companion app
//

import SwiftUI

@main
struct OneRepStrengthWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(connectivity)
        }
    }
}

// MARK: - Main Content View
struct WatchContentView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    
    var body: some View {
        Group {
            if connectivity.workoutState.isActive {
                // Show timer or rest based on phase
                if connectivity.workoutState.phase.lowercased() == "rest" {
                    WatchRestView()
                } else {
                    WatchTimerView()
                }
            } else {
                // Show idle/waiting state
                WatchIdleView()
            }
        }
    }
}

// MARK: - Idle View (No Active Workout)
struct WatchIdleView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // App icon
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("OneRepStrength")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(connectivity.isReachable ? "Ready" : "Connecting...")
                    .font(.caption2)
                    .foregroundColor(connectivity.isReachable ? .green : .gray)
                
                if connectivity.isReachable {
                    Text("Start workout on iPhone")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
    }
}

#Preview("Idle") {
    WatchIdleView()
        .environmentObject(WatchConnectivityManager.shared)
}

#Preview("Timer") {
    WatchTimerView()
}

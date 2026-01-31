//
//  WatchRestView.swift
//  OneRepStrength Watch App
//
//  Rest timer view for Apple Watch between exercises
//

import SwiftUI

struct WatchRestView: View {
    @ObservedObject var connectivity = WatchConnectivityManager.shared
    
    var state: WatchWorkoutState {
        connectivity.workoutState
    }
    
    var body: some View {
        ZStack {
            // Calm background
            Color(red: 0.1, green: 0.1, blue: 0.15)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Rest indicator
                Text("REST")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                    .tracking(2)
                
                // Large countdown
                Text("\(state.timeRemaining)")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Text("seconds")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Skip button
                Button(action: skipRest) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("Skip")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }
    
    func skipRest() {
        WatchConnectivityManager.shared.sendCommand(.skip)
    }
}

#Preview {
    WatchRestView()
}

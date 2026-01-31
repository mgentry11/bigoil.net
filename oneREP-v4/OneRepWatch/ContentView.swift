#if os(watchOS)
//
//  ContentView.swift
//  OneRepWatch v4
//
//  Redesigned Watch app content view with v4 dark theme
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivityManager: LocalWatchConnectivityManager

    // V4 Theme Colors (optimized for Watch)
    private let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    var body: some View {
        if connectivityManager.workoutState.isActive {
            WorkoutView()
        } else {
            VStack(spacing: 12) {
                // App icon with flame gradient
                ZStack {
                    Circle()
                        .fill(accentOrange.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentOrange, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Text("OneRep")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Strength")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(accentOrange)
                    }

                    Text("Start workout on iPhone")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
    }
}
#endif


import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var connectivityManager: LocalWatchConnectivityManager
    var state: LocalWatchWorkoutState { connectivityManager.workoutState }
    
    var body: some View {
        VStack {
            Text(state.exerciseName)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: CGFloat(state.timeRemaining) / CGFloat(max(state.phaseDuration, 1)))
                    .stroke(phaseColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: state.timeRemaining)
                    
                VStack {
                    Text("\(state.timeRemaining)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(state.phase)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(phaseColor)
                        .textCase(.uppercase)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    connectivityManager.sendCommand(state.isRunning ? .pause : .resume)
                }) {
                    Image(systemName: state.isRunning ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .frame(width: 24, height: 24)
                }
                .tint(state.isRunning ? .yellow : .green)
                .clipShape(Circle())
                
                Button(action: {
                    connectivityManager.sendCommand(.skip)
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .frame(width: 24, height: 24)
                }
                .tint(.gray)
                .clipShape(Circle())
            }
            .padding(.bottom, 4)
        }
    }
    
    var phaseColor: Color {
        switch state.phase {
        case "Eccentric": return .purple
        case "Concentric": return .orange
        case "Rest": return .blue
        case "Prep", "Positioning": return .yellow
        default: return .green
        }
    }
}

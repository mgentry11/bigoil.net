
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivityManager: LocalWatchConnectivityManager
    
    var body: some View {
        if connectivityManager.workoutState.isActive {
            WorkoutView()
        } else {
            VStack {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                    .padding(.bottom, 8)
                
                Text("OneRep")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Start workout on iPhone")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
    }
}

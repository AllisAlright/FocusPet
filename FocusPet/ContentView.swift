import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeSceneView()
    }
}

#Preview {
    ContentView()
        .environmentObject(FocusPetStore())
}

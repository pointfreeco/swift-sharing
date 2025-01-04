import Dependencies
import Sharing
import SwiftUI

struct ContentView: View {
  @SharedReader(.remoteConfig("showPromo")) var showPromo = false

  var body: some View {
    ZStack(alignment: .bottom) {
      Form {
        Image(systemName: "globe")
          .foregroundStyle(.tint)
        Text("Hello, world!")
      }
      if $showPromo.isLoading {
        ProgressView()
          .padding()
      } else if let loadError = $showPromo.loadError {
        Text(loadError.localizedDescription)
          .foregroundColor(.white)
          .padding()
          .background(Color.red)
          .cornerRadius(8)
      } else if showPromo {
        Text("Our promo has started!")
          .font(.title3)
          .foregroundColor(.white)
          .padding()
          .background(Color.blue)
          .cornerRadius(8)
      }
    }
  }
}

#Preview {
  ContentView()
}

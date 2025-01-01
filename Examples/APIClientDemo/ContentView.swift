import Sharing
import SwiftUI

struct ContentView: View {
  @Shared(.appStorage("count")) var count = 0
  @SharedReader(.fact(nil)) var fact

  var body: some View {
    Form {
      Section {
        Text("\(count)")
        Button("Increment") {
          $count.withLock { $0 += 1 }
        }
        Button("Decrement") {
          $count.withLock { $0 -= 1 }
        }
      }
    }
    .onChange(of: count) {
      $fact = SharedReader(.fact(nil))
    }
    .refreshable {
      do {
        $fact = try await SharedReader(require: .fact(count))
      } catch {}
    }
    VStack(spacing: 24) {
      if $fact.isLoading {
        ProgressView()
      } else if let loadError = $fact.loadError {
        Text(loadError.localizedDescription)
      } else if let fact {
        Text(fact)
      }
      Button("Get Fact") {
        $fact = SharedReader(.fact(count))
      }
    }
    .padding()
  }
}

#Preview {
  ContentView()
}

import IssueReporting
import Sharing
import SwiftUI

private let readMe = """
  This app demonstrates how one can use data from an external API service to power the state held \
  in a '@SharedReader' property. The 'fact` property represents a fact loaded from a server about \
  a number. The way you fetch a new fact is by assign '$fact' with a new '@SharedReader` instance \
  that provides the number.
  
  You can also invoke 'try await $fact.load()' explicitly to reload the fact for the current \
  number.
  """

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
    .task(id: count) {
      do {
        $fact = try await SharedReader(require: .fact(nil))
      } catch {
        reportIssue(error)
      }
    }
    .refreshable {
      do {
        $fact = try await SharedReader(require: .fact(count))
      } catch {
        reportIssue(error)
      }
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

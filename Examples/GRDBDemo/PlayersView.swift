import Dependencies
import Foundation
import GRDB
import Sharing
import SwiftUI

@MainActor
private let readMe: LocalizedStringKey = """
  This app demonstrates a simple way to persist data with GRDB. It introduces a new \
  `SharedReaderKey` conformance, `grdbQuery`, which queries a database for populating state. When \
  the database is updated the state will automatically be refreshed.

  A list of players is powered by `grdbQuery`. The demo also shows how to perform a dynamic \
  query on the players in the form of sorting the list by name or their injury status.
  """

struct PlayersView: View {
  @Dependency(\.defaultDatabase) private var database
  @SharedReader private var players: [Player]
  @Shared(.appStorage("order")) private var order = PlayerOrder.name
  @State private var addPlayerIsPresented = false
  @State private var aboutIsPresented = false

  init() {
    _players = SharedReader(.players(order: _order.wrappedValue))
  }

  var body: some View {
    NavigationStack {
      List {
        if !players.isEmpty {
          Section {
            ForEach(players, id: \.id) { player in
              HStack {
                Text(player.name)
                Spacer()
                if player.isInjured {
                  Image(systemName: "stethoscope")
                    .foregroundColor(.red)
                }
              }
            }
            .onDelete(perform: deleteItems)
          }
        }
      }
      .navigationTitle("Players")
      .toolbar {
        ToolbarItem {
          Picker("Sort", selection: Binding($order)) {
            Section {
              Text("Name").tag(PlayerOrder.name)
              Text("Is injured?").tag(PlayerOrder.isInjured)
            } header: {
              Text("Sort by:")
            }
          }
        }
        ToolbarItem {
          Button {
            addPlayerIsPresented = true
          } label: {
            Label("Add Item", systemImage: "plus")
          }
        }
        ToolbarItem(placement: .cancellationAction) {
          Button("About") {
            aboutIsPresented = true
          }
        }
      }
    }
    .onChange(of: order) {
      $players = SharedReader(.players(order: order))
    }
    .sheet(isPresented: $addPlayerIsPresented) {
      AddPlayerView()
        .presentationDetents([.medium])
    }
    .sheet(isPresented: $aboutIsPresented) {
      Form {
        Text(readMe)
      }
      .presentationDetents([.fraction(0.7)])
    }
  }

  private func deleteItems(offsets: IndexSet) {
    do {
      try database.write { db in
        _ = try Player.deleteAll(db, keys: offsets.map { players[$0].id })
      }
    } catch {
      reportIssue(error)
    }
  }
}

struct AddPlayerView: View {
  @Dependency(\.defaultDatabase) private var databaseQueue
  @Environment(\.dismiss) var dismiss
  @State var player = Player()

  var body: some View {
    NavigationStack {
      Form {
        TextField("Name", text: $player.name)
        Toggle("Is injured?", isOn: $player.isInjured)
      }
      .navigationTitle("Add player")
      .toolbar {
        Button("Save") {
          do {
            try databaseQueue.write { db in
              _ = try player.inserted(db)
            }
          } catch {
            reportIssue(error)
          }
          dismiss()
        }
      }
    }
  }
}

#Preview(
  traits: .dependency(\.defaultDatabase, .appDatabase)
) {
  @Dependency(\.defaultDatabase) var databaseQueue
  let _ = try! databaseQueue.write { db in
    for index in 0...9 {
      _ = try Player(name: "Blob \(index)", isInjured: index.isMultiple(of: 3))
        .inserted(db)
    }
  }
  PlayersView()
}

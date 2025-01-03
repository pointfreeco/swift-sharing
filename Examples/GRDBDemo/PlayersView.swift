import Dependencies
import Foundation
import GRDB
import Sharing
import SwiftUI

@MainActor
private let readMe: LocalizedStringKey = """
  This app demonstrates a simple way to persist data with GRDB. It introduces a new \
  `SharedReaderKey` conformance, `query`, which queries a database for populating state. When the \
  database is updated the state will automatically be refreshed.

  A list of players is powered by `query`. The demo also shows how to perform a dynamic query on \
  the players in the form of sorting the list by name or their injury status.
  """

@MainActor
@Observable
final class PlayersModel {
  @ObservationIgnored
  @Dependency(\.defaultDatabase) var database

  @ObservationIgnored
  @Shared(.appStorage("order")) var order: Players.Order = .name

  @ObservationIgnored
  @SharedReader var players: [Player]

  @ObservationIgnored
  @SharedReader(.fetchOne(sql: #"SELECT count(*) FROM "players" WHERE NOT "isInjured""#))
  var uninjuredCount = 0

  init() {
    _players = SharedReader(.fetch(Players(order: _order.wrappedValue), animation: .default))
  }

  func reload() async {
    do {
      let players = try await SharedReader(
        require: .fetch(Players(order: order), animation: .default)
      )
      withAnimation {
        $players = players
      }
    } catch {
      reportIssue(error)
    }
  }
}

struct PlayersView: View {
  @Dependency(\.defaultDatabase) var database
  @State private var aboutIsPresented = false
  @State private var addPlayerIsPresented = false
  let model: PlayersModel

  var body: some View {
    NavigationStack {
      List {
        if !model.players.isEmpty {
          Section {
            ForEach(model.players, id: \.id) { player in
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
          } header: {
            Text("^[\(model.uninjuredCount) player](inflect: true) are available")
          }
        }
      }
      .navigationTitle("Players")
      .toolbar {
        ToolbarItem {
          Picker("Sort", selection: Binding(model.$order)) {
            Section {
              Text("Name").tag(Players.Order.name)
              Text("Is injured?").tag(Players.Order.isInjured)
            } header: {
              Text("Sort by:")
            }
          }
        }
        ToolbarItem {
          Button {
            addPlayerIsPresented = true
          } label: {
            Label("Add Player", systemImage: "plus")
          }
        }
        ToolbarItem(placement: .cancellationAction) {
          Button("About") {
            aboutIsPresented = true
          }
        }
      }
    }
    .onChange(of: model.order) {
      Task {
        await
        model.reload()
      }
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
        _ = try Player.deleteAll(db, keys: offsets.map { model.players[$0].id })
      }
    } catch {
      reportIssue(error)
    }
  }
}

struct Players: QueryKeyRequest {
  enum Order: String { case name, isInjured }
  let order: Order
  init(order: Order = .name) {
    self.order = order
  }
  func fetch(_ db: Database) throws -> [Player] {
    let ordering: any SQLOrderingTerm =
      switch order {
      case .name:
        Column("name")
      case .isInjured:
        Column("isInjured").desc
      }
    return
      try Player
      .all()
      .order(ordering)
      .fetchAll(db)
  }
}

struct AddPlayerView: View {
  @Dependency(\.defaultDatabase) private var database
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
            try database.write { db in
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
  @Dependency(\.defaultDatabase) var database
  let _ = try! database.write { db in
    for index in 0...9 {
      _ = try Player(name: "Blob \(index)", isInjured: index.isMultiple(of: 3))
        .inserted(db)
    }
  }
  PlayersView(model: PlayersModel())
}

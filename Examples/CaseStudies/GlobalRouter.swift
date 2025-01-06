import Sharing
import SwiftUI

private enum Route: Codable, Hashable {
  case plainView
  case observableModel
  case viewController
}

private let readMe = """
  This demonstrates how one can hold onto the global routing information for an app in a \
  `@Shared` value so that any part of the app can read from and write to it. This allows views \
  _and_ `@Observable` models to make changes to the routes.

  Further, the routes are automatically persisted to disk so that the state of the app will \
  be restored when the app is relaunched.
  """

struct GlobalRouterView: SwiftUICaseStudy {
  let readMe = CaseStudies.readMe
  let caseStudyTitle = "Global Router"
  let isPresentedInSheet = true
  let usesOwnLayout = true

  @Shared(.path) private var path

  var body: some View {
    NavigationStack(path: Binding($path)) {
      RootView()
        .navigationDestination(for: Route.self) { route in
          switch route {
          case .plainView:
            PlainView()
          case .observableModel:
            ViewWithObesrvableModel()
          case .viewController:
            ViewController.Representable()
              .navigationTitle(Text("UIKit controller"))
          }
        }
        .navigationTitle(caseStudyTitle)
    }
  }
}

private struct RootView: View {
  @Shared(.path) var path

  var body: some View {
    Form {
      Text(template: readMe)

      Section {
        Button("Go to plain SwiftUI view") {
          $path.withLock { $0.append(.plainView) }
        }
        Button("Go to view with @Observable model") {
          $path.withLock { $0.append(.observableModel) }
        }
        Button("Go to UIViewController") {
          $path.withLock { $0.append(.viewController) }
        }
      }
    }
  }
}

private struct PlainView: View {
  @Shared(.path) var path

  var body: some View {
    Form {
      Text(
        template: """
          This screen holds onto `@Shared(.path)` directly in the view and can mutate it directly.
          """)
      Section {
        Button("Go to plain SwiftUI view") {
          $path.withLock { $0.append(.plainView) }
        }
        Button("Go to view with @Observable model") {
          $path.withLock { $0.append(.observableModel) }
        }
        Button("Go to UIViewController") {
          $path.withLock { $0.append(.viewController) }
        }
      }
    }
    .navigationTitle(Text("Plain SwiftUI view"))
  }
}

private struct ViewWithObesrvableModel: View {
  @Observable class Model {
    @ObservationIgnored @Shared(.path) var path
  }
  @State var model = Model()

  var body: some View {
    Form {
      Text(
        template: """
          This screen holds onto `@Shared(.path)` in an `@Observable` model. This shows that even
          models can mutate the global router directly.
          """)
      Section {
        Button("Go to plain SwiftUI view") {
          model.$path.withLock { $0.append(.plainView) }
        }
        Button("Go to view with @Observable model") {
          model.$path.withLock { $0.append(.observableModel) }
        }
        Button("Go to UIViewController") {
          model.$path.withLock { $0.append(.viewController) }
        }
      }
    }
    .navigationTitle(Text("@Observable model"))
  }
}

private class ViewController: UIViewController {
  @Shared(.path) var path

  override func viewDidLoad() {
    super.viewDidLoad()

    let label = UILabel()
    label.text = """
      This screen holds onto the @Shared(.path) in a UIKit view controller. This shows that even \
      UIKit can mutate the global router directly.
      """
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    let screenAButton = UIButton(type: .system)
    screenAButton.setTitle("Go to plain SwiftUI view", for: .normal)
    screenAButton.addAction(
      UIAction { [weak self] _ in
        self?.$path.withLock { $0.append(.plainView) }
      },
      for: .touchUpInside
    )
    let screenBButton = UIButton(type: .system)
    screenBButton.setTitle("Go to view with @Observable model", for: .normal)
    screenBButton.addAction(
      UIAction { [weak self] _ in
        self?.$path.withLock { $0.append(.plainView) }
      },
      for: .touchUpInside
    )
    let screenCButton = UIButton(type: .system)
    screenCButton.setTitle("Go to UIViewController", for: .normal)
    screenCButton.addAction(
      UIAction { [weak self] _ in
        self?.$path.withLock { $0.append(.plainView) }
      },
      for: .touchUpInside
    )
    let stackView = UIStackView(
      arrangedSubviews: [
        label,
        screenAButton,
        screenBButton,
        screenCButton,
      ]
    )
    stackView.axis = .vertical
    stackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
      stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  struct Representable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController { ViewController() }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
  }
}

extension SharedReaderKey where Self == FileStorageKey<[Route]>.Default {
  fileprivate static var path: Self {
    Self[
      .fileStorage(.documentsDirectory.appending(path: "path.json")),
      default: []
    ]
  }
}

#Preview {
  CaseStudyView {
    GlobalRouterView()
  }
}

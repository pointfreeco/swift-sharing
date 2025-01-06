import ConcurrencyExtras
import Sharing
import SwiftUI

struct NotificationsView: SwiftUICaseStudy {
  let readMe = """
    This application demonstrates how to use the `@SharedReader` tool to introduce a piece of \
    read-only state to your feature whose true value lives in an external system. In this case, \
    the state is the number of times a screenshot is taken, which is counted from the \
    `userDidTakeScreenshotNotification` notification, as well as the number of times the app has \
    been backgrounded, which is counted from the `willResignActiveNotification` notification.

    Run this application in the simulator, and take a few screenshots by going to \
    *Device › Trigger Screenshot* in the menu, and observe that the UI counts the number of times \
    that happens. And then background the app and re-open the app to see that the UI counts the \
    number of times you do that.
    """
  let caseStudyTitle = "Notifications"

  @SharedReader(.count(UIApplication.userDidTakeScreenshotNotification)) var screenshotCount = 0
  @SharedReader(.count(UIApplication.willResignActiveNotification)) var resignCount = 0

  var body: some View {
    Section {
      Text("Number of screenshots: \(screenshotCount)")
      Text("Number of times resigned active: \(resignCount)")
    }
  }
}

extension SharedReaderKey where Self == NotificationKey<Int> {
  static func count(_ name: Notification.Name) -> Self {
    Self(initialValue: 0, name: name) { value, _ in value += 1 }
  }
}

private struct NotificationKey<Value: Sendable>: SharedReaderKey {
  let name: Notification.Name
  let transform: @Sendable (Notification) -> Value

  init(
    initialValue: Value,
    name: Notification.Name,
    transform: @escaping @Sendable (inout Value, Notification) -> Void
  ) {
    self.name = name
    let value = LockIsolated(initialValue)
    self.transform = { notification in
      nonisolated(unsafe) let notification = notification
      return value.withValue {
        transform(&$0, notification)
        return $0
      }
    }
  }

  var id: some Hashable { name }

  func load(context _: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    continuation.resumeReturningInitialValue()
  }

  func subscribe(
    context: LoadContext<Value>, subscriber: SharedSubscriber<Value>
  ) -> SharedSubscription {
    nonisolated(unsafe) let token = NotificationCenter.default.addObserver(
      forName: name,
      object: nil,
      queue: nil
    ) { notification in
      subscriber.yield(transform(notification))
    }
    return SharedSubscription {
      NotificationCenter.default.removeObserver(token)
    }
  }
}

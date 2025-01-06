//
//  SharedStateInView 2.swift
//  Examples
//
//  Created by Brandon Williams on 11/26/24.
//

import Sharing
import SwiftUI

struct SwiftUIBindingFromSharedView: SwiftUICaseStudy {
  let caseStudyTitle = "SwiftUI bindings"
  let readMe = """
    Demonstrates how to derive a binding to a piece of shared state.

    Any piece of shared state can be turned into a SwiftUI `Binding` by using the special \
    `Binding.init(_:)` initializer.
    """

  @Shared(.appStorage("count")) var count = 0

  var body: some View {
    Section {
      Stepper("\(count)", value: Binding($count))
    } header: {
      Text("SwiftUI Binding")
    }
  }
}

#Preview {
  NavigationStack {
    CaseStudyView {
      SharedStateInView()
    }
  }
}

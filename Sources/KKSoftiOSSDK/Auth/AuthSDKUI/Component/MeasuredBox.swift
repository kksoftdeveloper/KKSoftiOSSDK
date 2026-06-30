//
//  File.swift
//  AuthSDK
//
//  Created by Admin on 4/27/25.
//

import Foundation
import SwiftUI

private struct HeightPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

struct MeasuredBox<Content: View>: View {
  @State private var contentHeight: CGFloat = 0
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    VStack {
      content
        .background(
          GeometryReader { geo in
            Color.clear
              .preference(key: HeightPreferenceKey.self, value: geo.size.height)
          }
        )
//      // now you have contentHeight available:
//      Text("Height is \(Int(contentHeight))pt")
//        .font(.caption)
//        .foregroundColor(.secondary)
    }
    .onPreferenceChange(HeightPreferenceKey.self) {
      self.contentHeight = $0
    }
  }
}

// Usage:
//MeasuredBox {
//  Text("This box reports its own height")
//}

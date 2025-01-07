import SwiftUI
import ComposableArchitecture

@main
struct photo_copyApp: App {
  static let store = Store(
      initialState: PhotoCopyFeature.State()
  ) {
      PhotoCopyFeature()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView(store: Self.store)
    }
  }
}


import SwiftUI
import ComposableArchitecture

@main
struct photo_copyApp: App {
  @State var store = Store(initialState: AppFeature.State()) {
    AppFeature()._printChanges()
  }
  
  var body: some Scene {
    Window("Rex Photo Selector", id: "mainWindow") {
      ContentView(store: self.store)
    }
    .windowResizability(.contentSize)
  }
}


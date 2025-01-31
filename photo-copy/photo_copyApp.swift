import SwiftUI
import ComposableArchitecture

@main
struct photo_copyApp: App {
  @State var store = Store(initialState: AppFeature.State()) {
    AppFeature()._printChanges()
  }
  
  var body: some Scene {
    Window("Rex Photo Selector", id: "mainWindow") {
//      ContentView(store: self.store)
//        .onOpenURL { url in
//          self.store.send(.folder(.didPressChooseBase(url)))
//        }
      SideBarMenuView()
    }
    .windowResizability(.contentSize)
  }
}


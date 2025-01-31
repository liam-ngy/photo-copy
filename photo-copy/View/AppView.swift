import SwiftUI
import ComposableArchitecture

enum Page {
  case home
  //  case settings
}

struct AppView : View {
  @State private var selectedSection: Page = .home
  
  @State var store = Store(initialState: AppFeature.State()) {
    AppFeature()._printChanges()
  }
  
  var body: some View {
    WithPerceptionTracking {
      
      NavigationSplitView {
        List(selection: $selectedSection) {
          Section(header: Text("General")) {
            
            NavigationLink(value: Page.home) {
              Label("Home", systemImage: "house")
            }
            
            
            //          NavigationLink(value: Page.settings) {
            //            Label("Settings", systemImage: "gear")
            //          }
          }
          
          
          Section(header: Text("Customers")) {
            ForEach(store.customerState.existingCustomers) { customer in
              CustomerRow(customer: customer)
            }
          }
        }
      } detail: {
        switch selectedSection {
        case .home:
          HomeView(store: self.store)
            .onOpenURL { url in
              self.store.send(.folder(.didPressChooseBase(url)))
            }
        }
      }
      .navigationTitle("Rex Photo tools")
      .background(.ultraThinMaterial)
      .listStyle(.sidebar)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          // NOTE: Action for creating a new customer
          Button(action: {}) {
            Image(systemName: "plus")
          }
        }
      }
    }
  }
}

//#Preview {
//  AppView()
//}


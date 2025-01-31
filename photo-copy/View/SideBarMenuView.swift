import SwiftUI

enum Page {
  case home
  case settings
  case customer
}

struct SideBarMenuView : View {
  @State var searchableText: String = ""
  @State private var selectedSection: Page = .home
  
  var body: some View {
    NavigationSplitView {
      List(selection: $selectedSection) {
        Section(header: Text("General")) {
          
          NavigationLink(value: Page.home) {
            Label("Home", systemImage: "house")
          }
          
          NavigationLink(value: Page.settings) {
            Label("Settings", systemImage: "gear")
          }
        }
        
        
        Section(header: Text("Customers")) {
          NavigationLink(value: Page.customer) {
            CustomerRow()
          }
        }
      }
    } detail: {
      switch selectedSection {
      case .home:
        HomeView()
      case .settings:
        SettingsView()
      case .customer:
        CustomerDetailView()
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

#Preview {
  SideBarMenuView()
}


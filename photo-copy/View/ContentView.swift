import SwiftUI
import ComposableArchitecture

struct HomeView: View {
  let store: StoreOf<AppFeature>
  
  @State private var showingBasePicker = false
  @FocusState private var isCustomerInputFocused: Bool
  @FocusState private var isPhotoInputFocused: Bool
  @State private var isDrop: Bool = false
  
  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading) {
        BaseFolderView(
          store: store.scope(state: \.folderState, action: \.folder),
          showingSourcePicker: $showingBasePicker
        )
        .padding(.bottom)
        
        CustomerSelectionView(store: store.scope(state: \.customerState, action: \.customer))
          .padding(.bottom)
        
        PhotoSelectionView(store: store.scope(state: \.photoState, action: \.photo))
          .padding(.bottom)
        
        ResultDisplayView(store: store)
          .transition(.slide)
        Spacer()
      }
      .padding()
      .onChange(of: store.customerState.customerFolder) { _ in
        if store.customerState.customerFolder == nil {
          isCustomerInputFocused = true
        }
      }
    }
  }
}


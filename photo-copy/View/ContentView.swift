import SwiftUI
import ComposableArchitecture

struct ContentView: View {
  let store: StoreOf<AppFeature>
  
  @State private var showingBasePicker = false
  @FocusState private var isCustomerInputFocused: Bool
  @FocusState private var isPhotoInputFocused: Bool
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Rex Photo Selector")
        .font(.largeTitle)
        .fontWeight(.bold)
        .padding(.top)
        .padding(.bottom)
      
      BaseFolderView(
        store: store.scope(state: \.folderState, action: \.folder),
        showingSourcePicker: $showingBasePicker
      )
      
      CustomerSelectionView(store: store.scope(state: \.customerState, action: \.customer))
      PhotoSelectionView(store: store.scope(state: \.photoState, action: \.photo))
      
      if store.folderState.hasFolderErrorMessages || store.photoState.copyResponse.isCompleted {
        ResultDisplayView(store: store)
          .transition(.slide)
      }
      Spacer()
    }
    .padding()
    .frame(minWidth: 400, minHeight: 500)
    .onChange(of: store.customerState.customerFolder) { _ in
      if store.customerState.customerFolder == nil {
        isCustomerInputFocused = true
      }
    }
  }
}

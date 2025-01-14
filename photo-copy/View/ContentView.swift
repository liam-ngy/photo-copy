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
      PhotoSelectionView(store: store)
      
      if store.hasFolderErrorMessages || isCopyOperationCompleted(store.copyState) {
        ResultDisplayView(store: store)
          .transition(.slide)
      }
      Spacer()
    }
    .padding()
    .frame(minWidth: 400, minHeight: 500)
    .onChange(of: store.destinationFolder) { _ in
      if store.destinationFolder == nil {
        isCustomerInputFocused = true
      }
    }
  }
  // TODO: Move it to feature
  private func isCopyOperationCompleted(_ copyState: AppFeature.State.CopyState) -> Bool {
    switch copyState {
    case .completed(_):
      return true
    default:
      return false
    }
  }
}

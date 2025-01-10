import SwiftUI
import ComposableArchitecture

struct ContentView: View {
  let store: StoreOf<PhotoCopyFeature>
  
  @State private var showingBasePicker = false
  @FocusState private var isCustomerInputFocused: Bool
  @FocusState private var isPhotoInputFocused: Bool
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(alignment: .leading) {
        Text("Rex Photo Selector")
          .font(.largeTitle)
          .fontWeight(.bold)
          .padding(.top)
          .padding(.bottom)
        
        BaseFolderView(store: store, showingSourcePicker: $showingBasePicker)
        CustomerSelectionView(store: store)
        PhotoSelectionView(store: store)
        
        if viewStore.hasFolderErrorMessages || isCopyOperationCompleted(viewStore.copyState) {
          ResultDisplayView(store: store)
            .transition(.slide)
           }
        Spacer()
      }
      .padding()
      .frame(minWidth: 400, minHeight: 500)
      .onChange(of: viewStore.destinationFolder) { _ in
        if viewStore.destinationFolder == nil {
          isCustomerInputFocused = true
        }
      }
    }
  }
  // TODO: Move it to feature
  private func isCopyOperationCompleted(_ copyState: PhotoCopyFeature.State.CopyState) -> Bool {
      switch copyState {
      case .completed(_):
          return true
      default:
          return false
      }
  }
}

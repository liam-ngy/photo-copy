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
        ResultDisplayView(store: store)
        
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
}

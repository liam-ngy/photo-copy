import SwiftUI
import ComposableArchitecture

struct PhotoSelectionView: View {
  let store: StoreOf<PhotoCopyFeature>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      if viewStore.canProceedToPhotos {
        GroupBox(label: Text("Photos").font(.headline)) {
          TextField("Enter photo range or single photos (e.g. 1, 1-10)",
                    text: viewStore.binding(
                      get: \.photoInput,
                      send: { .updatePhotoInput($0) }
                    )
          )
          .textFieldStyle(.roundedBorder)
          .onSubmit {
            viewStore.send(.copyPhotos)
          }
          
          Button(action: {
            viewStore.send(.copyPhotos)
          }) {
            Text(viewStore.copyState.isCopying ? "Copying..." : "Copy Photos")
              .frame(maxWidth: .infinity)
              .padding()
              .foregroundColor(.white)
              .background(viewStore.copyState.isCopying ? Color.gray : Color.blue)
              .cornerRadius(8)
          }
          .disabled(viewStore.copyState.isCopying)
          .padding(.top)
        }
      }
    }
  }
}

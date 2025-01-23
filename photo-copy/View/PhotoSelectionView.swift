import SwiftUI
import ComposableArchitecture

struct PhotoSelectionView: View {
  @Perception.Bindable var store: StoreOf<PhotoFeature>
  
  var body: some View {
    WithPerceptionTracking {
      GroupBox(label: Text("Photos").font(.headline)) {
        Group {
          HStack {
            TextField(
              "Enter photo range or single photos (e.g. 1, 1-10)",
              text: $store.photoInput.sending(\.photoInputChanged)
            )
            .textFieldStyle(.roundedBorder)
            .onSubmit {
              store.send(.didTapCopy)
            }
            Button(action: {
              store.send(.didTapCopy)
            }) {
              Text(store.copyResponse.isCopying ? "Copying..." : "Copy Photos")
            }
            .disabled(!store.canCopyPhotos)
          }
          .padding()
        }
        
      }
    }
  }
}

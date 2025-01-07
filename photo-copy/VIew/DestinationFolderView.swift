import SwiftUI
import ComposableArchitecture

struct DestinationFolderView: View {
  let store: StoreOf<PhotoCopyFeature>
  @Binding var showingDestinationPicker: Bool
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      GroupBox(label: Text("Base Destination").font(.headline)) {
        HStack {
          Button("Choose...") {
            showingDestinationPicker.toggle()
          }
          .keyboardShortcut("d", modifiers: .command)
          .fileImporter(
            isPresented: $showingDestinationPicker,
            allowedContentTypes: [.folder],
            onCompletion: { result in
              if case .success(let url) = result {
                viewStore.send(.setBaseDestinationFolder(url))
              }
            }
          )
          
          if let destinationPath = viewStore.baseDestinationFolder?.path {
            Text(destinationPath)
              .lineLimit(1)
              .truncationMode(.middle)
          }
        }
      }
    }
  }
}

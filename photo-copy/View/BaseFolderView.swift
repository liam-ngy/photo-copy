import SwiftUI
import ComposableArchitecture

struct BaseFolderView: View {
  let store: StoreOf<PhotoCopyFeature>
  @Binding var showingSourcePicker: Bool
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      GroupBox(label: Text("Base Folder").font(.headline)) {
        HStack {
          Button("Choose...") {
            showingSourcePicker.toggle()
          }
          .keyboardShortcut("o", modifiers: .command)
          .fileImporter(
            isPresented: $showingSourcePicker,
            allowedContentTypes: [.folder],
            onCompletion: { result in
              if case .success(let url) = result {
                viewStore.send(.setBaseFolder(url))
              }
            }
          )
          
          if let sourcePath = viewStore.baseFolder?.path {
            Text(sourcePath)
              .lineLimit(1)
              .truncationMode(.middle)
          }
        }
      }
    }
  }
}

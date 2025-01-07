import SwiftUI
import ComposableArchitecture

struct SourceFolderView: View {
  let store: StoreOf<PhotoCopyFeature>
  @Binding var showingSourcePicker: Bool
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      GroupBox(label: Text("Source Folder (Photos)").font(.headline)) {
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
                viewStore.send(.setFinalsFolder(url))
              }
            }
          )
          
          if let sourcePath = viewStore.finalsFolder?.path {
            Text(sourcePath)
              .lineLimit(1)
              .truncationMode(.middle)
          }
        }
      }
    }
  }
}

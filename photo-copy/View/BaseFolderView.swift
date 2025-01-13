import SwiftUI
import ComposableArchitecture

struct BaseFolderView: View {
  let store: StoreOf<FolderFeature>
  @Binding var showingSourcePicker: Bool
  
  var body: some View {
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
              store.send(.didPressChooseBase(url))
            }
          }
        )
        
        if let sourcePath = store.baseFolder?.path {
          Text(sourcePath)
            .lineLimit(1)
            .truncationMode(.middle)
        }
      }
    }
  }
}

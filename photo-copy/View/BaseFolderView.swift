import SwiftUI
import ComposableArchitecture

struct BaseFolderView: View {
  @Perception.Bindable var store: StoreOf<FolderFeature>
  @Binding var showingSourcePicker: Bool
  @State private var isDrop: Bool = false
  
  var body: some View {
    WithPerceptionTracking {
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
          
          Spacer()
          
          Text(store.baseFolder?.lastPathComponent ?? "No base folder selected")
            .foregroundColor(.gray)
            .padding(.leading)
        }
        .frame(maxWidth: .infinity)
        .padding()
      }
      .onDrop(of: [.folder], isTargeted: $store.isDroppingFolder.sending(\.updateIsDrop)) { providers in
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.folder") { urlData, _ in
          guard let url = urlData as? URL else { return }
          
          // NOTE: We need to make sure that this is run on the main thread otherwise it will crash.
          Task { @MainActor in
              store.send(.didDropFolder(url))
          }
        }
          
        return true
      }
    }
  }
}

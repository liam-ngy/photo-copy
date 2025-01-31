import ComposableArchitecture
import SwiftUI

struct ResultDisplayView: View {
  @Perception.Bindable var store: StoreOf<AppFeature>
  @Shared(.inMemory("customerFolder"))
  var customerFolder: URL? = nil

  var body: some View {
    WithPerceptionTracking {
      ScrollView(.vertical, showsIndicators: true) {
        VStack(alignment: .leading, spacing: 16) {
          // MARK: Folder Error
          if store.folderState.hasFolderErrorMessages {
            GroupBox(label: Text("Errors").font(.headline)) {
              VStack(alignment: .leading, spacing: 8) {
                ForEach(store.folderState.folderErrorMessages, id: \.self) { errorMessage in
                  HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle.fill")
                      .foregroundColor(.red)
                      .padding(.top, 2)
                    Text(errorMessage)
                      .foregroundColor(.red)
                      .multilineTextAlignment(.leading)
                  }
                }
              }
              .padding()
            }
          }
          
          // MARK: - Photocopy Result
          if case let .completed(result) = store.photoState.copyResponse {
            GroupBox(label: Text("Operation Result").font(.headline)) {
              VStack(alignment: .leading, spacing: 12) {
                switch result {
                case .success(let files):
                  HStack {
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(.green)
                    Text("Successfully copied \(files.count) files:")
                      .fontWeight(.medium)
                  }
                  
                  FileGridView(files: files)
                  
                case .partialSuccess(let copied, let missing):
                  HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                      .foregroundColor(.yellow)
                    Text("Partially completed:")
                      .fontWeight(.medium)
                  }
                  
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Copied Files (\(copied.count)):")
                      .font(.subheadline)
                      .foregroundColor(.secondary)
                    FileGridView(files: copied)
                  }
                  
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Missing Files (\(missing.count)):")
                      .font(.subheadline)
                      .foregroundColor(.red)
                    FileGridView(
                      files: missing,
                      iconName: "photo.badge.exclamationmark",
                      iconColor: .red,
                      textColor: .red
                    )
                  }
                  
                case .failure(let error):
                  HStack {
                    Image(systemName: "xmark.circle.fill")
                      .foregroundColor(.red)
                    Text("Error:")
                      .fontWeight(.medium)
                      .foregroundColor(.red)
                  }
                  Text(error.description)
                    .foregroundColor(.red)
                    .padding(.leading)
                }
              }
              .padding()
            }
          }
        }
        .padding()
      }
    }
  }
}

#Preview {
  ResultDisplayView(store: Store(initialState: AppFeature.State(), reducer: {
    AppFeature()._printChanges()
  }), customerFolder: nil)
}


import SwiftUI
import ComposableArchitecture

struct ResultDisplayView: View {
  let store: StoreOf<PhotoCopyFeature>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      // MARK: Flder Error
      if viewStore.hasFolderErrorMessages {
          GroupBox(label: Text("Errors").font(.headline)) {
              VStack(alignment: .leading, spacing: 8) {
                  ForEach(viewStore.folderErrorMessages, id: \.self) { errorMessage in
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
          .frame(maxHeight: 200) // Adjust as needed
      }
      
      // MARK: - Photocopy Result
      
      if case let .completed(result) = viewStore.copyState {
        GroupBox(label: Text("Operation Result").font(.headline)) {
          HStack {
            VStack(alignment: .leading, spacing: 12) {
              switch result {
              case .success(let files):
                HStack {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                  Text("Successfully copied \(files.count) files:")
                    .fontWeight(.medium)
                }
                
                ForEach(files, id: \.self) { file in
                  HStack {
                    Image(systemName: "photo")
                      .foregroundColor(.blue)
                    Text(file)
                      .font(.system(.body, design: .monospaced))
                  }
                }
                
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
                  HStack {
                    ForEach(copied, id: \.self) { file in
                      HStack {
                        Image(systemName: "photo")
                          .foregroundColor(.blue)
                        Text(file)
                          .font(.system(.body, design: .monospaced))
                      }
                    }
                  }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                  Text("Missing Files (\(missing.count)):")
                    .font(.subheadline)
                    .foregroundColor(.red)
                  ForEach(missing, id: \.self) { file in
                    HStack {
                      Image(systemName: "photo.badge.exclamationmark")
                        .foregroundColor(.red)
                      Text(file)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.red)
                    }
                  }
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
          }
        }
        .frame(maxHeight: 300)  // Adjust height as needed
      }
    }
  }
}

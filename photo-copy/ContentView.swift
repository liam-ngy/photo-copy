import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel = FileCopyViewModel()
  
  @State private var showingSourcePicker = false
  @State private var showingDestinationPicker = false
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Photo Copier")
        .font(.largeTitle)
        .fontWeight(.bold)
        .padding(.top)
        .padding(.bottom)
      
      GroupBox(label: Text("Source Folder (Photos)").font(.headline)) {
        HStack {
          Button("Choose...") {
            showingSourcePicker.toggle()
          }
          .fileImporter(isPresented: $showingSourcePicker, allowedContentTypes: [.folder], onCompletion: { result in
            switch result {
            case .success(let url):
              viewModel.sourceFolder = url
            case .failure(_):
              break
            }
          })
          Spacer()
          Text(viewModel.sourceFolder?.path ?? "No source selected")
            .foregroundColor(.gray)
            .padding(.leading)
        }
        .padding()
      }
      .padding(.vertical, 5)
      
      GroupBox(label: Text("Destination Folder").font(.headline)) {
        HStack {
          Button("Choose...") {
            showingDestinationPicker.toggle()
          }
          .fileImporter(isPresented: $showingDestinationPicker, allowedContentTypes: [.folder], onCompletion: { result in
            switch result {
            case .success(let url):
              viewModel.destinationFolder = url
            case .failure(_):
              break
            }
          })
          Spacer()
          Text(viewModel.destinationFolder?.path ?? "No destination selected")
            .foregroundColor(.gray)
            .padding(.leading)
        }
        .padding()
      }
      .padding(.vertical, 5)
      
      GroupBox(label: Text("Photos").font(.headline)) {
        TextField("Enter photo range or single photos (e.g. 1, 1-10)", text: $viewModel.photoInput)
          .textFieldStyle(.roundedBorder)
          .frame(height: 40)
          .padding()
          .onSubmit {
            viewModel.copyPhotos()
          }
      }
      .padding(.vertical, 5)
      
      if let result = viewModel.result {
          Text(result.description)
              .foregroundColor(resultColor(for: result))
              .padding()
      }
      
      // Copy Photos Button
      Button(action: {
        viewModel.copyPhotos()
      }) {
        Text(viewModel.isBusy ? "Copying..." : "Copy Photos")
          .padding()
          .foregroundColor(.white)
          .disabled(viewModel.isBusy)
      }
      .background(viewModel.isBusy ? Color.gray : Color.blue)
      .padding(.top)
      .cornerRadius(8)
    }
    .padding()
  }
  
  private func resultColor(for result: FileCopyService.FileCopyResult) -> Color {
      switch result {
      case .success:
          return .green
      case .failure:
          return .red
      case .partialSuccess(copiedFiles: _, missingFiles: _):
        return .green
      }
  }
}

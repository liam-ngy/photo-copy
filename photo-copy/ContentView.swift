import SwiftUI

struct ContentView: View {
    @State private var sourceFolder: URL?
    @State private var destinationFolder: URL?
    @State private var photoInput: String = ""
    @State private var isBusy: Bool = false

    @State private var showingSourcePicker = false
    @State private var showingDestinationPicker = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Photo Copier")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
                .padding(.bottom)

            GroupBox(label: Text("Source Folder").font(.headline)) {
                HStack {
                    Button("Choose...") {
                        showingSourcePicker.toggle()
                    }
                    .fileImporter(isPresented: $showingSourcePicker, allowedContentTypes: [.folder], onCompletion: { result in
                        switch result {
                        case .success(let url):
                            sourceFolder = url
                        case .failure(_):
                            break
                        }
                    })
                    Spacer()
                    Text(sourceFolder?.path ?? "No source selected")
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
                            destinationFolder = url
                        case .failure(_):
                            break
                        }
                    })
                    Spacer()
                    Text(destinationFolder?.path ?? "No destination selected")
                        .foregroundColor(.gray)
                        .padding(.leading)
                }
                .padding()
            }
            .padding(.vertical, 5)

            GroupBox(label: Text("Photos").font(.headline)) {
                TextField("Enter photo range or single photos (e.g., rex-1, rex-1-rex-10)", text: $photoInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 40) // Increased height for larger text field
                    .padding()
            }
            .padding(.vertical, 5)

            // Copy Photos Button
            Button(action: {
                // Trigger photo copying logic here
                isBusy.toggle()
            }) {
                Text(isBusy ? "Copying..." : "Copy Photos")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isBusy ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isBusy)
            .padding(.top)
        }
        .padding()
        .frame(width: 500, height: 350) // Increased window frame size
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 500, height: 350) // Increased preview window size
    }
}

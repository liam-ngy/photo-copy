import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel = FileCopyViewModel()
  
  @State private var showingSourcePicker = false
  @State private var showingDestinationPicker = false
  @FocusState private var isCustomerInputFocused: Bool
  @FocusState private var isPhotoInputFocused: Bool
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Rex Photo Selector")
        .font(.largeTitle)
        .fontWeight(.bold)
        .padding(.top)
        .padding(.bottom)
      
      GroupBox(label: Text("Source Folder (Photos)").font(.headline)) {
        HStack {
          Button("Choose...") {
            showingSourcePicker.toggle()
          }
          .keyboardShortcut("o", modifiers: .command)
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
      .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60)
      .padding(.vertical, 5)
      
      GroupBox(label: Text("Destination Folder").font(.headline)) {
        VStack {
          // Base Destination Folder
          HStack {
            Button("Choose Pax Folder") {
              showingDestinationPicker.toggle()
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
            .fileImporter(
              isPresented: $showingDestinationPicker,
              allowedContentTypes: [.folder],
              onCompletion: { result in
                switch result {
                case .success(let url):
                  viewModel.baseDestinationFolder = url
                case .failure(_):
                  break
                }
              }
            )
            Spacer()
            Text(viewModel.baseDestinationFolder?.path ?? "No base folder selected")
              .foregroundColor(.gray)
              .padding(.leading)
          }
          .padding(.bottom, 5)
          
          if let _ = viewModel.baseDestinationFolder {
            // Always show the Menu and New Customer button
            HStack {
              Menu(viewModel.destinationFolder != nil ? "Selected: \(viewModel.customerInput)" : "Select Customer") {
                ForEach(viewModel.getExistingCustomers(), id: \.self) { customer in
                  Button(customer) {
                    viewModel.selectExistingCustomer(customer)
                  }
                }
              }
              
              if viewModel.destinationFolder != nil {
                Button("New Customer") {
                  viewModel.clearCustomer()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                
              }
            }
            .padding(.vertical, 5)
            
            // Show input field when no customer is selected
            if viewModel.destinationFolder == nil {
              HStack {
                TextField("Enter customer (e.g., 69 Liam)", text: $viewModel.customerInput)
                  .textFieldStyle(.roundedBorder)
                  .frame(maxWidth: 300)
                  .focused($isCustomerInputFocused)
                  .onSubmit {
                    if !viewModel.customerInput.isEmpty && viewModel.baseDestinationFolder != nil {
                      viewModel.createCustomerDirectory()
                    }
                  }
                
                Button("Create") {
                  viewModel.createCustomerDirectory()
                }
                .disabled(viewModel.customerInput.isEmpty || viewModel.baseDestinationFolder == nil)
              }
              
              Text("Create a customer directory to continue")
                .foregroundColor(.orange)
                .padding(.top, 5)
            }
          }
        }
        .padding()
      }
      .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60)
      .padding(.vertical, 5)
      
      GroupBox(label: Text("Photos").font(.headline)) {
        TextField("Enter photo range or single photos (e.g. 1, 1-10)", text: $viewModel.photoInput)
          .textFieldStyle(.roundedBorder)
          .frame(height: 40)
          .focused($isPhotoInputFocused)
          .padding()
          .onSubmit {
            viewModel.copyPhotos()
          }
      }
      .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60)
      .padding(.vertical, 5)
      
      if let result = viewModel.result, !viewModel.isBusy {
        Text(result.description)
          .foregroundColor(result.color)
          .padding()
          .frame(minHeight: 50)
      }
      
      Button(action: {
        viewModel.copyPhotos()
      }) {
        Text(viewModel.isBusy ? "Copying..." : "Copy Photos")
          .frame(maxWidth: .infinity)
          .padding()
          .foregroundColor(.white)
          .background(viewModel.isBusy ? Color.gray : Color.blue)
          .cornerRadius(8)
      }
      .disabled(viewModel.isBusy)
      .padding(.top)
    }
    .padding()
    .frame(minWidth: 400, minHeight: 500)
    .onChange(of: viewModel.destinationFolder) { newValue in
      if newValue == nil {
        isCustomerInputFocused = true
      } else {
        // Focus photo input when a customer is successfully selected/created
        isPhotoInputFocused = true
      }
    }
  }
}

extension FileCopyService.FileCopyResult {
  var color: Color {
    switch self {
    case .success:
        return .green
    case .failure:
        return .red
    case .partialSuccess(copiedFiles: _, missingFiles: _):
      return .green
    }
  }
}

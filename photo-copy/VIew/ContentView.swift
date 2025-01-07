import SwiftUI
import ComposableArchitecture

struct ContentView: View {
  @StateObject private var viewModel = FileCopyViewModel()
  
  let store: StoreOf<PhotoCopyFeature>
  
  @State private var showingSourcePicker = false
  @State private var showingDestinationPicker = false
  @FocusState private var isCustomerInputFocused: Bool
  @FocusState private var isPhotoInputFocused: Bool
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
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
                viewStore.send(.setSourceFolder(url))
              case .failure(_):
                viewStore.send(.sourceSelectionCancelled)
              }
            })
            Spacer()
            Text(viewStore.sourceFolder?.path ?? "No source selected")
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
                    viewStore.send(.setBaseDestinationFolder(url))
                  case .failure(_):
                    viewStore.send(.destinationSelectionCancelled)
                  }
                }
              )
              Spacer()
              Text(viewStore.baseDestinationFolder?.path ?? "No base folder selected")
                .foregroundColor(.gray)
                .padding(.leading)
            }
            .padding(.bottom, 5)
            
            if let _ = viewModel.baseDestinationFolder {
              // Always show the Menu and New Customer button
              HStack {
                Menu(viewStore.isCustomerDirectoryCreated ? "Selected: \(viewStore.customerInput)" : "Select Customer") {
                  ForEach(viewModel.getExistingCustomers(), id: \.self) { customer in
                    Button(customer) {
                      Task {
                        _ = await viewModel.selectExistingCustomer(customer)
                      }
                    }
                  }
                }
                
                // Always show New Customer button when a customer is selected
                if viewStore.isCustomerDirectoryCreated {
                  Button("New Customer") {
                    viewStore.send(.clearCustomer)
                  }
                  .keyboardShortcut("n", modifiers: [.command, .shift])
                }
              }
              .padding(.vertical, 5)
              
              // Show input field when no customer is selected
              if viewStore.shouldShowCustomerInput {
                HStack {
                  TextField(
                    "Enter customer (e.g., 69 Liam)",
                    text: viewStore.binding(get: \.customerInput, send: { .updateCustomerInput($0) })
                  )
                  .textFieldStyle(.roundedBorder)
                  .frame(maxWidth: 300)
                  .focused($isCustomerInputFocused)
                  .onSubmit {
                    if viewStore.canCreateCustomerDirectory {
                      viewStore.send(.createCustomerDirectory)
                    }
                  }
                  
                  Button("Create") {
                    viewStore.send(.createCustomerDirectory)
                  }
                  .disabled(!viewStore.canCreateCustomerDirectory)
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
        
        if viewStore.canProceedToPhotos {
          GroupBox(label: Text("Photos").font(.headline)) {
            TextField("Enter photo range or single photos (e.g. 1, 1-10)", text: $viewModel.photoInput)
              .textFieldStyle(.roundedBorder)
              .frame(height: 40)
              .padding()
              .focused($isPhotoInputFocused)
              .onSubmit {
                Task {
                  _ = await viewModel.copyPhotos()
                }
              }
          }
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60)
          .padding(.vertical, 5)
          
        }
        
        if !viewStore.lastOperationMessage.isEmpty {
          Text(viewStore.lastOperationMessage)
                .foregroundColor(.green)
                .padding()
                .frame(minHeight: 50)
        }

        if let result = viewModel.result, !viewModel.isBusy {
            Text(result.description)
                .foregroundColor(result.color)
                .padding()
                .frame(minHeight: 50)
        }
        
        if let result = viewModel.result, !viewModel.isBusy {
          Text(result.description)
            .foregroundColor(result.color)
            .padding()
            .frame(minHeight: 50)
        }
        
        Button(action: {
          Task {
            _ = await viewModel.copyPhotos()
          }
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
      .onChange(of: viewModel.destinationFolder) { _ in
        if viewModel.destinationFolder == nil {
          isCustomerInputFocused = true
        }
      }
      .onChange(of: viewModel.shouldFocusPhotoInput) { shouldFocus in
        isPhotoInputFocused = shouldFocus
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

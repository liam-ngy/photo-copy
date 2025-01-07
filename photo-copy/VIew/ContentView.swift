import SwiftUI
import ComposableArchitecture

struct ContentView: View {
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
        
        // Source Folder Selection
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
                  viewStore.send(.setSourceFolder(url))
                }
              }
            )
            
            if let sourcePath = viewStore.sourceFolder?.path {
              Text(sourcePath)
                .lineLimit(1)
                .truncationMode(.middle)
            }
          }
        }
        
        // Base Destination Selection
        GroupBox(label: Text("Base Destination").font(.headline)) {
          HStack {
            Button("Choose...") {
              showingDestinationPicker.toggle()
            }
            .keyboardShortcut("d", modifiers: .command)
            .fileImporter(
              isPresented: $showingDestinationPicker,
              allowedContentTypes: [.folder],
              onCompletion: { result in
                if case .success(let url) = result {
                  viewStore.send(.setBaseDestinationFolder(url))
                }
              }
            )
            
            if let destinationPath = viewStore.baseDestinationFolder?.path {
              Text(destinationPath)
                .lineLimit(1)
                .truncationMode(.middle)
            }
          }
        }
        
        // Customer Selection and Creation
        if let _ = viewStore.baseDestinationFolder {
          GroupBox(label: Text("Customer").font(.headline)) {
            if viewStore.isCustomerDirectoryCreated {
              // Show selected customer and New Customer button
              HStack {
                Text("Selected: \(viewStore.customerInput)")
                  .fontWeight(.medium)
                
                Button("New Customer") {
                  viewStore.send(.clearCustomer)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
              }
            } else {
              // Show customer selection and creation
              VStack(alignment: .leading, spacing: 10) {
                Menu("Select Existing Customer") {
                  ForEach(viewStore.existingCustomers, id: \.self) { customer in
                    Button(customer) {
                      viewStore.send(.selectExistingCustomer(customer))
                    }
                  }
                }
                .onAppear {
                  viewStore.send(.loadExistingCustomers)
                }
                
                HStack {
                  TextField("Enter customer name",
                            text: viewStore.binding(
                              get: \.customerInput,
                              send: { .updateCustomerInput($0) }
                            )
                  )
                  .textFieldStyle(.roundedBorder)
                  .focused($isCustomerInputFocused)
                  
                  Button("Create") {
                    viewStore.send(.createCustomerDirectory)
                  }
                  .disabled(!viewStore.canCreateCustomerDirectory)
                }
              }
            }
          }
        }
        
        // Photo Selection and Copy
        if viewStore.canProceedToPhotos {
          GroupBox(label: Text("Photos").font(.headline)) {
            TextField("Enter photo range or single photos (e.g. 1, 1-10)",
                      text: viewStore.binding(
                        get: \.photoInput,
                        send: { .updatePhotoInput($0) }
                      )
            )
            .textFieldStyle(.roundedBorder)
            .focused($isPhotoInputFocused)
            .onSubmit {
              viewStore.send(.copyPhotos)
            }
            
            Button(action: {
              viewStore.send(.copyPhotos)
            }) {
              Text(viewStore.copyState.isCopying ? "Copying..." : "Copy Photos")
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(viewStore.copyState.isCopying ? Color.gray : Color.blue)
                .cornerRadius(8)
            }
            .disabled(viewStore.copyState.isCopying)
            .padding(.top)
            
            // Result Display
            if case let .completed(result) = viewStore.copyState {
              GroupBox(label: Text("Operation Result").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                  switch result {
                  case .success(let files):
                    Text("✅ Successfully copied \(files.count) files:")
                      .fontWeight(.medium)
                    ScrollView {
                      Text(files.joined(separator: "\n"))
                        .font(.system(.body, design: .monospaced))
                    }
                    
                  case .partialSuccess(let copied, let missing):
                    Text("⚠️ Partially completed:")
                      .fontWeight(.medium)
                    Text("Copied (\(copied.count)):")
                      .fontWeight(.medium)
                    ScrollView {
                      Text(copied.joined(separator: "\n"))
                        .font(.system(.body, design: .monospaced))
                    }
                    Text("Missing (\(missing.count)):")
                      .fontWeight(.medium)
                      .foregroundColor(.red)
                    ScrollView {
                      Text(missing.joined(separator: "\n"))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.red)
                    }
                    
                  case .failure(let error):
                    Text("❌ Error:")
                      .fontWeight(.medium)
                      .foregroundColor(.red)
                    Text(error.description)
                      .foregroundColor(.red)
                  }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
              }
              .frame(maxHeight: 200)
            }
          }
        }
        
        Spacer()
      }
      .padding()
      .frame(minWidth: 400, minHeight: 500)
      .onChange(of: viewStore.destinationFolder) { _ in
        if viewStore.destinationFolder == nil {
          isCustomerInputFocused = true
        }
      }
    }
  }
}

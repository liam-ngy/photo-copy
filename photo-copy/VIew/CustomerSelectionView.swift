import SwiftUI
import ComposableArchitecture

struct CustomerSelectionView: View {
  let store: StoreOf<PhotoCopyFeature>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      if let _ = viewStore.baseDestinationFolder {
        GroupBox(label: Text("Customer").font(.headline)) {
          if viewStore.isCustomerDirectoryCreated {
            HStack {
              Text("Selected: \(viewStore.customerInput)")
                .fontWeight(.medium)
              
              Button("New Customer") {
                viewStore.send(.clearCustomer)
              }
              .keyboardShortcut("n", modifiers: [.command, .shift])
            }
          } else {
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
                
                Button("Create") {
                  viewStore.send(.createCustomerDirectory)
                }
                .disabled(!viewStore.canCreateCustomerDirectory)
              }
            }
          }
        }
      }
    }
  }
}

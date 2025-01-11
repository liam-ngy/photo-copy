import SwiftUI
import ComposableArchitecture

struct CustomerSelectionView: View {
  let store: StoreOf<PhotoCopyFeature>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      GroupBox(label: Text("Customer").font(.headline)) {
        HStack {
          if viewStore.paxFolder != nil {
            Menu(viewStore.isCustomerDirectoryCreated && viewStore.paxFolder != nil ? "Selected: \(viewStore.customerInput)" : "Select Existing Customer") {
              ForEach(viewStore.existingCustomers, id: \.self) { customer in
                Button(customer) {
                  viewStore.send(.customer(.selectExistingCustomer(customer)))
                }
              }
            }
          }
            
          
          if viewStore.isCustomerDirectoryCreated {
            Button("New Customer") {
              viewStore.send(.customer(.clearCustomer))
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
          }
        }
        
        if !viewStore.isCustomerDirectoryCreated {
          HStack {
            TextField("Enter customer name",
                      text: viewStore.binding(
                        get: \.customerInput,
                        send: { .customer(.updateCustomerInput($0)) }
                      )
            )
            .textFieldStyle(.roundedBorder)
            
            Button("Create") {
              viewStore.send(.customer(.createCustomerDirectory))
            }
            .disabled(!viewStore.canCreateCustomerDirectory)
          }
        }
      }
    }
  }
}

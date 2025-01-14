import SwiftUI
import ComposableArchitecture

struct CustomerSelectionView: View {
  @Perception.Bindable var store: StoreOf<CustomerFeature>
  
  var body: some View {
    WithPerceptionTracking {
      GroupBox(label: Text("Customer").font(.headline)) {
        HStack {
          if store.paxFolder != nil {
            Menu(store.customerFolderIsSet ? "Selected: \(store.customerInput)" : "Select Existing Customer") {
              ForEach(store.existingCustomers, id: \.self) { customer in
                Button(customer) {
                  store.send(.didSelectExistingCustomer(customer))
                }
              }
            }
          }
          
          
          if store.customerFolderIsSet {
            Button("New Customer") {
              store.send(.didTapNewCustomer)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
          }
        }
        
        if !store.customerFolderIsSet {
          HStack {
            TextField("Enter customer safety number and name", text: $store.customerInput.sending(\.customerInputChanged))
            .textFieldStyle(.roundedBorder)
            
            Button("Create") {
              store.send(.didTapCreateCustomer)
            }
            .disabled(!store.canCreateCustomerDirectory)
          }
        }
      }
    }
  }
}

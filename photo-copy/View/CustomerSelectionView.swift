import SwiftUI
import ComposableArchitecture

struct CustomerSelectionView: View {
  @Perception.Bindable var store: StoreOf<CustomerFeature>
  
  var body: some View {
    WithPerceptionTracking {
      GroupBox(label: Text("Customer").font(.headline)) {
        Group {
          HStack {
            HStack {
              Menu("Selected Customer: \(store.selectedCustomer?.name ?? "None")") {
                ForEach(store.existingCustomers) { customer in
                  Button(customer.name) {
                    store.send(.didSelectExistingCustomer(customer.id))
                  }
                }
              }
              .frame(maxWidth: 200)
              .disabled(store.paxFolder == nil || store.existingCustomers.isEmpty)
              
              TextField("Enter customer safety number and name", text: $store.customerInput.sending(\.customerInputChanged))
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                  store.send(.didTapCreateCustomer)
                }
              
              Button("Create") {
                store.send(.didTapCreateCustomer)
              }
              .disabled(!store.canCreateCustomerDirectory)
            }
          }
          .padding()
        }
      }
    }
  }
}

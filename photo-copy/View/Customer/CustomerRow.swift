import SwiftUI
import ComposableArchitecture

struct CustomerRow: View {
  let customer: Customer
  @State var hasPaid: Bool = false
  
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(customer.name)
          .font(.headline)
        Text("3 Photos")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      Spacer()
      
      ZStack {
        Image(systemName: "circle")
          .foregroundColor(.gray)
          .opacity(hasPaid ? 0 : 1)
          .scaleEffect(hasPaid ? 0.5 : 1)
        
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(.green)
          .opacity(hasPaid ? 1 : 0)
          .scaleEffect(hasPaid ? 1 : 0.5)
      }
      .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hasPaid)
      .onTapGesture {
        hasPaid.toggle()
      }
    }
    .padding(.vertical, 4)
  }
}

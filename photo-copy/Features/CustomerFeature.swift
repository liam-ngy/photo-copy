
import Foundation
import ComposableArchitecture


@Reducer
struct CustomerFeature {
  
  @ObservableState
  struct State: Equatable {
    @Shared(.inMemory("paxFolder"))
    var paxFolder: URL?
    
    @Shared(.inMemory("customerFolder"))
    var customerFolder: URL?

    var selectedCustomer: Customer?
    
    var existingCustomers: [Customer] = []
    var customerInput: String = ""
    
    var hasValidCustomerInput: Bool {
      !customerInput.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var customerFolderIsSet: Bool {
      customerFolder != nil
    }

    var canCreateCustomerDirectory: Bool {
      hasValidCustomerInput && paxFolder != nil
    }
    
    var shouldShowCustomerInput: Bool {
      !customerFolderIsSet
    }
  }
  
  enum Action: Equatable {
    // Can be called from the UI
    case didSelectExistingCustomer(UUID)
    case didTapCreateCustomer
    case customerInputChanged(String)
    
    case selectCustomer(Customer)
    case existingCustomersLoaded([Customer])
    case loadExistingCustomers
    case setCustomerFolder(URL)
    case customerDirectoryFailed(FileCopyService.FileCopyError)
  }
  
  @Dependency(\.fileManager) var fileManager

  var body: some ReducerOf<Self> {
    
    Reduce { state, action in
      switch action {
      case let .existingCustomersLoaded(customers):
        state.existingCustomers = customers
        return .none
        
      case .loadExistingCustomers:
        guard let paxFolder = state.paxFolder else { return .none }
        
        return .run { [existingCustomers = state.existingCustomers] send in
          switch await fileManager.listContents(paxFolder) {
          case let .success(customers):
            let transformedCustomers = customers.map { url in
              if let existingCustomer = existingCustomers.first(where: { $0.url == url }) {
                return existingCustomer  // Preserve existing customer with same ID
              }
              
              return Customer(url: url)  // Only create new one if not found
            }.sorted { $0.name < $1.name }
            
            await send(.existingCustomersLoaded(transformedCustomers))
            
          case let .failure(error):
            await send(.customerDirectoryFailed(error))
          }
        }
        
      case let .didSelectExistingCustomer(id):
        guard let customer = state.existingCustomers.first(where: { $0.id == id }) else { return .none }
        
        return .send(.selectCustomer(customer))
        
      case let .setCustomerFolder(url):
        state.$customerFolder.withLock { $0 = url }
        
        return .send(.loadExistingCustomers)
        
        
      case .customerDirectoryFailed:
        return .none
        
      case .didTapCreateCustomer:
        guard let paxFolder = state.paxFolder,
              !state.customerInput.trimmingCharacters(in: .whitespaces).isEmpty else { return .none }
          
        return .run { [customerInput = state.customerInput] send in
          switch await fileManager.createDirectory(paxFolder, customerInput.sanitizedCustomerInput()) {
            case let .success(url):
              let newCustomer = Customer(url: url)
              await send(.loadExistingCustomers)
              await send(.selectCustomer(newCustomer))
                
            case let .failure(error):
                await send(.customerDirectoryFailed(error))
            }
        }
        
      case let .customerInputChanged(text):
        state.customerInput = text
        return .none
        
      case let .selectCustomer(customer):
        state.selectedCustomer = customer
        state.customerInput = ""
        guard let paxFolder = state.paxFolder else { return .none }
        
        return .run { send in
            switch await fileManager.getDirectory(paxFolder, customer.name) {
            case let .success(url):
                await send(.setCustomerFolder(url))
            case let .failure(error):
                await send(.customerDirectoryFailed(error))
            }
        }
      }
    }
  }
}


extension CustomerFeature.State {
  mutating func reset() -> Effect<CustomerFeature.Action> {
    $customerFolder.withLock { $0 = nil }
    existingCustomers = []
    customerInput = ""
    
    return .none
  }
}


extension String {
  
  func sanitizedCustomerInput() -> String {
    return self.trimmingCharacters(in: .whitespaces)
      .components(separatedBy: .init(charactersIn: "/\\:*?\"<>|"))
      .joined()
  }
  
}

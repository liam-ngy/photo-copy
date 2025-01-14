
import Foundation
import ComposableArchitecture


@Reducer
struct CustomerFeature {
  @ObservableState
  struct State: Equatable {
    @Shared(.inMemory("paxFolder"))
    var paxFolder: URL?
    
    // TODO: Should i check for pax
    @Shared(.inMemory("customerFolder"))
    var customerFolder: URL?

    var existingCustomers: [String] = []
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
    case didSelectExistingCustomer(String)
    case didTapCreateCustomer
    case didTapNewCustomer
    case customerInputChanged(String)
    
    case existingCustomersLoaded([String])
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
        print(state.existingCustomers)
        return .none
        
      case .loadExistingCustomers:
        guard let paxFolder = state.paxFolder else { return .none }
        
        return .run { send in
          switch await fileManager.listContents(paxFolder) {
          case let .success(customers):
            await send(.existingCustomersLoaded(customers))
            
          case let .failure(error):
            await send(.customerDirectoryFailed(error))
          }
        }
        
      case let .didSelectExistingCustomer(customer):
        guard let paxFolder = state.paxFolder else { return .none }
        state.customerInput = customer
        
        return .run { send in
          // TODO: Fix it
          //          await send(.photo(.clearPhotoInput))
          switch await fileManager.getDirectory(paxFolder, customer) {
          case let .success(url):
            await send(.setCustomerFolder(url))
            
          case let .failure(error):
            await send(.customerDirectoryFailed(error))
          }
        }
        
      case let .setCustomerFolder(url):
        state.$customerFolder.withLock { $0 = url }
        
        return .send(.loadExistingCustomers)
        
        
      case .customerDirectoryFailed:
        return .none
        
      case .didTapCreateCustomer:
        guard let paxFolder = state.paxFolder, !state.customerInput.trimmingCharacters(in: .whitespaces).isEmpty else { return .none }
          
        return .run { [customerInput = state.customerInput] send in
          switch await fileManager.createDirectory(paxFolder, customerInput) {
          case let .success(customerUrl):
            await send(.setCustomerFolder(customerUrl))
            
          case let .failure(error):
            await send(.customerDirectoryFailed(error))
          }
          
        }
        
      case .didTapNewCustomer:
        state.customerInput = ""
        state.$customerFolder.withLock { $0 = nil }
        // state.copyState = .idle
        return .none
        
      case let .customerInputChanged(text):
        state.customerInput = text
        return .none
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


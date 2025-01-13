
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

    var existingCustomers: [String] = []
    var customerInput: String = ""
  }
  
  enum Action: Equatable, Sendable {
    case existingCustomersLoaded([String])
    case loadExistingCustomers
    // TODO: Rename to UI
    case selectExistingCustomer(String)
    case setCustomerFolder(URL)
    case customerDirectoryFailed
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
            // TODO: Fix that
            
            // await send(.folder(.requiredFoldersFailed(folder: .pax, error: error)))
            print(error)
          }
        }
        
      case let .selectExistingCustomer(customer):
        guard let paxFolder = state.paxFolder else { return .none }
        state.customerInput = customer
        
        return .run { send in
          // TODO
//          await send(.photo(.clearPhotoInput))
          switch await fileManager.getDirectory(paxFolder, customer) {
          case let .success(url):
            await send(.setCustomerFolder(url))
            
          case let .failure(error):
            await send(.customerDirectoryFailed)
          }
        }
        
      case let .setCustomerFolder(url):
        guard let paxFolder = state.paxFolder else { return .none }
        state.$customerFolder.withLock { $0 = url }
        
        return .send(.loadExistingCustomers)
        
        
      case .customerDirectoryFailed:
        return .none
      }
    }
  }
}


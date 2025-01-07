import ComposableArchitecture
import Foundation

@Reducer
struct PhotoCopyFeature {
  @Dependency(\.fileManager) var fileManager
  
  struct State: Equatable {
    var sourceFolder: URL? = nil
    var baseDestinationFolder: URL? = nil
    var customerInput: String = ""
    var destinationFolder: URL? = nil
    
    var hasValidCustomerInput: Bool {
        !customerInput.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var canCreateCustomerDirectory: Bool {
        hasValidCustomerInput && baseDestinationFolder != nil
    }
  }
  
  enum Action: Equatable {
    case setSourceFolder(URL)
    case sourceSelectionCancelled
    case setBaseDestinationFolder(URL)
    case destinationSelectionCancelled
    
    case updateCustomerInput(String)
    case createCustomerDirectory
    case customerDirectoryCreated(URL)
    case customerDirectoryFailed(FileCopyService.FileCopyError)
  }
  
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .setSourceFolder(url):
        state.sourceFolder = url
        return .none
        
      case .sourceSelectionCancelled:
        return .none
        
      case let .setBaseDestinationFolder(url):
        state.baseDestinationFolder = url
        return .none
        
      case .destinationSelectionCancelled:
        return .none
        
      case let .updateCustomerInput(input):
        state.customerInput = input
        return .none
        
      case .createCustomerDirectory:
        guard let baseDestination = state.baseDestinationFolder else {
          return .send(.customerDirectoryFailed(.invalidDestination))
        }
        
        let trimmedInput =  state.customerInput.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty else {
          return .send(.customerDirectoryFailed(.invalidCustomerInput))
        }
        
        return .run { [trimmedInput] send in
          let result = await fileManager.createDirectory(baseDestination, trimmedInput)
          switch result {
          case .success(let url):
            await send(.customerDirectoryCreated(url))
          case .failure(let error):
            await send(.customerDirectoryFailed(error))
          }
        }
        
        
      case let .customerDirectoryCreated(url):
        state.destinationFolder = url
        return .none
        
      case .customerDirectoryFailed(_):
        return .none
      }
    }
  }
}

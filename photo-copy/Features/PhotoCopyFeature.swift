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
    var lastOperationMessage: String = ""
    
    var hasValidCustomerInput: Bool {
      !customerInput.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var canCreateCustomerDirectory: Bool {
      hasValidCustomerInput && baseDestinationFolder != nil
    }
    
    var isCustomerDirectoryCreated: Bool {
      destinationFolder != nil
    }
    
    var shouldShowCustomerInput: Bool {
      !isCustomerDirectoryCreated
    }
    
    var canProceedToPhotos: Bool {
      isCustomerDirectoryCreated
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
        print("⚡️ Creating directory...") // Debug log
        guard let baseDestination = state.baseDestinationFolder else {
          print("❌ No base destination") // Debug log
          return .send(.customerDirectoryFailed(.invalidDestination))
        }
        
        let trimmedInput = state.customerInput.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty else {
          print("❌ Empty input") // Debug log
          return .send(.customerDirectoryFailed(.invalidCustomerInput))
        }
        
        return .run { [trimmedInput] send in
          print("🏃‍♂️ Running directory creation...") // Debug log
          let result = await self.fileManager.createDirectory(baseDestination, trimmedInput)
          print("📝 Result: \(result)") // Debug log
          switch result {
          case .success(let url):
            await send(.customerDirectoryCreated(url))
          case .failure(let error):
            await send(.customerDirectoryFailed(error))
          }
        }
        
        
      case let .customerDirectoryCreated(url):
        state.destinationFolder = url
        state.lastOperationMessage = "Directory was created successfully"
        return .none
        
      case let .customerDirectoryFailed(error):
        state.lastOperationMessage = error.description
        return .none
      }
    }
  }
}

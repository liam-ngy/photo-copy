import Foundation
import ComposableArchitecture

struct PhotoCopyFeature: Reducer {
  struct State: Equatable {
    var sourceFolder: URL?
    var baseDestinationFolder: URL?
    var destinationFolder: URL?
    var customerInput: String = ""
    var photoInput: String = ""
    var existingCustomers: [String] = []
    var copyState: CopyState = .idle
    
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
    
    enum CopyState: Equatable {
      case idle
      case copying
      case completed(FileCopyService.FileCopyResult)
      
      var isCopying: Bool {
        if case .copying = self {
          return true
        }
        return false
      }
    }
  }
  
  enum Action: Equatable {
    case setSourceFolder(URL)
    case sourceSelectionCancelled
    case setBaseDestinationFolder(URL)
    case destinationSelectionCancelled
    
    case loadExistingCustomers
    case existingCustomersLoaded([String])
    case selectExistingCustomer(String)
    
    case updateCustomerInput(String)
    case createCustomerDirectory
    case customerDirectoryCreated(URL)
    case customerDirectoryFailed(FileCopyService.FileCopyError)
    
    case clearCustomer
    
    case updatePhotoInput(String)
    case copyPhotos
    case copyPhotosCompleted(FileCopyService.FileCopyResult)
  }
  
  @Dependency(\.fileManager) var fileManager
  
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
        return .run { send in
          await send(.loadExistingCustomers)
        }
        
      case .destinationSelectionCancelled:
        return .none
        
      case .loadExistingCustomers:
        guard let baseDir = state.baseDestinationFolder else { return .none }
        return .run { send in
          let result = await fileManager.listContents(baseDir)
          switch result {
          case .success(let customers):
            await send(.existingCustomersLoaded(customers))
          case .failure:
            await send(.existingCustomersLoaded([]))
          }
        }
        
      case let .existingCustomersLoaded(customers):
        state.existingCustomers = customers
        return .none
        
      case let .selectExistingCustomer(customer):
        guard let baseDir = state.baseDestinationFolder else { return .none }
        state.customerInput = customer
        return .run { send in
          let result = await fileManager.getDirectory(baseDir, customer)
          switch result {
          case .success(let url):
            await send(.customerDirectoryCreated(url))
          case .failure(let error):
            await send(.customerDirectoryFailed(error))
          }
        }
        
      case let .updateCustomerInput(input):
        state.customerInput = input
        return .none
        
      case .createCustomerDirectory:
        guard let baseDir = state.baseDestinationFolder,
              !state.customerInput.trimmingCharacters(in: .whitespaces).isEmpty
        else { return .none }
        
        return .run { [customerInput = state.customerInput] send in
          let result = await fileManager.createDirectory(baseDir, customerInput)
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
        
      case .customerDirectoryFailed:
        return .none
        
      case .clearCustomer:
        state.customerInput = ""
        state.destinationFolder = nil
        state.copyState = .idle
        return .none
        
      case let .updatePhotoInput(input):
        state.photoInput = input
        return .none
        
      case .copyPhotos:
        guard let source = state.sourceFolder,
              let destination = state.destinationFolder else {
          state.copyState = .completed(.failure(.invalidSource))
          return .none
        }
        
        state.copyState = .copying
        
        switch PhotoInputParser.parseToFileNames(state.photoInput) {
        case .success(let photos):
          if photos.isEmpty {
            state.copyState = .completed(.failure(.invalidPhotoRange))
            return .none
          }
          
          return .run { send in
            let result = await FileCopyService.copyFiles(
              from: source,
              to: destination,
              files: photos
            )
            await send(.copyPhotosCompleted(result))
          }
          
        case .failure:
          state.copyState = .completed(.failure(.invalidPhotoRange))
          return .none
        }
        
      case let .copyPhotosCompleted(result):
        state.copyState = .completed(result)
        return .none
      }
    }
  }
}

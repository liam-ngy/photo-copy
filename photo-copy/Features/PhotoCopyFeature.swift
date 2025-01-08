import Foundation
import ComposableArchitecture

struct PhotoCopyFeature: Reducer {
  struct State: Equatable {
    var baseFolder: URL?
    
    var finalsFolder: URL? {
      guard let base = baseFolder else { return nil }
      return base.appendingPathComponent("finals")
    }
    
    var paxFolder: URL? {
      guard let base = baseFolder else { return nil }
      return base.appendingPathComponent("pax")
    }
    
    var destinationFolder: URL?
    var customerInput: String = ""
    var photoInput: String = ""
    var existingCustomers: [String] = []
    var copyState: CopyState = .idle
    
    
    
    var hasValidCustomerInput: Bool {
      !customerInput.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var canCreateCustomerDirectory: Bool {
      hasValidCustomerInput && paxFolder != nil
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
    case setBaseFolder(URL)
    case baseSelectionCancelled
    
    case finalsSelectionCancelled
    case paxSelectionCancelled
    
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
      case let .setBaseFolder(url):
        state.baseFolder = url
        
        return .run { send in
          await send(.loadExistingCustomers)
        }

        
      case .baseSelectionCancelled:
        return .none
        
      case .finalsSelectionCancelled:
        return .none
        
      case .paxSelectionCancelled:
        return .none
        
      case .loadExistingCustomers:
        guard let baseFolder = state.baseFolder else {
          return .none
        }
        return .run { send in
          switch await fileManager.getDirectory(baseFolder, "pax") {
          case let .success(paxDir):
            switch await fileManager.listContents(paxDir) {
            case let .success(customers):
              await send(.existingCustomersLoaded(customers))
              
            case let .failure(error):
              print(error)
              await send(.existingCustomersLoaded([]))
            }
          case let .failure(error):
            // TODO: Is that the correct way to handle it like this
            print(error)
            await send(.existingCustomersLoaded([]))
          }
        }
        
      case let .existingCustomersLoaded(customers):
        state.existingCustomers = customers
        return .none
        
      case let .selectExistingCustomer(customer):
        guard let paxDir = state.paxFolder else { return .none }
        state.customerInput = customer
        return .run { send in
          let result = await fileManager.getDirectory(paxDir, customer)
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
        guard let paxDir = state.paxFolder,
              !state.customerInput.trimmingCharacters(in: .whitespaces).isEmpty
        else { return .none }
        
        return .run { [customerInput = state.customerInput] send in
          let result = await fileManager.createDirectory(paxDir, customerInput)
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
        guard let source = state.finalsFolder,
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

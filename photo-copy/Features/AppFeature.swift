import Foundation
import ComposableArchitecture

// MARK: - PhotoCopyFeature

@Reducer
struct AppFeature {
  
  @ObservableState
  struct State: Equatable {
    var folderState = FolderFeature.State()
    var customerState = CustomerFeature.State()
    var photoState = PhotoFeature.State()
  }
  
  // MARK: - Actions
  
  enum Action: Equatable, Sendable {
    case folder(FolderFeature.Action)
    case customer(CustomerFeature.Action)
    case photo(PhotoFeature.Action)
    case resetState
  }
  
  // MARK: - Customer Actions
  
  enum customer: Equatable {
    case loadExistingCustomers(URL)
    case existingCustomersLoaded([String])
    case selectExistingCustomer(String)
    case updateCustomerInput(String)
    case createCustomerDirectory
    case customerDirectoryCreated(URL)
    case customerDirectoryFailed(FileCopyService.FileCopyError)
    case clearCustomer
  }
  
  // MARK: - Photo Actions
  
  @Dependency(\.fileManager) var fileManager
  
  var body: some ReducerOf<Self> {
    Scope(state: \.folderState, action: \.folder) {
      FolderFeature()
    }
    
    Scope(state: \.customerState, action: \.customer) {
      CustomerFeature()
    }
    
    Scope(state: \.photoState, action: \.photo) {
      PhotoFeature()
    }

    Reduce { state, action in
      switch action {
      case let .folder(.didPressChooseBase(url)):
        return .concatenate(
          .send(.resetState),
          FolderFeature()
            .reduce(into: &state.folderState, action: .setBaseFolder(url))
            .map(AppFeature.Action.folder)
        )
      
      case .folder(.setPaxFolder):
        return CustomerFeature()
          .reduce(into: &state.customerState, action: .loadExistingCustomers)
          .map(AppFeature.Action.customer)
        
      case let .customer(.customerDirectoryFailed(error)): // TODO: Need to specify Folder error
        return FolderFeature()
          .reduce(into: &state.folderState, action: .requiredFoldersFailed(folder: .pax, error: error))
          .map(AppFeature.Action.folder)
        
      case .customer(.didTapNewCustomer):
        return FolderFeature()
          .reduce(into: &state.folderState, action: .clearFolderErrorMessages)
          .map(AppFeature.Action.folder)
        
      case .customer(.didSelectExistingCustomer):
        return PhotoFeature()
          .reduce(into: &state.photoState, action: .clearPhotoInput)
          .map(AppFeature.Action.photo)
        
        
      case .resetState:
        return .concatenate(
          state.folderState.reset().map(Action.folder),
          state.customerState.reset().map(Action.customer),
          state.photoState.reset().map(Action.photo)
        )

          
      default:
          return .none
      }
    }
  }
}


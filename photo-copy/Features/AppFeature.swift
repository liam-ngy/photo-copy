import Foundation
import ComposableArchitecture

// MARK: - PhotoCopyFeature

@Reducer
struct AppFeature {
  
  @ObservableState
  struct State: Equatable {
    var folderState = FolderFeature.State()
    var customerState = CustomerFeature.State()
    
    var baseFolder: URL?
    var finalsFolder: URL?
    var paxFolder: URL?
    var destinationFolder: URL?
    var customerInput: String = ""
    var photoInput: String = ""
    var existingCustomers: [String] = []
    var copyState: CopyState = .idle
    var folderErrorMessages: [String] = []
    
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
    
    var hasFolderErrorMessages: Bool {
      !folderErrorMessages.isEmpty
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
  
  // MARK: - Actions
  
  enum Action: Equatable, Sendable {
    case folder(FolderFeature.Action)
    case customer(CustomerFeature.Action)
    case photo(PhotoAction)
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
  
  enum PhotoAction: Equatable {
    case updatePhotoInput(String)
    case clearPhotoInput
    case copyPhotos
    case copyPhotosCompleted(FileCopyService.FileCopyResult)
  }
  
  @Dependency(\.fileManager) var fileManager
  
  var body: some ReducerOf<Self> {
    Scope(state: \.folderState, action: \.folder) {
      FolderFeature()
    }
    
    Scope(state: \.customerState, action: \.customer) {
      CustomerFeature()
    }
    
    Reduce { state, action in
      switch action {
      case .photo(let photoAction):
        return handlePhotoAction(&state, photoAction)
        
      case .resetState:
        return .concatenate(
          state.folderState.reset().map(Action.folder),
          state.customerState.reset().map(Action.customer)
          // TODO: Add photostate
        )
        
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
          
      default:
          return .none
      }
    }
  }
  
  // MARK: - Photo Handling
  
  private func handlePhotoAction(_ state: inout State, _ action: PhotoAction) -> Effect<Action> {
    switch action {
    case let .updatePhotoInput(input):
      state.photoInput = input
      return .none
      
    case .clearPhotoInput:
      state.photoInput = ""
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
          await send(.photo(.copyPhotosCompleted(result)))
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

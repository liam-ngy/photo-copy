import Foundation
import ComposableArchitecture

@Reducer
struct PhotoFeature {
  
  @ObservableState
  struct State: Equatable {
    @Shared(.inMemory("finalsFolder"))
    var finalsFolder: URL?
    
    @Shared(.inMemory("customerFolder"))
    var customerFolder: URL?
    
    
    var photoInput: String = ""
    var copyResponse: FileCopyService.FileCopyResponse = .idle
    
    var foldersAreReady: Bool {
      finalsFolder != nil && customerFolder != nil
    }
    
    var canCopyPhotos: Bool {
      return !photoInput.isEmpty && foldersAreReady && !copyResponse.isCopying
    }
  }
  
  enum Action: Equatable {
    // UI Action
    case didTapCopy
    case photoInputChanged(String)
    
    case copyPhotosCompleted(FileCopyService.FileCopyResponse)
    case clearPhotoInput
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didTapCopy:
        guard let finalsFolder = state.finalsFolder, let customerFolder = state.customerFolder else {
          return .none
        }
        
        let photoInput = state.photoInput
        state.copyResponse = .copying
        
        return .run { send in
          switch PhotoInputParser.parseToFileNames(photoInput) {
          case let .success(photos):
            let result = await FileCopyService.copyFiles(
              from: finalsFolder,
              to: customerFolder,
              files: photos
            )
            
            await send(.copyPhotosCompleted(result))
            
          case let .success(photos) where photos.isEmpty:
            // TODO: Better error display
            await send(.copyPhotosCompleted(.completed(.failure(.invalidPhotoRange))))
            
          case .failure:
            await send(.copyPhotosCompleted(.completed(.failure(.invalidPhotoRange))))
          }
        }
        
      case let .photoInputChanged(text):
        state.photoInput = text
        return .none
        
      case .clearPhotoInput:
        state.photoInput = ""
        return .none
        
      case let .copyPhotosCompleted(result):
        state.copyResponse = result
        return .none
      }
    }
  }
}

extension PhotoFeature.State {
  mutating func reset() -> Effect<PhotoFeature.Action> {
    photoInput = ""
    copyResponse = .idle
    return .none
  }
}

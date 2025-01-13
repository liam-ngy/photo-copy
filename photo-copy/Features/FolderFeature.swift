import Foundation
import ComposableArchitecture

// MARK: - FolderFeature

@Reducer
struct FolderFeature {
  
  @ObservableState
  struct State: Equatable {
    var baseFolder: URL?
    var finalsFolder: URL?
    
    
    @Shared(.inMemory("paxFolder"))
    var paxFolder: URL?
    
    @Shared(.inMemory("destinationFolder"))
    var destinationFolder: URL?
    
    var folderErrorMessages: [String] = []
    
    var hasFolderErrorMessages: Bool {
      !folderErrorMessages.isEmpty
    }
  }
  
  enum Action: Equatable {
    // MARK: - UI Action
    case didPressChooseBase(URL)
    
    case setFinalsFolder(URL)
    case setPaxFolder(URL)
    case requiredFoldersFailed(folder: Folder, error: FileCopyService.FileCopyError)
    case clearFolderErrorMessages
    case loadFolders(URL) // Action to load folders
  }
  
  @Dependency(\.fileManager) var fileManager
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didPressChooseBase(url):
        state.baseFolder = url
        state.folderErrorMessages = []
        
        return .run { send in
          await send(.loadFolders(url))
        }
        
      case let .setFinalsFolder(url):
        state.finalsFolder = url
        return .none
        
      case let .setPaxFolder(url):
        state.$paxFolder.withLock { $0 = url }
        
        
        return .none
        
        
      case let .requiredFoldersFailed(folder, error):
        state.folderErrorMessages.append("Failed to set \(folder.rawValue) folder: \(error.localizedDescription)")
        return .none
        
      case .clearFolderErrorMessages:
        state.folderErrorMessages = []
        return .none
        
      case let .loadFolders(url):
        return .run { send in
          let folders: [(Folder, (URL) -> Action)] = [
            (.pax, { Action.setPaxFolder($0) }),
            (.finals, { Action.setFinalsFolder($0) })
          ]
          
          for (folder, successAction) in folders {
            switch await fileManager.getDirectory(url, folder.rawValue) {
            case let .success(folderURL):
              await send(successAction(folderURL))
            case let .failure(error):
              await send(.requiredFoldersFailed(folder: folder, error: error))
            }
          }
        }
      }
    }
  }
}

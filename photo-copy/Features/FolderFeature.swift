import Foundation
import ComposableArchitecture

// MARK: - FolderFeature

@Reducer
struct FolderFeature {
  
  @ObservableState
  struct State: Equatable {
    var baseFolder: URL?
    
    @Shared(.inMemory("finalsFolder"))
    var finalsFolder: URL?
    
    @Shared(.inMemory("paxFolder"))
    var paxFolder: URL?
    
    var folderErrorMessages: [String] = []
    
    var hasFolderErrorMessages: Bool {
      !folderErrorMessages.isEmpty
    }
  }
  
  enum Action: Equatable {
    // MARK: - UI Action
    case didPressChooseBase(URL)
    
    case setBaseFolder(URL)
    case setFinalsFolder(URL)
    case setPaxFolder(URL)
    case requiredFoldersFailed(folder: Folder, error: FileCopyService.FileCopyError)
    case clearFolderErrorMessages
    // TODO: Remove action maybe
    case loadFolders(URL)
  }
  
  @Dependency(\.fileManager) var fileManager
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didPressChooseBase:
        // Case is being handled by AppFeature
        return .none
        
      case let .setBaseFolder(url):
        state.baseFolder = url
        
        return .run { send in
          await send(.loadFolders(url))
        }
        
      case let .setFinalsFolder(url):
        state.$finalsFolder.withLock { $0 = url }
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

extension FolderFeature.State {
  mutating func reset() -> Effect<FolderFeature.Action> {
    baseFolder = nil
    $finalsFolder.withLock { $0 = nil }
    $paxFolder.withLock { $0 = nil }
    folderErrorMessages = []
    
    return .none
  }
}

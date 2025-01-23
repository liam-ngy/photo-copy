import ComposableArchitecture
import Foundation

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
    var isDroppingFolder: Bool = false

    var hasFolderErrorMessages: Bool {
      !folderErrorMessages.isEmpty
    }
  }

  enum Action: Equatable {
    // MARK: - UI Action
    case didPressChooseBase(URL)
    case didDropFolder(URL)
    case updateIsDrop(Bool)
    

    case setBaseFolder(URL)
    case setFinalsFolder(URL)
    case setPaxFolder(URL)
    // TODO: Fix folder issue
    case requiredFoldersFailed(folder: Folder, error: FileCopyService.FileCopyError)
    case clearFolderErrorMessages
    case loadFolders(URL)
  }

  @Dependency(\.fileManager) var fileManager

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didPressChooseBase:
        // Case is being handled by AppFeature
        return .none
        
      case .didDropFolder:
        // Case being handled by AppFeature
        return .none
        
      case let .updateIsDrop(bool):
        state.isDroppingFolder = bool
        return .none

      case let .setBaseFolder(url):
        // TODO: Replace with dependency Injection
        return .run { send in
          switch await fileManager.secureBaseFolder(url) {
          case .success(let secureURL):
            await send(.loadFolders(secureURL))
          case .failure(let error):
            await send(.requiredFoldersFailed(folder: .pax, error: error))
          }
        }

      case let .setFinalsFolder(url):
        state.$finalsFolder.withLock { $0 = url }
        return .none

      case let .setPaxFolder(url):
        state.$paxFolder.withLock { $0 = url }
        return .none

      case let .requiredFoldersFailed(folder, error):
        state.folderErrorMessages.append(
          "Failed to set \(folder.rawValue) folder: \(error.description)")
        return .none

      case .clearFolderErrorMessages:
        state.folderErrorMessages = []
        return .none

      case let .loadFolders(url):
        state.baseFolder = url
        
        return .run { send in
          let folders: [(Folder, (URL) -> Action)] = [
            (.pax, { Action.setPaxFolder($0) }),
            (.finals, { Action.setFinalsFolder($0) }),
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

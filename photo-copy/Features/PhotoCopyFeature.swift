import ComposableArchitecture
import Foundation

@Reducer
struct PhotoCopyFeature {
  struct State: Equatable {
    var sourceFolder: URL?
    var baseDestinationFolder: URL?
  }
  
  enum Action {
    case setSourceFolder(URL)
    case sourceSelectionCancelled
    case setBaseDestinationFolder(URL)
    case destinationSelectionCancelled
    
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
      }
    }
  }
}

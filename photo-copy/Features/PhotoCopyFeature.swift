import ComposableArchitecture
import Foundation

@Reducer
struct PhotoCopyFeature {
  struct State: Equatable {
    var sourceFolder: URL?
  }
  
  enum Action {
    case setSourceFolder(URL)
    case sourceSelectionCancelled
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .setSourceFolder(url):
        //TODO: Need to be removed
        print("🔵 TCA: Source folder set to: \(url.path)")
        state.sourceFolder = url
        return .none
        
      case .sourceSelectionCancelled:
        
        print("🔴 TCA: Source folder selection cancelled")
        return .none
      }
    }
  }
}

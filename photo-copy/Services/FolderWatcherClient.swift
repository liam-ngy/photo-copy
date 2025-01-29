import Foundation
import ComposableArchitecture

struct FolderWatcherClient {
  var start: @Sendable (URL) -> AsyncStream<Result<[URL], FileCopyService.FileCopyError>>
}

extension FolderWatcherClient: DependencyKey {
  static let liveValue = Self { url in
    AsyncStream { continuation in
      let task = Task {
        let fileManager = SecureFileManager()
        
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else {
          continuation.yield(.failure(.insufficientPermissions))
          return
        }
        
        let source = DispatchSource.makeFileSystemObjectSource(
          fileDescriptor: descriptor,
          eventMask: [.write, .extend, .delete, .rename],
          queue: .main
        )
        
        source.setEventHandler {
          Task { @MainActor in
            let result = fileManager.listContents(of: url)
            continuation.yield(with: .success(result))
          }
        }
        
        source.setCancelHandler {
          close(descriptor)
        }
        
        source.resume()
        
        let initialResult = fileManager.listContents(of: url)
        continuation.yield(with: .success(initialResult))
        
        continuation.onTermination = { _ in
          source.cancel()
        }
      }
    }
  }
}

extension DependencyValues {
  var folderWatcher: FolderWatcherClient {
    get { self[FolderWatcherClient.self] }
    set { self[FolderWatcherClient.self] = newValue }
  }
}

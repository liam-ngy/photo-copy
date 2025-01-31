import Foundation
import ComposableArchitecture
import os.log

// MARK: - FolderWatcherClient

struct FolderWatcherClient {
  var start: @Sendable (URL) -> AsyncStream<Result<[URL], FileCopyService.FileCopyError>>
  var stop: @Sendable (URL) -> Void
}

// MARK: - Implementation

extension FolderWatcherClient: DependencyKey {
  static let liveValue: FolderWatcherClient = {
    // Logger for debugging
    
    // Keep track of active watchers to prevent memory leaks
    actor WatcherStorage {
      private var activeSources: [URL: DispatchSourceFileSystemObject] = [:]
      private var activeDescriptors: [URL: Int32] = [:]
      let logger = Logger(subsystem: "com.photo-copy.folderWatcher", category: "FolderWatcherClient")

      func store(source: DispatchSourceFileSystemObject, descriptor: Int32, for url: URL) {
        activeSources[url] = source
        activeDescriptors[url] = descriptor
        logger.debug("📁 Stored watcher for folder: \(url)")
      }
      
      func removeWatcher(for url: URL) {
        if let source = activeSources[url] {
          source.cancel()
          activeSources[url] = nil
          logger.debug("🛑 Cancelled watcher for folder: \(url)")
        }
        
        if let descriptor = activeDescriptors[url] {
          close(descriptor)
          activeDescriptors[url] = nil
          logger.debug("🚪 Closed descriptor for folder: \(url)")
        }
      }
    }
    
    let storage = WatcherStorage()
    let logger = Logger(subsystem: "com.photo-copy.folderWatcher", category: "FolderWatcherClient")
    
    return Self(
      start: { url in
        AsyncStream { continuation in
          let task = Task {
            
            // TODO: Figure out how to use dependency during initial process
            func listContents(_ url: URL) -> Result<[URL], FileCopyService.FileCopyError> {
              SecurityScopedHelper.access(url) {
                do {
                  let fileManager = FileManager.default
                  let contents = try fileManager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                  )
                  return .success(contents)
                } catch {
                  return .failure(.insufficientPermissions)
                }
              }
            }
            
            // Open directory for monitoring
            let descriptor = open(url.path, O_EVTONLY)
            guard descriptor >= 0 else {
              logger.error("❌ Failed to open directory for monitoring: \(url)")
              continuation.yield(.failure(.insufficientPermissions))
              return
            }
            
            let source = DispatchSource.makeFileSystemObjectSource(
              fileDescriptor: descriptor,
              eventMask: [.write, .extend, .delete, .rename],
              queue: .main
            )
            
            // Store the watcher
            storage.store(source: source, descriptor: descriptor, for: url)
            
            source.setEventHandler {
              Task { @MainActor in
                logger.debug("🔍 Folder change detected for: \(url)")
                let result = listContents(url)
                  .map { urls in
                    urls.filter { url in
                      let suffix = url.pathExtension.lowercased()
                      return ["jpg", "jpeg", "png"].contains(suffix)
                    }
                  }
                continuation.yield(result)
              }
            }
            
            source.setCancelHandler {
              close(descriptor)
              logger.debug("🛑 Watcher cancelled for folder: \(url)")
            }
            
            source.resume()
            logger.debug("▶️ Watcher resumed for folder: \(url)")
            
            // Send initial state
            let initialResult = listContents(url)
              .map { urls in
                urls.filter { url in
                  let suffix = url.pathExtension.lowercased()
                  return ["jpg", "jpeg", "png"].contains(suffix)
                }
              }
            continuation.yield(initialResult)
            
            continuation.onTermination = { _ in
              Task {
                logger.debug("⏹ Watcher terminated for folder: \(url)")
                storage.removeWatcher(for: url)
              }
            }
          }
          
          // Ensure the task is cancelled when the effect is cancelled
          continuation.onTermination = { _ in
            logger.debug("⏹ Effect cancelled for folder: \(url)")
            task.cancel()
          }
        }
      }, stop: { url in
        Task {
          logger.debug("🛑 Stopping watcher for folder: \(url)")
          storage.removeWatcher(for: url)
        }
      }
    )
  }()
}

// MARK: - Dependency Registration

extension DependencyValues {
  var folderWatcher: FolderWatcherClient {
    get { self[FolderWatcherClient.self] }
    set { self[FolderWatcherClient.self] = newValue }
  }
}

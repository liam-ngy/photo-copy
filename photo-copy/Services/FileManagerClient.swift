import ComposableArchitecture
import Foundation

struct FileManagerClient {
  var createDirectory: @Sendable (URL, String) async -> Result<URL, FileCopyService.FileCopyError>
  var getDirectory: @Sendable (URL, String) async -> Result<URL, FileCopyService.FileCopyError>
  var listContents: @Sendable (URL) async -> Result<[URL], FileCopyService.FileCopyError>
  var secureBaseFolder: @Sendable (URL) async -> Result<URL, FileCopyService.FileCopyError>
}

extension FileManagerClient: DependencyKey {
  static let liveValue = FileManagerClient(
    createDirectory: { baseURL, name in
      SecureFileManager().createDirectory(at: baseURL, withName: name)
    },
    getDirectory: { baseURL, name in
      SecureFileManager().getDirectory(at: baseURL, withName: name)
    },
    listContents: { url in
      SecureFileManager().listContents(of: url)
    },
    secureBaseFolder: { url in
      SecureFileManager().secureBaseFolder(url)
    }
  )
}

extension DependencyValues {
  var fileManager: FileManagerClient {
    get { self[FileManagerClient.self] }
    set { self[FileManagerClient.self] = newValue }
  }
}

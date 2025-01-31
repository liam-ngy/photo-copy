import ComposableArchitecture
import Foundation

struct FileManagerClient {
  func createDirectory(_ url: URL, _ name: String) async -> Result<URL, FileCopyService.FileCopyError> {
    SecurityScopedHelper.access(url) {
      let newDirURL = url.appendingPathComponent(name)
      do {
        try FileManager.default.createDirectory(
          at: newDirURL,
          withIntermediateDirectories: true,
          attributes: nil
        )
        return SecurityScopedHelper.createSecureBookmark(for: newDirURL)
      } catch {
        return .failure(.customerDirectoryCreationFailed)
      }
    }
  }
  
  func getDirectory(_ baseURL: URL, _ name: String) async -> Result<URL, FileCopyService.FileCopyError> {
    let dirURL = baseURL.appendingPathComponent(name)
    if FileManager.default.fileExists(atPath: dirURL.path) {
      return SecurityScopedHelper.createSecureBookmark(for: dirURL)
    } else {
      return .failure(.directoryNotFound(dirURL.lastPathComponent))
    }
  }
  
  func listContents(_ url: URL) async -> Result<[URL], FileCopyService.FileCopyError> {
    SecurityScopedHelper.access(url) {
      do {
        let contents = try FileManager.default.contentsOfDirectory(
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
  
  
  func secureBaseFolder(_ url: URL) async -> Result<URL, FileCopyService.FileCopyError> {
    SecurityScopedHelper.createSecureBookmark(for: url)
  }
  
  // TODO: Make use of listCOntents
  func countPhotos(url: URL) async -> Result<Int, FileCopyService.FileCopyError> {
    do {
      let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
      let photoCount = contents.filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "png" }.count
      return .success(photoCount)
    } catch {
      return .failure(.unknownError("Count Photos Error"))
    }
  }
  
}

extension FileManagerClient: DependencyKey {
  static let liveValue = FileManagerClient()
}

extension DependencyValues {
  var fileManager: FileManagerClient {
    get { self[FileManagerClient.self] }
    set { self[FileManagerClient.self] = newValue }
  }
}


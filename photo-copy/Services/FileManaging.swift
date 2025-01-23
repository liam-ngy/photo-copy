import Foundation

protocol FileManaging {
  func createDirectory(at baseURL: URL, withName name: String) -> Result<
    URL, FileCopyService.FileCopyError
  >
  func getDirectory(at baseURL: URL, withName name: String) -> Result<
    URL, FileCopyService.FileCopyError
  >
  func listContents(of url: URL) -> Result<[URL], FileCopyService.FileCopyError>
  func secureBaseFolder(_ url: URL) -> Result<URL, FileCopyService.FileCopyError>
}

final class SecureFileManager: FileManaging {
  private let fileManager = FileManager.default

  func secureBaseFolder(_ url: URL) -> Result<URL, FileCopyService.FileCopyError> {
    SecurityScopedHelper.createSecureBookmark(for: url)
  }

  func getDirectory(at baseURL: URL, withName name: String) -> Result<
    URL, FileCopyService.FileCopyError
  > {
    let dirURL = baseURL.appendingPathComponent(name)
    if FileManager.default.fileExists(atPath: dirURL.path) {
      return SecurityScopedHelper.createSecureBookmark(for: dirURL)
    } else {
      return .failure(.directoryNotFound(dirURL.lastPathComponent))
    }
  }

  func createDirectory(at baseURL: URL, withName name: String) -> Result<
    URL, FileCopyService.FileCopyError
  > {
    SecurityScopedHelper.access(baseURL) {
      let newDirURL = baseURL.appendingPathComponent(name)
      do {
        try fileManager.createDirectory(
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

  func listContents(of url: URL) -> Result<[URL], FileCopyService.FileCopyError> {
    SecurityScopedHelper.access(url) {
      do {
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
}

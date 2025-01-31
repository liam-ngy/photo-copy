import ComposableArchitecture
import Foundation

struct FileManagerClient {
  var createDirectory: @Sendable (URL, String) async -> Result<URL, FileCopyService.FileCopyError>
  var getDirectory: @Sendable (URL, String) async -> Result<URL, FileCopyService.FileCopyError>
  var listContents: @Sendable (URL) async -> Result<[URL], FileCopyService.FileCopyError>
  var secureBaseFolder: @Sendable (URL) async -> Result<URL, FileCopyService.FileCopyError>
  var countPhotos: @Sendable (URL) async -> Result<Int, FileCopyService.FileCopyError>
  
}

extension FileManagerClient: DependencyKey {
  
  static let liveValue = FileManagerClient(
    createDirectory: { baseURL, name in
      SecurityScopedHelper.access(baseURL) {
        let newDirURL = baseURL.appendingPathComponent(name)
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
    },
    
    getDirectory: { baseURL, name in
      let dirURL = baseURL.appendingPathComponent(name)
      if FileManager.default.fileExists(atPath: dirURL.path) {
        return SecurityScopedHelper.createSecureBookmark(for: dirURL)
      } else {
        return .failure(.directoryNotFound(dirURL.lastPathComponent))
      }
    },
    
    listContents: { url in
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
    },
    
    secureBaseFolder: { url in
      SecurityScopedHelper.createSecureBookmark(for: url)
    },
    
    countPhotos: { url in
      do {
        let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        let photoCount = contents.filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "png" }.count
        return .success(photoCount)
      } catch {
        return .failure(.unknownError("Count Photos Error"))
      }
    }
  )
}

extension DependencyValues {
  var fileManager: FileManagerClient {
    get { self[FileManagerClient.self] }
    set { self[FileManagerClient.self] = newValue }
  }
}

//extension String {
//  func sanitizedCustomerInput() -> String {
//    return self.trimmingCharacters(in: .whitespaces)
//      .components(separatedBy: .init(charactersIn: "/\\:*?\"<>|"))
//      .joined()
//  }
//}

import Foundation

protocol FileManaging {
    func createDirectory(at baseURL: URL, withName name: String) -> Result<URL, FileCopyService.FileCopyError>
    func getDirectory(at baseURL: URL, withName name: String) -> Result<URL, FileCopyService.FileCopyError>
    func listContents(of url: URL) -> Result<[String], FileCopyService.FileCopyError>
}

final class SecureFileManager: FileManaging {
    private let fileManager = FileManager.default
    
  // TODO: Needs to be changed to finals
    func createDirectory(at baseURL: URL, withName name: String) -> Result<URL, FileCopyService.FileCopyError> {
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
    
    func getDirectory(at baseURL: URL, withName name: String) -> Result<URL, FileCopyService.FileCopyError> {
      let dirURL = baseURL.appendingPathComponent(name)
      
      if FileManager.default.fileExists(atPath: dirURL.path) {
        return SecurityScopedHelper.access(baseURL) {
          return SecurityScopedHelper.createSecureBookmark(for: dirURL)
        }
      } else {
        return .failure(.directoryNotFound)
      }
    }
    
    func listContents(of url: URL) -> Result<[String], FileCopyService.FileCopyError> {
        SecurityScopedHelper.access(url) {
            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: nil
                )
                return .success(contents.map { $0.lastPathComponent }.sorted())
            } catch {
                return .failure(.insufficientPermissions)
            }
        }
    }
  
  func checkDirectory(at url: URL) -> Result<URL, FileCopyService.FileCopyError> {
      do {
          let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
          
          // Check if the resource exists and is a directory
          guard resourceValues.isDirectory == true else {
            return .failure(.directoryNotFound)
          }
          
          // Return the directory URL on success
          return .success(url)
          
      } catch {
        return .failure(.fileNotFound("\(url.lastPathComponent)"))
      }
  }
}

import Foundation

protocol FileManaging {
    func createDirectory(at baseURL: URL, withName name: String) -> Result<URL, FileCopyService.FileCopyError>
    func getDirectory(at baseURL: URL, withName name: String) -> Result<URL, FileCopyService.FileCopyError>
    func listContents(of url: URL) -> Result<[String], FileCopyService.FileCopyError>
}

final class SecureFileManager: FileManaging {
    private let fileManager = FileManager.default
    
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
        SecurityScopedHelper.access(baseURL) {
            let dirURL = baseURL.appendingPathComponent(name)
            return SecurityScopedHelper.createSecureBookmark(for: dirURL)
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
}

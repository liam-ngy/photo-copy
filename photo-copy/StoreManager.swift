import Foundation

// TODO: Implement protocol for dependency injection
final class StorageManager {
    static let shared = StorageManager()
    
    private init() {}
    
    func saveSourceFolderPath(_ path: String) {
        UserDefaults.standard.set(path, forKey: "sourceFolderPath")
    }
    
    func loadSourceFolderPath() -> URL? {
        if let savedPath = UserDefaults.standard.string(forKey: "sourceFolderPath") {
            return URL(string: savedPath)
        }
        return nil
    }
    
    func saveDestinationFolderPath(_ path: String) {
        UserDefaults.standard.set(path, forKey: "destinationFolderPath")
    }
    
    func loadDestinationFolderPath() -> URL? {
        if let savedPath = UserDefaults.standard.string(forKey: "destinationFolderPath") {
            return URL(string: savedPath)
        }
        return nil
    }
}

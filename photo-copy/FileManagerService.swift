import Foundation

enum FileCopyService {
  enum FileCopyError: Error, CustomStringConvertible {
      case invalidSource
      case invalidDestination
      case fileNotFound(String)
      case copyFailed(String)
      case insufficientPermissions
      case invalidPhotoRange
      case unknownError(String)

      var description: String {
          switch self {
          case .invalidSource:
              return "The source folder does not exist."
          case .invalidDestination:
              return "The destination folder does not exist."
          case .fileNotFound(let file):
              return "The file '\(file)' was not found in the source folder."
          case .copyFailed(let file):
              return "Failed to copy the file '\(file)'."
          case .insufficientPermissions:
              return "Insufficient permissions to access or copy files."
          case .invalidPhotoRange:
              return "Please enter a valid photo range."
          case .unknownError(let message):
              return "An unknown error occurred: \(message)"
          }
      }
  }
    
    enum FileCopyResult {
        case success([String]) // Successfully copied files
        case partialSuccess(copiedFiles: [String], missingFiles: [String]) // Some files copied, others missing
        case failure(FileCopyError) // An error occurred
        
        var description: String {
            switch self {
            case .success(let copiedFiles):
              return "Successfully copied files: \(copiedFiles.joined(separator: ", "))"
            case .partialSuccess(let copiedFiles, let missingFiles):
                return "Successfully copied files: \(copiedFiles.joined(separator: ", "))\nFiles not found: \(missingFiles.joined(separator: ", "))"
            case .failure(let error):
                return error.description
            }
        }
    }
    
    static func copyFiles(from source: URL, to destination: URL, files: [String]) -> FileCopyResult {
        var copiedFiles: [String] = []
        var missingFiles: [String] = []
        
        // Ensure both the source and destination are accessible
        if !source.startAccessingSecurityScopedResource() {
            return .failure(.invalidSource)
        }
        defer { source.stopAccessingSecurityScopedResource() }
        
        if !destination.startAccessingSecurityScopedResource() {
            return .failure(.invalidDestination)
        }
        defer { destination.stopAccessingSecurityScopedResource() }
      
      let fileNames = files.map { $0.generatedFileName() }
        
        // Iterate through files to copy
      for file in fileNames {
            let sourceFilePath = source.appendingPathComponent(file)  // Using generatedFileName()
            let destinationFilePath = destination.appendingPathComponent(file)  // Using generatedFileName()
            
            // Check if the file exists in the source folder
            guard FileManager.default.fileExists(atPath: sourceFilePath.path) else {
              missingFiles.append(file)
                continue
            }
            
            // Check if the file already exists in the destination folder
            if FileManager.default.fileExists(atPath: destinationFilePath.path) {
              copiedFiles.append(file) // No need to copy, file exists
                continue
            }
            
            do {
                // Try to copy the file
                try FileManager.default.copyItem(at: sourceFilePath, to: destinationFilePath)
                copiedFiles.append(file)
            } catch let error as NSError {
                if error.domain == NSCocoaErrorDomain && error.code == 513 {
                    // Error code 513 corresponds to permission-related issues
                    return .failure(.insufficientPermissions)
                }
                missingFiles.append(file) // Failed to copy file, mark as missing
            }
        }
        
        if missingFiles.isEmpty {
            return .success(copiedFiles)
        } else {
            return .partialSuccess(copiedFiles: copiedFiles, missingFiles: missingFiles)
        }
    }
}

private extension String {
    func generatedFileName() -> String {
        return "rex-\(self).jpg"
    }
}

private extension Int {
    func generatedFileName() -> String {
        return "rex-\(self).jpg"
    }
}

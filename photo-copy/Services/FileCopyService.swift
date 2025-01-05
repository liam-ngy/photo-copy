import Foundation

enum FileCopyService {
  enum FileCopyError: Error {
    case invalidSource
    case invalidDestination
    case fileNotFound(String)
    case copyFailed(String)
    case insufficientPermissions
    case invalidPhotoRange
    case unknownError(String)
    case customerDirectoryCreationFailed
    case invalidCustomerInput
  }
  
  enum FileCopyResult {
    case success([String])
    case partialSuccess(copiedFiles: [String], missingFiles: [String])
    case failure(FileCopyError)
    
    var description: String {
      let message = FileCopyMessageBuilder.buildMessage(for: self)
      return message
    }
  }
  
  static func copyFiles(from source: URL, to destination: URL, files: [String]) async -> FileCopyResult {
    var copiedFiles: [String] = []
    var missingFiles: [String] = []
    
    // Ensure both the source and destination are accessible
    guard source.startAccessingSecurityScopedResource() else {
      return .failure(.invalidSource)
    }
    defer { source.stopAccessingSecurityScopedResource() }
    
    guard destination.startAccessingSecurityScopedResource() else {
      return .failure(.invalidDestination)
    }
    defer { destination.stopAccessingSecurityScopedResource() }
    
    let fileNames = files.map { "rex-\($0).jpg" }
    
    for file in fileNames {
      let sourceFilePath = source.appendingPathComponent(file)
      let destinationFilePath = destination.appendingPathComponent(file)
      
      guard FileManager.default.fileExists(atPath: sourceFilePath.path) else {
        missingFiles.append(file)
        continue
      }
      
      if FileManager.default.fileExists(atPath: destinationFilePath.path) {
        copiedFiles.append(file)
        continue
      }
      
      do {
        try FileManager.default.copyItem(at: sourceFilePath, to: destinationFilePath)
        copiedFiles.append(file)
      } catch let error as NSError {
        if error.domain == NSCocoaErrorDomain && error.code == 513 {
          // Error code 513 corresponds to permission-related issues
          return .failure(.insufficientPermissions)
        }
        missingFiles.append(file)
      }
    }
    
    if missingFiles.isEmpty {
      return .success(copiedFiles)
    } else if copiedFiles.isEmpty && !missingFiles.isEmpty {
      return .failure(.fileNotFound(missingFiles.joined(separator: ", ")))
    } else {
      return .partialSuccess(copiedFiles: copiedFiles, missingFiles: missingFiles)
    }
  }
}


// MARK: - Error

extension FileCopyService.FileCopyError: CustomStringConvertible {
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
      case .customerDirectoryCreationFailed:
        return "Couldn't create directory"
      case .invalidCustomerInput:
      return "Invalid customer input"
      }
    }

}

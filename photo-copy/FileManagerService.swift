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
        return "The photo range input is invalid."
      case .unknownError(let message):
        return "An unknown error occurred: \(message)"
      }
    }
  }
  
  static func copyFiles(from source: URL, to destination: URL, files: [String]) -> Result<String, FileCopyError> {
    // Ensure both the source and destination are accessible
    if !source.startAccessingSecurityScopedResource() {
      return .failure(.invalidSource)
    }
    defer { source.stopAccessingSecurityScopedResource() }
    
    if !destination.startAccessingSecurityScopedResource() {
      return .failure(.invalidDestination)
    }
    defer { destination.stopAccessingSecurityScopedResource() }
    
    // Iterate through files to copy
    for file in files {
      let sourceFilePath = source.appendingPathComponent(file.generatedFileName())
      let destinationFilePath = destination.appendingPathComponent(file.generatedFileName())
      
      // Check if the file exists in the source folder
      guard FileManager.default.fileExists(atPath: sourceFilePath.path) else {
        return .failure(.fileNotFound(file))
      }
      
      do {
        // Try to copy the file
        try FileManager.default.copyItem(at: sourceFilePath, to: destinationFilePath)
      } catch let error as NSError {
        if error.domain == NSCocoaErrorDomain && error.code == 513 {
          // Error code 513 corresponds to permission-related issues
          return .failure(.insufficientPermissions)
        }
        return .failure(.copyFailed(file.generatedFileName()))
      }
    }
    
    return .success("All files were copied successfully!")
  }
  
  // Parse the range from input
  static func parsePhotoRange(_ input: String) -> [String]? {
    let cleanedInput = input.replacingOccurrences(of: "rex-", with: "")
    
    let components = cleanedInput.split(separator: ",").map { String($0) }
    var fileList: [String] = []
    
    for component in components {
      if let range = parseRange(component) {
        fileList.append(contentsOf: range)
      } else {
        fileList.append(component.generatedFileName())
      }
    }
    
    return fileList.isEmpty ? nil : fileList
  }
  
  private static func parseRange(_ range: String) -> [String]? {
    let bounds = range.split(separator: "-").map { String($0) }
    
    guard bounds.count == 2, let start = Int(bounds[0]), let end = Int(bounds[1]) else {
      return nil
    }
    
    guard start <= end else { return nil }
    
    return (start...end).map { String($0).generatedFileName() }
  }
}

extension String {
  func generatedFileName() -> String {
    return "rex-\(self).jpg"
  }
}

extension Int {
  func generatedFileName() -> String {
    return "rex-\(self).jpg"
  }
}

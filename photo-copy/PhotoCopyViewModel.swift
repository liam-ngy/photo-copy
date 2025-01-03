import Foundation

/// ViewModel responsible for managing the file copy operation
/// in the context of selecting source and destination folders,
/// parsing the photo range input, and handling the copy process.
@MainActor
final class FileCopyViewModel: ObservableObject {
  
  // MARK: - Published Properties
  
  /// The source folder URL where files will be copied from.
  @Published var sourceFolder: URL? {
    didSet {
      // TODO: Handle saving source folder path if needed in future iterations.
    }
  }
  
  /// The destination folder URL where files will be copied to.
  @Published var destinationFolder: URL? {
    didSet {
      // TODO: Handle saving destination folder path if needed in future iterations.
    }
  }
  
  /// A string representing the input photo range or specific photo names to copy.
  @Published var photoInput: String = ""
  
  /// Boolean flag to indicate if the copy operation is currently in progress.
  @Published var isBusy: Bool = false
  
  /// The result of the file copy operation, either success or failure with error details.
  @Published var result: FileCopyService.FileCopyResult?
  
  // MARK: - Initializer
  
  /// Initializes the view model, potentially loading saved source and destination folder paths.
  init() {
    // Future iteration: Load source and destination folder paths from a persistent storage solution.
    self.sourceFolder = nil
    self.destinationFolder = nil
  }
  
  // MARK: - Public Methods
  
  /// Initiates the file copy operation by validating the source and destination folders,
  /// parsing the photo range, and performing the file copy asynchronously.
  func copyPhotos() {
    // Ensure source and destination folders are set
    guard let source = sourceFolder, let destination = destinationFolder else {
      result = .failure(.invalidSource)
      return
    }
    
    // Parse the input photo range
    let photoRange = parsePhotoRange()
    
    // If no valid photo range is found, return failure
    if photoRange.isEmpty {
      result = .failure(.invalidPhotoRange)
      return
    }
    
    // Perform the file copy operation asynchronously
    Task {
      isBusy = true
      let serviceResult = await FileCopyService.copyFiles(from: source, to: destination, files: photoRange)
      result = serviceResult
      isBusy = false
    }
  }
  
  // MARK: - Private Methods
  
  /// Parses the photo input string into an array of photo names or ranges.
  ///
  /// Example: "1, 2-5, 7" becomes ["1", "2", "3", "4", "5", "7"].
  ///
  /// - Returns: An array of photo names or ranges.
  private func parsePhotoRange() -> [String] {
    var photoList: [String] = []
    
    // Split the input by commas and remove unnecessary whitespace
    let components = photoInput.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    
    for component in components {
      // Check if component is a valid range or single photo number
      if let range = parseRange(component) {
        photoList.append(contentsOf: range)
      } else if let singleValue = Int(component) {
        photoList.append(String(singleValue))
      }
    }
    
    return photoList
  }
  
  /// Parses a single photo range input like "2-5" into an array of photo numbers.
  ///
  /// Example: "2-5" becomes ["2", "3", "4", "5"].
  ///
  /// - Parameter range: A string representing a range of photo numbers.
  /// - Returns: An array of strings representing the individual photo numbers in the range, or `nil` if invalid.
  private func parseRange(_ range: String) -> [String]? {
    let bounds = range.split(separator: "-").map { String($0) }
    
    // Ensure there are two bounds and they are valid numbers
    guard bounds.count == 2, let start = Int(bounds[0]), let end = Int(bounds[1]), start <= end else {
      return nil
    }
    
    return (start...end).map { String($0) }
  }
}

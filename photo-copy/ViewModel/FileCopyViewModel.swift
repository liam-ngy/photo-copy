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
  
  @Published var baseDestinationFolder: URL?
  
  @Published var customerInput: String = "" {
      didSet {
          if customerInput.isEmpty {
              clearDestination()
          }
        
        result = nil
      }
  }
  
  private var customerDirBookmark: Data?
  private let fileManager: FileManaging
  
  // MARK: - Initializer
  
  /// Initializes the view model, potentially loading saved source and destination folder paths.
  init(fileManager: FileManaging = SecureFileManager()) {
    // Future iteration: Load source and destination folder paths from a persistent storage solution.
    self.sourceFolder = nil
    self.destinationFolder = nil
    self.fileManager = fileManager
  }
  
  // MARK: - Public Methods
  
  func selectExistingCustomer(_ customerDir: String) {
      guard let baseDestination = baseDestinationFolder else { return }
      
      switch fileManager.getDirectory(at: baseDestination, withName: customerDir) {
      case .success(let secureURL):
          destinationFolder = secureURL
          customerInput = customerDir
      case .failure(let error):
          result = .failure(error)
      }
  }
  
  func getExistingCustomers() -> [String] {
      guard let baseDestination = baseDestinationFolder else { return [] }
      
      switch fileManager.listContents(of: baseDestination) {
      case .success(let customers):
          return customers
      case .failure:
          return []
      }
  }
  
  func clearCustomer() {
      customerInput = ""
      // clearDestination() will be called by customerInput didSet
  }
  
  
  // Add new function for customer directory
  func createCustomerDirectory() {
      guard let baseDestination = baseDestinationFolder else {
          result = .failure(.invalidDestination)
          return
      }
      
      let trimmedInput = customerInput.trimmingCharacters(in: .whitespaces)
      guard !trimmedInput.isEmpty else {
          result = .failure(.invalidCustomerInput)
          return
      }
      
      switch fileManager.createDirectory(at: baseDestination, withName: trimmedInput) {
      case .success(let secureURL):
          destinationFolder = secureURL
          result = .success(["Created directory for \(trimmedInput)"])
      case .failure(let error):
          result = .failure(error)
      }
  }
  
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
  
  /// Parses a single photo range input like "2-5" or "5-1" into an array of photo numbers.
  ///
  /// Example: "2-5" becomes ["2", "3", "4", "5"].
  /// Example: "5-1" becomes ["1", "2", "3", "4", "5"].
  ///
  /// - Parameter range: A string representing a range of photo numbers.
  /// - Returns: An array of strings representing the individual photo numbers in the range, or `nil` if invalid.
  private func parseRange(_ range: String) -> [String]? {
      let bounds = range.split(separator: "-").map { String($0) }
      
      // Ensure there are two bounds and they are valid numbers
      guard bounds.count == 2, let start = Int(bounds[0]), let end = Int(bounds[1]) else {
          return nil
      }
      
      // Adjust the bounds if the start is greater than the end
      let (startRange, endRange) = start <= end ? (start, end) : (end, start)
      
      return (startRange...endRange).map { String($0) }
  }
  
  private func clearDestination() {
      destinationFolder = nil
  }
}


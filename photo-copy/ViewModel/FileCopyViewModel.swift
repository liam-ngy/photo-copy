import Foundation

/// ViewModel responsible for managing the file copy operation
/// in the context of selecting source and destination folders,
/// parsing the photo range input, and handling the copy process.
@MainActor
final class FileCopyViewModel: ObservableObject {
  
  // MARK: - Published Properties
  
  /// The source folder URL where files will be copied from.
  @Published var sourceFolder: URL? {
    didSet { updateViewState() }
  }
  
  /// The destination folder URL where files will be copied to.
  @Published var destinationFolder: URL? {
    didSet { updateViewState() }
  }
  
  /// A string representing the input photo range or specific photo names to copy.
  @Published var photoInput: String = ""
  
  /// Boolean flag to indicate if the copy operation is currently in progress.
  @Published private(set) var viewState: PhotoCopyViewState = .initial
  
  /// The result of the file copy operation, either success or failure with error details.
  @Published var result: FileCopyService.FileCopyResult?
  
  @Published var baseDestinationFolder: URL? {
    didSet { updateViewState() }
  }
  
  @Published var customerInput: String = "" {
    didSet {
      if customerInput.isEmpty {
        clearDestination()
      }
      result = nil
    }
  }
  
  // MARK: - Private Properties
  
  private let fileManager: FileManaging
  
  // MARK: - Computed Properties
  
  var isBusy: Bool {
    viewState == .copying
  }
  
  var shouldFocusCustomerInput: Bool {
    viewState == .customerInputRequired
  }
  
  var shouldFocusPhotoInput: Bool {
    viewState == .photoInputRequired
  }
  
  // MARK: - Initializer
  
  /// Initializes the view model, potentially loading saved source and destination folder paths.
  init(fileManager: FileManaging = SecureFileManager()) {
    // Future iteration: Load source and destination folder paths from a persistent storage solution.
    self.sourceFolder = nil
    self.destinationFolder = nil
    self.fileManager = fileManager
  }
  
  // MARK: - Public Methods
  
  func updateCustomerInput(_ input: String) {
    customerInput = input
  }
  
  func getExistingCustomers() -> [String] {
    guard let baseDestination = baseDestinationFolder else { return [] }
    
    switch fileManager.listContents(of: baseDestination) {
    case .success(let customers):
      return customers.sorted()
    case .failure:
      return []
    }
  }
  
  func selectExistingCustomer(_ customerDir: String) async -> Result<Void, FileCopyService.FileCopyError> {
    guard let baseDestination = baseDestinationFolder else {
      return .failure(.invalidDestination)
    }
    
    switch fileManager.getDirectory(at: baseDestination, withName: customerDir) {
    case .success(let secureURL):
      destinationFolder = secureURL
      customerInput = customerDir
      return .success(())
    case .failure(let error):
      return .failure(error)
    }
  }
  
  func createCustomerDirectory() async -> Result<Void, FileCopyService.FileCopyError> {
    guard let baseDestination = baseDestinationFolder else {
      return .failure(.invalidDestination)
    }
    
    let trimmedInput = customerInput.trimmingCharacters(in: .whitespaces)
    guard !trimmedInput.isEmpty else {
      return .failure(.invalidCustomerInput)
    }
    
    switch fileManager.createDirectory(at: baseDestination, withName: trimmedInput) {
    case .success(let secureURL):
      destinationFolder = secureURL
      return .success(())
    case .failure(let error):
      return .failure(error)
    }
  }
  
  func clearCustomer() {
    customerInput = ""
    clearDestination()
  }
  
  func copyPhotos() async -> Result<FileCopyService.FileCopyResult, FileCopyService.FileCopyError> {
    guard let source = sourceFolder,
          let destination = destinationFolder else {
      return .failure(.invalidSource)
    }
    
    let photoRange = parsePhotoRange()
    if photoRange.isEmpty {
      return .failure(.invalidPhotoRange)
    }
    
    viewState = .copying
    
    let result = await FileCopyService.copyFiles(
      from: source,
      to: destination,
      files: photoRange
    )
    
    self.result = result
    viewState = .completed(result)
    return .success(result)
  }
  
  // MARK: - Private Methods
  
  private func updateViewState() {
    viewState = computeViewState()
  }
  
  private func computeViewState() -> PhotoCopyViewState {
    switch (sourceFolder, baseDestinationFolder, destinationFolder) {
    case (nil, _, _):
      return .initial
    case (_, nil, _):
      return .sourceSelected
    case (_, _, nil):
      return .customerInputRequired
    case (_, _, .some):
      return .photoInputRequired
    }
  }
  
  private func clearDestination() {
    destinationFolder = nil
  }
  
  private func parsePhotoRange() -> [String] {
    var photoList: [String] = []
    let components = photoInput.split(separator: ",")
      .map { String($0).trimmingCharacters(in: .whitespaces) }
    
    for component in components {
      if let range = parseRange(component) {
        photoList.append(contentsOf: range)
      } else if let singleValue = Int(component) {
        photoList.append(String(singleValue))
      }
    }
    
    return photoList
  }
  
  private func parseRange(_ range: String) -> [String]? {
    let bounds = range.split(separator: "-").map { String($0) }
    
    guard bounds.count == 2,
          let start = Int(bounds[0]),
          let end = Int(bounds[1]) else {
      return nil
    }
    
    let (startRange, endRange) = start <= end ? (start, end) : (end, start)
    return (startRange...endRange).map { String($0) }
  }
}


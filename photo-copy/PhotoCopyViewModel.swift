import Foundation
import SwiftUI

enum FileCopyResult: CustomStringConvertible {
    case success(String)
    case failure(String)
    
    var description: String {
        switch self {
        case .success(let message):
            return message
        case .failure(let error):
            return error
        }
    }
}

class FileCopyViewModel: ObservableObject {
    @Published var sourceFolder: URL?
    @Published var destinationFolder: URL?
    @Published var photoInput: String = ""
    @Published var isBusy: Bool = false
    @Published var result: FileCopyResult? // Unified result type

    func copyPhotos() {
        guard let source = sourceFolder, let destination = destinationFolder else {
            result = .failure("Please select both source and destination folders.")
            return
        }

        let photoRange = parsePhotoRange()
        if photoRange.isEmpty {
            result = .failure("Please enter a valid photo range.")
            return
        }

        isBusy = true
        let serviceResult = FileCopyService.copyFiles(from: source, to: destination, files: photoRange)
        
        switch serviceResult {
        case .success:
            result = .success("Files were successfully copied!")
        case .failure(let error):
            result = .failure(error.description)
        }
        
        isBusy = false
    }

  private func parsePhotoRange() -> [String] {
      var photoList: [String] = []
      
      let components = photoInput.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
      
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
      
      guard bounds.count == 2, let start = Int(bounds[0]), let end = Int(bounds[1]), start <= end else {
          return nil
      }
      
      return (start...end).map { String($0) }
  }
}

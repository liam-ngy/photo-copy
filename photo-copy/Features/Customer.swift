import Foundation
struct Customer: Identifiable, Hashable, Equatable {
  let id: UUID  // Unique identifier for each customer
  let name: String // Folder name
  let url: URL    // Folder path
  
  init(id: UUID = UUID(), name: String, url: URL) {
    self.id = id
    self.name = name
    self.url = url
  }
  
  func hash(into hasher: inout Hasher) {
    // Hash based on same properties we use for equality
    hasher.combine(url)
    hasher.combine(name)
  }
  static func == (lhs: Customer, rhs: Customer) -> Bool {
      lhs.url == rhs.url && lhs.name == rhs.name
  }
}

extension Customer {
  init(url: URL) {
    self.url = url
    self.id = UUID()
    self.name = url.lastPathComponent
  }
}

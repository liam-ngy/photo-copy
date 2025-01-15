enum Folder: String, CaseIterable, Identifiable {
  case pax
  case finals
  
  var id: String { self.rawValue }
  
  var displayName: String {
    switch self {
    case .pax:
      return "pax"
    case .finals:
      return "finals"
    }
  }
}


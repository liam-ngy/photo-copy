/// Represents the different states of the photo copying workflow.
enum PhotoCopyViewState: Equatable {
    case initial
    case sourceSelected
    case destinationSelected
    case customerInputRequired
    case photoInputRequired
    case copying
    case completed(FileCopyService.FileCopyResult)
    
    var isCompleted: Bool {
        if case .completed = self {
            return true
        }
        return false
    }
    
    static func == (lhs: PhotoCopyViewState, rhs: PhotoCopyViewState) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial),
             (.sourceSelected, .sourceSelected),
             (.destinationSelected, .destinationSelected),
             (.customerInputRequired, .customerInputRequired),
             (.photoInputRequired, .photoInputRequired),
             (.copying, .copying):
            return true
        case (.completed(let lhsResult), .completed(let rhsResult)):
            switch (lhsResult, rhsResult) {
            case (.success, .success),
                 (.failure, .failure):
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}

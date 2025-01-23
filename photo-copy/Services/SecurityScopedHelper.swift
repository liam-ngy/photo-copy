import Foundation

struct SecurityScopedHelper {
  static func access<T>(_ url: URL, operation: () -> Result<T, FileCopyService.FileCopyError>)
    -> Result<T, FileCopyService.FileCopyError>
  {
    guard url.startAccessingSecurityScopedResource() else {
      return .failure(.insufficientPermissions)
    }

    defer {
      url.stopAccessingSecurityScopedResource()
    }

    return operation()
  }

  static func createSecureBookmark(for url: URL) -> Result<URL, FileCopyService.FileCopyError> {
    // If URL already has security scope, just return it
    if url.startAccessingSecurityScopedResource() {
      //url.stopAccessingSecurityScopedResource()
      return .success(url)
    }

    do {
      let bookmark = try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )

      var isStale = false
      let secureURL = try URL(
        resolvingBookmarkData: bookmark,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      return .success(secureURL)
    } catch {
      return .failure(.insufficientPermissions)
    }
  }
}

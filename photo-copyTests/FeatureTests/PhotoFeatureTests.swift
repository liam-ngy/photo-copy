import Testing
import ComposableArchitecture
import Foundation
@testable import photo_copy

@Suite("PhotoFeature Tests")
struct PhotoFeatureTests {
  @Test("Initial state should be properly configured")
  func testInitialState() async {
    let store = await TestStore(initialState: PhotoFeature.State()) {
      PhotoFeature()
    }
    
    await store.assert { state in
      #expect(state.canCopyPhotos == false)
    }
  }
}

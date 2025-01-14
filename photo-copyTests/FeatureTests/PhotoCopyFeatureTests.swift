import Testing
import ComposableArchitecture
import Foundation
@testable import photo_copy

struct PhotoCopyFeatureTests {
  @Test("Initial state should have create directory disabled")
  func testInitialState() async {
    let store = await TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }
    
    await #expect(store.state.customerInput == "")
    await #expect(store.state.hasValidCustomerInput == false)
    await #expect(store.state.paxFolder == nil)
    await #expect(store.state.canCreateCustomerDirectory == false)
  }
  
  @Test("Customer input alone should not enable directory creation")
  func testCustomerInputOnly() async {
    let store = await TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }
    
    await store.send(.updateCustomerInput("69 Test")) {
      $0.customerInput = "69 Test"
    }
    await #expect(store.state.canCreateCustomerDirectory == false)
  }
  
  @Test("Base destination alone should not enable directory creation")
  func testBaseDestinationOnly() async {
    let store = await TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }
    
    let testURL = URL(fileURLWithPath: "/test/path")
    await store.send(.setPaxFolder(testURL)) {
      $0.paxFolder = testURL
    }
    
    await store.receive(.loadExistingCustomers)
    await store.receive(.existingCustomersLoaded([]))

    await #expect(store.state.canCreateCustomerDirectory == false)
  }
  
  @Test("Both valid input and destination should enable directory creation")
  func testValidInputAndDestination() async {
    let store = await TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }
    
    let testURL = URL(fileURLWithPath: "/test/path")
    await store.send(.setPaxFolder(testURL)) {
      $0.paxFolder = testURL
    }
    
    await store.receive(.loadExistingCustomers)
    await store.receive(.existingCustomersLoaded([]))
    
    await store.send(.updateCustomerInput("69 Test")) {
      $0.customerInput = "69 Test"
    }
    await #expect(store.state.canCreateCustomerDirectory == true)
  }
  
  @Test("Directory creation should succeed with valid inputs")
  func testDirectoryCreationSuccess() async {
    _ = await TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.fileManager.createDirectory = { baseURL, name in
        let newURL = baseURL.appendingPathComponent(name)
        return .success(newURL)
      }
    }
  }
  
  @Test("Directory creation should fail with invalid permissions")
  func testDirectoryCreationFailure() async {
    _ = await TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.fileManager.createDirectory = { _, _ in
          .failure(.insufficientPermissions)
      }
    }
  }
  
  @Test("Empty customer input should fail immediately")
  func testEmptyCustomerInput() async {
    let _ = await TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }
  }
  
  @Test("Clear customer should reset customer-related state")
  func testClearCustomer() async {
    let store = await TestStore(initialState: AppFeature.State(
      paxFolder: URL(fileURLWithPath: "/test/path"),
      destinationFolder: URL(fileURLWithPath: "/test/path/69 Test"),
      customerInput: "69 Test"
    )) {
      AppFeature()
    }
    
    // Verify initial state
    await #expect(store.state.isCustomerDirectoryCreated == true)
    await #expect(store.state.customerInput == "69 Test")
    
    // Send clear action
    await store.send(.clearCustomer) {
      $0.destinationFolder = nil
      $0.customerInput = ""
    }
    
    // Verify cleared state
    await #expect(store.state.isCustomerDirectoryCreated == false)
    await #expect(store.state.shouldShowCustomerInput == true)
  }
}

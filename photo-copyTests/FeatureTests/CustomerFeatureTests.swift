import Testing
import ComposableArchitecture
import Foundation
@testable import photo_copy

@Suite("CustomerFeature Tests")
struct CustomerFeatureTests {
  @Test("Initial state should be properly configured")
  func testInitialState() async {
    let store = await TestStore(initialState: CustomerFeature.State()) {
      CustomerFeature()
    }
    
    await store.assert { state in
      #expect(state.$paxFolder.wrappedValue == nil)
      #expect(state.$customerFolder.wrappedValue == nil)
      #expect(state.selectedCustomer == nil)
      #expect(state.existingCustomers.isEmpty)
      #expect(state.customerInput.isEmpty)
      #expect(!state.hasValidCustomerInput)
      #expect(!state.customerFolderIsSet)
      #expect(!state.canCreateCustomerDirectory)
      #expect(state.shouldShowCustomerInput)
    }
  }
  
  @Test("Can load existing customers")
  func testLoadExistingCustomers() async {
    let paxURL = URL(fileURLWithPath: "/test/pax")
    let customer1URL = paxURL.appendingPathComponent("customer1")
    let customer2URL = paxURL.appendingPathComponent("customer2")
    
    // Create customers first so we have stable IDs
    let customer1 = Customer(url: customer1URL)
    let customer2 = Customer(url: customer2URL)
    
    var initialState = CustomerFeature.State()
    initialState.$paxFolder.withLock { $0 = paxURL }
    initialState.existingCustomers = [customer1, customer2]
    
    let store = await TestStore(initialState: initialState) {
      CustomerFeature()
    } withDependencies: {
      $0.fileManager.listContents = { url in
        return .success([customer1URL, customer2URL])
      }
    }
    
    await store.send(.loadExistingCustomers)
    await store.receive(.existingCustomersLoaded([customer1, customer2]))
  }
  
  @Test("Loading customers handles directory failure")
  func testLoadCustomersFailure() async {
    let paxURL = URL(fileURLWithPath: "/test/pax")
    
    let initialState = CustomerFeature.State()
    initialState.$paxFolder.withLock { $0 = paxURL }
    
    let store = await TestStore(initialState: initialState) {
      CustomerFeature()
    } withDependencies: {
      $0.fileManager.listContents = { url in
        return .failure(.insufficientPermissions)
      }
    }
    
    await store.send(.loadExistingCustomers)
    await store.receive(.customerDirectoryFailed(.insufficientPermissions))
  }
  
  @Test("Can create new customer")
  func testCreateNewCustomer() async {
    let paxURL = URL(fileURLWithPath: "/test/pax")
    let newCustomerURL = paxURL.appendingPathComponent("123Test")
    
    var initialState = CustomerFeature.State()
    initialState.$paxFolder.withLock { $0 = paxURL }
    initialState.customerInput = "123 Test"
    
    let store = await TestStore(initialState: initialState) {
      CustomerFeature()
    } withDependencies: {
      $0.fileManager.createDirectory = { _, _ in
        return .success(newCustomerURL)
      }
      $0.fileManager.getDirectory = { _, _ in
        return .success(newCustomerURL)
      }
      $0.fileManager.listContents = { _ in
        return .success([newCustomerURL])
      }
    }
    
    Task { @MainActor in
      store.exhaustivity = .off
    }
    
    let newCustomer = Customer(url: newCustomerURL)
    
    await store.send(.didTapCreateCustomer)
    
    await store.receive(.loadExistingCustomers) {
      $0.$customerFolder.withLock { $0 = newCustomerURL }
    }
    
    await store.receive(.selectCustomer(newCustomer)) {
      $0.selectedCustomer = newCustomer
      $0.customerInput = ""
    }
    
    await store.receive(.existingCustomersLoaded([newCustomer])) {
      $0.existingCustomers = [newCustomer]
    }
  }
  
  @Test("Can select existing customer")
  func testSelectExistingCustomer() async {
    let paxURL = URL(fileURLWithPath: "/test/pax")
    let customerURL = paxURL.appendingPathComponent("existingCustomer")
    let existingCustomer = Customer(url: customerURL)
    
    var initialState = CustomerFeature.State()
    initialState.$paxFolder.withLock { $0 = paxURL }
    initialState.existingCustomers = [existingCustomer]
    
    let store = await TestStore(initialState: initialState) {
      CustomerFeature()
    } withDependencies: {
      $0.fileManager.getDirectory = { _, _ in
        return .success(customerURL)
      }
      $0.fileManager.listContents = { _ in
        return .success([customerURL])
      }
    }
    
    await store.send(.didSelectExistingCustomer(existingCustomer.id))
    
    await store.receive(.selectCustomer(existingCustomer)) {
      $0.customerInput = ""
      $0.$customerFolder.withLock { $0 = customerURL }
      $0.selectedCustomer = existingCustomer
    }
    
    await store.receive(.setCustomerFolder(customerURL))
    
    await store.receive(.loadExistingCustomers)
    
    await store.receive(.existingCustomersLoaded([existingCustomer]))
  }
}

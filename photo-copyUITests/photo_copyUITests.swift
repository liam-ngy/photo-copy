//import XCTest
//
//final class photo_copyUITests: XCTestCase {
//
//  var app: XCUIApplication!
//
//  override func setUpWithError() throws {
//    continueAfterFailure = false
//    app = XCUIApplication() // Use your macOS app bundle identifier
//    app.launch()
//  }
//
//  override func tearDownWithError() throws {
//    app?.terminate()
//    app = nil
//  }
//
//  func testChooseButtonExists() throws {
//    let chooseFolderButton = app.buttons["Choose..."]
//    XCTAssertTrue(chooseFolderButton.exists, "Choose button should exist.")
//    XCTAssertTrue(chooseFolderButton.isEnabled, "Choose button should be enabled.")
//  }
//
//  func testNewCustomerCreation() throws {
//    let customerInput = app.textFields["Enter customer safety number and name"]
//    let createButton = app.buttons["Create"]
//
//    customerInput.tap()
//    customerInput.typeText("123 Test Customer")
//
//    XCTAssertTrue(createButton.isEnabled, "Create button should be enabled after entering customer details.")
//    createButton.tap()
//
//    let customerMenu = app.menus["Selected Customer: 123 Test Customer"]
//    XCTAssertTrue(customerMenu.exists, "Customer menu should display the newly created customer.")
//  }
//}

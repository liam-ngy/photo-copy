import Testing
import ComposableArchitecture
import Foundation
@testable import photo_copy

@Suite("FolderFeature Tests")
struct FolderFeatureTests {
  
  @Test("Initial state should have no folders set")
  func initialState() async throws {
    let store = await TestStore(initialState: FolderFeature.State()) {
      FolderFeature()
    }
    
    await store.assert { state in
      #expect(state.baseFolder == nil)
      #expect(state.$finalsFolder.wrappedValue == nil)
      #expect(state.$paxFolder.wrappedValue == nil)
      #expect(state.folderErrorMessages.isEmpty)
      #expect(!state.hasFolderErrorMessages)
    }
  }
  
  @Test("Setting base folder triggers folder loading")
  func testSetBaseFolder() async {
    let baseURL = URL(fileURLWithPath: "/test/base")
    let paxURL = baseURL.appendingPathComponent("pax")
    let finalsURL = baseURL.appendingPathComponent("finals")
    
    let initialState = FolderFeature.State()
    
    let store = await TestStore(initialState: initialState) {
      FolderFeature()
    } withDependencies: {
      $0.fileManager.secureBaseFolder =  { url in
        return .success(url)
      }
      
      $0.fileManager.getDirectory = { url, folderName in
        switch folderName {
        case "pax":
          return .success(paxURL)
        case "finals":
          return .success(finalsURL)
        default:
          return .failure(.directoryNotFound(folderName))
        }
      }
    }
    
    await store.send(.setBaseFolder(baseURL))
    await store.receive(.loadFolders(baseURL)) {
      $0.baseFolder = baseURL
      $0.$paxFolder.withLock { $0 = paxURL }
      $0.$finalsFolder.withLock { $0 = finalsURL }
    }
    
    await store.receive(.setPaxFolder(paxURL))
    await store.receive(.setFinalsFolder(finalsURL))
  }
  
  @Test("Loading folders handles missing pax folder")
  func testLoadFoldersMissingPax() async {
    let baseURL = URL(fileURLWithPath: "/test/base")
    let finalsURL = baseURL.appendingPathComponent("finals")
    
    let store = await TestStore(initialState: FolderFeature.State()) {
      FolderFeature()
    } withDependencies: {
      $0.fileManager.secureBaseFolder =  { url in
        return .success(url)
      }
      
      $0.fileManager.getDirectory = { url, folderName in
        switch folderName {
        case "pax":
          return .failure(.directoryNotFound("pax"))
        case "finals":
          return .success(finalsURL)
        default:
          return .failure(.directoryNotFound(folderName))
        }
      }
    }
    
    await store.send(.setBaseFolder(baseURL))
    
    await store.receive(.loadFolders(baseURL)) {
      $0.baseFolder = baseURL
      $0.$finalsFolder.withLock { $0 = finalsURL }
    }
    
    await store.receive(.requiredFoldersFailed(
      folder: .pax,
      error: .directoryNotFound("pax")
    )) {
      $0.folderErrorMessages.append("Failed to set pax folder: Couldn't find directory pax")
    }
    
    await store.receive(.setFinalsFolder(finalsURL))
  }
  
  @Test("Loading folders handles missing finals folder")
  func testLoadFoldersMissingFinals() async {
    let baseURL = URL(fileURLWithPath: "/test/base")
    let paxURL = baseURL.appendingPathComponent("pax")
    
    let store = await TestStore(initialState: FolderFeature.State()) {
      FolderFeature()
    } withDependencies: {
      $0.fileManager.secureBaseFolder = { .success($0) }
      
      $0.fileManager.getDirectory = { url, folderName in
        switch folderName {
        case "pax":
          return .success(paxURL)
        case "finals":
          return .failure(.directoryNotFound("finals"))
        default:
          return .failure(.directoryNotFound(folderName))
        }
      }
    }
    
    await store.send(.setBaseFolder(baseURL))
    
    await store.receive(.loadFolders(baseURL)) {
      $0.baseFolder = baseURL
      $0.$paxFolder.withLock { $0 = paxURL }
    }
    
    await store.receive(.setPaxFolder(paxURL))
    
    await store.receive(.requiredFoldersFailed(
      folder: .finals,
      error: .directoryNotFound("finals")
    )) {
      $0.folderErrorMessages.append("Failed to set finals folder: Couldn't find directory finals")
    }
  }
  
  @Test("Can clear folder error messages")
  func testClearFolderErrorMessages() async {
    var initialState = FolderFeature.State()
    initialState.folderErrorMessages = [
      "Failed to set pax folder: Couldn't find directory pax",
      "Failed to set finals folder: Couldn't find directory finals"
    ]
    
    let store = await TestStore(initialState: initialState) {
      FolderFeature()
    }
    
    await store.send(.clearFolderErrorMessages) {
      $0.folderErrorMessages = []
    }
  }
  
  @Test("Loading folders handles both folders missing")
  func testLoadFoldersBothMissing() async {
    let baseURL = URL(fileURLWithPath: "/test/base")
    
    let store = await TestStore(initialState: FolderFeature.State()) {
      FolderFeature()
    } withDependencies: {
      $0.fileManager.secureBaseFolder = { .success($0) }
      $0.fileManager.getDirectory = { url, folderName in
        switch folderName {
        case "pax", "finals":
          return .failure(.directoryNotFound(folderName))
        default:
          return .failure(.directoryNotFound(folderName))
        }
      }
    }
    
    await store.send(.setBaseFolder(baseURL))
    
    await store.receive(.loadFolders(baseURL)) {
      $0.baseFolder = baseURL
    }
    
    await store.receive(.requiredFoldersFailed(
      folder: .pax,
      error: .directoryNotFound("pax")
    )) {
      $0.folderErrorMessages.append("Failed to set pax folder: Couldn't find directory pax")
    }
    
    await store.receive(.requiredFoldersFailed(
      folder: .finals,
      error: .directoryNotFound("finals")
    )) {
      $0.folderErrorMessages.append("Failed to set finals folder: Couldn't find directory finals")
    }
  }
  
  @Test("didPressChooseBase returns none as it's handled by AppFeature")
  func testDidPressChooseBase() async {
      let store = await TestStore(initialState: FolderFeature.State()) {
          FolderFeature()
      }
      
      await store.send(.didPressChooseBase(URL(fileURLWithPath: "/test")))
  }
  
//  @Test("Cannot load folders when base folder is nil")
//  func testLoadFoldersWithNilBase() async {
//      let store = await TestStore(initialState: FolderFeature.State()) {
//          FolderFeature()
//      } withDependencies: {
//          $0.fileManager.getDirectory = { url, folderName in
//            Issue.record("Should not attempt to get directory when base folder is nil")
//            return .failure(.directoryNotFound(folderName))
//          }
//      }
//      
//      await store.send(.loadFolders(URL(fileURLWithPath: "/test")))
//      
//      await store.receive(.requiredFoldersFailed(
//          folder: .pax,
//          error: .directoryNotFound("pax")
//      )) {
//          $0.folderErrorMessages.append("Failed to set pax folder: The source folder does not exist.")
//      }
//    
//    await store.receive(.requiredFoldersFailed(
//        folder: .finals,
//        error: .directoryNotFound("finals")
//    )) {
//        $0.folderErrorMessages.append("Failed to set finals folder: Couldn't find directory folder")
//    }
//  }
}

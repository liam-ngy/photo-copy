import Testing
import ComposableArchitecture
import Foundation
@testable import photo_copy

struct PhotoInputParserTests {
    @Test("Parse single photo number")
    func testSinglePhoto() {
        let result = PhotoInputParser.parseToFileNames("1")
        #expect(result == .success(["rex-1.jpg"]))
    }
    
    @Test("Parse photo range")
    func testPhotoRange() {
        let result = PhotoInputParser.parseToFileNames("1-3")
        #expect(result == .success([
            "rex-1.jpg",
            "rex-2.jpg",
            "rex-3.jpg"
        ]))
    }
    
    @Test("Parse mixed input")
    func testMixedInput() {
        let result = PhotoInputParser.parseToFileNames("1, 3-5, 7")
        #expect(result == .success([
            "rex-1.jpg",
            "rex-3.jpg",
            "rex-4.jpg",
            "rex-5.jpg",
            "rex-7.jpg"
        ]))
    }
    
    @Test("Handle overlapping ranges")
    func testOverlappingRanges() {
        let result = PhotoInputParser.parseToFileNames("1-10, 5-20")
        #expect(result == .success([
            "rex-1.jpg", "rex-2.jpg", "rex-3.jpg", "rex-4.jpg", "rex-5.jpg",
            "rex-6.jpg", "rex-7.jpg", "rex-8.jpg", "rex-9.jpg", "rex-10.jpg",
            "rex-11.jpg", "rex-12.jpg", "rex-13.jpg", "rex-14.jpg", "rex-15.jpg",
            "rex-16.jpg", "rex-17.jpg", "rex-18.jpg", "rex-19.jpg", "rex-20.jpg"
        ]))
    }
    
    @Test("Handle complex mixed input with duplicates")
    func testComplexMixedInput() {
        let result = PhotoInputParser.parseToFileNames("1, 1-5, 3, 4-8, 7-10")
        #expect(result == .success([
            "rex-1.jpg", "rex-2.jpg", "rex-3.jpg", "rex-4.jpg", "rex-5.jpg",
            "rex-6.jpg", "rex-7.jpg", "rex-8.jpg", "rex-9.jpg", "rex-10.jpg"
        ]))
    }
    
    @Test("Empty input should return error")
    func testEmptyInput() {
        let result = PhotoInputParser.parseToFileNames("  ")
        #expect(result == .failure(.emptyInput))
    }
    
    @Test("Invalid format should return error")
    func testInvalidFormat() {
        #expect(PhotoInputParser.parseToFileNames("abc") == .failure(.invalidFormat))
        #expect(PhotoInputParser.parseToFileNames("1-a") == .failure(.invalidFormat))
    }
    
    @Test("Negative numbers should return error")
  func testNegativeNumbers() {
      // Single negative number
    #expect(PhotoInputParser.parseToFileNames("-1") == .failure(.invalidFormat))
      
      // Negative number in range
    #expect(PhotoInputParser.parseToFileNames("-1-5") == .failure(.invalidFormat))
    #expect(PhotoInputParser.parseToFileNames("1--5") == .failure(.invalidFormat))
    #expect(PhotoInputParser.parseToFileNames("-1--5") == .failure(.invalidFormat))
      
      // Mixed with valid numbers
    #expect(PhotoInputParser.parseToFileNames("1, -3, 5") == .failure(.invalidFormat))
    #expect(PhotoInputParser.parseToFileNames("1-3, -5-7") == .failure(.invalidFormat))
  }
}

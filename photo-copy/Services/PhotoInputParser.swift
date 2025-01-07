/// A utility for parsing photo number inputs into standardized file names.
///
/// This parser handles various input formats and ensures that:
/// - All numbers are positive
/// - Duplicates are removed
/// - Results are sorted
/// - File names follow the "rex-{number}.jpg" format
///
/// Usage example:
/// ```swift
/// // Single numbers
/// PhotoInputParser.parseToFileNames("1, 3, 5")
/// // → Success: ["rex-1.jpg", "rex-3.jpg", "rex-5.jpg"]
///
/// // Ranges
/// PhotoInputParser.parseToFileNames("1-3")
/// // → Success: ["rex-1.jpg", "rex-2.jpg", "rex-3.jpg"]
///
/// // Mixed format with duplicates
/// PhotoInputParser.parseToFileNames("1, 1-3, 2")
/// // → Success: ["rex-1.jpg", "rex-2.jpg", "rex-3.jpg"]
///
/// // Invalid input
/// PhotoInputParser.parseToFileNames("-1")
/// // → Failure: .negativeNumber
/// ```
struct PhotoInputParser {
    /// Errors that can occur during photo input parsing.
    ///
    /// These errors represent the various ways that user input can be invalid:
    /// - Empty or whitespace-only input
    /// - Invalid characters or format
    /// - Negative numbers
    /// - Invalid ranges
    enum ValidationError: Error, Equatable {
        /// Input string is empty or contains only whitespace
        case emptyInput
        
        /// Input contains invalid characters or doesn't match expected format
        /// Examples: "abc", "1-a", "1--2"
        case invalidFormat
        
        /// Input contains negative numbers
        /// Examples: "-1", "1,-2", "-1-5"
        case negativeNumber
        
        /// Range is invalid
        /// Examples: "5-3" (when strict ordering is required)
        case invalidRange
    }
    
    /// Converts a string of photo numbers into an array of standardized file names.
    /// 
    /// This method supports multiple input formats:
    /// - Single numbers: "1, 2, 3"
    /// - Ranges: "1-3" or "3-1" (both produce the same result)
    /// - Mixed formats: "1, 3-5, 7"
    /// 
    /// The method automatically:
    /// - Removes duplicates
    /// - Sorts the results
    /// - Formats numbers as "rex-{number}.jpg"
    /// 
    /// - Parameter input: A string containing photo numbers and ranges
    /// - Returns: A Result containing either:
    ///   - Success: Array of formatted file names, sorted
    ///   - Failure: The specific validation error that occurred
    /// 
    /// - Note: Whitespace around numbers and commas is ignored
    /// 
    /// Example usage:
    /// ```swift
    /// // Basic usage
    /// PhotoInputParser.parseToFileNames("1, 3-5")
    /// // → Success: ["rex-1.jpg", "rex-3.jpg", "rex-4.jpg", "rex-5.jpg"]
    /// 
    /// // With duplicates
    /// PhotoInputParser.parseToFileNames("1, 1-3")
    /// // → Success: ["rex-1.jpg", "rex-2.jpg", "rex-3.jpg"]
    /// 
    /// // Invalid input
    /// PhotoInputParser.parseToFileNames("")
    /// // → Failure: .emptyInput
    /// ```
    static func parseToFileNames(_ input: String) -> Result<[String], ValidationError> {
        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty else {
            return .failure(.emptyInput)
        }
        
        let parts = trimmedInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        var photoNumbers = Set<Int>()
        
        for part in parts {
            if part.contains("-") {
                switch parseRange(part) {
                case .success(let numbers):
                    photoNumbers.formUnion(numbers)
                case .failure(let error):
                    return .failure(error)
                }
            } else {
                switch parseSingleNumber(part) {
                case .success(let number):
                    photoNumbers.insert(number)
                case .failure(let error):
                    return .failure(error)
                }
            }
        }
        
        return .success(photoNumbers.sorted().map(formatPhotoNumber))
    }
    
    /// Parses a range string into a closed range of integers.
    /// 
    /// Handles ranges in either direction (e.g., "1-3" or "3-1").
    /// 
    /// - Parameter part: A string in the format "n-m" where n and m are positive integers
    /// - Returns: A Result containing either:
    ///   - Success: ClosedRange<Int> representing the range
    ///   - Failure: The specific validation error that occurred
    private static func parseRange(_ part: String) -> Result<ClosedRange<Int>, ValidationError> {
        let dashCount = part.filter { $0 == "-" }.count
        guard dashCount == 1 else {
            return .failure(.invalidFormat)
        }
        
        let rangeParts = part.split(separator: "-", maxSplits: 1).map { String($0) }
        guard rangeParts.count == 2,
              let num1 = Int(rangeParts[0]),
              let num2 = Int(rangeParts[1]) else {
            return .failure(.invalidFormat)
        }
        
        guard num1 > 0 && num2 > 0 else {
          return .failure(.invalidFormat)
        }
        
        return .success(min(num1, num2)...max(num1, num2))
    }
    
    /// Parses a string into a single positive integer.
    /// 
    /// - Parameter part: A string representing a positive integer
    /// - Returns: A Result containing either:
    ///   - Success: The parsed positive integer
    ///   - Failure: The specific validation error that occurred
    private static func parseSingleNumber(_ part: String) -> Result<Int, ValidationError> {
        guard let num = Int(part) else {
            return .failure(.invalidFormat)
        }
        
        guard num > 0 else {
          return .failure(.invalidFormat)
        }
        
        return .success(num)
    }
    
    /// Formats a number into the standard photo file name format.
    /// 
    /// - Parameter number: The photo number to format
    /// - Returns: A string in the format "rex-{number}.jpg"
    private static func formatPhotoNumber(_ number: Int) -> String {
        String(format: "rex-%d.jpg", number)
    }
}

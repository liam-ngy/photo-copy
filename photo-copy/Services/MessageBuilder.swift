final class MessageBuilder {
    private var parts: [String] = []

    /// Adds a title or main heading to the message.
    @discardableResult
    func addTitle(_ title: String) -> Self {
      let copy = self
        copy.parts.append("\(title.uppercased())\n")
        return copy
    }

    /// Adds a key-value pair in a formatted way.
    @discardableResult
    func addKeyValue(_ key: String, value: String) -> Self {
      let copy = self
        copy.parts.append("\(key): \(value)")
        return copy
    }

    /// Adds a simple line of text.
    @discardableResult
    func addLine(_ line: String) -> Self {
      let copy = self
        copy.parts.append(line)
        return copy
    }

    /// Combines all parts into a single message string.
    func build() -> String {
        parts.joined(separator: "\n")
    }
}

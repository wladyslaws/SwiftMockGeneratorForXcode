class LocationConverter {

    private static let newLineCharacterCount = 1

    static func convert(line: Int, column: Int, in string: String) -> Int64? {
        let zeroBasedLine = line - 1
        var lines = string.components(separatedBy: .newlines)
        lines = appendNewlines(to: lines)
        guard areLineAndColumnValid(zeroBasedLine, column, in: lines) else { return nil }
        return findOffset(atLine: zeroBasedLine, atColumn: column, in: lines)
    }

    private static func appendNewlines(to lines: [String]) -> [String] {
        return lines.enumerated().map { i, line in
            let isLastLine = lines.count - 1 == i
            if isLastLine {
                return line
            }
            return line + "\n"
        }
    }

    private static func findOffset(atLine line: Int, atColumn column: Int, in lines: [String]) -> Int64? {
        var offset = getOffset(atLine: line, in: lines)
        var columnCount = 0
        for character in lines[line].unicodeScalars {
            if columnCount == column {
                return offset
            }
            columnCount += 1
            offset += getOffset(character)
        }
        return nil
    }

    private static func areLineAndColumnValid(_ line: Int, _ column: Int, in lines: [String]) -> Bool {
        return 0 <= line && line < lines.count && 0 <= column
    }

    private static func getOffset(atLine line: Int, in lines: [String]) -> Int64 {
        return lines[..<line].reduce(0, addCharacters)
    }

    private static func addCharacters(count: Int64, string: String) -> Int64 {
        return count + Int64(string.utf8.count)
    }

    private static func getOffset(_ character: UnicodeScalar) -> Int64 {
        return Int64(String(character).utf8.count)
    }

    static func convert(caretOffset: Int64, in string: String) -> (line: Int, column: Int)? {
        guard isOffsetValid(Int(caretOffset), in: string) else { return nil }
        let strings = string.components(separatedBy: .newlines)
        var remainingOffset = Int(caretOffset)
        let zeroBasedLine = findLineNumber(inLines: strings, remainingOffset: &remainingOffset)
        let column = findColumnNumber(inLine: strings[zeroBasedLine], remainingOffset: &remainingOffset)
        let line = zeroBasedLine + 1
        return (line, column)
    }

    private static func isOffset(_ remainingOffset: Int, containedIn stringLength: Int) -> Bool {
        return remainingOffset - stringLength < 0
    }

    private static func isOffsetValid(_ offset: Int, in string: String) -> Bool {
        return 0 <= offset && offset <= string.utf8.count
    }

    private static func findLineNumber(inLines lines: [String], remainingOffset: inout Int) -> Int {
        var lineNumber = 0
        for line in lines {
            let stringLength = line.utf8.count + newLineCharacterCount
            if isOffset(remainingOffset, containedIn: stringLength) {
                break
            }
            remainingOffset -= stringLength
            lineNumber += 1
        }
        return lineNumber
    }

    private static func findColumnNumber(inLine line: String, remainingOffset: inout Int) -> Int {
        var columnNumber = 0
        for character in line.unicodeScalars {
            let charLength = String(character).utf8.count
            if isOffset(remainingOffset, containedIn: charLength) {
                break
            }
            remainingOffset -= charLength
            columnNumber += 1
        }
        return columnNumber
    }

}

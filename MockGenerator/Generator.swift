import Foundation
// TODO: remove testable when API becomes more clear
@testable import SwiftStructureInterface

public class Generator {

    public static func generateMock(fromFileContents contents: String, projectURL: URL, line: Int, column: Int) -> ([String]?, Error?) {
        // TODO: put files elsewhere
        ResolveUtil.files = SourceFileFinder(projectRoot: projectURL).findSourceFiles()
        guard let file = SKElementFactory().build(from: contents) else {
            return reply(with: "Could not parse Swift file")
        }
        guard let cursorOffset = LocationConverter.convert(line: line, column: column, in: contents) else {
            return reply(with: "Could not get the cursor position")
        }
        guard let elementUnderCaret = CaretUtil().findElementUnderCaret(in: file, cursorOffset: cursorOffset) else {
            return reply(with: "No Swift element found under the cursor")
        }
        guard let typeElement = (elementUnderCaret as? SwiftTypeElement) ?? ElementTreeUtil().findParentType(elementUnderCaret) else {
            return reply(with: "Place the cursor on a mock class declaration")
        }
        guard let inheritedType = typeElement.inheritedTypes.first else {
            return reply(with: "Could not find a protocol on \(typeElement.name)")
        }
        guard let resolved = ResolveUtil().resolve(inheritedType) else {
            return reply(with: "\(inheritedType.name) element could not be resolved")
        }
        return buildMock(toFile: file, atElement: typeElement, resolvedProtocol: resolved)
    }
    
    private static func reply(with message: String) -> ([String]?, Error?) {
        let nsError = NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey : message])
        return (nil, nsError)
    }
    
    private static func buildMock(toFile file: Element, atElement element: SwiftTypeElement, resolvedProtocol: Element) -> ([String]?, Error?) {
        let mockLines = getMockBody(fromResolvedProtocol: resolvedProtocol)
        guard let (newFile, newTypeElement) = delete(contentsOf: element) else {
            return reply(with: "Could not delete body from: \(element.text)")
        }
        let fileLines = insert(mockLines, atTypeElement: newTypeElement, in: newFile)
        return (format(fileLines), nil)
    }
    
    private static func getMockBody(fromResolvedProtocol resolvedProtocol: Element) -> [String] {
        let environment = JavaEnvironment.shared
        let generator = JavaXcodeMockGeneratorBridge(javaEnvironment: environment)
        let visitor = MethodGatheringVisitor(environment: environment)
        resolvedProtocol.accept(RecursiveElementVisitor(visitor: visitor))
        visitor.properties.forEach { generator.addProtocolProperty($0) }
        visitor.methods.forEach { generator.addProtocolMethod($0) }
        let mockString = generator.generate()
        return mockString.components(separatedBy: .newlines)
    }
    
    private static func delete(contentsOf typeElement: SwiftTypeElement) -> (SwiftFile, SwiftTypeElement)? {
        guard let (newFile, newTypeElement) = DeleteBodyUtil().deleteClassBody(from: typeElement) as? (SwiftFile, SwiftTypeElement) else {
            return nil
        }
        return (newFile, newTypeElement)
    }
    
    private static func insert(_ mockBody: [String], atTypeElement typeElement: SwiftTypeElement, in file: Element) -> [String] {
        var fileLines = file.text.components(separatedBy: .newlines)
        let lineColumn = LocationConverter.convert(caretOffset: typeElement.bodyOffset + typeElement.bodyLength, in: file.text)!
        let zeroBasedLine = lineColumn.line - 1
        let insertIndex = zeroBasedLine
        fileLines.insert(contentsOf: mockBody, at: insertIndex)
        return fileLines
    }
    
    private static func format(_ lines: [String]) -> [String] {
        let newFileText = lines.joined(separator: "\n")
        guard let newFile = SKElementFactory().build(from: newFileText) else { return lines }
        let formatted = FormatUtil().format(newFile).text
        return formatted.components(separatedBy: .newlines)
    }
}

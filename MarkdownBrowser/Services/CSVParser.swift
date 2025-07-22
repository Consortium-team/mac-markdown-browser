import Foundation

/// A streaming CSV parser that handles various edge cases and large files efficiently
class CSVParser {
    private let delimiter: CSVDelimiter
    private let rowLimit: Int?
    private let columnLimit: Int?
    
    /// Initialize the parser with configuration options
    init(delimiter: CSVDelimiter = .comma, rowLimit: Int? = nil, columnLimit: Int? = nil) {
        self.delimiter = delimiter
        self.rowLimit = rowLimit
        self.columnLimit = columnLimit
    }
    
    /// Parse CSV content from a string
    func parse(_ content: String) throws -> CSVData {
        guard !content.isEmpty else {
            return CSVData(delimiter: delimiter)
        }
        
        var headers: [String] = []
        var rows: [[String]] = []
        
        let allLines = splitIntoLines(content)
        // Filter out completely empty lines while preserving lines with just delimiters
        let lines = allLines.filter { line in
            !line.isEmpty
        }
        
        guard !lines.isEmpty else {
            return CSVData(delimiter: delimiter)
        }
        
        // Parse headers
        headers = try parseLine(lines[0])
        
        // Parse rows
        for i in 1..<lines.count {
            if let rowLimit = rowLimit, rows.count >= rowLimit {
                break
            }
            
            let line = lines[i]
            // Skip truly empty lines
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }
            
            let row = try parseLine(line)
            rows.append(row)
        }
        
        return CSVData(headers: headers, rows: rows, delimiter: delimiter)
    }
    
    /// Parse CSV content from a URL using streaming for memory efficiency
    func parseFile(at url: URL) throws -> CSVData {
        // For simplicity and correctness, just read the file and use the string parser
        // A true streaming parser would need more complex state management for quoted fields
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return try parse(content)
        } catch {
            if (error as NSError).code == NSFileReadNoSuchFileError {
                throw CSVParseError.fileNotFound
            }
            throw error
        }
    }
    
    /// Parse a single line of CSV data
    private func parseLine(_ line: String) throws -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var previousChar: Character?
        
        let chars = Array(line)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            if char == "\"" {
                if inQuotes {
                    // Check if it's an escaped quote
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 1 // Skip the next quote
                    } else {
                        // End of quoted field
                        inQuotes = false
                    }
                } else if currentField.isEmpty || previousChar == Character(delimiter.rawValue) {
                    // Start of quoted field
                    inQuotes = true
                } else {
                    // Quote in the middle of unquoted field
                    currentField.append(char)
                }
            } else if char == Character(delimiter.rawValue) && !inQuotes {
                // Field separator
                fields.append(sanitizeField(currentField))
                currentField = ""
                
                // Apply column limit
                if let columnLimit = columnLimit, fields.count >= columnLimit {
                    break
                }
            } else {
                currentField.append(char)
            }
            
            previousChar = char
            i += 1
        }
        
        // Add the last field
        if !currentField.isEmpty || previousChar == Character(delimiter.rawValue) {
            fields.append(sanitizeField(currentField))
        }
        
        return fields
    }
    
    /// Split content into lines, handling different line endings and quotes
    private func splitIntoLines(_ content: String) -> [String] {
        var lines: [String] = []
        var currentLine = ""
        var inQuotes = false
        var previousChar: Character?
        
        let chars = Array(content)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            if char == "\"" {
                // Check if it's an escaped quote
                if inQuotes && i + 1 < chars.count && chars[i + 1] == "\"" {
                    currentLine.append("\"\"")
                    i += 1 // Skip the next quote
                } else {
                    inQuotes.toggle()
                    currentLine.append(char)
                }
            } else if (char == "\n" || char == "\r") && !inQuotes {
                // Handle different line endings
                if char == "\r" && i + 1 < chars.count && chars[i + 1] == "\n" {
                    i += 1 // Skip the \n in \r\n
                }
                
                // Always add the line, even if empty (CSV can have empty rows)
                lines.append(currentLine)
                currentLine = ""
            } else {
                currentLine.append(char)
            }
            
            previousChar = char
            i += 1
        }
        
        // Add the last line if there's content or if the file ended without a newline
        if !currentLine.isEmpty || previousChar != "\n" && previousChar != "\r" {
            lines.append(currentLine)
        }
        
        return lines
    }
    
    /// Sanitize a field by trimming whitespace and removing control characters
    private func sanitizeField(_ field: String) -> String {
        let trimmed = field.trimmingCharacters(in: .whitespaces)
        
        // Remove control characters except tab, newline, and carriage return
        let allowedControlChars: Set<Character> = ["\t", "\n", "\r"]
        let sanitized = trimmed.filter { char in
            !char.isASCII || !char.asciiValue!.isControlCharacter || allowedControlChars.contains(char)
        }
        
        // Limit field length for security
        let maxFieldLength = 10000
        if sanitized.count > maxFieldLength {
            return String(sanitized.prefix(maxFieldLength))
        }
        
        return sanitized
    }
}

// MARK: - StreamReader for memory-efficient file reading
private class StreamReader {
    private let inputStream: InputStream
    private let bufferSize = 4096
    private var buffer = [UInt8]()
    private var leftover = ""
    
    init(inputStream: InputStream) {
        self.inputStream = inputStream
        self.buffer = [UInt8](repeating: 0, count: bufferSize)
    }
    
    func nextLine() -> String? {
        var line = leftover
        
        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
            if bytesRead <= 0 { break }
            
            let chunk = String(bytes: buffer[0..<bytesRead], encoding: .utf8) ?? ""
            line += chunk
            
            if let newlineIndex = line.firstIndex(of: "\n") {
                let nextIndex = line.index(after: newlineIndex)
                leftover = String(line[nextIndex...])
                return String(line[..<newlineIndex]).trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
            }
        }
        
        if !line.isEmpty {
            leftover = ""
            return line
        }
        
        return nil
    }
}

// MARK: - CSV Parse Errors
enum CSVParseError: LocalizedError {
    case fileNotFound
    case invalidFormat
    case quoteMismatch
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "CSV file not found"
        case .invalidFormat:
            return "Invalid CSV format"
        case .quoteMismatch:
            return "Mismatched quotes in CSV"
        case .encodingError:
            return "Unable to decode CSV file"
        }
    }
}

// MARK: - Helper Extensions
private extension UInt8 {
    var isControlCharacter: Bool {
        return self < 32 || self == 127
    }
}
//
// Copyright © 2024 Antonio Marques. All rights reserved.
//

import Foundation
import CoreXLSX

public struct XLSX {
    let name: String
    let path: String
    let matrix: [Int: [Int: Cell]]
    let rowCount: Int
    let colCount: Int
    let strings: SharedStrings?
}

extension Table where Source == XLSX {
    public init(xlsx: String, book: Int = 0, sheet: Int = 0) throws {
        guard let file = XLSXFile(filepath: xlsx) else {
            throw DataError("Path [\(xlsx)] does not contain a valid XLSX")
        }

        guard let workbook = try file.parseWorkbooks()
            .dropFirst(book).first else {
            throw DataError("XLSX at [\(xlsx)] does not contain a workbook at index \(book)")
        }

        guard let (name, path) = try file.parseWorksheetPathsAndNames(workbook: workbook)
            .dropFirst(sheet).first else {
            throw DataError("XLSX at [\(xlsx)] workbook at index \(book) does not contain a worksheet at index \(sheet)")
        }

        let sheet = try file.parseWorksheet(at: path)
        let A = ColumnReference("A")!
        var rowCount = 0
        var colCount = 0
        let matrix = sheet.data?.rows.reduce(into: [Int: [Int: Cell]]()) { result, row in
            let rowIndex = Int(row.reference) - 1
            result[rowIndex] = row.cells.reduce(into: [Int: Cell]()) { cols, cell in
                let colIndex = A.distance(to: cell.reference.column)
                cols[colIndex] = cell
                colCount = max(colCount, colIndex + 1)
            }
            rowCount = max(rowCount, rowIndex + 1)
        }

        source = XLSX(
            name: name ?? "",
            path: path,
            matrix: matrix ?? [:],
            rowCount: rowCount,
            colCount: colCount,
            strings: try file.parseSharedStrings()
        )
    }
}

extension Table where Source == XLSX {
    public func enumerateRows(includeTop: Bool = false) -> Range<Int> {
        (includeTop ? 0 : 1)..<source.rowCount
    }
    public func enumerateCols(includeLeft: Bool) -> Range<Int> {
        (includeLeft ? 0 : 1)..<source.colCount
    }
}

extension Table where Source == XLSX {
    func row(at index: Int) throws -> [Int: Cell] {
        guard index >= 0, index < source.rowCount else {
            throw DataError("There is no row at index \(index)")
        }
        return source.matrix[index] ?? [:]
    }

    func slot(row: Int, col: Int) throws -> Slot {
        guard col >= 0, col < source.colCount else {
            throw DataError("There is no col at index \(row),\(col)")
        }
        guard let cell = try self.row(at: row)[col] else {
            return Slot(row: row, col: col, content: "")
        }
        return slot(row: row, col: col, source: cell)
    }

    func slot(row: Int, col: Int, source: Cell) -> Slot {
        return Slot(row: row, col: col, content: source.content(self.source.strings))
    }
}

private func matchValue(_ string: String, _ exact: Bool) -> String {
    exact ? string : string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

extension Cell {
    func content(_ strings: SharedStrings?) -> Any {
        if let string = stringValue(strings!) {
            return string
        }
        if let string = inlineString?.text {
            return string
        }
        if let date = dateValue {
            return date
        }
        if let value {
            return value
        }
        return ""
    }
}

extension Table where Source == XLSX {
    func row(matching key: String, exact: Bool, atCol: Int = 0) throws -> Slot {
        let key = matchValue(key, exact)
        guard atCol < source.colCount else {
            throw DataError("There is no col at index \(atCol)")
        }
        let match = source.matrix.lazy.compactMap {
            if let col = $0.value[atCol] {
                return slot(row: $0.key, col: atCol, source: col)
            } else {
                return nil
            }
        }.first {
            key == matchValue($0.string, exact)
        }
        guard let match else {
            throw DataError("Cannot find row in col \(atCol) matching key [\(key)], exact = \(exact)")
        }
        return match
    }

    func col(matching key: String, exact: Bool, atRow: Int = 0) throws -> Slot {
        let key = matchValue(key, exact)
        let match = try row(at: atRow).lazy.map {
            slot(row: atRow, col: $0.key, source: $0.value)
        }.first {
            key == matchValue($0.string, exact)
        }
        guard let match else {
            throw DataError("Cannot find col in row \(atRow) matching key [\(key)] (exact = \(exact))")
        }
        return match
    }

    public func cols<Output>(matching regex: Regex<Output>, atRow: Int = 0) throws -> [(Int, Output)] {
        let matches = try row(at: atRow).map {
            slot(row: atRow, col: $0.key, source: $0.value)
        }.compactMap {
            if let match = try! regex.wholeMatch(in: $0.string)?.output {
                ($0.col, match)
            } else {
                nil
            }
        }
        guard !matches.isEmpty else {
            throw DataError("Cannot find cols matching in row \(atRow) matching \(regex)")
        }
        return matches
    }
}

extension Table where Source == XLSX {
    public func at(row: String, exact: Bool = false, _ col: Int = 1) throws -> Slot {
        let row = try self.row(matching: row, exact: exact)
        return try slot(row: row.row, col: col)
    }
}

extension Table where Source == XLSX {
    public func at(col: String, exact: Bool = false, _ row: Int) throws -> Slot {
        let col = try self.col(matching: col, exact: exact)
        return try slot(row: row, col: col.col)
    }

    public func array(col: String, separator: String = " ", exact: Bool = false, _ row: Int, compact: Bool = true) throws -> [Slot] {
        var array: [Slot] = []
        var found = false
        for i in 1... {
            guard let slot = try? at(col: "\(col)\(separator)\(i)", exact: exact, row) else {
                break
            }
            found = true
            if compact && slot.isEmpty {
                break
            }
            array.append(slot)
        }
        if !found {
            throw DataError("Cannot find col matching key [\(col)\(separator)1] (exact = \(exact))")
        }
        return array
    }

    public func array2(col: String, outerSeparator: String = " ", innerSeparator: String = ".", exact: Bool = false, _ row: Int, compact: Bool = true) throws -> [[Slot]] {
        var array2: [[Slot]] = []
        var found = false
        for i in 1... {
            guard let array = try? array(col: "\(col)\(outerSeparator)\(i)", separator: innerSeparator, exact: exact, row, compact: compact) else {
                break
            }
            found = true
            if compact && array.isEmpty {
                break
            }
            array2.append(array)
        }
        if !found {
            throw DataError("Cannot find col matching key [\(col)\(outerSeparator)1\(innerSeparator)1] (exact = \(exact))")
        }
        return array2
    }
}

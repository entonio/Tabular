//
// Copyright © 2024 Antonio Marques. All rights reserved.
//
// Project started 17/04/2024.
//

import Foundation

public struct Table<Source> {
    let source: Source
}

struct DataError: Error, CustomStringConvertible, CustomDebugStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }

    var debugDescription: String { description }
}

# Tabular

The basic spreadsheet format - rows, columns, headers - is well understood by regular computer users. There are many spreadsheet programs, all of which offer advanced editing of the data, and there are even other programs that can export their own data as a table. These circumstances make it an ideal format for some kinds of data interchange, but there aren't always tools ready to convert the data back into structured objects. The purpose of this package is to help in the access to, and conversion of, the required values.

This package is not meant to handle very large tables or to process them at maximum speed or minimum memory cost, nor does it do conversion itself. Rather, it's focused on easing the sharing of data between regular users and developers, by having the former produce the data in a familiar format, and the latter easily extract the relevant parts from it, with some degree of tolerance.

Reading XLSX files is supported via [CoreXLSX](https://github.com/CoreOffice/CoreXLSX).
CSV support may be added at some point.

## Examples

Header in row, single data column:

```swift
Data:
+-------+-------+
| Name  | Alice |
| Age   |   27  |
+-------+-------+

let person = Person(
    name: try table.at(row:"name").text(),
    age: try table.at(row:"age").int()
)
```

Create a map of people grouped by last name:

```swift
Data:
+-------------+------------+-----+
| First name  | Last name  | Age |
+-------------+------------+-----+
| Alice       | Goldsmith  |  27 |
| Bob         | Cooper     |  31 |
| Concha      | Delorean   |  60 |
| Zoe         | Cooper     |  36 |
+-------------+------------+-----+

let personsByLastName = try table.enumerateRows().reduce(into: [String:[Person]]()) { map, row in
    let lastName = try table.at(col:"last name", row).text()
    let person = try Person(
        firstName: table.at(col:"first name", row).text(),
        lastName: lastName,
        age: table.at(col:"age", row).int()
    )

    var list = map[lastName] ?? []
    list.append(person)
    map[lastName] = list
}
```

Loading related columns into arrays / 2-dimensional arrays:

```swift
Data:
+-------------+-----------------+-----------------+-----------------+-----------------+------------+-----------+
| Guest       | Main Course 1.1 | Main Course 1.2 | Main Course 2.1 | Main Course 2.2 | Dessert 1  | Dessert 2 |
+-------------+-----------------+-----------------+-----------------+-----------------+------------+-----------+
| Alice       | Veal            | Mutton          | Tuna            | Bass            | Porridge   | Mousse    |
| Bob         | Beef            | Pork            | Salmon          | Trout           | Cheesecake | Custard   |
+-------------+-----------------+-----------------+-----------------+-----------------+------------+-----------+

struct Choices {
    let guest: String
    let mains: [[String]]
    let dessert: [String]
}

let choices = try table.enumerateRows().map { row in Choices(
    guest: try table.at(col:"guest", row).text(),
    mains: try table.array2(col:"main course", row).map { $0.map { try $0.text() }},
    dessert: try table.array(col:"main course", row).map { try $0.text() }
)}
```

## License

Except where/if otherwise specified, all the files in this package are copyright of the package contributors mentioned in the `NOTICE` file and licensed under the [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0), which is permissive for business use.

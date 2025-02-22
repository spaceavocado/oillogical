#+feature dynamic-literals

package illogical

import "core:fmt"
import "core:encoding/json"

main :: proc() {
    // data := `
    // {
    //     "age": 19,
    //     "name": "peter",
    // }
    // `
    data := `
    {
        "age": 19,
        "name": "peter",
        "xx": "city",
        "y": "x",
        "options": [1, 2, 3],
        "address": {
            "city": "Toronto",
            "country": "Canada"
        }
    }
    `
    ctx, err := json.parse_string(data)

    value1 := new_value("+")
    value2 := new_value(19)
    value3 := new_value(20)

    reference, _ := new_reference("address.city")

    options := Serialize_Options_Collection{
        escaped_operators = make(map[string]bool),
        escape_character = "\\",
    }
    options.escaped_operators["+"] = true

    collection, _ := new_collection(value1, value2, value3, reference, options=&options)

    fmt.println(to_string(&collection))
    fmt.println(serialize(&collection))
    fmt.println(evaluate(&collection, ctx))
    fmt.println(simplify(&collection, ctx))


    eq := new_eq("eq", value1, value2)
    fmt.println(to_string(&eq))
    fmt.println(serialize(&eq))
    fmt.println(evaluate(&eq, ctx))
    fmt.println(simplify(&eq, ctx))

    and, _ := new_and("AND", eq, eq)
    fmt.println(to_string(&and))
    fmt.println(serialize(&and))
    fmt.println(evaluate(&and, ctx))
    fmt.println(simplify(&and, ctx))
}

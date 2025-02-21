package illogical

import "core:fmt"

Collection :: struct {
    data: [dynamic]Evaluable,
    options: Serialization_Options_Collection,
}

Serialization_Options_Collection :: struct {
    escaped_operators: map[string]bool,
    escape_character: string,
}

new_collection :: proc(items: ..Evaluable, options: ^Serialization_Options_Collection = nil) -> (Evaluable, Error) {
    if len(items) == 0 {
        return {}, .Invalid_Collection
    }

    c := Collection{
        data = make([dynamic]Evaluable, len(items)),
        options = options^ if options != nil else Serialization_Options_Collection{
            escaped_operators = make(map[string]bool),
            escape_character = "\\",
        },
    }

    for item, i in items {
        c.data[i] = item
    }

    return c, .None
}

evaluate_collection :: proc(collection: ^Collection, ctx: ^FlattenContext) -> ([dynamic]Primitive, Error) {
    result := make([dynamic]Primitive, len(collection.data))

    for &item, i in collection.data {
        eval, err := evaluate(&item, ctx)
        if err != .None {
            delete(result)
            return nil, err
        }

        #partial switch e in eval {
        case Primitive:
            result[i] = e
        case:
            panic("Unsupported collection item type")
        }
    }

    return result, .None
}

simplify_collection :: proc(collection: ^Collection, ctx: ^FlattenContext) -> ([dynamic]Primitive, Evaluable) {
    result := make([dynamic]Primitive, len(collection.data))

    for &item, i in collection.data {
        value, e := simplify(&item, ctx)
        if e != nil {
            delete(result)
            return nil, collection^
        }

        if v, ok := value.(Primitive); ok {
            result[i] = v
        } else {
            panic("Unsupported collection item type")
        }
    }

    return result, {}
}

serialize_collection :: proc(collection: ^Collection) -> Primitive {
    result := [dynamic]Primitive{}

    head := serialize(&collection.data[0])
    if _should_be_escaped(head, &collection.options) {
        head = _escape_operator(fmt.tprintf("%v", head), &collection.options)
    }
    append(&result, head)

    for &item, i in collection.data[1:] {
        append(&result, serialize(&item))
    }

    return result
}

to_string_collection :: proc(collection: ^Collection) -> string {
    result := ""
    for &item, i in collection.data {
        result = fmt.tprintf("%s%s", result, to_string(&item))
        if i < len(collection.data) - 1 {
            result = fmt.tprintf("%s, ", result)
        }
    }
    return fmt.tprintf("[%s]", result)
}

_should_be_escaped :: proc(input: Primitive, options: ^Serialization_Options_Collection) -> bool {
    if input == nil {
        return false
    }

    if v, ok := input.(string); ok {
        if _, ok := options.escaped_operators[v]; ok {
            return true
        }
    }

    return false;
}

_escape_operator :: proc(operator: string, options: ^Serialization_Options_Collection) -> string {
    return fmt.tprintf("%s%s", options.escape_character, operator)
}
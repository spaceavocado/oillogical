package illogical

import "core:fmt"

Value :: struct {
    data: Primitive,
}

new_value :: proc(data: Primitive) -> Evaluable {
    return Value{
        data = data,
    }
}

evaluate_value :: proc(value: ^Value) -> Primitive {
    return value.data
}

simplify_value :: proc(value: ^Value) -> Primitive {
    return value.data
}

serialize_value :: proc(value: ^Value) -> Primitive {
    return value.data
}

to_string_value :: proc(value: ^Value) -> string {
    #partial switch &dst in value.data {
    case string:
        return fmt.tprintf("\"%s\"", dst)
    case:
        return fmt.tprintf("%v", dst)
    }
}

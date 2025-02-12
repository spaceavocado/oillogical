package illogical

import "core:fmt"

new_in :: proc(operator: string, left: Evaluable, right: Evaluable) -> Evaluable {
    return new_comparison(operator, "<in>", handler_in, left, right)
}

handler_in :: proc(operands: []Evaluated) -> Evaluated {
    _, leftIsArray := operands[0].(Array)
    _, rightIsArray := operands[1].(Array)

    if (leftIsArray && rightIsArray) || (!leftIsArray && !rightIsArray) {
        return false
    }

    needle, ok := as_equatable_primitive(operands[leftIsArray ? 1 : 0])
    if !ok {
        return false
    }

    for item in operands[leftIsArray ? 0 : 1].(Array) {
        if left, ok := as_equatable_primitive(item); ok {
            return left == needle
        }
    }

    return false
}

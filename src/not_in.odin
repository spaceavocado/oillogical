package illogical

import "core:fmt"

new_not_in :: proc(operator: string, left: Evaluable, right: Evaluable) -> Evaluable {
    return new_comparison(operator, "<not in>", handler_not_in, left, right)
}

handler_not_in :: proc(operands: []Evaluated) -> Evaluated {
    _, leftIsArray := operands[0].(Array)
    _, rightIsArray := operands[1].(Array)

    if (leftIsArray && rightIsArray) || (!leftIsArray && !rightIsArray) {
        return true
    }

    needle, ok := as_equatable_primitive(operands[leftIsArray ? 1 : 0])
    if !ok {
        return true
    }

    for item in operands[leftIsArray ? 0 : 1].(Array) {
        if left, ok := as_equatable_primitive(item); ok {
            if left == needle {
                return false
            }
        }
    }

    return true
}

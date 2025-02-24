package illogical

import "core:fmt"

new_ne :: proc(operator: string, left: Evaluable, right: Evaluable) -> Evaluable {
    return new_comparison(operator, "!=", handler_ne, left, right)
}

handler_ne :: proc(operands: []Evaluated) -> Evaluated {
    if left, ok := as_equatable_primitive(operands[0]); ok {
        if right, ok := as_equatable_primitive(operands[1]); ok {
            return left != right
        }
    }
    return true
}

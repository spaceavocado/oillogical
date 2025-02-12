package illogical

import "core:fmt"

new_overlap :: proc(operator: string, left: Evaluable, right: Evaluable) -> Evaluable {
    return new_comparison(operator, "<overlaps>", handler_overlap, left, right)
}

handler_overlap :: proc(operands: []Evaluated) -> Evaluated {
    _, leftIsArray := operands[0].(Array)
    _, rightIsArray := operands[1].(Array)

    if !leftIsArray || !rightIsArray {
        return false
    }

    for left in operands[0].(Array) {
        for right in operands[1].(Array) {
            if a, ok := as_equatable_primitive(left); ok {
                if b, ok := as_equatable_primitive(right); ok {
                    if a == b {
                        return true
                    }
                }
            }
        }
    }

    return false
}

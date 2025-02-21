package illogical

import "core:fmt"

new_nil :: proc(operator: string, e: Evaluable) -> Evaluable {
    return new_comparison(operator, "<is nil>", handler_nil, e)
}

handler_nil :: proc(operands: []Evaluated) -> Evaluated {
    return operands[0] == nil
}

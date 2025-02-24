package illogical

import "core:fmt"

new_present :: proc(operator: string, e: Evaluable) -> Evaluable {
    return new_comparison(operator, "<is present>", handler_present, e)
}

handler_present :: proc(operands: []Evaluated) -> Evaluated {
    return operands[0] != nil
}

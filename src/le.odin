package illogical

import "core:fmt"

new_le :: proc(operator: string, left: Evaluable, right: Evaluable) -> Evaluable {
    return new_comparison(operator, "<=", handler_le, left, right)
}

handler_le :: proc(operands: []Evaluated) -> Evaluated {
    compare_int := proc(a: int, b: int) -> Evaluated { return a <= b }
    compare_float := proc(a: f64, b: f64) -> Evaluated { return a <= b }
    return compare_primitives(operands[0], operands[1], compare_int, compare_float)
}

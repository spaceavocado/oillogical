package illogical

import "core:fmt"
import "core:strings"

new_suffix :: proc(operator: string, left: Evaluable, right: Evaluable) -> Evaluable {
    return new_comparison(operator, "<with suffix>", handler_suffix, left, right)
}

handler_suffix :: proc(operands: []Evaluated) -> Evaluated {
    as_string := proc(a: string, b: string) -> Evaluated { return Primitive(strings.has_suffix(a, b)) }
    return compare_primitives(operands[0], operands[1], as_string=as_string)
}

package illogical

import "core:fmt"
import "core:strings"

new_prefix :: proc(operator: string, left: Evaluable, right: Evaluable) -> Evaluable {
    return new_comparison(operator, "<prefixes>", handler_prefix, left, right)
}

handler_prefix :: proc(operands: []Evaluated) -> Evaluated {
    as_string := proc(a: string, b: string) -> Evaluated { return new_primitive(strings.has_prefix(b, a)) }
    return compare_primitives(operands[0], operands[1], as_string=as_string)
}

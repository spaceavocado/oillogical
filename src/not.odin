package illogical

import "core:fmt"

new_not :: proc(operator: string, operand: Evaluable) -> Evaluable {
    simplify_handler : simplify_handler_base = simplify_not
    return new_logical(operator, "NOT", "N/A", "N/A", handler_not, simplify_handler, operand)
}

handler_not :: proc(ctx: ^Flatten_Context, operands: []Evaluable) -> (Evaluated, Error) {
    res, err := evaluate_logical_operand(&operands[0], ctx)
    if err != nil {
        return false, err
    }

    return !res, nil
}

simplify_not :: proc(operator: string, ctx: ^Flatten_Context, operands: []Evaluable) -> (Evaluated, Evaluable) {
    res, e := simplify(&operands[0], ctx)
    if b, ok := res.(Primitive).(bool); ok {
        return !b, nil
    }

    if e != nil {
        return nil, new_not(operator, e)
    }

	return nil, nil
}

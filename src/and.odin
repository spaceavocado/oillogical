package illogical

import "core:fmt"

new_and :: proc(operator: string, operands: ..Evaluable) -> (Evaluable, Error) {
    if len(operands) < 2 {
        return nil, .Invalid_Logical_Expression
    }

    simplify_handler : simplify_handler_base = simplify_and
    return new_logical(operator, "AND", "N/A", "N/A", handler_and, simplify_handler, ..operands), nil
}

handler_and :: proc(ctx: ^Flatten_Context, operands: []Evaluable) -> (Evaluated, Error) {
    for &e in operands {
		res, err := evaluate_logical_operand(&e, ctx)
		if err != nil {
			return false, err
		}
		if !res {
			return false, nil
		}
	}
	return true, nil
}

simplify_and :: proc(operator: string, ctx: ^Flatten_Context, operands: []Evaluable) -> (Evaluated, Evaluable) {
    simplified := make([dynamic]Evaluable)
    defer delete(simplified)
    
	for &e in operands {
		res, e := simplify(&e, ctx)
		if b, ok := res.(Primitive).(bool); ok {
			if !b {
				return false, nil
			}
			continue
		}

        append(&simplified, e)
	}

	if len(simplified) == 0 {
		return true, nil
	}

	if len(simplified) == 1 {
		return nil, simplified[0]
	}

    new_and, _ := new_and(operator, ..simplified[:])
	return nil, new_and
}

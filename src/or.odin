package illogical

import "core:fmt"

new_or :: proc(operator: string, operands: ..Evaluable) -> (Evaluable, Error) {
    if len(operands) < 2 {
        return nil, .Invalid_Logical_Expression
    }

    simplify_handler : simplify_handler_base = simplify_or
    return new_logical(operator, "OR", "N/A", "N/A", handler_or, simplify_handler, ..operands), nil
}

handler_or :: proc(ctx: ^Flatten_Context, operands: []Evaluable) -> (Evaluated, Error) {
    for &e in operands {
		res, err := evaluate_logical_operand(&e, ctx)
		if err != nil {
			return false, err
		}
		if res {
			return true, nil
		}
	}
	return false, nil
}

simplify_or :: proc(operator: string, ctx: ^Flatten_Context, operands: []Evaluable) -> (Evaluated, Evaluable) {
    simplified := make([dynamic]Evaluable)
    defer delete(simplified)
    
	for &e in operands {
		res, e := simplify(&e, ctx)
		if b, ok := res.(Primitive).(bool); ok {
			if b {
				return true, nil
			}
			continue
		}

        append(&simplified, e)
	}

	if len(simplified) == 0 {
		return false, nil
	}

	if len(simplified) == 1 {
		return nil, simplified[0]
	}

    new_or, _ := new_or(operator, ..simplified[:])
	return nil, new_or
}

package illogical

import "core:fmt"

new_nor :: proc(operator: string, not_operator: string, operands: ..Evaluable) -> (Evaluable, Error) {
    if len(operands) < 2 {
        return nil, .Invalid_Logical_Expression
    }

    simplify_handler : simplify_handler_with_not = simplify_nor
    return new_logical(operator, "NOR", not_operator, "N/A", handler_nor, simplify_handler, ..operands), nil
}

handler_nor :: proc(ctx: ^Flatten_Context, operands: []Evaluable) -> (Evaluated, Error) {
    for &e in operands {
		res, err := evaluate_logical_operand(&e, ctx)
		if err != nil {
			return false, err
		}
		if res {
			return false, nil
		}
	}
	return true, nil
}

simplify_nor :: proc(operator: string, ctx: ^Flatten_Context, operands: []Evaluable, not_operator: string) -> (Evaluated, Evaluable) {
    simplified := make([dynamic]Evaluable)
    defer delete(simplified)
    
	for &e in operands {
		res, e := simplify(&e, ctx)
		if b, ok := res.(Primitive).(bool); ok {
			if b {
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
		return nil, new_not(not_operator, simplified[0])
	}

    new_nor, _ := new_nor(operator, not_operator, ..simplified[:])
	return nil, new_nor
}

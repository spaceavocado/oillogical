package illogical

import "core:fmt"

new_xor :: proc(operator: string, not_operator: string, nor_operator: string, operands: ..Evaluable) -> (Evaluable, Error) {
    if len(operands) < 2 {
        return nil, .Invalid_Logical_Expression
    }

    simplify_handler : simplify_handler_with_not_nor = simplify_xor
    return new_logical(operator, "XOR", not_operator, nor_operator, handler_xor, simplify_handler, ..operands), nil
}

handler_xor :: proc(ctx: ^FlattenContext, operands: []Evaluable) -> (Evaluated, Error) {
    xor: bool

    for &e, i in operands {
		res, err := evaluate_logical_operand(&e, ctx)
		if err != nil {
			return false, err
		}

        if i == 0 {
            xor = res
            continue
        }

        if xor && res {
            return false, nil
        }

		if res {
			xor = true
		}
	}

	return new_primitive(xor), nil
}

simplify_xor :: proc(operator: string, ctx: ^FlattenContext, operands: []Evaluable, not_operator: string, nor_operator: string) -> (Evaluated, Evaluable) {
    simplified := make([dynamic]Evaluable)
    defer delete(simplified)
    
    truthy := 0

	for &e in operands {
		res, e := simplify(&e, ctx)
		if b, ok := res.(Primitive).(bool); ok {
			if b {
				truthy += 1
			}
            if truthy > 1 {
                return false, nil
            }
			continue
		}

        append(&simplified, e)
	}

	if len(simplified) == 0 {
		return truthy == 1, nil
	}

	if len(simplified) == 1 {
        if truthy == 1 {
            new_not, _ := new_not(not_operator, simplified[0])
		    return nil, new_not
        }
		return nil, simplified[0]
	}

    if truthy == 1 {
        new_nor, _ := new_nor(operator, not_operator, ..simplified[:])
        return nil, new_nor
    }

    new_xor, _ := new_xor(operator, not_operator, nor_operator, ..simplified[:])
	return nil, new_xor
}

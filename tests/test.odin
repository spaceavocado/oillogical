package illogical_test

import "core:fmt"

import illogical "../src"

ref :: proc(address: string) -> illogical.Evaluable {
    e, _ := illogical.new_reference(address)
    return e
}

val :: proc(data: illogical.Primitive) -> illogical.Evaluable {
    e := illogical.new_value(data)
    return e
}

col :: proc(items: ..illogical.Evaluable) -> illogical.Evaluable {
    e, _ := illogical.new_collection(..items)
    return e
}

and := proc(operands: []illogical.Evaluable) -> illogical.Evaluable {
    e, _ := illogical.new_and("AND", ..operands)
    return e
}

or := proc(operands: []illogical.Evaluable) -> illogical.Evaluable {
    e, _ := illogical.new_or("OR", ..operands)
    return e
}

not := proc(operand: illogical.Evaluable) -> illogical.Evaluable {
    e, _ := illogical.new_not("NOT", operand)
    return e
}

nor := proc(operands: []illogical.Evaluable) -> illogical.Evaluable {
    e, _ := illogical.new_nor("NOR", "NOT", ..operands)
    return e
}

xor := proc(operands: []illogical.Evaluable) -> illogical.Evaluable {
    e, _ := illogical.new_xor("XOR", "NOT", "NOR", ..operands)
    return e
}

fprint_evaluable :: proc(e: illogical.Evaluable) -> string {
    if e == nil {
        return "nil"
    }

    e := e
	return illogical.to_string(&e)
}

fprint_any :: proc (input: any) -> string {
    return fmt.tprintf("%v", input)
}

fprint :: proc { fprint_evaluable, fprint_any }



matches_primitive :: proc(evaluated: illogical.Evaluated, expected: illogical.Evaluated) -> bool {
    if a, ok := evaluated.(illogical.Primitive); ok {
        if b, ok := expected.(illogical.Primitive); ok {
            if a == nil && b == nil {
                return true
            }
        }
    }

    if a, ok := illogical.as_equatable_primitive(evaluated); ok {
        if b, ok := illogical.as_equatable_primitive(expected); ok {
            return a == b
        }
    }

    return false
}

matches_evaluated :: proc(evaluated: illogical.Evaluated, expected: illogical.Evaluated) -> bool {
    if a, ok := illogical.as_equatable_primitive(evaluated); ok {
        if b, ok := illogical.as_equatable_primitive(expected); ok {
            return a == b
        }
    }

    evaluated_collection, _ := evaluated.(illogical.Array)
    expected_collection, _ := expected.(illogical.Array)

    if len(evaluated_collection) != len(expected_collection) {
        return false
    }

    for i in 0..<len(evaluated_collection) {
        if a, ok := illogical.as_equatable_primitive(evaluated_collection[i]); ok {
            if b, ok := illogical.as_equatable_primitive(expected_collection[i]); ok {
                if a == b {
                    continue
                }
            }
        }
        return false
    }

    return true
}
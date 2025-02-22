package illogical_test

import "core:fmt"

@require import illogical "../src"

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

    return fmt.tprintf("%v", evaluated_collection) == fmt.tprintf("%v", expected_collection)
}

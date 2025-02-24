#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../illogical"

@test
test_not_handler :: proc(t: ^testing.T) {
    ctx := illogical.Flatten_Context{
        "RefA" = 10,
    }
    defer delete(ctx)

	tests := []struct {
		operands: []illogical.Evaluable,
		expected: bool
	}{
		// Truthy
		{[]illogical.Evaluable{val(true)}, false},
		// Falsy
		{[]illogical.Evaluable{val(false)}, true},
	}

	for test in tests {
		evaluated, err := illogical.handler_not(&ctx, test.operands[:])

		testing.expectf(t, evaluated.(illogical.Primitive).(bool) == test.expected, "input (%v): expected %v, got %v", test.operands, test.expected, evaluated)
		testing.expectf(t, err == nil, "input (%v): expected no error, got %v", test.operands, err)
	}

    errs := []struct {
		operands: []illogical.Evaluable,
		expected: illogical.Error,
	}{
		{[]illogical.Evaluable{val("bogus")}, .Invalid_Evaluated_Logical_Operand},
	}

	for test in errs {
		_, err := illogical.handler_or(&ctx, test.operands[:])

		testing.expectf(t, err == test.expected, "input (%v): expected %v, got %v", test.operands, test.expected, err)
	}
}

@test
test_not_simplify :: proc(t: ^testing.T) {
	ctx := illogical.Flatten_Context{
		"RefA" = true,
	}
	defer delete(ctx)

	tests := []struct {
		input: []illogical.Evaluable,
		value: illogical.Primitive,
		e:     illogical.Evaluable
	}{
		{[]illogical.Evaluable{val(true)}, false, nil},
		{[]illogical.Evaluable{val(false)}, true, nil},
		{[]illogical.Evaluable{ref("RefA")}, false, nil},
		{[]illogical.Evaluable{ref("Missing")}, nil, not(ref("Missing"))},
	}

	for &test in tests {
        e := not(test.input[0])
		value, self := illogical.simplify(&e, &ctx)

		testing.expectf(t, matches_evaluated(value, test.value), "input (%v): expected %v, got %v", test.input, test.value, value)
		testing.expectf(t, fprint(self) == fprint(test.e), "input (%v): expected %v, got %v", test.input, test.e, self)

        illogical.destroy_evaluable(&e)
        illogical.destroy_evaluable(&self)
        illogical.destroy_evaluable(&test.e)
	}
}
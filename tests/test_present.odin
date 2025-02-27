#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../illogical"

@test
test_present_handler :: proc(t: ^testing.T) {
	tests := []struct {
		e:     illogical.Evaluated,
		expected: illogical.Primitive,
	}{
        // Truthy
		{illogical.Primitive(i64(1)), true},
		{illogical.Primitive(1.1), true},
		{illogical.Primitive("1"), true},
		{illogical.Primitive(true), true},
        // Falsy
		{nil, false},
	}

	for test in tests {
        operands := []illogical.Evaluated{test.e}
		evaluated := illogical.handler_present(operands)

		testing.expectf(t, matches_evaluated(evaluated, test.expected), "input (%v): expected %v, got %v", test.e, test.expected, evaluated)
	}
}
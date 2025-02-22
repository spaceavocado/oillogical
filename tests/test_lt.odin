#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../src"

@test
test_lt_handler :: proc(t: ^testing.T) {
	tests := []struct {
		left:     illogical.Primitive,
		right:    illogical.Primitive,
		expected: illogical.Primitive,
	}{
		// Truthy
		{1, 2, true},
		{1.1, 1.2, true},
		// Falsy
		{1, 1, false},
		{1.1, 1.1, false},
		{1, 0, false},
		{1.1, 1.0, false},
		// Non comparable
		{"val", 1, false},
        {true, 1, false},
		{illogical.Array{1}, illogical.Array{1}, false},
		{illogical.Array{1}, illogical.Array{1.1}, false},
	}

	for test in tests {
        operands := []illogical.Evaluated{test.left, test.right}
		evaluated := illogical.handler_lt(operands)

		testing.expectf(t, matches_evaluated(evaluated, test.expected), "input (%v, %v): expected %v, got %v", test.left, test.right, test.expected, evaluated)

        illogical.destroy_primitive(test.left)
		illogical.destroy_primitive(test.right)
	}
}
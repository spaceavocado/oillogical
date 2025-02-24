#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../illogical"

@test
test_eq_handler :: proc(t: ^testing.T) {
	tests := []struct {
		left:     illogical.Primitive,
		right:    illogical.Primitive,
		expected: illogical.Primitive,
	}{
		// Same types
		{1, 1, true},
		{1.1, 1.1, true},
		{"1", "1", true},
		{true, true, true},
		{false, false, true},
		// Diff types
		{1, 1.1, false},
		{1, "1", false},
		{1, true, false},
		{1.1, "1", false},
		{1.1, true, false},
		{"1", true, false},
		// Slices
		{illogical.Array{1}, illogical.Array{1}, false},
		{illogical.Array{1}, illogical.Array{1.1}, false},
	}

	for test in tests {
        operands := []illogical.Evaluated{test.left, test.right}
		evaluated := illogical.handler_eq(operands)

		testing.expectf(t, matches_evaluated(evaluated, test.expected), "input (%v, %v): expected %v, got %v", test.left, test.right, test.expected, evaluated)

		illogical.destroy_primitive(test.left)
		illogical.destroy_primitive(test.right)
	}
}
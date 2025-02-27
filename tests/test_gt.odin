#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../illogical"

@test
test_gt_handler :: proc(t: ^testing.T) {
	tests := []struct {
		left:     illogical.Primitive,
		right:    illogical.Primitive,
		expected: illogical.Primitive,
	}{
		// Truthy
		{2, 1, true},
		{1.2, 1.1, true},
		// Falsy
		{1, 1, false},
		{1.1, 1.1, false},
		{0, 1, false},
		{1.0, 1.1, false},
		// Non comparable
		{"val", 1, false},
        {true, 1, false},
		{illogical.Array{1}, illogical.Array{1}, false},
		{illogical.Array{1}, illogical.Array{1.1}, false},
	}

	for test in tests {
        operands := []illogical.Evaluated{test.left, test.right}
		evaluated := illogical.handler_gt(operands)

		testing.expectf(t, matches_evaluated(evaluated, test.expected), "input (%v, %v): expected %v, got %v", test.left, test.right, test.expected, evaluated)

        illogical.destroy_evaluated(test.left)
		illogical.destroy_evaluated(test.right)
	}
}
#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../src"

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
		{[dynamic]illogical.Primitive{1}, [dynamic]illogical.Primitive{1}, false},
		{[dynamic]illogical.Primitive{1}, [dynamic]illogical.Primitive{1.1}, false},
	}

	for test in tests {
        operands := []illogical.Evaluated{test.left, test.right}
		evaluated := illogical.handler_gt(operands)

		testing.expectf(t, matches_evaluated(evaluated, test.expected), "input (%v, %v): expected %v, got %v", test.left, test.right, test.expected, evaluated)

        if arr, ok := test.left.([dynamic]illogical.Primitive); ok {
            delete(arr)
        }
        if arr, ok := test.right.([dynamic]illogical.Primitive); ok {
            delete(arr)
        }
	}
}
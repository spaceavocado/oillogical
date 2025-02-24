#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../illogical"

@test
test_overlap_handler :: proc(t: ^testing.T) {
	tests := []struct {
		left:     illogical.Evaluated,
		right:    illogical.Evaluated,
		expected: illogical.Primitive,
	}{
        // Truthy
		{illogical.Array{1}, illogical.Array{1}, true},
		{illogical.Array{1, 2}, illogical.Array{1, 3}, true},
		{illogical.Array{3, 2}, illogical.Array{2, 3}, true},
		{illogical.Array{"1"}, illogical.Array{"1"}, true},
		{illogical.Array{true}, illogical.Array{true}, true},
		{illogical.Array{1.1}, illogical.Array{1.1}, true},
		// Falsy
        {illogical.Array{1}, illogical.Array{2}, false},
		{illogical.Primitive(i64(1)), illogical.Array{1}, false},
		{illogical.Array{1}, illogical.Primitive(i64(1)), false},
		{illogical.Primitive("1"), illogical.Primitive("1"), false},
	}

	for test in tests {
        operands := []illogical.Evaluated{test.left, test.right}
		evaluated := illogical.handler_overlap(operands)

		testing.expectf(t, matches_evaluated(evaluated, test.expected), "input (%v, %v): expected %v, got %v", test.left, test.right, test.expected, evaluated)

        illogical.destroy_evaluated(test.left)
		illogical.destroy_evaluated(test.right)
	}
}
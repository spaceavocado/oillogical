#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../illogical"

@test
test_non_in_handler :: proc(t: ^testing.T) {
	tests := []struct {
		left:     illogical.Evaluated,
		right:    illogical.Evaluated,
		expected: illogical.Primitive,
	}{
		// Truthy
		{illogical.Primitive(i64(0)), illogical.Array{1}, true},
		{illogical.Array{1}, illogical.Primitive(i64(0)), true},
		{illogical.Primitive("0"), illogical.Array{"1"}, true},
		{illogical.Primitive(false), illogical.Array{true}, true},
		{illogical.Primitive(1.0), illogical.Array{1.1}, true},
		{illogical.Array{1}, illogical.Array{1}, true},
		// Falsy
		{illogical.Array{1}, illogical.Primitive(i64(1)), false},
		{illogical.Primitive(i64(1)), illogical.Array{1}, false},
	}

	for test in tests {
        operands := []illogical.Evaluated{test.left, test.right}
		evaluated := illogical.handler_not_in(operands)

		testing.expectf(t, matches_evaluated(evaluated, test.expected), "input (%v, %v): expected %v, got %v", test.left, test.right, test.expected, evaluated)

        illogical.destroy_evaluated(test.left)
		illogical.destroy_evaluated(test.right)
	}
}
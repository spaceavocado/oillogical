#+feature dynamic-literals

package illogical_test

import "core:testing"
import "core:fmt"

import illogical "../src"

@test
test_in_handler :: proc(t: ^testing.T) {
	tests := []struct {
		left:     illogical.Evaluated,
		right:    illogical.Evaluated,
		expected: illogical.Primitive,
	}{
		// Truthy
		{illogical.new_primitive(1), illogical.Array{1}, true},
		{illogical.Array{1}, illogical.new_primitive(1), true},
		{illogical.new_primitive("1"), illogical.Array{"1"}, true},
		{illogical.new_primitive(true), illogical.Array{true}, true},
		{illogical.new_primitive(1.1), illogical.Array{1.1}, true},
		// Falsy
		{illogical.new_primitive(1), illogical.Array{2}, false},
		{illogical.Array{2}, illogical.new_primitive(1), false},
		{illogical.new_primitive(1), illogical.new_primitive(1), false},
		{illogical.Array{1}, illogical.Array{1}, false},
	}

	for test in tests {
        operands := []illogical.Evaluated{test.left, test.right}
		evaluated := illogical.handler_in(operands)

		testing.expectf(t, matches_evaluated(evaluated, test.expected), "input (%v, %v): expected %v, got %v", test.left, test.right, test.expected, evaluated)

        illogical.destroy_evaluated(test.left)
		illogical.destroy_evaluated(test.right)
	}
}
package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

main :: proc() {

	input, ok := os.read_entire_file("2021-7.txt")
	assert(ok)

	input_string := string(input)
	input_left := input_string

	positions: [dynamic]int
	min_position := -1
	max_position := -1

	for len(input_left) > 0 {

		number_one_past_end := strings.index_rune(input_left, ',')
		number_string: string
		if number_one_past_end == -1 {
			number_one_past_end = strings.index_any(input_left, "\r\n")
			assert(number_one_past_end != -1)
			number_string = input_left[:number_one_past_end]
			input_left = input_left[len(input_left):]
		} else {
			number_string = input_left[:number_one_past_end]
			input_left = input_left[number_one_past_end + 1:]
		}

		number, ok := strconv.parse_int(number_string)
		assert(ok)

		append(&positions, number)

		if min_position == -1 {
			min_position = number
		} else {
			min_position = min(min_position, number)
		}

		if max_position == -1 {
			max_position = number
		} else {
			max_position = max(max_position, number)
		}

	}

	min_align_cost := -1

	for test_pos in min_position .. max_position {

		align_cost := 0

		for pos in positions {

			to_move := abs(pos - test_pos)

			if to_move > 0 {
				for step in 1 .. to_move {
					align_cost += step
				}
			}

		}

		if min_align_cost == -1 {
			min_align_cost = align_cost
		} else {
			min_align_cost = min(min_align_cost, align_cost)
		}

	}

	fmt.println(min_align_cost)

}

package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

main :: proc() {

	input, ok := os.read_entire_file("2021-5.txt")
	assert(ok)

	input_string := string(input)
	input_left := input_string

	lines: [dynamic][2][2]int
	max_x := 0
	max_y := 0

	for len(input_left) > 0 {

		read_point :: proc(input: string) -> ([2]int, string) {

			input_left := input

			comma_index := strings.index_rune(input_left, ',')
			assert(comma_index != -1, fmt.tprintf("no comma in '{}'", input_left))
			number1, ok1 := strconv.parse_int(input_left[:comma_index])
			assert(ok1, fmt.tprintf("failed to parse number from '{}'", input_left[:comma_index]))

			input_left = input_left[comma_index + 1:]

			space_index := strings.index_any(input_left, " \r\n")
			number2, ok2 := strconv.parse_int(input_left[:space_index])
			assert(ok2)

			return [2]int{number1, number2}, input_left[space_index:]
		}

		p1: [2]int
		p1, input_left = read_point(input_left)

		assert(input_left[:4] == " -> ")
		input_left = input_left[4:]

		p2: [2]int
		p2, input_left = read_point(input_left)

		max_x = max(max_x, p1.x, p2.x)
		max_y = max(max_y, p1.y, p2.y)

		line: [2][2]int = {p1, p2}
		append(&lines, line)

		for len(input_left) > 0 && (input_left[0] == '\n' || input_left[0] == '\r') {
			input_left = input_left[1:]
		}

	}

	field_dim: [2]int = {max_x + 1, max_y + 1}
	field := make([]int, field_dim.x * field_dim.y)

	for line in lines {

		is_horizontal := line[0].y == line[1].y

		if is_horizontal {

			y_coord := line[0].y
			x_start := min(line[0].x, line[1].x)
			x_end := max(line[0].x, line[1].x)

			for x_coord in x_start .. x_end {

				field_index := y_coord * field_dim.x + x_coord
				field[field_index] += 1

			}

		}

		is_vertical := line[0].x == line[1].x

		if is_vertical {

			x_coord := line[0].x
			y_start := min(line[0].y, line[1].y)
			y_end := max(line[0].y, line[1].y)

			for y_coord in y_start .. y_end {

				field_index := y_coord * field_dim.x + x_coord
				field[field_index] += 1

			}

		}

		is_diagonal := !is_horizontal && !is_vertical

		if is_diagonal {

			x_start := line[0].x
			x_end := line[1].x
			assert(x_start != x_end)
			x_step := x_start < x_end ? 1 : -1

			y_start := line[0].y
			y_end := line[1].y
			assert(y_start != y_end)
			y_step := y_start < y_end ? 1 : -1

			x_coord := x_start
			y_coord := y_start
			for {

				field_index := y_coord * field_dim.x + x_coord
				field[field_index] += 1

				if y_coord == y_end && x_coord == x_end {
					break
				}

				x_coord += x_step
				y_coord += y_step

			}

		}

	}

	for row in 0 ..< field_dim.y {
		//fmt.println(field[row * field_dim.x:row * field_dim.x + field_dim.x])
	}

	dangerous_area_count := 0

	for count in field {
		if count >= 2 {
			dangerous_area_count += 1
		}
	}

	fmt.println(dangerous_area_count)

}

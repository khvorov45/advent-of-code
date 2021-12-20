package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:unicode"

main :: proc() {

	input_left: string
	{
		input, ok := os.read_entire_file("2021-17.txt")
		assert(ok)
		input_string := string(input)
		input_left = input_string
	}

	target: [2][2]int
	{
		assert(input_left[:13] == "target area: ")
		input_left = input_left[13:]

		assert(input_left[:2] == "x=")
		input_left = input_left[2:]

		read_number :: proc(input: string) -> (int, string) {
			input_left := input
			num_end := strings.index_any(input_left, ".,\n\r")
			assert(num_end != -1)
			num, ok := strconv.parse_int(input_left[:num_end])
			assert(ok)
			input_left = input_left[num_end:]
			return num, input_left
		}

		target.x[0], input_left = read_number(input_left)
		assert(input_left[:2] == "..")
		input_left = input_left[2:]

		target.x[1], input_left = read_number(input_left)
		assert(input_left[:4] == ", y=")
		input_left = input_left[4:]

		target.y[0], input_left = read_number(input_left)
		assert(input_left[:2] == "..")
		input_left = input_left[2:]

		target.y[1], input_left = read_number(input_left)
	}

	fmt.println(target)

	highest_y := 0
	pos := [2]int{0, 0}
	overshoot_y_in_a_row := 0
	n_distinct_velocities := 0
	for test_y_vel := target.y[0]; overshoot_y_in_a_row < 100; test_y_vel += 1 {

		cur_y_vel := test_y_vel
		overshoot_y_in_a_row += 1
		pos.y = 0
		pos.x = 0
		test_y_vel_highest_y := 0

		step_x_min := target.x[1] + 1
		test_x_max := step_x_min
		for step_index := 0; pos.y >= target.y[0]; step_index += 1 {

			pos.y += cur_y_vel
			cur_y_vel -= 1
			test_y_vel_highest_y = max(test_y_vel_highest_y, pos.y)

			if pos.y >= target.y[0] && pos.y <= target.y[1] {

				overshoot_y_in_a_row = 0
				found_suitable_x := false

				for test_x_vel := 0; test_x_vel < test_x_max; test_x_vel += 1 {

					pos.x = 0
					cur_x_vel := test_x_vel
					for step_index_x := 0;
					    step_index_x <= step_index && cur_x_vel > 0;
					    step_index_x += 1 {

						pos.x += cur_x_vel
						cur_x_vel -= 1

					}

					if pos.x >= target.x[0] && pos.x <= target.x[1] {
						n_distinct_velocities += 1
						step_x_min = min(test_x_vel, step_x_min)
						fmt.printf("{},{}\n", test_x_vel, test_y_vel)
						found_suitable_x = true
					} else if pos.x > target.x[1] {
						if found_suitable_x {
							highest_y = max(highest_y, test_y_vel_highest_y)
						}
						break
					}

				}

			}

			test_x_max = step_x_min

		}

	}

	fmt.println(highest_y)
	fmt.println(n_distinct_velocities)

}

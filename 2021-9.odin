package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

Entry :: struct {
	unique_signals: [10]string,
	output_digits:  [4]string,
}

main :: proc() {

	input, ok := os.read_entire_file("2021-9.txt")
	assert(ok)

	input_string := string(input)
	input_left := input_string

	heights: [dynamic]int
	col_count := -1
	row_count := 0

	numbers_in_row := 0
	new_row := true
	for len(input_left) > 0 {

		if input_left[0] != '\r' && input_left[0] != '\n' {

			if new_row {
				row_count += 1
				new_row = false
			}

			number_string := input_left[0:1]

			number, ok := strconv.parse_int(number_string)
			assert(ok, fmt.tprintf("failed to parse {} as number", number_string))

			append(&heights, number)
			numbers_in_row += 1

		} else {

			new_row = true

			if col_count == -1 {
				col_count = numbers_in_row
			} else {
				assert(numbers_in_row == col_count)
			}
			numbers_in_row = 0

		}

		input_left = input_left[1:]
	}

	sum_risk := 0

	point_indices_to_check: [dynamic]int
	index_check_status := make([]bool, len(heights))
	top1_basin, top2_basin, top3_basin: int

	for row in 0 ..< row_count {
		for col in 0 ..< col_count {

			is_low := true
			this_index := row * col_count + col
			this_height := heights[this_index]

			assert(
				len(point_indices_to_check) == 0,
				fmt.tprintf("len(point_indices_to_check) = {}\n", len(point_indices_to_check)),
			)

			low_search: for test_row := max(0, row - 1);
			    test_row <= min(row + 1, row_count - 1);
			    test_row += 1 {

				for test_col := max(0, col - 1);
				    test_col <= min(col + 1, col_count - 1);
				    test_col += 1 {

					if (test_row == row || test_col == col) && (test_row != row || test_col != col) {

						test_index := test_row * col_count + test_col
						test_height := heights[test_index]

						if test_height <= this_height {
							is_low = false
							break low_search
						}

					}

				}

			}

			if is_low {

				risk_level := this_height + 1
				sum_risk += risk_level

				basin_size := 0
				append(&point_indices_to_check, this_index)
				index_check_status[this_index] = true

				for len(point_indices_to_check) > 0 {

					basin_size += 1

					check_index := pop(&point_indices_to_check)
					check_row := check_index / col_count
					check_col := check_index - check_row * col_count

					for test_row := max(0, check_row - 1);
					    test_row <= min(check_row + 1, row_count - 1);
					    test_row += 1 {

						for test_col := max(0, check_col - 1);
						    test_col <= min(check_col + 1, col_count - 1);
						    test_col += 1 {

							if (test_row == check_row || test_col == check_col) && (test_row != check_row || test_col !=
							   check_col) {

								test_index := test_row * col_count + test_col

								if !index_check_status[test_index] {
									test_height := heights[test_index]
									if test_height < 9 {
										append(&point_indices_to_check, test_index)
										index_check_status[test_index] = true
									}
								}

							}

						}

					}

				}

				switch {
				case basin_size > top1_basin:
					top3_basin = top2_basin
					top2_basin = top1_basin
					top1_basin = basin_size
				case basin_size > top2_basin:
					top3_basin = top2_basin
					top2_basin = basin_size
				case basin_size > top3_basin:
					top3_basin = basin_size
				}

			}

		}
	}

	fmt.println("sum of risk:", sum_risk)
	fmt.println(
		"top3 basins:",
		top1_basin,
		top2_basin,
		top3_basin,
		top1_basin * top2_basin * top3_basin,
	)

}

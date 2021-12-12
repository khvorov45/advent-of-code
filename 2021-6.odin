package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

main :: proc() {

	input, ok := os.read_entire_file("2021-6.txt")
	assert(ok)

	input_string := string(input)
	input_left := input_string

	age_counts: [9]int

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
		assert(number < len(age_counts))
		age_counts[number] += 1

	}

	fmt.println(age_counts)

	for day in 1 .. 256 {

		new_counts: [9]int

		for age := len(age_counts) - 1; age >= 0; age -= 1 {

			if age == 0 {

				new_counts[6] += age_counts[age]
				new_counts[8] += age_counts[age]

			} else {

				new_counts[age - 1] = age_counts[age]

			}


		}

		age_counts = new_counts

		day_end_count := 0
		for age_count in age_counts {
			day_end_count += age_count
		}

		fmt.printf("after {} days: {}\n", day, day_end_count)
	}


}

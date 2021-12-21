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
		input, ok := os.read_entire_file("2021-19-ex.txt")
		assert(ok)
		input_string := string(input)
		input_left = input_string
	}

	scanners: [dynamic][dynamic][3]int

	for len(input_left) > 0 {

		assert(input_left[:12] == "--- scanner ")
		newline_index := strings.index_any(input_left, "\r\n")
		assert(newline_index != -1)
		input_left = input_left[newline_index + 1:]

		skip_newlines :: proc(input: string) -> string {
			input_left := input
			for len(input_left) > 0 && (input_left[0] == '\r' || input_left[0] == '\n') {
				input_left = input_left[1:]
			}
			return input_left
		}

		input_left = skip_newlines(input_left)

		scanner_readings: [dynamic][3]int

		for len(input_left) >= 3 && input_left[:3] != "---" {

			read_number :: proc(input: string, at: string) -> (int, string) {
				input_left := input
				at_index := strings.index_any(input_left, at)
				assert(at_index != -1)
				num, ok := strconv.parse_int(input_left[:at_index])
				assert(ok)
				input_left = input_left[at_index + 1:]
				return num, input_left
			}

			coord: [3]int
			coord.x, input_left = read_number(input_left, ",")
			coord.y, input_left = read_number(input_left, ",")
			coord.z, input_left = read_number(input_left, "\r\n")

			append(&scanner_readings, coord)

			input_left = skip_newlines(input_left)

		}

		append(&scanners, scanner_readings)

	}

	fmt.println(scanners)

	identity: matrix[3, 3]int
	identity[0] = [3]int{1, 0, 0}
	identity[1] = [3]int{0, 1, 0}
	identity[2] = [3]int{0, 0, 1}

	fmt.println(m * [3]int{5, 6, 7})

}

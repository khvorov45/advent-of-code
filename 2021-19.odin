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
		input, ok := os.read_entire_file("2021-19.txt")
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

	face_forward: matrix[3, 3]int
	face_forward[0] = [3]int{1, 0, 0}
	face_forward[1] = [3]int{0, 1, 0}
	face_forward[2] = [3]int{0, 0, 1}

	face_right: matrix[3, 3]int
	face_right[0] = [3]int{0, -1, 0}
	face_right[1] = [3]int{1, 0, 0}
	face_right[2] = [3]int{0, 0, 1}

	face_left: matrix[3, 3]int
	face_left[0] = [3]int{0, 1, 0}
	face_left[1] = [3]int{-1, 0, 0}
	face_left[2] = [3]int{0, 0, 1}

	face_back: matrix[3, 3]int
	face_back[0] = [3]int{-1, 0, 0}
	face_back[1] = [3]int{0, -1, 0}
	face_back[2] = [3]int{0, 0, 1}

	face_up: matrix[3, 3]int
	face_up[0] = [3]int{0, 0, 1}
	face_up[1] = [3]int{0, 1, 0}
	face_up[2] = [3]int{-1, 0, 0}

	face_down: matrix[3, 3]int
	face_down[0] = [3]int{0, 0, -1}
	face_down[1] = [3]int{0, 1, 0}
	face_down[2] = [3]int{1, 0, 0}

	face_directions: [6]matrix[3,
	3]int = {face_forward, face_right, face_left, face_back, face_up, face_down}

	tilt_none: matrix[3, 3]int
	tilt_none[0] = [3]int{1, 0, 0}
	tilt_none[1] = [3]int{0, 1, 0}
	tilt_none[2] = [3]int{0, 0, 1}

	tilt_left: matrix[3, 3]int
	tilt_left[0] = [3]int{1, 0, 0}
	tilt_left[1] = [3]int{0, 0, -1}
	tilt_left[2] = [3]int{0, 1, 0}

	tilt_right: matrix[3, 3]int
	tilt_right[0] = [3]int{1, 0, 0}
	tilt_right[1] = [3]int{0, 0, 1}
	tilt_right[2] = [3]int{0, -1, 0}

	tilt_upside_down: matrix[3, 3]int
	tilt_upside_down[0] = [3]int{1, 0, 0}
	tilt_upside_down[1] = [3]int{0, -1, 0}
	tilt_upside_down[2] = [3]int{0, 0, -1}

	tilt_directions: [4]matrix[3,
	3]int = {tilt_none, tilt_left, tilt_right, tilt_upside_down}

	scanners_transformed: [dynamic]int
	append(&scanners_transformed, 0)

	scanner_positions: [dynamic][3]int
	append(&scanner_positions, [3]int{0, 0, 0})

	for len(scanners_transformed) < len(scanners) {

		best_match_count := 0
		best_match_scanner_index := -1
		best_match_face: matrix[3, 3]int
		best_match_tilt: matrix[3, 3]int
		best_match_translation: [3]int

		search: for test_scanner, test_scanner_index in &scanners {

			already_transformed := false
			for scanner_transformed in scanners_transformed {
				if scanner_transformed == test_scanner_index {
					already_transformed = true
					break
				}
			}

			if !already_transformed {

				for compare_scanner_index_index := len(scanners_transformed) - 1;
				    compare_scanner_index_index >= 0;
				    compare_scanner_index_index -= 1 {

					compare_scanner_index := scanners_transformed[compare_scanner_index_index]
					compare_scanner := scanners[compare_scanner_index]

					for face_direction, face_direction_index in face_directions {
						for tilt_direction, tilt_direction_index in tilt_directions {

							for test_overlap in test_scanner {

								test_overlap_turned := face_direction * test_overlap
								test_overlap_rotated := tilt_direction * test_overlap_turned

								for compare_overlap in compare_scanner {

									translation := compare_overlap - test_overlap_rotated
									match_count := 0

									for test_reading in test_scanner {

										test_reading_turned := face_direction * test_reading
										test_reading_rotated := tilt_direction * test_reading_turned
										test_reading_translated := test_reading_rotated + translation

										for compare_reading in compare_scanner {
											if (compare_reading == test_reading_translated) {
												match_count += 1
											}
										}

									}

									if best_match_count < match_count {
										best_match_count = match_count
										best_match_scanner_index = test_scanner_index
										best_match_face = face_direction
										best_match_tilt = tilt_direction
										best_match_translation = translation
									}

									if match_count >= 12 {
										break search
									}

								}
							}

						}
					}

				}

			}

		}

		fmt.println(scanners_transformed, best_match_count, best_match_scanner_index)
		assert(best_match_count >= 12)

		for reading in &scanners[best_match_scanner_index] {
			reading_turned := best_match_face * reading
			reading_rotated := best_match_tilt * reading_turned
			reading_translated := reading_rotated + best_match_translation
			reading = reading_translated
		}
		append(&scanners_transformed, best_match_scanner_index)
		append(&scanner_positions, best_match_translation)

	}

	unique_readings: [dynamic][3]int

	for scanner in scanners {
		for reading in scanner {
			in_unique := false
			for unique_reading in unique_readings {
				if unique_reading == reading {
					in_unique = true
					break
				}
			}
			if !in_unique {
				append(&unique_readings, reading)
			}
		}
	}


	slice.sort_by(
		unique_readings[:],
		proc(r1: [3]int, r2: [3]int) -> bool {return r1.x < r2.x},
	)

	for reading in unique_readings {
		fmt.println(reading)
	}

	fmt.println(len(unique_readings))

	fmt.println(scanner_positions)

	max_delta := 0

	for r1_index in 0 ..< len(scanner_positions) {
		r1 := scanner_positions[r1_index]
		for r2_index in r1_index + 1 ..< len(scanner_positions) {
			r2 := scanner_positions[r2_index]
			delta := r1 - r2
			manhattan_distance := abs(delta.x) + abs(delta.y) + abs(delta.z)
			max_delta = max(max_delta, manhattan_distance)
		}
	}

	fmt.println(max_delta)

}

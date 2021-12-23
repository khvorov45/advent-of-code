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
		input, ok := os.read_entire_file("2021-20.txt")
		assert(ok)
		input_string := string(input)
		input_left = input_string
	}

	skip_spaces :: proc(input: string) -> (string, int) {
		input_left := input
		count := 0
		for len(input_left) > 0 && (input_left[0] == '\r' || input_left[0] == '\n') {
			input_left = input_left[1:]
			count += 1
		}
		return input_left, count
	}

	newline_char_count := 1
	if strings.index(input_left, "\r\n") != -1 || strings.index(input_left, "\n\r") != -1 {
		newline_char_count = 2
	}

	enchancement: [dynamic]bool

	print_hashes :: proc(input: []bool) {
		for ch in input {
			if ch {
				fmt.print('#')
			} else {
				fmt.print('.')
			}
		}
		fmt.print('\n')
	}

	for {

		ch := input_left[0]
		assert(ch == '#' || ch == '.')
		if ch == '#' {
			append(&enchancement, true)
		} else {
			append(&enchancement, false)
		}
		input_left = input_left[1:]

		newline_chars: int
		input_left, newline_chars = skip_spaces(input_left)
		if newline_chars == 2 * newline_char_count {
			break
		}

	}

	print_hashes(enchancement[:])

	image: [dynamic]bool
	image_dim: [2]int

	for len(input_left) > 0 {

		ch := input_left[0]

		switch ch {
		case '#':
			append(&image, true)
		case '.':
			append(&image, false)
		case:
			unreachable()
		}

		input_left = input_left[1:]
		if image_dim.y == 0 {
			image_dim.x += 1
		}

		skipped: int
		input_left, skipped = skip_spaces(input_left)
		if skipped > 0 {
			image_dim.y += 1
		}

	}

	for row in 0 ..< image_dim.y {
		print_hashes(image[row * image_dim.x:row * image_dim.x + image_dim.x])
	}

	fmt.println(image_dim)

	next_image: [dynamic]bool
	next_image_dim := image_dim + 2
	outer_region_is_lit := false

	for step in 1 .. 50 {

		for next_image_row in 0 ..< next_image_dim.y {
			image_row := next_image_row - 1
			for next_image_col in 0 ..< next_image_dim.x {
				image_col := next_image_col - 1

				number_seq_current := 0
				number_seq: [9]bool

				if outer_region_is_lit {
					for digit in &number_seq {
						digit = true
					}
				}

				for image_row_sample in image_row - 1 .. image_row + 1 {
					for image_col_sample in image_col - 1 .. image_col + 1 {

						row_in_bounds := image_row_sample >= 0 && image_row_sample < image_dim.y
						col_in_bounds := image_col_sample >= 0 && image_col_sample < image_dim.x
						if row_in_bounds && col_in_bounds {
							sample_index := image_row_sample * image_dim.x + image_col_sample
							number_seq[number_seq_current] = image[sample_index]
						}

						number_seq_current += 1

					}
				}

				number := 0
				cur_pow2 := 1
				for digit_index := 8; digit_index >= 0; digit_index -= 1 {
					number += int(number_seq[digit_index]) * cur_pow2
					cur_pow2 *= 2
				}

				enchancement_value := enchancement[number]
				append(&next_image, enchancement_value)

			}
		}

		if step == 50 {
			for row in 0 ..< next_image_dim.y {
				print_hashes(
					next_image[row * next_image_dim.x:row * next_image_dim.x + next_image_dim.x],
				)
			}
			fmt.println(next_image_dim)
		}

		lit := 0
		for pix in next_image {
			lit += int(pix)
		}
		fmt.println(lit)

		image, next_image = next_image, image
		image_dim = next_image_dim
		next_image_dim = image_dim + 2

		for pix in &next_image {
			pix = false
		}
		clear(&next_image)

		if enchancement[0] {
			outer_region_is_lit = !outer_region_is_lit
		}
	}

}

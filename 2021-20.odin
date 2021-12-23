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
		input, ok := os.read_entire_file("2021-20-ex.txt")
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
}

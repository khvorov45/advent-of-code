package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"

main :: proc() {

	input, ok := os.read_entire_file("2021-10.txt")
	assert(ok)

	input_string := string(input)
	input_left := input_string

	cur_line_expected_closers: [dynamic]u8
	error_score := 0
	line_completion_scores: [dynamic]int
	for len(input_left) > 0 {

		ch := input_left[0]
		input_left = input_left[1:]

		switch ch {
		case '(':
			append(&cur_line_expected_closers, ')')
		case '[':
			append(&cur_line_expected_closers, ']')
		case '{':
			append(&cur_line_expected_closers, '}')
		case '<':
			append(&cur_line_expected_closers, '>')

		case ')', ']', '}', '>':
			line_corrupted := pop(&cur_line_expected_closers) != ch
			if line_corrupted {
				line_end := strings.index_any(input_left, "\r\n")
				if line_end == -1 {
					input_left = input_left[len(input_left):]
				} else {
					input_left = input_left[line_end:]
				}

				cost := 3
				switch ch {
				case ']':
					cost = 57
				case '}':
					cost = 1197
				case '>':
					cost = 25137
				}
				error_score += cost

				for len(cur_line_expected_closers) > 0 {
					pop(&cur_line_expected_closers)
				}

			}


		case '\r', '\n':
			line_completion_score := 0
			for len(cur_line_expected_closers) > 0 {
				missing_closer := pop(&cur_line_expected_closers)
				cost := 1
				switch missing_closer {
				case ']':
					cost = 2
				case '}':
					cost = 3
				case '>':
					cost = 4
				}
				line_completion_score = line_completion_score * 5 + cost
			}
			if line_completion_score > 0 {
				append(&line_completion_scores, line_completion_score)
			}

		case:
			unreachable(fmt.tprintf("unexpected char: {}\n", ch))
		}

	}

	fmt.println(error_score)
	{
		to_sort := line_completion_scores[:]
		slice.sort(to_sort)
	}
	assert(len(line_completion_scores) % 2 == 1)
	{
		middle_score_index := len(line_completion_scores) / 2
		fmt.println(line_completion_scores[middle_score_index])
	}
}

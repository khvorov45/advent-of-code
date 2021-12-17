package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:unicode"

read_word :: proc(input: string, index: int) -> (string, string) {
	assert(index != -1)
	word := input[:index]
	input_left := input[index + 1:]
	return word, input_left
}

read_word_space :: proc(input: string) -> (string, string) {
	space_index := strings.index_any(input, " \r\n")
	word, input_left := read_word(input, space_index)
	return word, input_left
}

skip_spaces :: proc(input: string) -> string {
	input_left := input
	for
	    len(input_left) > 0 && (input_left[0] == ' ' || input_left[0] == '\r' || input_left[0] ==
	    '\n') {
		input_left = input_left[1:]
	}
	return input_left
}

main :: proc() {

	input, ok := os.read_entire_file("2021-14.txt")
	assert(ok)

	input_string := string(input)

	start, input_left := read_word_space(input_string)
	input_left = skip_spaces(input_left)

	rules: map[[2]u8]u8

	for len(input_left) > 0 {

		pair: string
		pair, input_left = read_word_space(input_left)

		assert(
			input_left[:3] == "-> ",
			fmt.tprintf("unexpected input after pair '{}': '{}'", pair, input_left[:3]),
		)
		input_left = input_left[3:]

		insertion := input_left[0]
		input_left = input_left[1:]

		rules[[2]u8{pair[0], pair[1]}] = insertion

		input_left = skip_spaces(input_left)
	}

	fmt.println(start)
	fmt.println(rules)

	cur_pair_counts: map[[2]u8]int
	for index in 1 ..< len(start) {
		pair := [2]u8{start[index - 1], start[index]}
		cur_pair_counts[pair] += 1
	}
	fmt.println(cur_pair_counts)

	new_pair_counts: map[[2]u8]int

	for step_index in 1 .. 40 {

		for pair, count in cur_pair_counts {

			insertion := rules[pair]

			new_pair1 := [2]u8{pair[0], insertion}
			new_pair_counts[new_pair1] += count

			new_pair2 := [2]u8{insertion, pair[1]}
			new_pair_counts[new_pair2] += count

		}

		new_pair_counts, cur_pair_counts = cur_pair_counts, new_pair_counts

		clear(&new_pair_counts)

	}

	fmt.println(cur_pair_counts)

	counts: map[u8]int

	first_pair := true
	for pair, count in cur_pair_counts {
		if first_pair {
			counts[pair[0]] += count
			first_pair = false
		}
		counts[pair[1]] += count
	}

	max_count := 0
	min_count := -1

	for ch, count in counts {
		max_count = max(max_count, count)
		if min_count == -1 {
			min_count = count
		} else {
			min_count = min(min_count, count)
		}
	}

	fmt.println(max_count, min_count, max_count - min_count)

}

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

	input, ok := os.read_entire_file("2021-8.txt")
	assert(ok)

	input_string := string(input)
	input_left := input_string

	entries: [dynamic]Entry

	for len(input_left) > 0 {

		read_segments :: proc(input: string) -> (string, string) {

			input_left := input

			space_index := strings.index_any(input_left, " \r\n")
			assert(space_index != -1, fmt.tprintf("no space in '{}'\n", input_left))
			segments_string := input_left[:space_index]
			input_left = input_left[space_index + 1:]

			return segments_string, input_left
		}

		unique_signals: [10]string
		for index in 0 .. 9 {
			segments: string
			segments, input_left = read_segments(input_left)
			unique_signals[index] = segments
		}
		assert(
			input_left[0] == '|',
			fmt.tprintf("unexpected end of unique signals: '%c'\n", input_left[0]),
		)
		input_left = input_left[1:]

		skip_spaces :: proc(input: string) -> string {
			input_left := input
			for
			    len(input_left) > 0 && (input_left[0] == '\n' || input_left[0] == '\r' || input_left[0] ==
			    ' ') {
				input_left = input_left[1:]
			}
			return input_left
		}

		input_left = skip_spaces(input_left)

		output_digits: [4]string
		for index in 0 .. 3 {
			segments: string
			segments, input_left = read_segments(input_left)
			output_digits[index] = segments
		}
		input_left = skip_spaces(input_left)

		entry := Entry{unique_signals, output_digits}
		append(&entries, entry)

	}

	easy_digit_count := 0
	for entry in entries {
		for out in entry.output_digits {
			n := len(out)
			if n == 2 || n == 4 || n == 3 || n == 7 {
				easy_digit_count += 1
			}
		}
	}
	fmt.println(easy_digit_count)

	sum_of_output_values := 0
	wire_map: map[rune]rune
	for entry in entries {

		for ch in 'a' .. 'g' {
			wire_map[ch] = 0
		}

		siglen2_1: string
		siglen3_7: string
		siglen4_4: string
		siglen7_8: string
		siglen6_all: [3]string
		siglen6_found_count := 0
		siglen5_all: [3]string
		siglen5_found_count := 0
		for signal in entry.unique_signals {

			switch len(signal) {
			case 2:
				siglen2_1 = signal
			case 3:
				siglen3_7 = signal
			case 4:
				siglen4_4 = signal
			case 7:
				siglen7_8 = signal
			case 6:
				siglen6_all[siglen6_found_count] = signal
				siglen6_found_count += 1
			case 5:
				siglen5_all[siglen5_found_count] = signal
				siglen5_found_count += 1
			}

		}

		a_search: for ch_siglen3 in siglen3_7 {
			for ch_siglen2 in siglen2_1 {
				if ch_siglen3 != ch_siglen2 {
					wire_map['a'] = ch_siglen3
					break a_search
				}
			}
		}

		siglen6_6: string
		siglen6_6_index: int
		for siglen6, index in siglen6_all {
			count := 0
			for ch6 in siglen6 {
				for ch2 in siglen2_1 {
					if ch6 == ch2 {
						count += 1
					}
				}
			}
			if count == 1 {
				siglen6_6 = siglen6
				siglen6_6_index = index
				break
			}
			assert(count == 2)
		}

		for ch7 in siglen7_8 {
			if strings.index_rune(siglen6_6, ch7) == -1 {
				wire_map['c'] = ch7
				for ch2 in siglen2_1 {
					if ch2 != ch7 {
						wire_map['f'] = ch2
						break
					}
				}
				break
			}
		}

		siglen5_5: string
		siglen5_5_index: int
		for siglen5, index in siglen5_all {
			if strings.index_rune(siglen5, wire_map['c']) == -1 {
				siglen5_5 = siglen5
				siglen5_5_index = index
				break
			}
		}

		for ch7 in siglen7_8 {
			if strings.index_rune(siglen5_5, ch7) == -1 && ch7 != wire_map['c'] {
				wire_map['e'] = ch7
			}
		}

		siglen6_0: string
		siglen6_9: string
		for siglen6, index in siglen6_all {
			if index != siglen6_6_index {
				if strings.index_rune(siglen6, wire_map['e']) == -1 {
					siglen6_9 = siglen6
				} else {
					siglen6_0 = siglen6
				}
			}
		}

		for ch7 in siglen7_8 {
			if strings.index_rune(siglen6_0, ch7) == -1 {
				wire_map['d'] = ch7
				break
			}
		}

		siglen5_2: string
		siglen5_3: string
		for siglen5, index in siglen5_all {
			if index != siglen5_5_index {
				if strings.index_rune(siglen5, wire_map['e']) == -1 {
					siglen5_3 = siglen5
				} else {
					siglen5_2 = siglen5
				}
			}
		}

		for ch7 in siglen7_8 {
			if strings.index_rune(siglen5_2, ch7) == -1 && ch7 != wire_map['f'] {
				wire_map['b'] = ch7
				break
			}
		}

		for ch7 in siglen7_8 {
			if ch7 != wire_map['a'] && ch7 != wire_map['b'] && ch7 != wire_map['c'] && ch7 != wire_map['d'] &&
			   ch7 != wire_map['e'] && ch7 != wire_map['f'] {
				wire_map['g'] = ch7
				break
			}
		}

		output_value := 0
		current_pow10 := 1000
		for output in entry.output_digits {

			digit := -1
			switch len(output) {
			case 2:
				digit = 1
			case 3:
				digit = 7
			case 4:
				digit = 4
			case 7:
				digit = 8

			case 6:
				switch {
				case strings.index_rune(output, wire_map['d']) == -1:
					digit = 0
				case strings.index_rune(output, wire_map['c']) == -1:
					digit = 6
				case strings.index_rune(output, wire_map['e']) == -1:
					digit = 9
				}

			case 5:
				b_off := strings.index_rune(output, wire_map['b']) == -1
				e_off := strings.index_rune(output, wire_map['e']) == -1
				switch {
				case b_off && strings.index_rune(output, wire_map['f']) == -1:
					digit = 2
				case b_off && e_off:
					digit = 3
				case strings.index_rune(output, wire_map['c']) == -1 && e_off:
					digit = 5
				}
			}

			assert(digit != -1)
			output_value += digit * current_pow10
			current_pow10 /= 10

		}

		sum_of_output_values += output_value
		//fmt.println(output_value)

	}

	fmt.println(sum_of_output_values)

}

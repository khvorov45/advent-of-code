package main

import "core:os"
import "core:unicode"
import "core:strconv"
import "core:strings"
import "core:fmt"

main :: proc() {

    input, ok := os.read_entire_file("2015-2.txt")
    assert(ok)

    input_string := string(input)

    string_left := input_string

    input_total := 0
    input_total_ribbon := 0
    for {

        first_newline_index := strings.index_any(string_left, "\r\n")
        line := string_left[:first_newline_index]

        line_total := 0
        line_total_ribbon := 0
        {
            read_number_and_advance_to_next :: proc(line: string) -> (int, string) {

                assert(len(line) > 0)

                line_left := line
                number_one_past_end := strings.index_proc(line_left, proc(ch: rune) -> bool {return !unicode.is_number(ch)})

                number_string: string

                if number_one_past_end == -1 {

                    number_string = line_left
                    line_left = line_left[len(line_left):]

                } else {

                    number_string = line_left[:number_one_past_end]
                    line_left = line_left[number_one_past_end:]

                    next_number := strings.index_proc(line_left, unicode.is_number)
                    assert(next_number != -1)
                    line_left = line_left[next_number:]

                }

                number, ok := strconv.parse_int(number_string)
                assert(ok)

                return number, line_left
            }

            line_left := line
            dim1, dim2, dim3: int
            dim1, line_left = read_number_and_advance_to_next(line_left)
            dim2, line_left = read_number_and_advance_to_next(line_left)
            dim3, line_left = read_number_and_advance_to_next(line_left)

            side1 := dim1 * dim2
            side2 := dim1 * dim3
            side3 := dim2 * dim3

            min_side := min(side1, side2, side3)

            line_total = 2 * (side1 + side2 + side3) + min_side

            per1 := 2 * (dim1 + dim2)
            per2 := 2 * (dim1 + dim3)
            per3 := 2 * (dim2 + dim3)

            min_per := min(per1, per2, per3)

            line_total_ribbon = dim1 * dim2 * dim3 + min_per

        }

        input_total += line_total
        input_total_ribbon += line_total_ribbon

        string_left = string_left[first_newline_index:]

        next_line_start := strings.index_proc(string_left, unicode.is_number)
        if next_line_start == -1 {
            break
        } else {
            string_left = string_left[next_line_start:]
        }

    }

    fmt.println(input_total)
    fmt.println(input_total_ribbon)

}

package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:unicode"
import "core:strconv"

main :: proc() {

    input, ok := os.read_entire_file("2021-1.txt")
    assert(ok)

    input_string := string(input)
    input_left := input_string

    prev_number := -1
    n_increases := 0

    line_index := 0
    n_increases_window3 := 0

    sum1 := -1
    sum2 := -1
    sum3 := -1

    for {

        first_newline_char := strings.index_any(input_left, "\r\n")

        {
            line := input_left[:first_newline_char]
            number, ok := strconv.parse_int(line)
            assert(ok)

            if prev_number != -1 && number - prev_number > 0 {
                n_increases += 1
            }

            prev_number = number

            switch {
                case line_index == 0:
                    sum1 = number
                case line_index == 1:
                    sum1 += number
                    sum2 = number
                case line_index == 2:
                    sum1 += number
                    sum2 += number
                    sum3 = number
                case:
                    sum2 += number
                    sum3 += number
                    if sum2 > sum1 {
                        n_increases_window3 += 1
                    }

                    sum1 = sum2
                    sum2 = sum3
                    sum3 = number
            }


        }

        input_left = input_left[first_newline_char:]
        next_line_start := strings.index_proc(input_left, unicode.is_number)

        if next_line_start == -1 {
            break
        } else {
            input_left = input_left[next_line_start:]
            line_index += 1
        }

    }

    fmt.println(n_increases)
    fmt.println(n_increases_window3)

}

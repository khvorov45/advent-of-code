package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:unicode"
import "core:strconv"

main :: proc() {

    input, ok := os.read_entire_file("2021-3.txt")
    assert(ok)

    input_string := string(input)
    input_left := input_string

    first_line := input_left[:strings.index_any(input_left, "\r\n")]
    zero_counts := make([]int, len(first_line))
    one_counts := make([]int, len(first_line))

    all_numbers: [dynamic]string

    for {

        number_string: string
        {
            next_newline := strings.index_any(input_left, "\r\n")
            assert(next_newline != -1)

            number_string = input_left[:next_newline]
            input_left = input_left[next_newline:]
        }

        append(&all_numbers, number_string)

        {
            for pos in 0..<len(number_string) {
                value := number_string[pos]
                switch value {
                    case '0':
                        zero_counts[pos] += 1
                    case '1':
                        one_counts[pos] += 1
                    case:
                        unreachable()
                }
            }
        }

        {
            next_line_start := strings.index_any(input_left, "10")
            if next_line_start == -1 {
                break
            } else {
                input_left = input_left[next_line_start:]
            }
        }

    }

    {
        current_pow2 := 1
        for pos in 1..<len(first_line) {
            current_pow2 *= 2
        }

        gamma_rate := 0
        epsilon_rate := 0

        for pos in 0..<len(first_line) {

            zero_count := zero_counts[pos]
            one_count := one_counts[pos]

            assert(zero_count != one_count)

            if one_count > zero_count {
                gamma_rate += current_pow2
            } else {
                epsilon_rate += current_pow2
            }

            current_pow2 /= 2

        }

        fmt.println(gamma_rate, epsilon_rate, gamma_rate * epsilon_rate)
    }

    {
        result_o2 := -1
        result_co2 := -1

        current_indices_o2 := make([]int, len(all_numbers))
        current_indices_co2 := make([]int, len(all_numbers))
        for index in 0..<len(all_numbers) {
            current_indices_o2[index] = index
            current_indices_co2[index] = index
        }

        for pos in 0..<len(first_line) {

            if len(current_indices_o2) == 1 && len(current_indices_co2) == 1 {

                break

            } else {

                if len(current_indices_o2) > 1 {

                    zero_count := 0
                    one_count := 0
                    for index_o2 in current_indices_o2 {
                        number := all_numbers[index_o2]
                        switch number[pos] {
                            case '0':
                                zero_count += 1
                            case '1':
                                one_count += 1
                            case:
                                unreachable()
                        }
                    }

                    o2_kept := 0
                    for index_o2 in current_indices_o2 {
                        number := all_numbers[index_o2]
                        keep0 := one_count < zero_count && number[pos] == '0'
                        keep1 := one_count >= zero_count && number[pos] == '1'
                        if keep0 || keep1 {
                            current_indices_o2[o2_kept] = index_o2
                            o2_kept += 1
                        }
                    }
                    assert(o2_kept > 0)
                    current_indices_o2 = current_indices_o2[:o2_kept]

                }

                if len(current_indices_co2) > 1 {

                    zero_count := 0
                    one_count := 0
                    for index_co2 in current_indices_co2 {
                        number := all_numbers[index_co2]
                        switch number[pos] {
                            case '0':
                                zero_count += 1
                            case '1':
                                one_count += 1
                            case:
                                unreachable()
                        }
                    }

                    co2_kept := 0
                    for index_co2 in current_indices_co2 {
                        number := all_numbers[index_co2]
                        keep0 := zero_count <= one_count && number[pos] == '0'
                        keep1 := one_count < zero_count && number[pos] == '1'
                        if keep0 || keep1 {
                            current_indices_co2[co2_kept] = index_co2
                            co2_kept += 1
                        }
                    }
                    assert(co2_kept > 0, fmt.tprintf("none found for co2 for pos {} in {}", pos, current_indices_co2))
                    current_indices_co2 = current_indices_co2[:co2_kept]

                }

            }

        }

        assert(len(current_indices_o2) == 1)
        assert(len(current_indices_co2) == 1)

        number_o2, o2_ok := strconv.parse_int(all_numbers[current_indices_o2[0]], 2)
        assert(o2_ok)
        number_co2, co2_ok := strconv.parse_int(all_numbers[current_indices_co2[0]], 2)
        assert(co2_ok)

        fmt.println(number_o2, number_co2, number_o2 * number_co2)

    }

}

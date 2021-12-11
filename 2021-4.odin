package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:unicode"
import "core:strconv"
import "core:unicode/utf8"

index_any :: proc(s, chars: string) -> int {
	if chars == "" {
		return -1
	}

	if len(chars) == 1 {
		r := rune(chars[0])
		if r >= utf8.RUNE_SELF {
			r = utf8.RUNE_ERROR
		}
		return strings.index_rune(s, r)
	}

	if len(s) > 8 {
		if as, ok := strings.ascii_set_make(chars); ok {
			for i in 0..<len(s) {
				if strings.ascii_set_contains(as, s[i]) {
					return i
				}
			}
			return -1
		}
	}

    min_i := len(s)
	for c in chars {
		if i := strings.index_rune(s, c); i >= 0 {
			min_i = min(min_i, i)
		}
	}
    if min_i < len(s) {
        return min_i
    }

	return -1
}

main :: proc() {

    input, ok := os.read_entire_file("2021-4.txt")
    assert(ok)

    input_string := string(input)
    input_left := input_string

    draw_numbers: [dynamic]int
    {
        newline_index := index_any(input_left, "\r\n")
        first_line := input_left[:newline_index]
        input_left = input_left[newline_index:]
        next_line_start := index_any(input_left, "0123456789")
        input_left = input_left[next_line_start:]

        first_line_left := first_line
        for len(first_line_left) > 0 {
            number_end := strings.index_rune(first_line_left, ',')
            next_number_start: int
            if number_end == -1 {
                number_end = len(first_line_left)
                next_number_start = number_end
            } else {
                next_number_start = number_end + 1
            }
            number_string := first_line_left[:number_end]
            first_line_left = first_line_left[next_number_start:]

            number, ok := strconv.parse_int(number_string)
            assert(ok)
            append(&draw_numbers, number)
        }
    }

    Board :: struct {
        numbers: [25]int,
        sum_unmarked: int,
    }

    boards: [dynamic]Board
    for len(input_left) > 0 {
        board: Board
        for row_index in 0..4 {
            board_row := board.numbers[row_index * 5:]
            for col_index in 0..4 {
                number_end := index_any(input_left, " \r\n")
                assert(number_end != -1, fmt.tprintf("no number found for board, {}, {}, {}, {}", len(input_left), row_index, col_index, board))
                number_string := input_left[:number_end]
                input_left = input_left[number_end:]

                number, ok := strconv.parse_int(number_string)
                assert(ok)
                board_row[col_index] = number
                board.sum_unmarked += number

                next_number_start := index_any(input_left, "0123456789")

                if next_number_start == -1 {
                    input_left = input_left[len(input_left):]
                } else {
                    input_left = input_left[next_number_start:]
                }
            }
        }
        append(&boards, board)
    }

    board_highlight_counts_rows := make([][5]int, len(boards))
    board_highlight_counts_cols := make([][5]int, len(boards))

    winning_board_count := 0
    winning_board_indices := make([]int, len(boards))
    for index in &winning_board_indices {
        index = -1
    }

    first_winning_board_snapshot: Board
    first_winning_draw_number := -1

    last_winning_board_snapshot: Board
    last_winning_draw_number := -1

    draw_number_loop: for draw_number, draw_number_index in draw_numbers {

        for board, board_index in &boards {

            highlight_counts_rows := &board_highlight_counts_rows[board_index]
            highlight_counts_cols := &board_highlight_counts_cols[board_index]

            for row_index in 0..4 {
                for col_index in 0..4 {
                    board_number := board.numbers[row_index * 5 + col_index]
                    if board_number == draw_number {
                        highlight_counts_rows[row_index] += 1
                        highlight_counts_cols[col_index] += 1
                        board.sum_unmarked -= draw_number
                    }
                }
            }

            for dim_index in 0..4 {

                row_counts := highlight_counts_rows[dim_index]
                col_counts := highlight_counts_cols[dim_index]

                if row_counts == 5 || col_counts == 5 {

                    won_already := false
                    for winning_board_index in winning_board_indices[:winning_board_count] {
                        if winning_board_index == board_index {
                            won_already = true
                            break
                        }
                    }

                    if !won_already {

                        winning_board_indices[winning_board_count] = board_index
                        winning_board_count += 1

                        if winning_board_count == 1 {
                            first_winning_draw_number = draw_number
                            first_winning_board_snapshot = board
                        }

                        if winning_board_count == len(boards) {
                            last_winning_draw_number = draw_number
                            last_winning_board_snapshot = board
                            break draw_number_loop
                        }

                    }

                }
            }

        }

    }

    assert(winning_board_count == len(boards))

    fmt.println(
        winning_board_indices[0],
        first_winning_board_snapshot.sum_unmarked,
        first_winning_draw_number,
        first_winning_board_snapshot.sum_unmarked * first_winning_draw_number,
    )

    fmt.println(
        winning_board_indices[len(boards) - 1],
        first_winning_board_snapshot.sum_unmarked,
        last_winning_draw_number,
        last_winning_board_snapshot.sum_unmarked * last_winning_draw_number,
    )

}

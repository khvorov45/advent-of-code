package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:unicode"
import "core:strconv"

Command :: enum {
    None,
    Forward,
    Up,
    Down,
}

main :: proc() {

    input, ok := os.read_entire_file("2021-2.txt")
    assert(ok)

    input_string := string(input)
    input_left := input_string

    hor_pos := 0
    depth := 0

    aim := 0
    aim_depth := 0

    for {

        read_cmd :: proc(input: string) -> (Command, string) {

            next_space := strings.index_rune(input, ' ')
            assert(next_space != -1)

            cmd_string := input[:next_space]
            left := input[next_space:]

            cmd: Command
            switch {
                case cmd_string == "forward":
                    cmd = .Forward
                case cmd_string == "up":
                    cmd = .Up
                case cmd_string == "down":
                    cmd = .Down
            }
            assert(cmd != .None, fmt.tprintf("failed to parse command '{}'", cmd_string))

            return cmd, left
        }

        cmd: Command
        cmd, input_left = read_cmd(input_left)

        input_left = input_left[1:]

        read_number :: proc(input: string) -> (int, string) {

            next_space := strings.index_any(input, "\r\n")
            assert(next_space != -1)

            number_string := input[:next_space]
            left := input[next_space:]

            number, ok := strconv.parse_int(number_string)
            assert(ok)

            return number, left
        }

        number: int
        number, input_left = read_number(input_left)

        switch cmd {
            case .Forward:
                hor_pos += number
                aim_depth += aim * number
            case .Down:
                depth += number
                aim += number
            case .Up:
                depth -= number
                aim -= number
            case .None:
                unreachable()
        }

        next_line_start := strings.index_proc(input_left, unicode.is_alpha)

        if next_line_start == -1 {
            break
        } else {
            input_left = input_left[next_line_start:]
        }

    }

    fmt.println(depth, hor_pos, depth * hor_pos)
    fmt.println(aim_depth, hor_pos, aim_depth * hor_pos)

}

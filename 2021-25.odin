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
		input, ok := os.read_entire_file("2021-25.txt")
		assert(ok)
		input_string := string(input)
		input_left = input_string
	}

    Cucumber :: enum {
        None,
        East,
        South,
    }

    cucumbers: [dynamic]Cucumber
    cucumbers_dim: [2]int

    for len(input_left) > 0 {


        switch input_left[0] {
        case '.':
            append(&cucumbers, Cucumber.None)
        case '>':
            append(&cucumbers, Cucumber.East)
        case 'v':
            append(&cucumbers, Cucumber.South)
        case '\r', '\n':
            cucumbers_dim.y += 1
            for len(input_left) > 0 && (input_left[0] == '\r' || input_left[0] == '\n') {
                input_left = input_left[1:]
            }
            continue
        }

        input_left = input_left[1:]
        if cucumbers_dim.y == 0 {
            cucumbers_dim.x += 1
        }

    }

    print_state :: proc(input: []Cucumber, dim: [2]int) {
        for row in 0..<dim.y {
            for col in 0..<dim.x {
                switch input[row * dim.x + col] {
                case .None:
                    fmt.print('.')
                case .East:
                    fmt.print('>')
                case .South:
                    fmt.print('v')
                }
            }
            fmt.print('\n')
        }
    }

    cur_state := make([]Cucumber, len(cucumbers))
    next_state := make([]Cucumber, len(cucumbers))

    for val, index in cucumbers {
        cur_state[index] = val
    }

    for iteration := 1;; iteration += 1 {

        //fmt.println("=======================")
        //print_state(cur_state, cucumbers_dim)

        for val in &next_state {
            val = .None
        }

        moved_anything := false

        for row in 0..<cucumbers_dim.y {
            for col in 0..<cucumbers_dim.x {
                index := row * cucumbers_dim.x + col
                if cur_state[index] == .East {
                    next_col := (col + 1) % cucumbers_dim.x
                    next_index := row * cucumbers_dim.x + next_col
                    if cur_state[next_index] == .None {
                        next_state[next_index] = .East
                        moved_anything = true
                    } else {
                        next_state[index] = .East
                    }
                }
            }
        }

        for row in 0..<cucumbers_dim.y {
            for col in 0..<cucumbers_dim.x {
                index := row * cucumbers_dim.x + col
                if cur_state[index] == .South {
                    next_row := (row + 1) % cucumbers_dim.y
                    next_index := next_row * cucumbers_dim.x + col
                    if cur_state[next_index] != .South && next_state[next_index] == .None {
                        moved_anything = true
                        next_state[next_index] = .South
                    } else {
                        next_state[index] = .South
                    }
                }
            }
        }

        cur_state, next_state = next_state, cur_state

        if !moved_anything {
            fmt.println(iteration)
            break
        }
    }

    //fmt.println("=======================")
    //print_state(cur_state, cucumbers_dim)

}

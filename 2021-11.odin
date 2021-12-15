package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"

main :: proc() {

	input, ok := os.read_entire_file("2021-11.txt")
	assert(ok)

	input_string := string(input)
	input_left := input_string

	energies: [100]int
	cur_energy_index := 0
	for len(input_left) > 0 {

		ch := input_left[0]

		if ch != '\r' && ch != '\n' {
			number, ok := strconv.parse_int(input_left[0:1])
			assert(ok)
			energies[cur_energy_index] = number
			cur_energy_index += 1
		}

		input_left = input_left[1:]
	}
	assert(cur_energy_index == 100)

	to_flash_buf: [100]int
	to_flash_arr := to_flash_buf[:0]
	flashed_map: [100]bool
	total_flashes := 0
	first_sync_flash := -1

	for step_index := 1;; step_index += 1 {

		to_flash_arr := to_flash_buf[:0]
		for flashed in &flashed_map {
			flashed = false
		}

		for energy, index in &energies {
			energy += 1
			if energy > 9 {
				to_flash_arr = to_flash_buf[0:len(to_flash_arr) + 1]
				to_flash_arr[len(to_flash_arr) - 1] = index
			}
		}

		for len(to_flash_arr) > 0 {

			to_flash := to_flash_arr[len(to_flash_arr) - 1]
			to_flash_arr = to_flash_buf[:len(to_flash_arr) - 1]

			assert(!flashed_map[to_flash])

			if step_index <= 100 {
				total_flashes += 1
			}

			energies[to_flash] = 0
			flashed_map[to_flash] = true

			to_flash_row := to_flash / 10
			to_flash_col := to_flash - to_flash_row * 10

			for other_row := max(0, to_flash_row - 1);
			    other_row <= min(9, to_flash_row + 1);
			    other_row += 1 {
				for other_col := max(0, to_flash_col - 1);
				    other_col <= min(9, to_flash_col + 1);
				    other_col += 1 {

					if other_row != to_flash_row || other_col != to_flash_col {

						other_index := other_row * 10 + other_col

						if !flashed_map[other_index] {

							already_scheduled := false
							for to_flash_future in to_flash_arr {
								if to_flash_future == other_index {
									already_scheduled = true
									break
								}
							}

							if !already_scheduled {
								energies[other_index] += 1
								if energies[other_index] > 9 {
									to_flash_arr = to_flash_buf[0:len(to_flash_arr) + 1]
									to_flash_arr[len(to_flash_arr) - 1] = other_index
								}
							}

						}
					}

				}
			}

		}

		synced_flash := true
		for flashed in flashed_map {
			if !flashed {
				synced_flash = false
				break
			}
		}
		if synced_flash {
			if first_sync_flash == -1 {
				first_sync_flash = step_index
			}
		}

		if first_sync_flash != -1 && step_index > 100 {
			break
		}

	}

	fmt.println(total_flashes)

	assert(first_sync_flash != -1)
	fmt.println(first_sync_flash)

}

package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:unicode"

main :: proc() {

	start_positions := [2]int{10, 3}

	player_turn_index := 0
	other_turn_index := 1

	Universe :: struct {
		scores:    [2]int,
		positions: [2]int,
	}

	universe_counts_current: map[Universe]int
	universe_counts_current[Universe{[2]int{0, 0}, start_positions}] = 1

	universe_counts_next: map[Universe]int

	won_counts: [2]int

	die_outcomes: [dynamic]int
	one_die_outcome := [3]int{1, 2, 3}
	for d1 in one_die_outcome {
		for d2 in one_die_outcome {
			for d3 in one_die_outcome {
				append(&die_outcomes, d1 + d2 + d3)
			}
		}
	}

	step := 1
	for len(universe_counts_current) > 0 {

		assert(len(universe_counts_next) == 0)

		for universe, count in universe_counts_current {

			for die_outcome in die_outcomes {

				new_universe := universe

				new_pos := ((die_outcome + universe.positions[player_turn_index] - 1) % 10) + 1
				new_universe.positions[player_turn_index] = new_pos
				new_universe.scores[player_turn_index] += new_pos

				if new_universe.scores[player_turn_index] >= 21 {
					won_counts[player_turn_index] += count
				} else {
					universe_counts_next[new_universe] += count
				}

			}
		}

		//fmt.println(universe_counts_current)
		//fmt.println(universe_counts_next)
		//fmt.println("====")

		universe_counts_current, universe_counts_next = universe_counts_next, universe_counts_current
		clear(&universe_counts_next)
		player_turn_index, other_turn_index = other_turn_index, player_turn_index

		if step == 2 {
			//break
		}
		step += 1

	}

	fmt.println(won_counts)

}

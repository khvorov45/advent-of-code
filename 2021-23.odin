package main

import "core:fmt"
import "core:slice"
import "core:time"

// Taken from https://github.com/Mesoptier/advent-of-code-2021/blob/master/src/days/day23.rs

ROOM_COUNT :: 4
ROOM_SIZE :: 4
HALLWAY_LENGTH :: 11
ROOM_HALLWAY_POSITIONS: [4]int : {2, 4, 6, 8}
AMP_COUNT :: 8


AmpKind :: enum {
	A,
	B,
	C,
	D,
}

State :: struct {
	hallway: [HALLWAY_LENGTH]Maybe(AmpKind),
	rooms: [ROOM_COUNT][ROOM_SIZE]Maybe(AmpKind),
}

Transition :: struct {
	state: State,
	cost: int,
}

get_target_room_index :: proc(amp_kind: AmpKind) -> int {
	return int(amp_kind)
}

get_energy :: proc(amp_kind: AmpKind) -> int {
	energy := 1
	switch amp_kind {
	case .A:
	case .B:
		energy *= 10
	case .C:
		energy *= 100
	case .D:
		energy *= 1000
	}
	return energy
}

from_room_index :: proc(room_index: int) -> AmpKind {
	assert(room_index >= 0 && room_index < ROOM_COUNT)
	return AmpKind(room_index)
}

encode :: proc(state: State) -> u64 {

	encode_space :: proc(space: Maybe(AmpKind)) -> u64 {
		result: u64 = 0
		if space != nil {
			result = u64(get_target_room_index(space.(AmpKind)) + 1)
		}
		return result
	}

	get_new_result :: proc(old: u64, space: Maybe(AmpKind)) -> u64 {
		result := old * u64(5) + encode_space(space)
		return result
	}

	result: u64 = 0
	for room in state.rooms {
		for room_slot in room {
			result = get_new_result(result, room_slot)
		}
	}
	for hallway in state.hallway {
		result = get_new_result(result, hallway)
	}

	return result
}

decode :: proc(encoded: u64) -> State {

	state: State

	decode_space :: proc(encoded_space: u64) -> Maybe(AmpKind) {
		result: Maybe(AmpKind)
		if encoded_space != 0 {
			assert(encoded_space >= 1 && encoded_space <= 4)
			result = AmpKind(encoded_space - 1)
		}
		return result
	}

	next_space :: proc(cur_encoded: u64) -> (space: Maybe(AmpKind), next_encoded: u64) {
		encoded_space := cur_encoded % 5
		next_encoded = cur_encoded / 5
		space = decode_space(encoded_space)
		return space, next_encoded
	}

	cur_encoded := encoded

	for hallway_index := len(state.hallway) - 1; hallway_index >= 0; hallway_index -= 1 {
		state.hallway[hallway_index], cur_encoded = next_space(cur_encoded)
	}

	for room_index := len(state.rooms) - 1; room_index >= 0; room_index -= 1 {
		room := &state.rooms[room_index]
		for room_slot := len(room) - 1; room_slot >= 0; room_slot -= 1 {
			room[room_slot], cur_encoded = next_space(cur_encoded)
		}
	}

	return state
}

is_room_enterable :: proc(state: State, room_index: int) -> bool {
	result := true
	for slot in state.rooms[room_index] {
		if slot != nil {
			if get_target_room_index(slot.(AmpKind)) != room_index {
				result = false
				break
			}
		}
	}
	return result
}

is_room_exitable :: proc(state: State, room_index: int) -> bool {
	result := !is_room_enterable(state, room_index)
	return result
}

get_room_hallway_position :: proc(room_index: int) -> int {
	room_hallway_position := ROOM_HALLWAY_POSITIONS
	return room_hallway_position[room_index]
}

is_above_room :: proc(hallway_index: int) -> bool {
	result := false
	for pos in ROOM_HALLWAY_POSITIONS {
		if pos == hallway_index {
			result = true
			break
		}
	}
	return result
}

is_hallway_clear :: proc(state: State, start: int, end: int) -> bool {
	result := true
	if start != end {
		step := start < end ? 1 : -1
		for pos := start + step; pos != end + step; pos += step {
			if state.hallway[pos] != nil {
				result = false
				break
			}
		}
	}
	return result
}

room_to_hallway_transitions :: proc(state: State, storage: ^[dynamic]Transition) {

	for room, room_index in state.rooms {
		if is_room_exitable(state, room_index) {

			topmost_kind: AmpKind
			topmost_depth: int
			for slot, slot_index in room {
				if slot != nil {
					topmost_kind = slot.(AmpKind)
					topmost_depth = slot_index
					break
				}
			}

			cur_hallway_index := get_room_hallway_position(room_index)

			start := [2]int{cur_hallway_index + 1, cur_hallway_index - 1}
			steps := [2]int{1, -1}
			stops := [2]int{len(state.hallway), -1}

			for start, dir_index in start {

				step := steps[dir_index]
				stop := stops[dir_index]

				step_count := 1 + topmost_depth

				for cur_hallway_index := start; cur_hallway_index != stop; cur_hallway_index += step {
					if state.hallway[cur_hallway_index] == nil {
						step_count += 1
						if !is_above_room(cur_hallway_index) {
							energy := step_count * get_energy(topmost_kind)
							new_state := state
							new_state.hallway[cur_hallway_index], new_state.rooms[room_index][topmost_depth] =
								new_state.rooms[room_index][topmost_depth], new_state.hallway[cur_hallway_index]
							transition := Transition{new_state, energy}
							append(storage, transition)
						}
					} else {
						break
					}
				}

			}

		}
	}

}

hallway_to_room_transitions :: proc(state: State, storage: ^[dynamic]Transition) {

	for hallway_slot, hallway_index in state.hallway {

		if hallway_slot != nil {

			amp := hallway_slot.(AmpKind)
			target_room_index := get_target_room_index(amp)

			if is_room_enterable(state, target_room_index) {

				target_hallway_index := get_room_hallway_position(target_room_index)

				if is_hallway_clear(state, hallway_index, target_hallway_index) {

					target_room := state.rooms[target_room_index]

					target_room_depth: int
					for slot, slot_index in target_room {
						if slot == nil {
							target_room_depth = slot_index
						}
					}

					steps := target_room_depth + 1 + abs(hallway_index - target_hallway_index)
					energy := steps * get_energy(amp)

					new_state := state
					new_state.rooms[target_room_index][target_room_depth], new_state.hallway[hallway_index] =
						new_state.hallway[hallway_index], new_state.rooms[target_room_index][target_room_depth]

					transition := Transition{new_state, energy}

					append(storage, transition)

				}

			}

		}

	}

}

estimate_cost :: proc(state: State) -> int {

	cost := 0

	// NOTE(sen) Cost to move from where they are to the space above target
	// and for target amps to enter the rooms
	for room, room_index in state.rooms {

		room_hallway_position := get_room_hallway_position(room_index)

		// NOTE(sen) First from bottom that's either nil or has the wrong amp
		deepest_slot_that_needs_to_move := len(room) - 1
		for ; deepest_slot_that_needs_to_move >= 0; deepest_slot_that_needs_to_move -= 1 {

			slot := room[deepest_slot_that_needs_to_move]

			if slot != nil {

				amp := slot.(AmpKind)
				amp_target := get_target_room_index(amp)

				if amp_target != room_index {
					break
				}


			} else {
				break
			}

		}

		for slot_index := deepest_slot_that_needs_to_move; slot_index >= 0; slot_index -= 1 {

			slot := room[slot_index]

			// NOTE(sen) Target amp should move in here at some point
			target_amp := from_room_index(room_index)
			steps := slot_index + 1
			cost += steps * get_energy(target_amp)

			if slot != nil {

				// NOTE(sen) This one needs to exit the room and move to the space above target
				amp := slot.(AmpKind)
				amp_target := get_target_room_index(amp)
				amp_target_hallway := get_room_hallway_position(amp_target)

				hallway_steps := 2
				if amp_target != room_index {
					hallway_steps = abs(amp_target_hallway - room_hallway_position)
				}
				steps := slot_index + 1 + hallway_steps

				cost += steps * get_energy(amp)
			}

		}

	}

	// NOTE(sen) Energy for hallway amps to move to space above target
	for hallway, hallway_index in state.hallway {

		if hallway != nil {

			amp := hallway.(AmpKind)
			amp_target_room_index := get_target_room_index(amp)
			amp_target_hallway_index := get_room_hallway_position(amp_target_room_index)

			steps := abs(amp_target_hallway_index - hallway_index)

			cost += steps * get_energy(amp)
		}

	}

	return cost

}

main :: proc() {

	time_program_start := time.now()

	target_state: State
	target_state.rooms = [ROOM_COUNT][ROOM_SIZE]Maybe(AmpKind){
		{.A, .A, .A, .A},
		{.B, .B, .B, .B},
		{.C, .C, .C, .C},
		{.D, .D, .D, .D},
	}
	assert(target_state == decode(encode(target_state)))

	init_state: State
	when false {
		init_state.rooms = [ROOM_COUNT][ROOM_SIZE]Maybe(AmpKind){
			{.B, .D, .D, .A},
			{.C, .C, .B, .D},
			{.B, .B, .A, .C},
			{.D, .A, .C, .A},
		}
	} else {
		init_state.rooms = [ROOM_COUNT][ROOM_SIZE]Maybe(AmpKind){
			{.B, .D, .D, .B},
			{.C, .C, .B, .C},
			{.A, .B, .A, .D},
			{.D, .A, .C, .A},
		}
	}

	OpenSetEntry :: struct {
		state: State,
		f_score: int,
	}

	open_set: [dynamic]OpenSetEntry
	append(&open_set, OpenSetEntry{init_state, estimate_cost(init_state)})

	g_score: map[State]int
	g_score[init_state] = 0

	transitions: [dynamic]Transition

	time_spent_sorting := 0.0

	for len(open_set) > 0 {

		open_set_entry := pop(&open_set)
		current_state := open_set_entry.state
		f_score := open_set_entry.f_score

		if current_state == target_state {
			fmt.println(f_score)
			break
		}

		current_g_score := g_score[current_state]

		clear(&transitions)
		room_to_hallway_transitions(current_state, &transitions)
		hallway_to_room_transitions(current_state, &transitions)

		for transition in transitions {

			tentative_g_score := current_g_score + transition.cost

			transition_g_score, transition_g_score_exists := g_score[transition.state]

			if !transition_g_score_exists || tentative_g_score < transition_g_score {

				g_score[transition.state] = tentative_g_score

				new_f_score := tentative_g_score + estimate_cost(transition.state)
				new_open_set_entry := OpenSetEntry{transition.state, new_f_score}

				append(&open_set, new_open_set_entry)

				// NOTE(sen) Move backwards into place so that open_set remains sorted
				time_sort_start := time.now()
				for open_set_index := len(open_set) - 2; open_set_index >= 0; open_set_index -= 1 {
					if open_set[open_set_index].f_score < new_f_score {
						open_set[open_set_index], open_set[open_set_index + 1] =
							open_set[open_set_index + 1], open_set[open_set_index]
					}
				}
				time_sort_end := time.since(time_sort_start)
				time_spent_sorting += time.duration_milliseconds(time_sort_end)

			}

		}

	}

	time_program_end := time.since(time_program_start)

	fmt.println(time.duration_milliseconds(time_program_end), time_spent_sorting)

}

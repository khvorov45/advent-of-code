package main

import "core:fmt"
import "core:slice"
import "core:time"

ROOM_COUNT :: 4
HALLWAY_LENGTH :: 11
ROOM_HALLWAY_POSITIONS: [4]int : {2, 4, 6, 8}
AMP_COUNT :: 8

Position :: union {
	Hallway,
	Room,
}

Hallway :: distinct int

Room :: struct {
	room:  int,
	front: bool,
}

Amp :: struct {
	kind: AmpKind,
	pos:  Position,
}

AmpKind :: enum {
	A,
	B,
	C,
	D,
}

Amps :: [AMP_COUNT]Amp

Node :: struct {
	amps:      Amps,
	occupancy: Occupancy,
}

Occupancy :: struct {
	hallway: [HALLWAY_LENGTH]Maybe(AmpKind),
	rooms:   [ROOM_COUNT]struct {
		front, back: Maybe(AmpKind),
	},
}

get_needed_room_index :: proc(amp_kind: AmpKind) -> int {
	return int(amp_kind)
}

get_cost_from_steps :: proc(step_count: int, amp_kind: AmpKind) -> int {
	cost := step_count
	switch amp_kind {
	case .A:
		cost *= 1
	case .B:
		cost *= 10
	case .C:
		cost *= 100
	case .D:
		cost *= 1000
	}
	return cost
}

estimate_cheapest_cost :: proc(amps: Amps) -> int {

	est_cost := 0
	room_hallway_positions := ROOM_HALLWAY_POSITIONS

	for amp in amps {

		steps := 0

		needed_room_index := get_needed_room_index(amp.kind)
		needed_hallway_index := room_hallway_positions[needed_room_index]

		switch pos in amp.pos {
		case Room:
			room_hallway_index := room_hallway_positions[pos.room]
			if room_hallway_index != needed_hallway_index {
				steps += abs(room_hallway_index - needed_room_index) + 2
				if !pos.front {
					steps += 1
				}
			}
		case Hallway:
			steps += abs(needed_hallway_index - int(pos)) + 1
		}

		cost := get_cost_from_steps(steps, amp.kind)

		est_cost += cost
	}

	return est_cost
}

print_amps :: proc(amps: Amps) {
	for hall_index in 0 ..< HALLWAY_LENGTH {
		found_amp: Maybe(Amp)
		for amp in amps {
			if amp_hall, ok := amp.pos.(Hallway); ok {
				if int(amp_hall) == hall_index {
					found_amp = amp
					break
				}
			}
		}
		if found_amp == nil {
			fmt.print('.')
		} else {
			fmt.print(found_amp.(Amp).kind)
		}
	}
	fmt.print("\n  ")

	for room_index in 0 ..< ROOM_COUNT {
		found_amp: Maybe(Amp)
		for amp in amps {
			if amp_room, ok := amp.pos.(Room); ok {
				if amp_room.room == room_index && amp_room.front {
					found_amp = amp
					break
				}
			}
		}
		if found_amp == nil {
			fmt.print('.')
		} else {
			fmt.print(found_amp.(Amp).kind)
		}
		fmt.print(' ')
	}
	fmt.print("\n  ")

	for room_index in 0 ..< ROOM_COUNT {
		found_amp: Maybe(Amp)
		for amp in amps {
			if amp_room, ok := amp.pos.(Room); ok {
				if amp_room.room == room_index && !amp_room.front {
					found_amp = amp
					break
				}
			}
		}
		if found_amp == nil {
			fmt.print('.')
		} else {
			fmt.print(found_amp.(Amp).kind)
		}
		fmt.print(' ')
	}

	fmt.print('\n')
}

get_occupancy :: proc(amps: Amps) -> Occupancy {
	occupancy: Occupancy
	for amp in amps {
		switch pos in amp.pos {
		case Room:
			if pos.front {
				occupancy.rooms[pos.room].front = amp.kind
			} else {
				occupancy.rooms[pos.room].back = amp.kind
			}
		case Hallway:
			occupancy.hallway[int(pos)] = amp.kind
		}
	}
	return occupancy
}

main :: proc() {

	nodes: [dynamic]Node
	{
		init_top := [ROOM_COUNT]AmpKind{.B, .C, .A, .D}
		init_bot := [ROOM_COUNT]AmpKind{.B, .C, .D, .A}
		first_node: Node
		for amp, amp_index in &first_node.amps {
			if amp_index < ROOM_COUNT {
				amp = Amp{init_top[amp_index], Room{amp_index, true}}
			} else {
				room_index := amp_index - ROOM_COUNT
				amp = Amp{init_bot[room_index], Room{room_index, false}}
			}
		}
		for room, room_index in &first_node.occupancy.rooms {
			room.front = init_top[room_index]
			room.back = init_bot[room_index]
		}
		first_node.occupancy = get_occupancy(first_node.amps)
		append(&nodes, first_node)
	}

	came_from: map[Amps]Amps

	costs_from_start: map[Amps]int
	costs_from_start[nodes[0].amps] = 0

	total_costs: map[Amps]int
	total_costs[nodes[0].amps] = estimate_cheapest_cost(nodes[0].amps)

	Move :: struct {
		amp_index: int,
		pos:       Position,
		cost:      int,
	}
	possible_moves: [dynamic]Move

	time_get_node := 0.0
	time_total := 0.0

	for iteration_index := 1; len(nodes) > 0; iteration_index += 1 {

		iteration_start := time.now()

		// NOTE(sen) Sort the "open set" so that the lowest cost node is at the end
		{
			context.user_ptr = &total_costs
			nodes_sort_proc :: proc(n1: Node, n2: Node) -> bool {
				total_costs := cast(^map[Amps]int)context.user_ptr
				n1_cost := total_costs[n1.amps]
				n2_cost := total_costs[n2.amps]
				/*fmt.println(n1_cost)
				fmt.println(n2_cost)
				print_amps(n1.amps)
				print_amps(n2.amps)*/
				assert(n1_cost != 0)
				assert(n2_cost != 0)
				return n1_cost > n2_cost
			}
			slice.sort_by(nodes[:], nodes_sort_proc)
		}

		node := pop(&nodes)
		assert(node.occupancy == get_occupancy(node.amps))
		time_get_node += time.duration_seconds(time.since(iteration_start))

		//print_amps(node.amps)

		node_is_sorted := true
		{
			sort_check: for amp in node.amps {
				switch pos in amp.pos {
				case Room:
					needed_room_index := get_needed_room_index(amp.kind)
					if needed_room_index != pos.room {
						node_is_sorted = false
						break sort_check
					}
				case Hallway:
					node_is_sorted = false
					break sort_check
				}
			}
		}

		if node_is_sorted {
			print_amps(node.amps)
			for parent, ok := came_from[node.amps]; ok; parent, ok = came_from[parent] {
				print_amps(parent)
			}
			fmt.println(costs_from_start[node.amps])
			break
		}

		// NOTE(sen) Find all possible moves
		{
			clear(&possible_moves)
			for amp, amp_index in node.amps {

				room_hallway_positions := ROOM_HALLWAY_POSITIONS

				amp_target_room_index := get_needed_room_index(amp.kind)
				amp_target_room_hallway := room_hallway_positions[amp_target_room_index]

				switch_pos: switch pos in amp.pos {
				case Room:
					// NOTE(sen) See if the amp is already where it needs to be
					{
						if pos.room == amp_target_room_index {
							if pos.front {
								if node.occupancy.rooms[pos.room].back == amp.kind {
									break switch_pos
								}
							} else {
								break switch_pos
							}
						}
					}

					// NOTE(sen) See if the room can be left
					{
						if !pos.front {
							if node.occupancy.rooms[pos.room].front != nil {
								break switch_pos
							}
						}
					}

					start_hallway_pos := [2]int{
						room_hallway_positions[pos.room] - 1,
						room_hallway_positions[pos.room] + 1,
					}
					steps := [2]int{-1, 1}
					breaks := [2]int{-1, HALLWAY_LENGTH}

					for start_hallway_pos, start_pos_index in start_hallway_pos {

						total_steps := 1
						if !pos.front {
							total_steps += 1
						}

						dir_search: for cur_hallway_index := start_hallway_pos;
						    cur_hallway_index != breaks[start_pos_index];
						    cur_hallway_index += steps[start_pos_index] {

							total_steps += 1

							if cur_hallway_index == amp_target_room_hallway {

								// NOTE(sen) See if target room is free
								steps_to_ender := 1
								going_to_front := true
								{
									if node.occupancy.rooms[amp_target_room_index].front != nil {
										continue
									}
									back_occupant := node.occupancy.rooms[amp_target_room_index].back
									if back_occupant != nil {
										if back_occupant.(AmpKind) != amp.kind {
											continue
										}
									} else {
										going_to_front = false
										steps_to_ender += 1
									}
								}

								cost := get_cost_from_steps(total_steps + steps_to_ender, amp.kind)

								append(
									&possible_moves,
									Move{amp_index, Room{amp_target_room_index, going_to_front}, cost},
								)

								break dir_search
							}

							facing_any_room := false
							for room_hallway in room_hallway_positions {
								if cur_hallway_index == room_hallway {
									facing_any_room = true
									break
								}
							}
							if facing_any_room {
								continue
							}

							if node.occupancy.hallway[cur_hallway_index] != nil {
								break dir_search
							}

							cost := get_cost_from_steps(total_steps, amp.kind)

							append(&possible_moves, Move{amp_index, Hallway(cur_hallway_index), cost})

						}
					}


				case Hallway:
					// NOTE(sen) See if target room can be reached
					total_steps := 2
					{
						step := amp_target_room_hallway > int(pos) ? 1 : -1
						for cur_hallway := int(pos) + step;
						    cur_hallway != amp_target_room_hallway;
						    cur_hallway += step {
							total_steps += 1
							if node.occupancy.hallway[cur_hallway] != nil {
								break switch_pos
							}
						}
					}

					// NOTE(sen) See if target room is free
					going_to_front := true
					{
						if node.occupancy.rooms[amp_target_room_index].front != nil {
							break switch_pos
						}
						back_occupant := node.occupancy.rooms[amp_target_room_index].back
						if back_occupant != nil {
							if back_occupant.(AmpKind) != amp.kind {
								break switch_pos
							}
						} else {
							going_to_front = false
							total_steps += 1
						}
					}

					cost := get_cost_from_steps(total_steps, amp.kind)

					append(
						&possible_moves,
						Move{amp_index, Room{amp_target_room_index, going_to_front}, cost},
					)

				}
			}
		}

		for move in possible_moves {

			//fmt.println(move)

			new_node := node
			new_node.amps[move.amp_index].pos = move.pos

			current_cost, current_cost_exists := costs_from_start[node.amps]
			assert(current_cost_exists)

			should_add := false
			tentative_cost_from_start := current_cost + move.cost
			if existing_cost_from_start, ok := costs_from_start[new_node.amps]; !ok {
				should_add = true
			} else if tentative_cost_from_start < existing_cost_from_start {
				should_add = true
			}

			if !should_add {
				continue
			}

			switch pos in node.amps[move.amp_index].pos {
			case Room:
				if pos.front {
					new_node.occupancy.rooms[pos.room].front = nil
				} else {
					new_node.occupancy.rooms[pos.room].back = nil
				}
			case Hallway:
				new_node.occupancy.hallway[int(pos)] = nil
			}

			switch pos in new_node.amps[move.amp_index].pos {
			case Room:
				if pos.front {
					new_node.occupancy.rooms[pos.room].front = new_node.amps[move.amp_index].kind
				} else {
					new_node.occupancy.rooms[pos.room].back = new_node.amps[move.amp_index].kind
				}
			case Hallway:
				new_node.occupancy.hallway[int(pos)] = new_node.amps[move.amp_index].kind
			}

			came_from[new_node.amps] = node.amps
			costs_from_start[new_node.amps] = tentative_cost_from_start
			new_est_cheap_cost := estimate_cheapest_cost(new_node.amps)
			total_costs[new_node.amps] = tentative_cost_from_start + new_est_cheap_cost

			already_in_nodes := false
			for existing_node in nodes {
				if existing_node.amps == new_node.amps {
					already_in_nodes = true
					assert(existing_node.occupancy == new_node.occupancy)
					break
				}
			}
			if !already_in_nodes {
				append(&nodes, new_node)
			}

		}

		time_total += time.duration_seconds(time.since(iteration_start))

		if iteration_index % 100 == 0 {
			fmt.println(iteration_index, len(nodes), time_get_node, time_total)
		}

	}

}

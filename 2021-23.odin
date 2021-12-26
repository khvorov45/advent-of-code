package main

import "core:fmt"

main :: proc() {

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
		kind: enum {
			None,
			A,
			B,
			C,
			D,
		},
		pos:  Position,
	}

	Node :: struct {
		amps: [8]Amp,
		free: struct {
			hallway: [11]bool,
			rooms:   [4]struct {
				front, back: bool,
			},
		},
	}

	estimate_cheapest_cost :: proc(amps: [8]Amp) -> int {

		est_cost := 0

		for amp in amps {

			cost := 0

			needed_room_index := int(amp.kind) - 1
			needed_hallway_index := needed_room_index * 2 + 2

			if room, ok := amp.pos.(Room); ok {
				room_hallway_index := room.room * 2 + 2
				if room_hallway_index != needed_hallway_index {
					cost = abs(room_hallway_index - needed_room_index) + 2
				}
			} else {
				cost = abs(needed_hallway_index - int(amp.pos.(Hallway))) + 1
			}

			#partial switch amp.kind {
			case .B:
				cost *= 10
			case .C:
				cost *= 100
			case .D:
				cost *= 1000
			}

			est_cost += cost
		}

		return est_cost
	}

	nodes: [dynamic]Node
	{
		first_node: Node
		first_node.amps = [8]Amp{
			{.B, Room{0, true}},
			{.A, Room{0, false}},
			{.C, Room{1, true}},
			{.D, Room{1, false}},
			{.B, Room{2, true}},
			{.C, Room{2, false}},
			{.D, Room{3, true}},
			{.A, Room{3, false}},
		}
		for slot in &first_node.free.hallway {
			slot = true
		}
		print_node(first_node.amps)
		append(&nodes, first_node)
	}

	all_room_hallway_pos: [4]int = {2, 4, 6, 8}

	print_node :: proc(amps: [8]Amp) {
		for hall_index in 0 .. 10 {
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

		for room_index in 0 .. 3 {
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

		for room_index in 0 .. 3 {
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

	came_from: map[[8]Amp][8]Amp

	costs_from_start: map[[8]Amp]int
	costs_from_start[nodes[0].amps] = 0

	total_costs: map[[8]Amp]int
	total_costs[nodes[0].amps] = estimate_cheapest_cost(nodes[0].amps)

	for len(nodes) > 0 {

		fmt.println(len(nodes))
		{
			cheapest_index := 0
			cheapest_cost := total_costs[nodes[0].amps]
			for node, index in nodes[1:] {
				if total_costs[node.amps] < cheapest_cost {
					cheapest_cost = total_costs[node.amps]
					cheapest_index = index + 1
				}
			}
			nodes[cheapest_index], nodes[len(nodes) - 1] = nodes[len(nodes) - 1], nodes[cheapest_index]
		}

		node := pop(&nodes)

		//fmt.println("============================")
		//print_node(node.amps)

		all_set := true
		for amp in node.amps {
			if room, ok := amp.pos.(Room); ok {
				needed_room_index := int(amp.kind) - 1
				if needed_room_index != room.room {
					all_set = false
					break
				}
			} else {
				all_set = false
				break
			}
		}

		if !all_set {

			for amp, amp_index in node.amps {

				needed_room_index := int(amp.kind) - 1
				room_hallway_pos := all_room_hallway_pos[needed_room_index]

				switch pos in amp.pos {

				case Room:
					should_not_move := false

					if pos.room == needed_room_index {
						if !pos.front {
							should_not_move = true
						} else {
							for other in node.amps {
								if other != amp && other.kind == amp.kind {
									if other_room, ok := other.pos.(Room); ok {
										if other_room.room == needed_room_index {
											assert(!other_room.front)
											should_not_move = true
										}
									}
								}
							}
						}
					}

					if !should_not_move && (pos.front || node.free.rooms[pos.room].front) {

						start_hallway_pos := [2]int{
							all_room_hallway_pos[pos.room] - 1,
							all_room_hallway_pos[pos.room] + 1,
						}
						steps := [2]int{-1, 1}
						breaks := [2]int{-1, len(node.free.hallway)}
						/*breaks := [2]int{
							max(start_hallway_pos[0] - 1, 0),
							min(start_hallway_pos[1] + 1, 10),
						}*/

						for start_hallway_pos, start_pos_index in start_hallway_pos {

							for cur_hallway_index := start_hallway_pos;
							    cur_hallway_index != breaks[start_pos_index];
							    cur_hallway_index += steps[start_pos_index] {

								if cur_hallway_index != all_room_hallway_pos[0] && cur_hallway_index != all_room_hallway_pos[1] &&
								   cur_hallway_index != all_room_hallway_pos[2] && cur_hallway_index != all_room_hallway_pos[3] {

									if node.free.hallway[cur_hallway_index] {

										new_amp := amp
										new_amp.pos = Hallway(cur_hallway_index)

										new_node := node
										new_node.amps[amp_index] = new_amp
										new_node.free.hallway[cur_hallway_index] = false

										if pos.front {
											new_node.free.rooms[pos.room].front = true
										} else {
											new_node.free.rooms[pos.room].back = true
										}

										add_cost_from_start := abs(start_hallway_pos - cur_hallway_index) + 2
										if !pos.front {
											add_cost_from_start += 1
										}

										#partial switch amp.kind {
										case .B:
											add_cost_from_start *= 10
										case .C:
											add_cost_from_start *= 100
										case .D:
											add_cost_from_start *= 1000
										}

										new_cost_from_start := costs_from_start[node.amps] + add_cost_from_start

										existing_cost_from_start, ok := costs_from_start[new_node.amps]
										if !ok || new_cost_from_start < existing_cost_from_start {

											came_from[new_node.amps] = node.amps
											costs_from_start[new_node.amps] = new_cost_from_start
											new_cheapest_cost := estimate_cheapest_cost(new_node.amps)
											total_costs[new_node.amps] = new_cost_from_start + new_cheapest_cost
											already_exists := false
											for existing_node in nodes {
												if existing_node.amps == new_node.amps {
													assert(existing_node.free == new_node.free)
													already_exists = true
													break
												}
											}
											if !already_exists {
												append(&nodes, new_node)
											}

										}

									}
									else {
										break
									}

								} else if cur_hallway_index == room_hallway_pos {

									should_not_enter := false
									if node.free.rooms[needed_room_index].front {
										if !node.free.rooms[needed_room_index].back {
											for other in node.amps {
												if other.kind != amp.kind {
													if other_room, ok := other.pos.(Room); ok {
														if other_room.room == needed_room_index {
															assert(!other_room.front)
															should_not_enter = true
														}
													}
												}
											}
										}
									}

									if !should_not_enter && node.free.rooms[needed_room_index].front {
										room := Room({needed_room_index, true})
										if node.free.rooms[needed_room_index].back {
											room.front = false
										}

										new_amp := amp
										new_amp.pos = room

										new_node := node

										new_node.amps[amp_index] = new_amp

										add_cost_from_start := abs(room_hallway_pos - all_room_hallway_pos[pos.room])
										add_cost_from_start += 2

										if pos.front {
											new_node.free.rooms[pos.room].front = true
										} else {
											new_node.free.rooms[pos.room].back = true
											add_cost_from_start += 1
										}

										if room.front {
											new_node.free.rooms[room.room].front = false
										} else {
											new_node.free.rooms[room.room].back = false
											add_cost_from_start += 1
										}

										#partial switch amp.kind {
										case .B:
											add_cost_from_start *= 10
										case .C:
											add_cost_from_start *= 100
										case .D:
											add_cost_from_start *= 1000
										}

										new_cost_from_start := costs_from_start[node.amps] + add_cost_from_start

										existing_cost_from_start, ok := costs_from_start[new_node.amps]
										if !ok || new_cost_from_start < existing_cost_from_start {

											came_from[new_node.amps] = node.amps
											costs_from_start[new_node.amps] = new_cost_from_start
											new_cheapest_cost := estimate_cheapest_cost(new_node.amps)
											total_costs[new_node.amps] = new_cost_from_start + new_cheapest_cost
											already_exists := false
											for existing_node in nodes {
												if existing_node.amps == new_node.amps {
													assert(existing_node.free == new_node.free)
													already_exists = true
													break
												}
											}
											if !already_exists {
												append(&nodes, new_node)
											}

										}

									}

								}

							}

						}

					}

				case Hallway:
					step := room_hallway_pos > int(pos) ? 1 : -1

					can_go := true
					for hallway_pos := int(pos) + step;
					    hallway_pos != room_hallway_pos;
					    hallway_pos += step {
						if !node.free.hallway[hallway_pos] {
							can_go = false
							break
						}
					}

					should_not_enter := false
					if node.free.rooms[needed_room_index].front {
						if !node.free.rooms[needed_room_index].back {
							for other in node.amps {
								if other.kind != amp.kind {
									if other_room, ok := other.pos.(Room); ok {
										if other_room.room == needed_room_index {
											assert(!other_room.front)
											should_not_enter = true
										}
									}
								}
							}
						}
					}

					if !should_not_enter && can_go && node.free.rooms[needed_room_index].front {
						room := Room({needed_room_index, true})
						if node.free.rooms[needed_room_index].back {
							room.front = false
						}

						new_amp := amp
						new_amp.pos = room

						new_node := node

						new_node.amps[amp_index] = new_amp

						new_node.free.hallway[int(pos)] = true

						add_cost_from_start := abs(room_hallway_pos - int(pos)) + 1

						if room.front {
							new_node.free.rooms[room.room].front = false
						} else {
							new_node.free.rooms[room.room].back = false
							add_cost_from_start += 1
						}

						#partial switch amp.kind {
						case .B:
							add_cost_from_start *= 10
						case .C:
							add_cost_from_start *= 100
						case .D:
							add_cost_from_start *= 1000
						}

						new_cost_from_start := costs_from_start[node.amps] + add_cost_from_start

						existing_cost_from_start, ok := costs_from_start[new_node.amps]
						if !ok || new_cost_from_start < existing_cost_from_start {

							came_from[new_node.amps] = node.amps
							costs_from_start[new_node.amps] = new_cost_from_start
							new_cheapest_cost := estimate_cheapest_cost(new_node.amps)
							total_costs[new_node.amps] = new_cost_from_start + new_cheapest_cost
							already_exists := false
							for existing_node in nodes {
								if existing_node.amps == new_node.amps {
									assert(existing_node.free == new_node.free)
									already_exists = true
									break
								}
							}
							if !already_exists {
								append(&nodes, new_node)
							}

						}

					}

				} // switch pos

			} // for amp

		} else {
			fmt.println(costs_from_start[node.amps])
			print_node(node.amps)
			for parent, ok := came_from[node.amps]; ok; parent, ok = came_from[parent] {
				print_node(parent)
			}
			break
		}

		if len(nodes) == 0 {
			fmt.println(costs_from_start[node.amps])
			print_node(node.amps)
			for parent, ok := came_from[node.amps]; ok; parent, ok = came_from[parent] {
				print_node(parent)
			}
		}

	}

}

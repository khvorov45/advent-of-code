package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:unicode"

main :: proc() {

	input, ok := os.read_entire_file("2021-12.txt")
	assert(ok)

	input_string := string(input)
	input_left := input_string

	Cave :: struct {
		name:        string,
		big:         bool,
		connections: [dynamic]CaveId,
	}

	CaveId :: distinct int

	caves: [dynamic]Cave
	start_id := CaveId(-1)

	for len(input_left) > 0 {

		read_cave :: proc(
			input: string,
			name_one_past_end: int,
			existing_caves: ^[dynamic]Cave,
		) -> (
			CaveId,
			string,
		) {

			assert(name_one_past_end != -1)
			input_left := input
			cave_name := input_left[:name_one_past_end]
			input_left = input_left[name_one_past_end + 1:]

			cave_id := CaveId(-1)
			for existing_cave, index in existing_caves {
				if cave_name == existing_cave.name {
					cave_id = CaveId(index)
					break
				}
			}

			if cave_id == -1 {
				cave_id = CaveId(len(existing_caves))
				cave_connections: [dynamic]CaveId
				cave_big := unicode.is_upper(rune(cave_name[0]))
				cave := Cave{cave_name, cave_big, cave_connections}
				append(existing_caves, cave)
			}

			return cave_id, input_left
		}

		dash_index := strings.index_rune(input_left, '-')
		cave_id1: CaveId
		cave_id1, input_left = read_cave(input_left, dash_index, &caves)

		newline_index := strings.index_any(input_left, "\r\n")
		cave_id2: CaveId
		cave_id2, input_left = read_cave(input_left, newline_index, &caves)

		assert(cave_id1 != cave_id2)
		append(&caves[cave_id1].connections, cave_id2)
		append(&caves[cave_id2].connections, cave_id1)

		if caves[cave_id1].name == "start" {
			start_id = cave_id1
		} else if caves[cave_id2].name == "start" {
			start_id = cave_id2
		}

		for len(input_left) > 0 && (input_left[0] == '\r' || input_left[0] == '\n') {
			input_left = input_left[1:]
		}

	}

	assert(start_id != CaveId(-1))

	Node :: struct {
		id:      CaveId,
		parents: [dynamic]CaveId,
	}

	nodes: [dynamic]Node
	append(&nodes, Node{start_id, nil})

	total_paths := 0

	for len(nodes) > 0 {


		node := pop(&nodes)

		for connection in caves[node.id].connections {

			is_in_parents := false
			for parent in node.parents {
				if parent == connection {
					is_in_parents = true
					break
				}
			}

			connected_cave := caves[connection]
			if !is_in_parents || connected_cave.big {

				if connected_cave.name == "end" {
					total_paths += 1
				} else {
					new_parents: [dynamic]CaveId
					for parent in node.parents {
						append(&new_parents, parent)
					}
					append(&new_parents, node.id)
					append(&nodes, Node{connection, new_parents})
				}

			}

		}

	}

	fmt.println(total_paths)

}

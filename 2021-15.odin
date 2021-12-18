package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:unicode"

main :: proc() {

	input, ok := os.read_entire_file("2021-15.txt")
	assert(ok)

	input_string := string(input)

	input_left := input_string

	Node :: struct {
		index:           int,
		risk:            int,
		cost_from_start: int,
		est_cost_to_end: int,
		came_from:       int,
	}

	all_nodes_fake: [dynamic]Node
	newline := true
	n_col_fake := 0
	n_row_fake := 0

	for len(input_left) > 0 {

		if newline {
			n_col_fake = 0
			n_row_fake += 1
			newline = false
		}

		ch := input_left[0:1]
		input_left = input_left[1:]

		risk, ok := strconv.parse_int(ch)
		assert(ok, fmt.tprintf("failed to parse {}\n", ch))

		node := Node{len(all_nodes_fake), risk, -1, -1, -1}

		append(&all_nodes_fake, node)
		n_col_fake += 1

		for len(input_left) > 0 && (input_left[0] == '\r' || input_left[0] == '\n') {
			newline = true
			input_left = input_left[1:]
		}

	}

	calc_est_cost_to_end :: proc(index, n_row, n_col: int) -> int {
		node_row := index / n_col
		node_col := index - node_row * n_col
		est_cost_to_end := (n_row - node_row - 1) + (n_col - node_col - 1)
		return est_cost_to_end
	}

	for node in &all_nodes_fake {
		node.est_cost_to_end = calc_est_cost_to_end(node.index, n_row_fake, n_col_fake)
	}

	all_nodes_fake[0].cost_from_start = 0

	n_col_real := n_col_fake * 5
	n_row_real := n_row_fake * 5
	all_nodes_real := make([]Node, n_col_real * n_row_real)

	for node, index_real in &all_nodes_real {

		node.est_cost_to_end = calc_est_cost_to_end(node.index, n_row_fake, n_col_fake)
		node.index = index_real
		node.came_from = -1
		node.cost_from_start = -1

		node_row_real := index_real / n_col_real
		node_col_real := index_real - node_row_real * n_col_real

		row_unit := node_row_real / n_row_fake
		col_unit := node_col_real / n_col_fake

		node_row_fake := node_row_real - row_unit * n_row_fake
		node_col_fake := node_col_real - col_unit * n_col_fake

		index_fake := node_row_fake * n_col_fake + node_col_fake
		risk_fake := all_nodes_fake[index_fake].risk

		risk_real := risk_fake + row_unit + col_unit
		if risk_real > 9 {
			risk_real -= 9
		}

		node.risk = risk_real

	}

	all_nodes_real[0].cost_from_start = 0

	all_nodes := all_nodes_real
	n_col := n_col_real
	n_row := n_row_real

	for row in 0..<n_row {
		for col in 0..<n_col {
			//node := all_nodes[row * n_col + col]
			//fmt.print(node.risk)
		}
		//fmt.print('\n')
	}

	open_nodes: [dynamic]Node
	append(&open_nodes, all_nodes[0])

	for len(open_nodes) > 0 {

		node := Node{-1, -1, -1, -1, -1}
		{
			current_lowest := 0
			assert(open_nodes[0].cost_from_start != -1)
			assert(open_nodes[0].est_cost_to_end != -1)
			current_lowest_cost := open_nodes[0].cost_from_start + open_nodes[0].est_cost_to_end

			for node, index in open_nodes[1:] {
				assert(node.cost_from_start != -1)
				assert(node.est_cost_to_end != -1)
				cost := node.cost_from_start + node.est_cost_to_end
				if cost < current_lowest_cost {
					current_lowest_cost = cost
					current_lowest = index + 1
				}
			}

			last := len(open_nodes) - 1
			open_nodes[current_lowest], open_nodes[last] = open_nodes[last], open_nodes[current_lowest]

			node = pop(&open_nodes)
			assert(node.cost_from_start != -1)
			assert(node.est_cost_to_end != -1)
		}
		assert(node.index != -1)

		if node.index == len(all_nodes) - 1 {
			parent_node := node
			fmt.println(node)
			for {
				//fmt.println(parent_node)
				if parent_node.came_from == -1 {
					break
				}
				parent_node = all_nodes[parent_node.came_from]
			}
			break
		}

		node_row := node.index / n_col
		node_col := node.index - node_row * n_col

		neighbors_buf: [4]int
		n_neighbors := 0
		if node_row > 0 {
			neighbors_buf[n_neighbors] = (node_row - 1) * n_col + node_col
			n_neighbors += 1
		}
		if node_row < n_row - 1 {
			neighbors_buf[n_neighbors] = (node_row + 1) * n_col + node_col
			n_neighbors += 1
		}
		if node_col > 0 {
			neighbors_buf[n_neighbors] = node.index - 1
			n_neighbors += 1
		}
		if node_col < n_col - 1 {
			neighbors_buf[n_neighbors] = node.index + 1
			n_neighbors += 1
		}

		neighbors := neighbors_buf[:n_neighbors]

		for neighbor_index in neighbors {

			neighbor := &all_nodes[neighbor_index]
			new_cost_from_start := node.cost_from_start + neighbor.risk

			if neighbor.cost_from_start == -1 || new_cost_from_start < neighbor.cost_from_start {

				neighbor.came_from = node.index
				neighbor.cost_from_start = new_cost_from_start

				is_in_open_set := false
				for node in open_nodes {
					if node.index == neighbor_index {
						is_in_open_set = true
						break
					}
				}
				if !is_in_open_set {
					append(&open_nodes, neighbor^)
				}

			}

		}

	}

}

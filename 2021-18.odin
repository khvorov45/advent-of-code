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
		input, ok := os.read_entire_file("2021-18.txt")
		assert(ok)
		input_string := string(input)
		input_left = input_string
	}

	Element :: union {
		int,
		NonTerminal,
	}

	NonTerminal :: struct {
		left:  ^Element,
		right: ^Element,
	}

	roots: [dynamic]^Element

	for len(input_left) > 0 {

		read_pair :: proc(input: string) -> (^Element, string) {

			input_left := input

			read_element :: proc(input: string, start, end: u8) -> (^Element, string) {
				input_left := input
				assert(input_left[0] == start)
				input_left = input_left[1:]
				element := new(Element)
				if input_left[0] == '[' {
					element, input_left = read_pair(input_left)
				} else {
					up_to_index := strings.index_byte(input_left, end)
					assert(up_to_index != -1)
					num, ok := strconv.parse_int(input_left[:up_to_index])
					assert(ok)
					element^ = num
					input_left = input_left[up_to_index:]
				}
				return element, input_left
			}

			non_terminal: NonTerminal
			non_terminal.left, input_left = read_element(input_left, '[', ',')
			non_terminal.right, input_left = read_element(input_left, ',', ']')

			assert(input_left[0] == ']')
			input_left = input_left[1:]

			root := new(Element)
			root^ = non_terminal

			return root, input_left
		}

		pair: ^Element
		pair, input_left = read_pair(input_left)
		append(&roots, pair)

		for len(input_left) > 0 && (input_left[0] == '\r' || input_left[0] == '\n') {
			input_left = input_left[1:]
		}

	}

	print_tree :: proc(root: ^Element) {
		switch val in root {
		case int:
			fmt.print(val)
		case NonTerminal:
			fmt.print('[')
			print_tree(val.left)
			fmt.print(",")
			print_tree(val.right)
			fmt.print("]")
		}
	}

	copy_tree :: proc(root: ^Element) -> ^Element {
		new_root := new(Element)
		switch val in root {
		case int:
			new_root^ = val
		case NonTerminal:
			new_non_terminal: NonTerminal
			new_non_terminal.left = copy_tree(val.left)
			new_non_terminal.right = copy_tree(val.right)
			new_root^ = new_non_terminal
		}
		return new_root
	}


	DepthProbe :: struct {
		el:    ^Element,
		depth: int,
	}
	depth_probes: [dynamic]DepthProbe

	add :: proc(
		el1: ^Element,
		el2: ^Element,
		depth_probes: ^[dynamic]DepthProbe,
	) -> ^Element {

		new_non_terminal := NonTerminal{el1, el2}
		new_element := new(Element)
		new_element^ = new_non_terminal

		for {

			assert(len(depth_probes) == 0)
			append(depth_probes, DepthProbe{new_element, 0})

			leftmost_pair_nested4: ^Element
			last_seen_left_num: ^Element

			leftmost_big_number: ^Element

			depth_search: for len(depth_probes) > 0 {

				probe := pop(depth_probes)

				switch val in probe.el {
				case int:
					last_seen_left_num = probe.el
					if val >= 10 && leftmost_big_number == nil {
						leftmost_big_number = probe.el
					}
				case NonTerminal:
					if probe.depth == 4 {
						leftmost_pair_nested4 = probe.el
						break depth_search
					} else {
						new_depth := probe.depth + 1
						append(depth_probes, DepthProbe{val.right, new_depth})
						append(depth_probes, DepthProbe{val.left, new_depth})
					}
				}

			}

			if leftmost_pair_nested4 != nil {

				leftmost_pair_nested4_val := leftmost_pair_nested4.(NonTerminal)

				if last_seen_left_num != nil {
					last_seen_left_num_val := last_seen_left_num.(int)
					temp := cast(^int)last_seen_left_num
					temp^ = last_seen_left_num_val + leftmost_pair_nested4_val.left.(int)
				}

				if len(depth_probes) > 0 {
					for len(depth_probes) > 0 {
						probe := pop(depth_probes)
						switch val in probe.el {
						case int:
							temp := cast(^int)probe.el
							temp^ += leftmost_pair_nested4_val.right.(int)
							clear(depth_probes)
						case NonTerminal:
							new_depth := probe.depth + 1
							append(depth_probes, DepthProbe{val.right, new_depth})
							append(depth_probes, DepthProbe{val.left, new_depth})
						}
					}
				}

				free(leftmost_pair_nested4_val.left)
				free(leftmost_pair_nested4_val.right)
				leftmost_pair_nested4^ = 0

			} else if leftmost_big_number != nil {

				leftmost_big_number_val := leftmost_big_number.(int)
				split_left := leftmost_big_number_val / 2
				split_right := (leftmost_big_number_val + 1) / 2
				split: NonTerminal
				split.left = new(Element)
				split.right = new(Element)
				split.left^ = split_left
				split.right^ = split_right
				leftmost_big_number^ = split

			} else {

				break
			}

		}

		return new_element

	}

	cur_result := copy_tree(roots[0])

	for root in roots[1:] {

		cur_result = add(cur_result, copy_tree(root), &depth_probes)

	}

	calc_mag :: proc(el: ^Element) -> int {
		result: int
		switch val in el {
		case int:
			result = val
		case NonTerminal:
			result = 3 * calc_mag(val.left) + 2 * calc_mag(val.right)
		}
		return result
	}

	fmt.println(calc_mag(cur_result))

	max_mag := 0
	for root1 in roots {
		for root2 in roots {

			if root1 != root2 {
				num := add(copy_tree(root1), copy_tree(root2), &depth_probes)
				mag := calc_mag(num)
				max_mag = max(max_mag, mag)
			}

		}
	}

	fmt.println(max_mag)

}

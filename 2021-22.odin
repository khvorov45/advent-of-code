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
		input, ok := os.read_entire_file("2021-22.txt")
		assert(ok)
		input_string := string(input)
		input_left = input_string
	}

	Instruction :: struct {
		on:      bool,
		x, y, z: [2]int,
	}

	instructions: [dynamic]Instruction

	for len(input_left) > 0 {

		instruction: Instruction

		switch {
		case input_left[:2] == "on":
			instruction.on = true
			input_left = input_left[3:]
		case input_left[:3] == "off":
			instruction.on = false
			input_left = input_left[4:]
		case:
			unreachable(fmt.tprintf("unexpected input: '{}'\n", input_left))
		}

		read_number :: proc(input: string, start: string, end: string) -> (int, string) {
			input_left := input
			assert(input_left[:len(start)] == start)
			input_left = input_left[len(start):]
			num_end_index := strings.index_any(input_left, end)
			assert(num_end_index != -1)
			num, ok := strconv.parse_int(input_left[:num_end_index])
			assert(ok)
			input_left = input_left[num_end_index:]
			return num, input_left
		}

		instruction.x[0], input_left = read_number(input_left, "x=", ".")
		instruction.x[1], input_left = read_number(input_left, "..", ",")

		instruction.y[0], input_left = read_number(input_left, ",y=", ".")
		instruction.y[1], input_left = read_number(input_left, "..", ",")

		instruction.z[0], input_left = read_number(input_left, ",z=", ".")
		instruction.z[1], input_left = read_number(input_left, "..", "\r\n")

		append(&instructions, instruction)

		for len(input_left) > 0 && (input_left[0] == '\r' || input_left[0] == '\n') {
			input_left = input_left[1:]
		}
	}

	fmt.println(instructions)

	Rect :: struct {
		min: [3]int,
		max: [3]int,
	}

	get_rect :: proc(instruction: Instruction) -> Rect {
		rect := Rect {
			min = [3]int{instruction.x[0], instruction.y[0], instruction.z[0]},
			max = [3]int{instruction.x[1], instruction.y[1], instruction.z[1]},
		}
		return rect
	}

	get_dim :: proc(rect: Rect) -> [3]int {
		dim := rect.max - rect.min + 1
		return dim
	}

	get_overlap :: proc(r1: Rect, r2: Rect) -> Maybe(Rect) {

		overlap := Rect {
			min = [3]int{
				max(r1.min.x, r2.min.x),
				max(r1.min.y, r2.min.y),
				max(r1.min.z, r2.min.z),
			},
			max = [3]int{
				min(r1.max.x, r2.max.x),
				min(r1.max.y, r2.max.y),
				min(r1.max.z, r2.max.z),
			},
		}

		result: Maybe(Rect)
		dim := get_dim(overlap)
		if dim.x > 0 && dim.y > 0 && dim.z > 0 {
			result = overlap
		}

		return result

	}

	get_volume :: proc(rect: Rect) -> int {
		dim := get_dim(rect)
		volume := dim.x * dim.y * dim.z
		return volume
	}

	remove_overlap :: proc(rect: Rect, overlap_rect: Maybe(Rect), store: ^[dynamic]Rect) {
		if overlap_rect != nil {

			overlap := overlap_rect.(Rect)

			neg := overlap.min - rect.min
			pos := rect.max - overlap.max

			cur_min := rect.min
			for neg_dir, neg_dir_index in neg {
				if neg_dir > 0 {
					new_rect := Rect{cur_min, rect.max}
					new_rect.max[neg_dir_index] = rect.min[neg_dir_index] + (neg_dir - 1)
					append(store, new_rect)
					cur_min[neg_dir_index] += neg_dir
				}
			}

			cur_max := rect.max
			for pos_dir, pos_dir_index in pos {
				if pos_dir > 0 {
					new_rect := Rect{cur_min, cur_max}
					new_rect.min[pos_dir_index] = rect.max[pos_dir_index] - (pos_dir - 1)
					append(store, new_rect)
					cur_max[pos_dir_index] -= pos_dir
				}
			}

		} else {
			append(store, rect)
		}
	}

	on_rects_current: [dynamic]Rect
	on_rects_next: [dynamic]Rect
	instruction_on_rects_current: [dynamic]Rect
	instruction_on_rects_next: [dynamic]Rect

	for instruction in instructions {

		assert(len(on_rects_next) == 0)
		assert(len(instruction_on_rects_current) == 0)
		assert(len(instruction_on_rects_next) == 0)

		//fmt.println("=========")
		fmt.println(instruction)

		if instruction.on {

			append(&instruction_on_rects_current, get_rect(instruction))

			for on_rect in on_rects_current {

				for instruction_on_rect in instruction_on_rects_current {
					overlap := get_overlap(on_rect, instruction_on_rect)
					//fmt.println("overlap ", overlap)
					remove_overlap(instruction_on_rect, overlap, &instruction_on_rects_next)
				}
				append(&on_rects_next, on_rect)

				instruction_on_rects_current, instruction_on_rects_next = instruction_on_rects_next, instruction_on_rects_current
				clear(&instruction_on_rects_next)

			}

			//fmt.println("instruction on rects: ", instruction_on_rects_current)

			for instruction_on_rect in instruction_on_rects_current {
				append(&on_rects_next, instruction_on_rect)
			}
			clear(&instruction_on_rects_current)

		} else {

			for on_rect in on_rects_current {

				overlap := get_overlap(on_rect, get_rect(instruction))
				remove_overlap(on_rect, overlap, &on_rects_next)

			}

		}

		//fmt.println("next on rects: ", on_rects_next)

		on_rects_current, on_rects_next = on_rects_next, on_rects_current
		clear(&on_rects_next)

	}

	on_volume := 0
	for on_rect in on_rects_current {
		on_rect_volume := get_volume(on_rect)
		assert(on_rect_volume > 0)
		on_volume += on_rect_volume
	}
	fmt.println(on_volume)

}

package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:unicode"

read_number :: proc(input: string, index: int) -> (int, string) {
	input_left := input
	assert(index != -1)
	number_string := input_left[:index]
	input_left = input_left[index + 1:]
	number, ok := strconv.parse_int(number_string)
	assert(ok)
	return number, input_left
}

main :: proc() {

	input, ok := os.read_entire_file("2021-13.txt")
	assert(ok)

	input_string := string(input)
	input_left := input_string

	points: [dynamic][2]int
	points_dim: [2]int

	for input_left[:4] != "fold" {

		comma_index := strings.index_rune(input_left, ',')
		number1: int
		number1, input_left = read_number(input_left, comma_index)

		newline_index := strings.index_any(input_left, "\r\n")
		number2: int
		number2, input_left = read_number(input_left, newline_index)

		point := [2]int{number1, number2}

		points_dim.x = max(point.x + 1, points_dim.x)
		points_dim.y = max(point.y + 1, points_dim.y)

		append(&points, point)

		for len(input_left) > 0 && (input_left[0] == '\r' || input_left[0] == '\n') {
			input_left = input_left[1:]
		}

	}

	assert(points_dim.x > 0)
	assert(points_dim.y > 0)

	//fmt.println(points)
	//fmt.println(points_dim)

	point_map := make([]bool, points_dim.x * points_dim.y)
	point_map_visible_dim := points_dim

	for point in points {
		index := point.y * points_dim.x + point.x
		point_map[index] = true
	}

	for row in 0 ..< points_dim.y {
		for col in 0 ..< points_dim.x {
			index := row * points_dim.x + col
			if point_map[index] {
				//fmt.print('#')
			} else {
				//fmt.print('.')
			}
		}
		//fmt.print('\n')
	}

	Fold :: struct {
		y: bool,
		n: int,
	}

	folds: [dynamic]Fold

	for len(input_left) > 0 {

		assert(input_left[:11] == "fold along ")
		input_left = input_left[11:]

		fold: Fold
		switch input_left[0] {
		case 'y':
			fold.y = true
		case 'x':
			fold.y = false
		case:
			unreachable(fmt.tprintf("unexpected fold char: {}", input_left[0]))
		}

		input_left = input_left[1:]
		assert(input_left[0] == '=')
		input_left = input_left[1:]

		newline_index := strings.index_any(input_left, "\r\n")
		fold.n, input_left = read_number(input_left, newline_index)

		append(&folds, fold)

		for len(input_left) > 0 && (input_left[0] == '\r' || input_left[0] == '\n') {
			input_left = input_left[1:]
		}

	}

	for fold, fold_index in folds {

		if fold.y {

			assert(fold.n <= point_map_visible_dim.y / 2)

			for point in &points {

				assert(point.y != fold.n)
				if point.y > fold.n {
					distance_from_fold := point.y - fold.n
					assert(distance_from_fold <= fold.n)
					point.y = fold.n - distance_from_fold
					point_map[point.y * points_dim.x + point.x] = true
				}

			}

			point_map_visible_dim.y = fold.n

		} else {

			assert(fold.n <= point_map_visible_dim.x / 2)

			for point in &points {

				assert(point.x != fold.n)
				if point.x > fold.n {
					distance_from_fold := point.x - fold.n
					assert(distance_from_fold <= fold.n)
					point.x = fold.n - distance_from_fold
					point_map[point.y * points_dim.x + point.x] = true
				}

			}

			point_map_visible_dim.x = fold.n

		}

		last_fold := fold_index == len(folds) - 1
		visible_dot_count := 0
		for row in 0 ..< point_map_visible_dim.y {
			for col in 0 ..< point_map_visible_dim.x {
				index := row * points_dim.x + col
				if point_map[index] {
					if last_fold do fmt.print('#')
					visible_dot_count += 1
				} else {
					if last_fold do fmt.print('.')
				}
			}
			if last_fold do fmt.print('\n')
		}

		if fold_index == 0 {
			fmt.println("fold", fold_index + 1, "visible", visible_dot_count)
		}


	}

}

package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:unicode"

main :: proc() {

	input, ok := os.read_entire_file("2021-16.txt")
	assert(ok)

	input_string := string(input)

	input_left := input_string

	binary: [dynamic]u8

	for len(input_left) > 0 {

		ch := input_left[0]
		input_left = input_left[1:]

		bin: [4]u8 = {2, 2, 2, 2}

		switch ch {
		case '0':
			bin = {0, 0, 0, 0}
		case '1':
			bin = {0, 0, 0, 1}
		case '2':
			bin = {0, 0, 1, 0}
		case '3':
			bin = {0, 0, 1, 1}
		case '4':
			bin = {0, 1, 0, 0}
		case '5':
			bin = {0, 1, 0, 1}
		case '6':
			bin = {0, 1, 1, 0}
		case '7':
			bin = {0, 1, 1, 1}
		case '8':
			bin = {1, 0, 0, 0}
		case '9':
			bin = {1, 0, 0, 1}
		case 'A':
			bin = {1, 0, 1, 0}
		case 'B':
			bin = {1, 0, 1, 1}
		case 'C':
			bin = {1, 1, 0, 0}
		case 'D':
			bin = {1, 1, 0, 1}
		case 'E':
			bin = {1, 1, 1, 0}
		case 'F':
			bin = {1, 1, 1, 1}
		case '\r', '\n':
		case:
			unreachable()
		}

		if bin[0] != 2 {
			for val in bin {
				assert(val != 2)
				append(&binary, val)
			}
		}

	}

	bin_left := binary[:]

	Packet :: struct {
		version:             int,
		type_id:             int,
		contents:            union {
			PacketCount,
			BitCount,
			Value,
		},
		parent:              ^Packet,
		children:            [dynamic]^Packet,
		total_children_bits: int,
	}

	PacketCount :: distinct int
	BitCount :: distinct int
	Value :: distinct int

	root: ^Packet
	cur_parent: ^Packet

	packet_parse: for len(bin_left) > 0 {

		to_dec :: proc(bin: []u8) -> int {
			assert(len(bin) > 0)
			cur_pow2 := 1
			result := 0
			for index := len(bin) - 1; index >= 0; index -= 1 {
				val := bin[index]
				assert(val == 0 || val == 1)
				result += int(val) * cur_pow2
				cur_pow2 *= 2
			}
			return result
		}

		if cur_parent != nil {
			for {
				if cur_parent == nil {
					bin_left = bin_left[len(bin_left):]
					break packet_parse
				}
				is_done: bool
				switch contents_val in cur_parent.contents {
				case PacketCount:
					is_done = len(cur_parent.children) == int(contents_val)
				case BitCount:
					is_done = cur_parent.total_children_bits == int(contents_val)
				case Value:
					unreachable()
				}
				if is_done {
					cur_parent = cur_parent.parent
				} else {
					break
				}
			}
		}

		packet := new(Packet)
		if root == nil {
			root = packet
		}

		packet.version = to_dec(bin_left[:3])
		bin_left = bin_left[3:]

		packet.type_id = to_dec(bin_left[:3])
		bin_left = bin_left[3:]

		packet.parent = cur_parent

		switch packet.type_id {

		case 4:
			assert(cur_parent != nil)
			append(&cur_parent.children, packet)

			digits := make([dynamic]int, context.temp_allocator)
			last_group := false
			for !last_group {
				last_group = bin_left[0] == 0
				bin_left = bin_left[1:]
				append(&digits, to_dec(bin_left[:4]))
				bin_left = bin_left[4:]
			}
			assert(len(digits) > 0)
			num := 0
			cur_pow16 := 1
			for index := len(digits) - 1; index >= 0; index -= 1 {
				val := digits[index]
				assert(val >= 0 && val <= 16)
				num += val * cur_pow16
				cur_pow16 *= 16
			}
			packet.contents = Value(num)

			at := cur_parent
			for at != nil {
				at.total_children_bits += 6 + len(digits) * 5
				at = at.parent
			}

		case:
			if cur_parent != nil {
				append(&cur_parent.children, packet)
			}

			length_type_id := bin_left[0]
			bin_left = bin_left[1:]

			packet_bits := 6 + 1

			switch length_type_id {

			case 0:
				total_length := to_dec(bin_left[:15])
				bin_left = bin_left[15:]
				packet.contents = BitCount(total_length)
				packet_bits += 15

			case 1:
				n_sub_packets := to_dec(bin_left[:11])
				bin_left = bin_left[11:]
				packet.contents = PacketCount(n_sub_packets)
				packet_bits += 11

			case:
				unreachable()

			}

			at := cur_parent
			for at != nil {
				at.total_children_bits += packet_bits
				at = at.parent
			}

			cur_parent = packet

		}

	}

	to_process: [dynamic]^Packet
	append(&to_process, root)
	version_sum := 0
	for len(to_process) > 0 {
		packet := pop(&to_process)
		version_sum += packet.version
		//fmt.println(packet)
		for child in packet.children {
			append(&to_process, child)
		}
	}
	fmt.println(version_sum)

	eval :: proc(packet: ^Packet) -> int {
		result: int
		switch packet.type_id {
		case 4:
			result = int(packet.contents.(Value))
		case 0:
			result = 0
			assert(len(packet.children) > 0)
			for child in packet.children {
				result += eval(child)
			}
		case 1:
			result = 1
			assert(len(packet.children) > 0)
			for child in packet.children {
				result *= eval(child)
			}
		case 2:
			result = eval(packet.children[0])
			for child in packet.children[1:] {
				result = min(result, eval(child))
			}
		case 3:
			result = eval(packet.children[0])
			for child in packet.children[1:] {
				result = max(result, eval(child))
			}
		case 5:
			assert(len(packet.children) == 2)
			result = int(eval(packet.children[0]) > eval(packet.children[1]))
		case 6:
			assert(len(packet.children) == 2)
			result = int(eval(packet.children[0]) < eval(packet.children[1]))
		case 7:
			assert(len(packet.children) == 2)
			result = int(eval(packet.children[0]) == eval(packet.children[1]))
		case:
			unreachable()
		}
		return result
	}

	fmt.println(eval(root))

}

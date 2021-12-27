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
		input, ok := os.read_entire_file("2021-24.txt")
		assert(ok)
		input_string := string(input)
		input_left = input_string
	}

    ALU :: distinct [4]int

    Register :: enum {
        W,
        X,
        Y,
        Z,
    }

    Instruction :: union {
        Inp,
        Add,
        Mul,
        Div,
        Mod,
        Eql,
    }

    Operand :: union {
        int,
        Register,
    }

    Inp :: struct {
        store: Register,
    }

    InstructionOp2 :: struct {
        reg: Register,
        op2: Operand,
    }

    Add :: distinct InstructionOp2
    Mul :: distinct InstructionOp2
    Div :: distinct InstructionOp2
    Mod :: distinct InstructionOp2
    Eql :: distinct InstructionOp2

    instructions: [dynamic]Instruction

    for len(input_left) > 0 {

        instruction_name: string
        {
            end := strings.index_rune(input_left, ' ')
            assert(end != -1)
            instruction_name = input_left[:end]
            assert(len(instruction_name) == 3)
            input_left = input_left[end + 1:]
        }

        read_operand :: proc(input: string) -> (Operand, string) {

            input_left := input

            end := strings.index_any(input_left, " \r\n")
            assert(end > 0)

            operand_name := input_left[:end]
            input_left = input_left[end:]

            operand: Operand

            if operand_name == "w" || operand_name == "x" || operand_name == "y" || operand_name == "z" {
                switch operand_name[0] {
                case 'w':
                    operand = Register.W
                case 'x':
                    operand = Register.X
                case 'y':
                    operand = Register.Y
                case 'z':
                    operand = Register.Z
                }
            } else {
                num, ok := strconv.parse_int(operand_name)
                assert(ok)
                operand = num
            }

            return operand, input_left
        }

        operand1: Operand
        operand1, input_left = read_operand(input_left)
        register1 := operand1.(Register)

        operand2: Maybe(Operand)
        if input_left[0] == ' ' {
            input_left = input_left[1:]
            operand2, input_left = read_operand(input_left)
        }

        instruction: Instruction
        switch instruction_name {
        case "inp":
            instruction = Inp{register1}
        case "add":
            instruction = Add{register1, operand2.(Operand)}
        case "mul":
            instruction = Mul{register1, operand2.(Operand)}
        case "div":
            instruction = Div{register1, operand2.(Operand)}
        case "mod":
            instruction = Mod{register1, operand2.(Operand)}
        case "eql":
            instruction = Eql{register1, operand2.(Operand)}
        case:
            unreachable()
        }

        append(&instructions, instruction)

        for len(input_left) > 0 && (input_left[0] == '\n' || input_left[0] == '\r') {
            input_left = input_left[1:]
        }

    }

    // Taken from https://www.reddit.com/r/adventofcode/comments/rnejv5/2021_day_24_solutions/?utm_source=share&utm_medium=web2x&context=3
    // and https://github.com/N8Brooks/deno_aoc/blob/main/year_2021/day_24.ts

    variables: [dynamic][3]int

    instructions_left := instructions[:]
    for len(instructions_left) > 0 {

        instr4 := instructions_left[4].(Div)
        assert(instr4.reg == Register.Z)

        instr5 := instructions_left[5].(Add)
        assert(instr5.reg == Register.X)\

        instr15 := instructions_left[15].(Add)
        assert(instr15.reg == Register.Y)

        append(&variables, [3]int{instr4.op2.(int), instr5.op2.(int), instr15.op2.(int)})

        instructions_left = instructions_left[18:]
    }

    stack: [dynamic][2]int
    rules: [dynamic][3]int

    for variable, variable_index in variables {

        if variable[0] == 1 {

            append(&stack, [2]int{variable[2], variable_index})

        } else if variable[0] == 26 {

            stack_entry := pop(&stack)
            addend := variable[1] + stack_entry[0]
            append(&rules, [3]int{stack_entry[1], variable_index, addend})

        } else {
            unreachable()
        }

    }

    pow10 :: proc(n: int) -> int {
        result := 1
        for i := n; i != 0; i -= 1 {
            result *= 10
        }
        return result
    }

    largest_number := 0
    smallest_number := 0
    for rule in rules {

        addend := rule[2]
        n1, n2: int
        if addend > 0 {
            n1, n2 = 9 - addend, 9
        } else {
            n1, n2 = 9, 9 + addend
        }

        s1, s2: int
        if addend > 0 {
            s1, s2 = 1, 1 + addend
        } else {
            s1, s2 = 1 - addend, 1
        }

        largest_number += n1 * pow10(13 - rule[0])
        largest_number += n2 * pow10(13 - rule[1])

        smallest_number += s1 * pow10(13 - rule[0])
        smallest_number += s2 * pow10(13 - rule[1])

    }

    fmt.println(largest_number, smallest_number)

}

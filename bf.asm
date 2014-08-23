[bits 64]

%define PLUS "+"
%define MINUS "-"
%define GREAT ">"
%define LESS "<"
%define LBRACK "["
%define RBRACK "]"
%define PERIOD "."
%define COMMA ","

%define STORE_LENGTH 30000
%define CODE_LENGTH 100000

%ifidn __OUTPUT_FORMAT__, macho64
	%define START _start

	%define EXIT_SYS 0x2000001
	%define READ_SYS 0x2000003
	%define WRITE_SYS 0x2000004
	%define OPEN_SYS 0x2000005
	%define CLOSE_SYS 0x2000006

	%define SYS_REG rax
	%define SYS_ARG1 rdi
	%define SYS_ARG2 rsi
	%define SYS_ARG3 rdx
%elif __OUTPUT_FORMAT__, elf64
	%define START _start

	%define EXIT_SYS 60
	%define READ_SYS 0
	%define WRITE_SYS 1
	%define OPEN_SYS 2
	%define CLOSE_SYS 3

	%define SYS_REG rax
	%define SYS_ARG1 rdi
	%define SYS_ARG2 rsi
	%define SYS_ARG3 rdx
%else
	%error This platform is not supported.
%endif

[section .text]
[global START]

START:
	mov rbx, [rsp]
	cmp rbx, 1
	jle .too_few_args

	mov rbx, QWORD code
	mov r14, QWORD code   ; unchanged
	mov r13, QWORD buffer

	mov SYS_ARG1, [rsp + 16]
	syscall

	call read_data

	mov rsi, QWORD store

	call exec_bf
	mov SYS_ARG1, 0
.exit:
	mov SYS_REG, EXIT_SYS
	syscall

.too_few_args:
	mov SYS_REG, WRITE_SYS
	mov SYS_ARG1, 2
	mov SYS_ARG2, QWORD too_few
	mov SYS_ARG3, too_few_len
	syscall

	mov SYS_ARG1, 1

	jmp .exit

read_data:
	mov SYS_REG, OPEN_SYS
	mov SYS_ARG2, 0
	syscall

	cmp SYS_REG, 2
	jle .open_error

	mov r15, SYS_REG

	mov SYS_REG, READ_SYS
	mov SYS_ARG1, r15
	mov SYS_ARG2, QWORD code
	mov SYS_ARG3, CODE_LENGTH - 1
	syscall

	add SYS_REG, rbx
	mov BYTE [SYS_REG], 0

	mov SYS_ARG1, r15
	mov SYS_REG, CLOSE_SYS
	syscall

	ret
.open_error:
	mov SYS_REG, WRITE_SYS
	mov SYS_ARG1, 2
	mov SYS_ARG2, open_err
	mov SYS_ARG3, open_err_len
	syscall

	mov SYS_REG, EXIT_SYS
	syscall

exec_bf_loop:
	inc rbx
exec_bf:
	cmp BYTE [rbx], 0
	je .end
	cmp BYTE [rbx], PLUS
	je .plus
	cmp BYTE [rbx], MINUS
	je .minus
	cmp BYTE [rbx], LESS
	je .less
	cmp BYTE [rbx], GREAT
	je .great
	cmp BYTE [rbx], LBRACK
	je .lbrack
	cmp BYTE [rbx], RBRACK
	je .rbrack
	cmp BYTE [rbx], PERIOD
	je .period
	cmp BYTE [rbx], COMMA
	jne exec_bf_loop
	.comma:
		mov r12, rsi

		mov SYS_REG, READ_SYS
		mov SYS_ARG1, 0
		mov SYS_ARG2, QWORD buffer
		mov SYS_ARG3, 1
		syscall

		mov rsi, r12

		cmp SYS_REG, 0
		je exec_bf_loop

		mov al, BYTE [r13]
		mov BYTE [rsi], al

		jmp exec_bf_loop
	.period:
		mov SYS_REG, WRITE_SYS
		mov SYS_ARG1, 1
		;mov SYS_ARG2, rsi
		mov SYS_ARG3, 1
		syscall

		jmp exec_bf_loop
	.plus:
		inc BYTE [rsi]
		jmp exec_bf_loop
	.minus:
		dec BYTE [rsi]
		jmp exec_bf_loop
	.less:
		mov rcx, QWORD store
		cmp rsi, rcx
		je exec_bf_loop
		dec rsi
		jmp exec_bf_loop
	.great:
		mov rcx, QWORD store + STORE_LENGTH
		cmp rsi, rcx
		je exec_bf_loop
		inc rsi
		jmp exec_bf_loop
	.lbrack:
		cmp BYTE [rsi], 0
		jne exec_bf_loop
		mov rcx, 1
		.lbrack_loop:
			inc rbx
			cmp BYTE [rbx], 0
			je .end
			cmp BYTE [rbx], RBRACK
			je .lbrack_found_rbrack
			cmp BYTE [rbx], LBRACK
			jne .lbrack_loop
			.lbrack_found_lbrack:
				inc rcx
				jmp .lbrack_loop
			.lbrack_found_rbrack:
				dec rcx
				jnz .lbrack_loop
		jmp exec_bf_loop
	.rbrack:
		cmp BYTE [rsi], 0
		je exec_bf_loop
		mov rcx, 1
		.rbrack_loop:
			dec rbx
			cmp rbx, r14
			je .end
			cmp BYTE [rbx], LBRACK
			je .rbrack_found_lbrack
			cmp BYTE [rbx], RBRACK
			jne .rbrack_loop
			.rbrack_found_rbrack:
				inc rcx
				jmp .rbrack_loop
			.rbrack_found_lbrack:
				dec rcx
				jnz .rbrack_loop
		jmp exec_bf_loop
	.end:
		ret

[section .data]

too_few: db "Error: too few arguments.", 10, 10, "Usage: bf [FILE]", 10
too_few_len: equ $ - too_few
open_err: db "Error: failed to open file.", 10
open_err_len: equ $ - open_err

[section .bss]

buffer: resb 1
code: resb CODE_LENGTH
store: resb STORE_LENGTH


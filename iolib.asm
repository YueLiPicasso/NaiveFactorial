	global read_char, read_word, parse_uint, parse_int
	global print_string, print_char, print_newline, print_int, print_uint
	global string_length, string_equal, string_copy, string_rev
	global exit
	
	section .text	
exit:				; accepts an exit code and terminates current process  
	mov rax, 60		; system call 'exit'
	syscall			; assume exit code is already passed to rdi
string_length:			; accepts a pointer to a string from rdi and
				; returns its length in rax (excl. NULL)
	xor rax, rax		; clear counter
	.loop:
	cmp byte[rdi+rax], 0
	je .end
	inc rax
	jmp .loop
	.end:
	ret
print_string:			; accepts a pointer to a string from rdi and prints it to stdout.
				; Returns: length of string in rax 
	xor rax, rax		; clear counter
	.loop:
	lea rsi, [rdi+rax]	; rsi points to the current byte
	cmp byte[rsi], 0
	je .end
	push rax		; save rax - the counter
	push rdi		; save rdi - the string pointer
	mov rax, 1		; write syscall descriptor
	mov rdi, 1		; stdout
	mov rdx, 1		; write 1 byte
	syscall
	pop rdi
	pop rax
	inc rax
	jmp .loop
	.end:
	ret
print_char: 			; accepts a character directly as first arg from rdi, and
				; prints to stdout
	dec rsp			; create char buffer in stack
	mov [rsp], dil
	mov rax, 1		; write syscall
	mov rdi, 1		; to stdout
	mov rsi, rsp
	mov rdx, 1
	syscall
	inc rsp
	ret
print_newline:
	mov dil, 0xA		; the newline ascii
	jmp print_char		; tail call optimization
print_int: 			; output a signed 8-byte integer from rdi in decimal format
	push rbp		; save the curent value of rbp on the stack
	mov rbp, rsp		; use rbp to stote the initial value of rsp, so that we don't
				; need to track stack size using a counter
	test rdi, rdi    	; just to activate SF in rflags
	jns print_uint.core
	dec rsp			
	mov byte[rsp], 0x2D	; buffer the minus sign
	neg rdi
	jmp print_uint.core
print_uint: 			; outputs an unsigned integer from rdi in decimal format
	push rbp		; save the curent value of rbp on the stack
	mov rbp, rsp
	.core:
	dec rsp			; buffer the string terminator
	mov byte[rsp], 0x00
	mov rax, rdi		; move the number to rax
	xor rdx, rdx		; clear rdx - the dividend is rdx:rax
	mov rcx, 10		; divide by ten	
	.loop:
	div rcx			; unsigned divide of rdx:rax by rcx
	dec rsp			; make buffer
	add dl, 0x30		; the remainder is guaranteed to be containable in dl.
				; Find its ascii code by adding the ascii of zero 
	mov [rsp], dl 		; copy the ascii code of the remainder to the buffer 
	xor rdx, rdx		; clear rdx - the remainder
	cmp rax, 0		; rax now holds the quotient
	je .end
	jmp .loop
	.end:
	cmp byte[rbp-1], 0x2D	; print_int may have put a minus sign here. Otherwise it is NULL
	jne .print
	dec rsp
	mov byte[rsp], 0x2D
	.print:
	mov rdi, rsp		; point rdi to the head of the digit string
	call print_string	; print and THEN delete stack frame,  otherwise there could be
				; data corruption
	mov rsp, rbp		; restote the inital rsp
	pop rbp			; restote initial rbp
	ret			; essentially print_uint is a sub-routine of print_int, but
				; both buffers a string representing the decimal of the number
read_char:			; read one character from stdin and return it; if the
				; end-of-input-stream occurs, return 0
	dec rsp			; buffer the char
	mov rsi, rsp		; prepare for read syscall
	xor rdi, rdi
	mov rdx, 1
	xor rax, rax
	syscall
	cmp rax, 0		; check how many bytes are successfully read, by the
				; system read...could only be 0 or 1
	je .no_byte
	mov al, [rsi]		; copy the char only if a successful read
	.no_byte:
	inc rsp			; restore rsp
	ret			; does not clear stdin buffer
read_word:			; Accepts a buffer address (rdi) and size (rsi) as arguments.
				; reads next word from stdin, skipping whitespaces 0x20, 0x9
				; and 0x10
				; Stops and returns 0 if the word is to big for the buffer,
				; otherwise returns the address. Null terminates the accepted
				; string
	xor rax, rax		; initialize the counter rax to 0
	cmp rsi, 0
	je .endt		; t for trivial - any input is too big if buffer size = 0
	.loop:			; otherwise, buffer size is at least one
	cmp rsi, rax
	je .endo		; non-trivial overflow
	push rdi		; save the useful values
	push rsi
	push rax
	call read_char
	mov rcx, rax		; store the read char in rcx
	pop rax
	pop rsi
	pop rdi
	cmp rcx, 0		; if null, stop reading
	je .endn
	cmp rcx, 0x20		; if 0x20, ignore it
	je .loop
	cmp rcx, 0x9		; if 0x9, ignore it
	je .loop
	cmp rcx, 0xA		; if 0xA, ignore it
	je .loop
	lea rdx, [rdi+rax]
	mov [rdx], cl		; store the char
	inc rax			; assume a printable char
	jmp .loop
	.endo:			; clears the sttdin buffer, leaving no garbage in it
	call read_char		; otherwise later routines would suffer
	cmp rax, 0
	je .endt
	jmp .endo
	.endt:
	xor rax, rax
	ret
	.endn:
	lea rdx, [rdi+rax]	; terminate by null
	mov byte[rdx], 0x0
	mov rdx, rax		; return the size (in bytes) of the word read 
	mov rax, rdi		; return the buffer addr
	ret
parse_uint:			; accepts a null-terminated string and tries to parse an
				; unsigned number from its start. Returns the number parsed
				; in rax, its character counts in rdx
	sub rsp, 21		; 64-bit uint has at most 20 decimal digits, plus NULL
	mov rdi, rsp
	mov rsi, 21
	call read_word		; read into the buffer
	test rax, rax		; in case read fails, rax is 0
	jz .fail
	mov rsi, rax		; use rsi to point to the string
	xor rdi, rdi		; store current parser position in the string
	xor rax, rax		; init rax
	.loop:			; enter parsing loop
	cmp byte[rsi+rdi], 0x0	; end of string reached
	je .success
	cmp byte[rsi+rdi], 0x30	; only digits are allowed
	jb .fail
	cmp byte[rsi+rdi], 0x39
	jnbe .fail
	mov rcx, 10
	mul rcx
	test rdx, rdx
	jnz .fail		; the number is too large to hold in rax
	mov cl, [rsi+rdi]
	sub cl, 0x30
	add rax, rcx
	jc .fail		; the number is too large to hold in rax
	inc rdi
	jmp .loop
	.fail:
	xor rdx, rdx
	jmp .end
	.success:
	mov rdx, rdi
	.end:
	add rsp, 21		; delete buffer
	ret
parse_int:			; Like parse_uint, but tries to parse a signed number. rdx inc.
				; sign if any. No space between sign the digits.
	sub rsp, 21		; 64-bit int has at most 19 decimal digits, plus NULL and
				; optional sign
	mov rdi, rsp		; passing args for read_word
	mov rsi, 21
	call read_word		; read into the buffer
	test rax, rax		; in case read fails, rax is 0
	jz .fail
	mov rsi, rax		; use rsi to point to the string. if read succeeds, rax is
				; string pointer
	xor rdi, rdi		; init counter - count all or nothing due to the strict
				; syntax of int that is assumed here
	xor rax, rax		; init rax - the parsed int
	cmp byte[rsi], 0x2D	; check if the first char is minus sign
	jne .loop
	inc rdi
	jmp .chk_dgt		; minus sign must be followed by a digit
.loop:				; enter parsing loop if read success. Now rax has the str addr
	cmp byte[rsi+rdi], 0x0	; end of string reached
	je .succ		; success
.chk_dgt:
	cmp byte[rsi+rdi], 0x30	; now only digits are allowed
	jb .fail
	cmp byte[rsi+rdi], 0x39
	jnbe .fail
	mov rcx, 10
	mul rcx
	test rdx, rdx	      	; non-zero rdx after mul means ...
	jnz .fail		; the number is definitely too large to hold in rax
	mov cl, [rsi+rdi]
	sub cl, 0x30
	add rax, rcx		; carry after add means ...
	jc .fail		; the number is definitely too large to hold in rax
	cmp byte[rsi], 0x2D	; determine the sign
	jne .pb_chk		; positive bound check
	mov rcx, 0x8000_0000_0000_0000 	; max magnitude for negative int
	cmp rax, rcx
	jnbe .fail		; the number is too large to hold in rax
	jmp .chk_ok		; check passed (ok)
.pb_chk:
	mov rcx, 0x7FFF_FFFF_FFFF_FFFF 	; max magnitude for positive int
	cmp rax, rcx
	jnbe .fail
.chk_ok:
	inc rdi
	jmp .loop
.fail:
	xor rdx, rdx
	jmp .end
.succ:
	mov rdx, rdi
	cmp byte[rsi], 0x2D	; check the sign
	jne .end
	neg rax
.end:
	add rsp, 21		; delete buffer
	ret
string_equal:			; accepts two pointers (rdi, rsi) to strings and compares them.
				; Returns 1 if they are equal, otherwise 0.
	xor rcx, rcx		; init counter
	.loop:
	mov dl, [rdi+rcx]
	cmp [rsi+rcx], dl
	jne .ueq
	cmp byte[rdi+rcx], 0x0	; now that there are equal bytes, check null terminator
	je .eq
	inc rcx
	jmp .loop
	.ueq:
	xor rax, rax
	ret
	.eq:
	xor rax, rax
	inc rax			; we may use ZF to get result in addition to rax
	ret
string_copy: 			; Accepts a pointer to a string (rdi), a pointer to a buffer (rsi)
				; and buffers length (rdx). Copies string to the destination.
				; The destination address is returned if the string fits
				; the buffer; otherwise zero is returned
	cmp rdx, 0
	je .endt		; trivial end
	xor rax, rax		; init counter
	.loop:
	mov cl, [rdi+rax]
	mov [rsi+rax], cl
	inc rax			; increment counter
	cmp cl, 0		; check if it is NULL
	je .endn		; normal end
	cmp rdx, rax
	je .endt		; reuse endt for overflow
	jmp .loop
	.endt:
	xor rax, rax
	ret
	.endn:
	mov rax, rsi
	ret

string_rev: 			; Accepts a pointer to a string (rdi), a pointer to a buffer (rsi)
				; and buffer length (rdx). Reverses the string to the destination.
				; The destination address is returned if the string fits
				; the buffer; otherwise zero is returned
	;; save input params
	push rbx		; callee-saved reg
	push rdi 		; [rsp+16] string
	push rsi		; [rsp+8]  buffer
	push rdx		; [rsp]    buffer size
	call string_length
	inc rax			; count the NULL
	cmp rax, [rsp]
	ja .overflow
	dec rax			; discount the NULL
	test rax, rax
	jz .null_string
	dec rax 		; rax indexes the byte before NULL  
	xor rbx, rbx		; rbx indexes the first byte in the buffer
	mov rsi, [rsp+8]	; buffer pointer
	mov rdi, [rsp+16]	; string pointer
	.loop:
	mov cl, [rdi+rax]
	mov [rsi+rbx], cl
	inc rbx
	test rax, rax
	jz .finish
	dec rax
	jmp .loop
	.finish:
	mov byte[rsi+rbx], 0
	mov rax, rsi
	jmp .clean_up
	.null_string:
	mov rsi, [rsp+8]
	mov byte[rsi], 0
	mov rax, rsi
	jmp .clean_up
	.overflow:
	xor rax, rax
	.clean_up:
	add rsp, 3*8
	pop rbx
	ret

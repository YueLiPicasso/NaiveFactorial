	;; test string_rev
	.test_string_rev:
	mov rdi, num_Y
	mov rsi, [rsp]
	mov rdx, SMALL_BUFFER_SIZE
	call string_rev
	test rax, rax
	jz .quit
	mov rdi, rax
	call print_string
	call print_newline
	jmp .quit

	;; test repeated division (binary to decimal)
	;; Now used as main program loop
	;; - prints the factorial base, then jump to compute factorial
	;; - maintains the factorial table counter
	.test_rep_div:
	mov eax, [tblc]		; load table counter
	test eax, eax		; if counter = 0 then quit
	jz .quit		; else dec counter, 
	dec eax
	mov [tblc], eax
	
	mov rdi, num_X		; num_X is dividend
	mov rsi, [rsp+16]
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy	; copy dividend to buffer I

	mov rdi, num_10		; num_10 is the divisor
	mov rsi, [rsp+8]
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy	; copy divisor to buffer II
	
	mov rdi, [rsp+16]	; I   - dividend
	mov rsi, [rsp+8]	; II  - divisor
	mov rdx, [rsp]		; III - quotient
	mov rcx, [rsp+32]	; IV  - remainder
	mov r8, num_10		; read-only divisor - num_10
	call rep_div
	test rax, rax
	jz .quit		; else rep_div result is in buffer I

	push rax
	mov rdi, bpar
	call print_string	; print <p>
	pop rax
	
	mov rdi, rax		; reverse-copy the decimal to buffer II
	mov rsi, [rsp+8] 	; II
	mov rdx, ARITH_BUFFER_SIZE
	call string_rev		; cannot fail
	mov rdi, rax
	call print_string	; print the decimal of num_X in ordinary order
	
	mov rdi, 0x21		; print !
	call print_char
	mov rdi, 0x20
	call print_char		; print space
	mov rdi, 0x3D		; print =
	call print_char
	mov rdi, epar
	call print_string	; print </p>
	call print_newline	; newline
	jmp .test_factorial

	;; unit test of long_multiply
	.test_long_multiply:
	mov rdi, num_X
	mov rsi, [rsp+16]
	mov rdx, ARITH_BUFFER_SIZE
	mov rcx, num_Y
	mov r8, [rsp+8]
	mov r9, [rsp]
	call long_multiply
	test rax, rax
	jz .quit
	mov rdi, rax
	call print_string
	call print_newline
	jmp .quit
	
	;; test long_div
	.test_long_div:
	mov rdi, num_Y		; num_Y is dividend
	mov rsi, [rsp+16]
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy	; copy dividend to buffer I

	mov rdi, num_10		; num_10 is the divisor
	mov rsi, [rsp+8]
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy	; copy divisor to buffer II

	mov rdi, [rsp+16]	; I   - dividend
	mov rsi, [rsp+8]	; II  - divisor
	mov rdx, [rsp]		; III - quotient
	mov rcx, [rsp+32]	; IV  - remainder
	mov r8, num_10		; read-only divisor - num_10
	call long_div
	test rax, rax
	jz .quit
	push rax
	push rdx 
	mov rdi, rax		; print quotient
	call print_string
	call print_newline
	mov rdi, [rsp]		; print remainder
	call print_string
	call print_newline
	pop rdx
	pop rax
	
	;; following long_div, test long_multiply
	;; remainder is lost, just multiply divisor with quotient
	mov rdi, rax		; read-only quotient (in buffer III)
	mov rcx, num_10		; read-only divisor
	mov rsi, [rsp+8]	; buffer II 
	mov rdx, ARITH_BUFFER_SIZE
	mov r8, [rsp+16]	; buffer I
	mov r9, [rsp+32]	; buffer IV
	call long_multiply
	test rax, rax
	jz .quit
	mov rdi, rax
	call print_string
	call print_newline
	jmp .quit
	
	;; num_inc test
	.test_num_inc:
	mov rdi, [rsp+24]	; use the small buffer
	mov rsi, SMALL_BUFFER_SIZE
	mov byte[rdi], 0	; init the buffer
	.inc_loop:
	call num_inc
	test rax, rax
	jz .quit
	mov rdi, rax
	call print_string
	call print_newline
	mov rdi, [rsp+24]	; use the small buffer
	mov rsi, SMALL_BUFFER_SIZE
	jmp .inc_loop

	;; test long_sub
	.test_long_sub:
	mov rdi, num_X		; copy num_X to buffer III
	mov rsi, [rsp]
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy

	mov rdi, num_Y		; copy num_Y to buffer II
	mov rsi, [rsp+8]
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy

	mov rdi, [rsp]		; num_X in buffer III is minuend
	mov rsi, [rsp+8]	; num_Y in buffer II is subtrahend
	call long_sub
	test rax, rax
	jz .quit
	mov rdi, rax
	call print_string
	call print_newline	; subtraction successful <-> print result
	jmp .quit

	;; call factorial
	.test_factorial:
	
	mov rdi, num_X
	mov rsi, [rsp+24]
	mov rdx, SMALL_BUFFER_SIZE
	mov rcx, [rsp+32]
	mov r8,  ARITH_BUFFER_SIZE
	call factorial

	test rax, rax		
	jz .fac_fail

	mov rdi, bpar
	call print_string	; print <p>

	;; convert result to decimal
	mov rdi, num_10		; load divisor buffer (III)
	mov rsi, [rsp]
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy	

	mov rdi, [rsp+32] 	; IV: factorial long buffer = dividend buffer
	mov rsi, [rsp]		; III
	mov rdx, [rsp+8]	; II
	mov rcx, [rsp+16]	; I
	mov r8, num_10
	call rep_div
	test rax, rax
	jz .quit
	mov rdi, rax		; reverse string
	mov rsi, [rsp+16]	; reverse to buffer I
	mov rdx,  ARITH_BUFFER_SIZE
	call string_rev
	test rax, rax
	jz .quit
	mov rdi, rax		; print the decimal result in ordinary left-to-right order
	call print_string
	
	mov rdi, epar
	call print_string	; print </p>
	call print_newline

	mov rdi, num_X		; increment num_X
	mov rsi, FAC_BASE_SIZE
	call num_inc
	
	jmp .test_rep_div
	
	;; mov rdi, succ_msg
	;; jmp .fac_print_msg
	
	.fac_fail:
	mov rdi, fail_msg
	.fac_print_msg:
	call print_string
	call print_newline	

	extern print_newline, print_string, print_char, exit
	extern string_copy, string_length, string_rev
	
	%define ARITH_BUFFER_SIZE 4096
	%define SMALL_BUFFER_SIZE 16
	%define TBL_COUNTER_SIZE 4
	%define FAC_BASE_SIZE 16
	%define TBL_COUNTER_MAX 521
	
	;; TBL_COUNTER_MAX determines the largest base number (=counter-1)
	;; whose factorial is to be computed. E.g. if counter = 9, then
	;; factorial will be computed for 0~8; then base size shall be at least
	;; 5 bytes to hold the ascii string "0001" (NULL terminated).

	;; A boundry case (null string) is accidentally treated as zero - acceptable.
	section .data
num_10:	db '0101', 0
num_Y:	db '11000',0

	section .data
fail_msg: 	db 'Error: Buffer overflow. Please retry with a larger buffer.', 0
succ_msg:	db 'Successful !', 0
bpar:	db '<p>', 0
epar:	db '</p>', 0

	section .bss
num_X:	resb FAC_BASE_SIZE
tblc:	resb TBL_COUNTER_SIZE
	
	section .text
	global _start

_start:
	mov byte[num_X], 0x30 		; init num_X
	mov byte[num_X+1], 0
	
	mov dword[tblc], TBL_COUNTER_MAX ; init table counter
	
	push r12			; callee-saved register
	
	mov rax, rsp
	
	sub rax, ARITH_BUFFER_SIZE 
	mov r8, rax		     	; compute pointer to buffer I
	
	sub rax, ARITH_BUFFER_SIZE 
	mov r9, rax			; compute pointer to buffer II
	
	sub rax, ARITH_BUFFER_SIZE 	
	mov r10, rax			; compute pointer to buffer III
	
	sub rax, ARITH_BUFFER_SIZE
 	mov r11, rax			; compute pointer to buffer IV
	
	sub rax, SMALL_BUFFER_SIZE
	mov r12, rax			; compute pointer to buffer V (small buffer)
	
	sub rsp, 4*ARITH_BUFFER_SIZE	; actually make the buffers
	sub rsp, SMALL_BUFFER_SIZE

	;; small and long buffer
	push r11		; IV        [rsp+32]   
	push r12		; V (small) [rsp+24]

	;; MULTIPLY long buffer
	push r8			; I         [rsp+16]
	push r9			; II        [rsp+8]
	push r10		; III       [rsp]
	
	jmp .bin_fac_table	; comment this line to generate a decimal factorial table

	.dec_fac_table:
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

	;; call factorial
	
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
	
	jmp .dec_fac_table


	
	;; generate binary factorial table
	.bin_fac_table:
	
	mov eax, [tblc]		; load table counter
	test eax, eax		; if counter = 0 then quit
	jz .quit		; else dec counter, 
	dec eax
	mov [tblc], eax

	mov rdi, bpar
	call print_string	; print <p>

	mov rdi, num_X		; reverse-copy num_X to buffer II
	mov rsi, [rsp+8] 	; II
	mov rdx, ARITH_BUFFER_SIZE
	call string_rev		; cannot fail
	mov rdi, rax
	call print_string	; print num_X in binary in ordinary order

	mov rdi, 0x20		; print space
	call print_char		
	mov rdi, 0x21		; print !
	call print_char
	mov rdi, 0x20		; print space
	call print_char		
	mov rdi, 0x3D		; print =
	call print_char
	mov rdi, epar		; print </p>
	call print_string	
	call print_newline	; newline

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

	mov rdi, [rsp+32]	; reverse factorial result
	mov rsi, [rsp+16]	; ... to buffer I
	mov rdx,  ARITH_BUFFER_SIZE
	call string_rev

	mov rdi, rax		; print the factorial result in binary in left-to-right order
	call print_string

	mov rdi, epar		; print </p>
	call print_string	
	call print_newline

	mov rdi, num_X		; increment num_X
	mov rsi, FAC_BASE_SIZE
	call num_inc
	
	jmp .bin_fac_table

	.fac_fail:
	mov rdi, fail_msg
	.fac_print_msg:
	call print_string
	call print_newline

	;; quit procedure 
	.quit:
	add rsp, 40
	add rsp, SMALL_BUFFER_SIZE
	add rsp, 4*ARITH_BUFFER_SIZE
	pop r12			; restore callee-saved register
	
	xor rdi, rdi
	jmp exit
	
	;; Add two arbitrarily long binary uint, both of which are from memory as strings (little-endian)
	;; Input: 
	;;      rdi- pointer to X (read-only)
	;;	rsi - pointer to Y (read-only)
	;;	rdx - pointer to X+Y buffer
	;; 	rcx - X+Y buffer size
	;; Output:
	;; 	rax - pointer to X+Y or 0 if failure (overflow)
	;; Input Guarantee:
	;; 	- rdi and rsi both point to a non-empty string that has only 0 or 1
	;;  	- the two strings have equal length
long_add:
	call string_length
	add rax, 0x2			; minimum buffer size for the result of addition
	cmp rcx, rax
	jb .failure
	push rdx		; store the output buffer pointer
	mov cl, 0x30		; cl holds the carry, initially 0 
	.loop:
	mov al, [rdi]		; compute input pattern
	add al, [rsi]
	cmp al, 0x60		; if both input bytes are 0
	je .both_zero
	cmp al, 0x61		; else if one byte is 0, the other btye is 1 
	je .one_zero
	cmp al, 0x62		; else if both bytes are 1
	je .both_one
	test al, al		; else if end of string
	je .finish
	xor rax, rax		; else - failure
	ret
	.both_zero:
	mov [rdx], cl		; when both are zero, take the carry-in as sum
	mov cl, 0x30		; set the carry-out to 0
	jmp .step
	.one_zero:		; under this pattern, the carry-in equals carry-out 
	cmp cl, 0x30
	jz .one_zero_nc		; jump if no carry-in
	mov byte[rdx], 0x30
	jmp .step
	.one_zero_nc:
	mov byte[rdx], 0x31
	jmp .step
	.both_one:		; under this pattern, carry-out is 1, sum equals carry-in
	mov byte[rdx], cl
	mov cl, 0x31
	.step:
	inc rdi
	inc rsi
	inc rdx
	jmp .loop
	.finish:
	cmp cl, 0x30
	je .finish_with_nc
	mov byte[rdx], cl	; take the carry-in as the most significant digit
	mov byte[rdx+1], 0	; NULL terminate the string
	jmp .finish_pop
	.finish_with_nc:
	mov byte[rdx], 0
	.finish_pop:
	pop rax			; pop the buffer pointer to rax 
	ret
	.failure:
	xor rax, rax
	ret
	
	;; Align two strings (representing binary uint) for addition. To align means to pad the shorter string
	;; with zeros on the significant bit positions to make it as long as the longer string
	;; Input:
	;; 	rdi - pointer to a buffer that contains a NULL terminated string
	;; 	rsi - similar to rdi
	;; Input Guarantee: the string buffers are large enough for making the alignment
	;; Output:
	;; 	rax - same as the input rdi
	;; 	rdx - same as the input rsi
num_align:
	push rdi		; save the input parameter
	call string_length	; this routine does not modify rsi
	push rax		; save the length of the rdi string
	mov rdi, rsi
	call string_length
	mov rdx, rax		; load the length of the rsi string to rdx
	pop rax			; load the length of the rdi string to rax
	cmp rax, rdx		
	je .quit		; equal length, nothing to do
	ja .above_loop
	pop rdi
	.below_loop:	
	mov byte[rdi+rax], 0x30
	inc rax
	cmp rax, rdx
	jb .below_loop
	mov byte[rdi+rax], 0	; NULL terminate
	mov rax, rdi
	mov rdx, rsi
	ret
	.above_loop:
	mov byte[rsi+rdx], 0x30
	inc rdx
	cmp rax, rdx
	ja .above_loop
	mov byte[rsi+rdx], 0	; NULL terminate
	.quit:
	pop rax
	mov rdx, rsi
	ret
	
	;; Shift-copy loop: repetitively copy string A into the buffer with left
	;; shift (padding 0) specified by string B as in a shift-add multiplier.
	;; Input:
	;; 	rdi - string pointer A (representing a binary uint, little-endian)
	;; 	rsi - buffer pointer
	;; 	rdx - buffer size
	;; 	rcx - string pointer B (similar to A)
	;; Output: rax - 1 for success, 0 for failure
	;; This routine is written in a primitive style,
	;; ... with many rsp adjustments (hard to manage)
	;; Not used by any other routine. Just a warm up before long_multiply
shift_copy:
	xor rax, rax		; counter init
	.main_loop:
	cmp byte[rcx+rax], 0x30	; check if the digit is 0
	je .continue		; if the digit is 0, go to the next cycle
	cmp byte[rcx+rax], 0	; check if end of string
	je .finish
	push rax		; otherwise the digit must be 1, do shift & copy. Save rax first
	.padding_loop:
	test rax, rax
	jz .copy
	dec rax
	mov byte[rsi+rax], 0x30	; pad 0
	jmp .padding_loop
	.copy:
	pop rax			; load index of the current 1, which equals the length of shift
	push rsi		; save original buffer pointer
	push rdx		; save original buffer size
	sub rdx, rax		; compute remaining buffer space after shift/padding 0
	lea rsi, [rsi+rax]
	push rax
	push rcx
	call string_copy	; which does not modify rdi, rsi and rdx; but modifies rax and rcx
	test rax, rax
	jz .finish		; failure to copy
	pop rcx
	pop rax
	pop rdx
	pop rsi
	;; after each shift & copy, print the result
	push rax 	; save before print
	push rdi
	push rsi
	push rdx
	push rcx
	mov rdi, rsi
	call print_string
	call print_newline
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	pop rax
	;; end of function block attached to the loop
	.continue:	
	inc rax
	jmp .main_loop
	.finish:
	ret

	;; Driven by a shift-copy loop. Repetitively copy string A into the buffer X with left
	;; shift (padding 0) specified by string B as in a shift-add multiplier.
	;; Input:
	;; 	rdi - read-only string pointer A (representing a binary uint, little-endian)
	;; 	rsi - buffer pointer X
	;; 	rdx - buffer size
	;; 	rcx - read-only string pointer B (similar to A)
	;; 	r8  - buffer pointer Y
	;; 	r9  - buffer pointer X+Y
	;; Input Guarantee: All buffers have the same size specified by rdx
	;; Output: rax - pointer result of the multiplication for success, 0 for failure
long_multiply:
	;; Tips: Avoid adjust rsp in the middle of the program. Save them all at the beginning.
	push rdi		; [rsp+48]
	push rsi		; [rsp+40]
	push rdx		; [rsp+32]
	push rcx		; [rsp+24]
	push r8			; [rsp+16]
	push r9			; [rsp+8]
	xor rax, rax
	push rax 		; [rsp] counter init

	;; buffer size check
	cmp rdx, 2
	jb .buffer_check_fail	; buffer must be at least 2 bytes

	;; init buffers
	mov byte[rsi], 0x30	; initialize buffer X
	mov byte[rsi+1], 0
	mov byte[r8], 0x30	; initialize buffer Y
	mov byte[r8+1], 0

	;; shift-adder loop (main loop)
	.main_loop:

	;; check the current digit in read-only string B
	mov rcx, [rsp+24]		; access read-only string B
	mov rax, [rsp]			; access counter
	cmp byte[rcx+rax], 0x30		; check if the current position is digit 0
	je .continue			; if the digit is 0, go to the next cycle
	cmp byte[rcx+rax], 0		; check if the current position is end of string
	je .success			; otherwise the digit must be 1
	cmp rax, [rsp+32]	    	; check buffer capacity
	jae .buffer_check_fail	 	; buffer too small

	;; padding zero according to the current digit 1 
	.padding_loop:
	test rax, rax
	jz .copy		
	dec rax				; padding form here backwards (rax becoming smaller)
	mov rsi, [rsp+40]		; buffer X is the shift-copy buffer
	mov byte[rsi+rax], 0x30		; pad 0
	jmp .padding_loop

	;; copy after zero padding, i.e. shift-copy
	.copy:
	mov rdx, [rsp+32]	; retrieve buffer space
	sub rdx, [rsp]		; compute remaining buffer space after padding 0
	mov rsi, [rsp+40]	; shift-copy buffer (X)
	add rsi, [rsp]	   	; compute start position of the string copy
	mov rdi, [rsp+48]	; retrieve read-only string A
	call string_copy	
	test rax, rax		; check whether copy is successful
	jz .buffer_check_fail	; failure to copy, same exit procedure as buffer_check_fail
	
	;; after each shift & copy, do an addition.
	mov rdi, [rsp+40]
	mov rsi, [rsp+16]
	call num_align
	mov rdi, rax
	mov rsi, rdx
	mov rdx, [rsp+8]
	mov rcx, [rsp+32]
	call long_add
	test rax, rax
	jz .buffer_check_fail

	;; after addition, copy the result (partial sum) to buffer Y
	mov rdi, rax 		; copy addition result to buffer Y
	mov rsi, [rsp+16]
	mov rdx, [rsp+32]
	call string_copy	; impossible to fail
	
	;; print partial sums
	;; mov rdi, rax
	;; call print_string	; print partial sum
	;; call print_newline
	
	.continue:	
	inc qword[rsp]		; inc counter
	jmp .main_loop

	;; exit procedures
	.success:
	mov rax, [rsp+16]
	jmp .clean_up
	.buffer_check_fail: 	
	xor rax, rax
	.clean_up:
	add rsp, 8*7
	ret
	
	;; tests if a string represents 0 - null string is considered 0
	;; Input: rdi - a string pointer
	;; Output: rax - the string pointer for false, or 0 for true.
	;; 	   rdx - pointer to the first non-zero digit, or undefined
is_zero:
	push rdi
	.loop:
	cmp byte[rdi], 0	; empty string is treated as 0
	je .indeed
	cmp byte[rdi], 0x30
	je .next
	mov rdx, rdi	     ;
	pop rax			; the string is not zero. Resturn pointer
	ret
	.next:
	inc rdi
	jmp .loop
	.indeed:
	pop rdi			; restore rsp
	xor rax, rax
	ret
	;; decrement a byte string that encodes a binary uint
	;; Input: rdi - pointer to string buffer
	;; Output: rax - 0 if the input string is zero, otherwise the buffer address
num_dec:	
	call is_zero
	test rax, rax
	jz .quit
	push rax
	push rdx
	lea rdi, [rdx+1]
	call is_zero 		; check if the lowest 1 is a leading 1.
	test rax, rax
	pop rdx
	pop rax
	jz .lowest_one_leading
	mov byte[rdx], 0x30	; set the lowest 1 to 0
	jmp .loop
	.lowest_one_leading:
	mov byte[rdx], 0	; terminate the string here
	.loop:			; set all 0 below the lowest 1 to 1
	cmp rdx, rax
	je .quit		; rdx is impossible to go below rax
	dec rdx
	mov byte[rdx], 0x31
	jmp .loop
	.quit:			; when quit, rax always has the proper value
	ret			; with rax = 0
	;; tests if a string represents a number greater than 1
	;; Input: rdi - a string pointer
	;; Output: rax - the string pointer, or 0 for false.
greater_than_one:
	call is_zero
	test rax, rax
	jz .quit
	cmp rax, rdx		; if first nonzero digit is not the lowest digit, then > 1
	jne .quit
	lea rdi, [rdx+1]	; now rdx=rax, check the rest of the number
	call is_zero
	test rax, rax		; if the rest is zero, the original num is 1
	jz .quit
	dec rax			; move to the lowest digit
	.quit:
	ret
	;; repetitively decrement a number, print the results
	;; Input: rdi - read-only string pointer
	;; 	  rsi - small buffer pointer
	;; 	  rdx - small buffer size
	;;        rcx - long buffer pointer
	;;         r8 - long buffer size
	;;         stack - three MULTIPLY long buffer pointers
	;; Output: rax - 0 if unsuccessful,
	;; 		 otherwise pointer to result in the long buffer 
factorial:
	;; save input parameters
	push rdi		; [rsp+32] - original string pointer
	push rsi		; [rsp+24] - small buffer pointer
	push rdx		; [rsp+16] - small buffer size
	push rcx		; [rsp+8]  - long buffer pointer
	push r8			; [rsp]    - long buffer size
	;; trivial case: check if the original number is zero
	call is_zero
	test rax, rax		; zero-check result
	jz .fac_of_zero
	;; the original string is a number >=1
	;; copy it to the small and long buffers
	mov rdi, [rsp+32]
	mov rsi, [rsp+24]
	mov rdx, [rsp+16]
	call string_copy	; copy to small buffer
	test rax, rax
	jz .init_fail		; buffer initialization failure
	
	mov rdi, [rsp+32]	
	mov rsi, [rsp+8]
	mov rdx, [rsp]
	call string_copy	; copy to long buffer
	test rax, rax
	jz .init_fail
	
	;; decrement & multiply loop
	.loop:
	
	;; test if the number in small buffer is greater than one
	mov rdi, [rsp+24]
	call greater_than_one
	test rax, rax
	jz .quit		; small buffer is reduced to 1 or is initially 1
	
	;; dec the small buffer and multiply with the partial product from the long buffer
	mov rdi, rax	       	; rax now holds the small buffer pointer, whose content >=2 
	call num_dec		; dec the small buffer; success guaranteed
	
	;; long_multiply
	mov rdi, [rsp+24]	; the small buffer pointer
	mov rsi, [rsp+48]	; MULTIPLY long buffer (WHY? - return address !)
	mov rdx, ARITH_BUFFER_SIZE
	mov rcx, [rsp+8]	; long buffer pointer
	mov r8, [rsp+56]	; MULTIPLY long buffer
	mov r9, [rsp+64]	; MULTIPLY long buffer
	call long_multiply
	test rax, rax
	jz .init_fail		; same quit logic as init failure
	
	;; copy the long_multiply result to long buffer 
	mov rdi, rax
	mov rsi, [rsp+8]
	mov rdx, [rsp]
	call string_copy	; copy partial product to long buffer (always success)
	jmp .loop

	;; quit 
	.fac_of_zero:
	mov rcx, [rsp+8]
	mov byte[rcx], 0x31	; if the input is zero, ditectly set output to 1
	mov byte[rcx+1], 0
	mov rax, rcx
	jmp .clean_up
	
	.init_fail:
	xor rax, rax
	jmp .clean_up
	
	.quit:
	mov rax, [rsp+8]	; the result is in the long buffer
	.clean_up:
	add rsp, 40
	ret

	;; subtraction by simultaneous decrement of the minuend and the subtrahend
	;; Input: rdi - minuend buffer pointer
	;; 	  rsi - subtrahend buffer pointer
	;; Output: rax - 0 if minuend is smaller than subtrahend; else pointer to minuend buffer
long_sub:
	;; save input parameters
	push rdi		; [rsp+8] - minuend
	push rsi		; [rsp]   - subtrahend

	.loop:			; loop of simultaneous dec
	
	;; if subtrahend is zero, return the minuend pointer directly 
	mov rdi, [rsp]
	call is_zero
	test rax, rax
	jz .subtrahend_cleared

	;; now subtrahend is >0, if minuend is 0, then subtraction fails
	mov rdi, [rsp+8]
	call is_zero
	test rax, rax
	jz .smaller_minuend

	;; now both subtrahend and minuend are > 0, decrement them both
	;; dec minuend
	mov rdi, [rsp+8]
	call num_dec		; guaranteed to succeed
	;; dec subtrahend
	mov rdi, [rsp]
	call num_dec		; guaranteed to succeed
	
	jmp .loop		; end of loop
	
	;; exit 
	.subtrahend_cleared:
	mov rax, [rsp+8]
	jmp .clean_up
	.smaller_minuend:
	xor rax, rax
	.clean_up:
	add rsp, 16
	ret

	;; Increments a binary uint.
	;; Input: rdi - pointer to a buffer containing the number
	;;        rsi - buffer size
	;; Output: rax - buffer pointer if successful; else 0 - when buffer overflows
num_inc:
	;; save the input param
	push rdi		; [rsp] - buffer pointer

	;; if it is null string, set the buffer to 1, provided buffer is large enough
	.loop:
	cmp byte[rdi], 0	; if NULL is ever reached ...
	jne .not_null 		; either initially NULL, or initially full 1 
	cmp rsi, 2		; in both case, at least 2-byte space is needed
	jb .overflow
	mov byte[rdi], 0x31
	mov byte[rdi+1], 0
	mov rax, [rsp]
	jmp .clean_up

	;; if current byte is not NULL, but is digit 0, set it to 1
	.not_null:
	cmp byte[rdi], 0x30
	jne .lowest_is_1
	mov byte[rdi], 0x31
	mov rax, [rsp]
	jmp .clean_up

	;; if the lowest digit is 1, set all consequtive 1 it to 0,  and increment the first 0
	.lowest_is_1:
	mov byte[rdi], 0x30	; change the lowest 1 to 0
	inc rdi			; point to the next digit
	dec rsi			; reduce avaliable buffer space
	cmp byte[rdi], 0x31
	je .lowest_is_1
	jmp .loop
		
	;; exit 
	.overflow:
	xor rax, rax
	.clean_up:
	add rsp, 8
	ret
	;; Division
	;; Input: rdi - dividend buffer pointer
	;; 	  rsi - divisor buffer pointer
	;;        rdx - quotient buffer pointer
	;;        rcx - remainder buffer pointer
	;;        r8  - read-only divisor pointer
	;; Input guarantee:
	;;   - all input buffers has size ARITH_BUFFER_SIZE
	;;   - the dividend and divisor buffers are preloaded before calling
	;; Output: rax - quotient buffer pointer, or 0 if divide by zero (DbZ)
	;;         rdx - remainder buffer pointer, or undefined if DbZ
long_div:
	push r8		; [rsp+32]  read-only divisor
	push rdi	; [rsp+24]  dividend
	push rsi	; [rsp+16]  divisor
	push rdx	; [rsp+8]   quotient
	push rcx	; [rsp]     remainder

	;; divide-by-zero check
	mov rdi, [rsp+16]
	call is_zero
	test rax, rax
	jnz .not_divide_by_zero
	xor rax, rax
	jmp .clean_up

	.not_divide_by_zero:	
	;; To initialize, copy dividend to remainder
	mov rdi, [rsp+24]
	mov rsi, [rsp]		
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy	; cannot fail
	;; Then set quotitent to 0
	mov rdi, [rsp+8]	
	mov byte[rdi], 0

	.loop:
	;; try subtract divisor from dividend
	mov rdi, [rsp+24]	; minuend is dividend
	mov rsi, [rsp+16]	; subtrahend is divisor
	call long_sub
	test rax, rax
	jz .finish
	;; now minuend is the diff, divisor is reduced to 0
	;; copy the minuend (dividend) to remainder
	mov rdi, rax
	mov rsi, [rsp]
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy	; cannot fail
	;; increment the quotient buffer
	mov rdi, [rsp+8]
	mov rsi, ARITH_BUFFER_SIZE
	call num_inc		; cannot fail
	;; reload the divisor
	mov rdi, [rsp+32]
	mov rsi, [rsp+16]
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy	; cannot fail
	jmp .loop

	;; exit
	.finish:
	mov rax, [rsp+8]
	mov rdx, [rsp]
	.clean_up:
	add rsp, 40
	ret

	;; Repeated division (aka. binary to decimal conversion)
	;; Input: rdi - dividend buffer pointer (source binary)
	;; 	  rsi - divisor buffer pointer
	;;        rdx - quotient buffer pointer
	;;        rcx - remainder buffer pointer
	;;        r8  - read-only divisor pointer
	;; Input guarantee: all input buffers has size ARITH_BUFFER_SIZE;
	;;                  dividend and divisor buffers are preloaded
	;; Output: rax - dividend buffer pointer (decimal of the src. binary) or 0
rep_div:
	sub rsp, ARITH_BUFFER_SIZE ; [rsp+48]  internal buffer
	xor rax, rax
	push rax	; [rsp+40]  internal buffer counter
	push r8		; [rsp+32]  read-only divisor
	push rdi	; [rsp+24]  dividend
	push rsi	; [rsp+16]  divisor
	push rdx	; [rsp+8]   quotient
	push rcx	; [rsp]     remainder

	.loop:
	;; perform a division
	call long_div
	test rax, rax		; quit if divide by zero
	jz .clean_up

	;; convert remainder to decimal and copy to internal buffer
	mov rdi, rdx
	call bin2dec_digit
	test al, al
	jz .clean_up
	lea rdi, [rsp+48]	; internal buffer pointer
	mov rdx, [rsp+40]	; internal buffer counter
	mov [rdi+rdx], al	; copy digit to internal buffer
	inc qword[rsp+40]	; increment internal buffer counter
	
	;; if quotient is zero, exit
	mov rdi, [rsp+8]
	call is_zero
	test rax, rax
	jnz .continue
	lea rdi, [rsp+48]	; internal buffer pointer
	mov rdx, [rsp+40]	; internal buffer counter
	mov byte[rdi+rdx], 0	; NULL terminate  internal buffer data
	mov rsi, [rsp+24]	; copy from internal buffer to dividend buffer
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy
	jmp .clean_up

	;; if quotient is not zero, repeat division
	.continue:
	
	;; copy quotient to dividend buffer
	mov rdi, [rsp+8]
	mov rsi, [rsp+24]
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy	; cannot fail

	;; reload divisor buffer
	mov rdi, [rsp+32]
	mov rsi, [rsp+16]
	mov rdx, ARITH_BUFFER_SIZE
	call string_copy	; cannot fail

	;; set the division params
	mov r8,  [rsp+32]
	mov rdi, [rsp+24]
	mov rsi, [rsp+16]
	mov rdx, [rsp+8]
	mov rcx, [rsp]
	jmp .loop
	
	;; exit
	.clean_up:
	add rsp, 6*8
	add rsp, ARITH_BUFFER_SIZE
	ret

	;; Binary number to decimal digit.
	;; >> ZERO
	;; 0/NULL - 0 (0x30)
	;; >> GROUP I
	;; 01     - 2 (0x32)   I-A
	;; 011    - 6
	;; 001    - 4          I-B
	;; 0001   - 8
	;; >> GROUP II
	;; 1      - 1 (0x31)
	;; 11     - 3	       II-A
	;; 111    - 7
	;; 101    - 5          II-B
	;; 1001   - 9
	;; Input: rdi - a string pointer (representing a binary number)
	;; Output: al - ascii of a single decimal digit, or 0 when it fails
bin2dec_digit:
	push rdi		; [rsp] the input string
	call is_zero
	test rax, rax
	jnz .not_zero
	
	;; IS ZERO
	mov al, 0x30
	jmp .clean_up

	;; NOT ZERO
	.not_zero:
	mov rdi, [rsp] ; point to bit[0]
	cmp byte[rdi], 0x30	
	jne .group_II
	
		;; GROUP I, see 0 at bit[0]
		mov rdi, [rsp]
		inc rdi	; point to bit[1]
		cmp byte[rdi], 0x30	
		je .group_IB
			;; I-A, see 1 at bit[1]
			mov rdi, [rsp]
			add rdi, 2 ; point to bit[2]
			call is_zero ; Is 0 from bit[2] (incl.) onwards?
			test rax, rax
			jnz .IA_not_zero_from_bit2
				;; Is 0 from bit[2] (incl.) onwards
				mov al, 0x32
				jmp .clean_up
				;; Not 0 from bit[2] (incl.) onwards
				.IA_not_zero_from_bit2:
				mov rdi, [rsp]
				add rdi, 2 ; point to bit[2], again
				cmp byte[rdi], 0x31 ; is bit[2] digit 1 ?
				jne .IA_bit2_not_one
					;; bit[2] is 1 
					inc rdi ; point to bit[3]
					call is_zero ; Is 0 from bit[3] (incl.) onwards?
					test rax, rax
						jnz .IA_not_zero_from_bit3
						;; 0 from bit[3] (incl.) onwards
						mov al, 0x36
						jmp .clean_up
						;; not 0 from bit[3] (incl.) onwards
						.IA_not_zero_from_bit3:
						xor al, al
						jmp .clean_up
					;; bit[2] not 1
					.IA_bit2_not_one: 
					xor al, al
					jmp .clean_up
			;; I-B, see 0 at bit[1]
			.group_IB:
			mov rdi, [rsp]
			add rdi, 2 ; point to bit[2] (must be a digit) 
			cmp byte[rdi], 0x31 ; Is bit[2] digit 1 ?
			jne .IB_not_one_at_bit2
				;; see 1 at bit[2]
				mov rdi, [rsp]
				add rdi, 3 ; point to  bit[3]
				call is_zero ; Is zero from bit[3] (incl.) onwards?
				test rax, rax
				jnz .IB_not_zero_from_bit3
					;; zero from bit[3] (incl.) onwards
					mov al, 0x34
					jmp .clean_up
					;; not zero from bit[3] (incl.) onwards
					.IB_not_zero_from_bit3:
					xor al, al
					jmp .clean_up
				;;  see 0 at bit[2]
				.IB_not_one_at_bit2:
				mov rdi, [rsp]
				add rdi, 3 ; point to bit[3]
				cmp byte[rdi], 0x31 ; Is bit[3] digit 1?
				je .IB_bit3_is_one
					;; bit[3] is zero
					xor al, al
					jmp .clean_up
					;; bit[3] is one
					.IB_bit3_is_one:
					mov rdi, [rsp]
					add rdi, 4 ; point to bit[4]
					call is_zero ; Is 0 from bit[4] (incl.) onwards?
					test rax, rax
					jne .IB_not_zero_from_bit4
						;; 0 from bit[4] (incl.) onwards
						mov al, 0x38
						jmp .clean_up
						;; not 0 from bit[4] (incl.) onwards
						.IB_not_zero_from_bit4:
						xor al, al
						jmp .clean_up
	
		;; GROUP II, see 1 at bit[0]
		.group_II:
		mov rdi, [rsp]
		inc rdi ; point at bit[1] 
		call is_zero ; Is zero from bit[1] (incl.) onwards?
		jnz .II_not_zero_from_bit1

			;; 0 from bit[1] (incl.) onwards
			mov al, 0x31
			jmp .clean_up

			;; not 0 from bit[1] (incl.) onwards
			.II_not_zero_from_bit1:
			mov rdi, [rsp]
			inc rdi ; point at bit[1]
			cmp byte[rdi], 0x30 ; Is bit[1] digit 0?
			jne .group_IIA
	
				;; II-B, see 0 at bit[1]
				mov rdi, [rsp]
				add rdi, 2 ; point at bit[2]
				cmp byte[rdi], 0x30 ; Is 0 at bit[2]
				je .IIB_zero_at_bit2

					;; see 1 at bit[2]
					mov rdi, [rsp]
					add rdi, 3 ; point at bit[3]
					call is_zero
					test rax, rax ; Is zero from bit[3] (incl.) onwards ?
					jz .IIB_zero_from_bit3
						;; not 0 from bit[3] (incl.) onwards
						xor al, al
						jmp .clean_up
						;; 0 from bit[3] (incl.) onwards
						.IIB_zero_from_bit3:
						mov al, 0x35
						jmp .clean_up
	
					;; see 0 at bit[2]
					.IIB_zero_at_bit2:
					mov rdi, [rsp]
					add rdi, 3 ; point at bit[3]
					cmp byte[rdi], 0x31 ; Is 1 at bit[3]
					jne .IIB_not_one_at_bit3

						;; see 1 at bit[3]
						mov rdi, [rsp]
						add rdi, 4 ; point at bit[4]
						call is_zero
						test rax, rax ; Is zero from bit[4] (incl.) onwards ?
						jz .IIB_zero_from_bit4
							;; not 0 from bit[4] (incl.) onwards
							xor al, al
							jmp .clean_up
							;; 0 from bit[4] (incl.) onwards 
							.IIB_zero_from_bit4:
							mov al, 0x39
							jmp .clean_up

						;; see 0 at bit[3]
						.IIB_not_one_at_bit3:
						xor al, al
						jmp .clean_up
	
				;; II-A, see 1 at bit[1]
				.group_IIA:
				mov rdi, [rsp]
				add rdi, 2 ; point at bit[2]
				call is_zero
				test rax, rax ; Is 0 from bit[2] (incl.) onwards ?
				jz .IIA_zero_from_bit2

					;; not 0 from bit[2] (incl.) onwards 
					mov rdi, [rsp]
					add rdi, 2 ; point at bit[2]
					cmp byte[rdi], 0x31 ; Is 1 at bit[2]?
					jne .IIA_not_one_at_bit2

						;; see 1 at bit[2]
						mov rdi, [rsp]
						add rdi, 3 ; point at bit[3]
						call is_zero
						test rax, rax ; Is zero from bit[3] onwards?
						jz .IIA_zero_from_bit3
							xor al, al
							jmp .clean_up
							.IIA_zero_from_bit3:
							mov al, 0x37
							jmp .clean_up
						;; see 0 at bit[2]
						.IIA_not_one_at_bit2:
						xor al, al
						jmp .clean_up
					;; 0 from bit[2] (incl.) onwards 
					.IIA_zero_from_bit2:
					mov al, 0x33
					jmp .clean_up	
	.clean_up:
	add rsp, 8
	ret

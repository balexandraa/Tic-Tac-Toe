.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Tic Tac Toe",0
my_width EQU 310
my_height EQU 280
area DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20

image_width EQU 48
image_height EQU 48

check_x_0 DD 0

format_int DB "%d", 13, 10, 0

board DB 0, 0, 0, 0, 0, 0, 0, 0, 0  ; intializam vectorul pt tabla cu 0

stop_game DD 0  ; cand gasim un castigator ne oprim din afisat simboluri

include digits.inc
include letters.inc
include symbols.inc

.code

; Make x (from an image) at the given coordinates
; arg1 - pointer to the pixel vector
; arg2 - x of drawing start position
; arg3 - y of drawing start position
make_x proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, symbol_0
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, my_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_x endp

; simple macro to call the procedure easier
make_x_macro macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_x
	add esp, 12
endm

make_0 proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, symbol_1
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, my_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_0 endp

; simple macro to call the procedure easier
make_0_macro macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_0
	add esp, 12
endm

make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, my_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0d1fc9ch
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm	
	

horizontal_line macro x, y, len, color
local line_loop
	mov eax, y ; eax = y
	mov ebx, my_width
	mul ebx ; eax = y * my_width
	add eax, x ; eax = y * my_width + x
	shl eax, 2 ; eax = (y * my_width + x) *4
	add eax, area
	mov ecx, len
	line_loop:
		mov dword ptr[eax], color
		add eax, 4
		loop line_loop
endm

vertical_line macro x, y, len, color
local line_loop
	mov eax, y ; eax = y
	mov ebx, my_width
	mul ebx ; eax = y * my_width
	add eax, x ; eax = y * my_width + x
	shl eax, 2 ; eax = (y * my_width + x) *4
	add eax, area
	mov ecx, len
	line_loop:
		mov dword ptr[eax], color
		add eax, 4 * my_width
		loop line_loop
endm

;arg1 - x
;arg2- y
make_symbol proc
;local draw_x
	;calculam coordonatele pentru plasarea simbolurilor
	push ebp
	mov ebp, esp
	push esi
	push edi
	
	 mov ebx, 52
	 xor edx, edx
	 
	 mov eax, [ebp+arg1] ; x
	 push eax
	 mul ebx  ; x * 52
	 add eax, 50  ; x*52 + 50 
	 mov esi, eax  ; coord x = esi
	
	 xor edx, edx
	 mov eax, [ebp+arg2] ; y
	 push eax
	 mul ebx ; y*52
	 add eax, 50 ;y*52 +50
	 mov edi, eax ; edi = coord y
	
	 call calcul_index
	 add esp, 8
	 
	 mov ebx, eax ; ebx = index
	 mov ecx, esi ; ecx = coord x
	 mov eax, edi ; edi = coord y
	
	;tranpunem in vector
	 lea edi, board ; edi = board[0]
	 add edi, ebx
	 
	 mov bl, byte ptr [edi] ; ebx = board[index]
	 
	 cmp bl, 0
	 jne go_end ; casuta ocupata
		 cmp check_x_0, 0
		 je draw_x
			 make_0_macro area, ecx, eax
			 mov check_x_0, 0
			 mov bl, 1
			 mov byte ptr [edi], bl
			 jmp go_end
		 draw_x:
			 make_x_macro area, ecx, eax
			 mov check_x_0, 1
			 mov bl, 2
			 mov byte ptr [edi], bl
	go_end:
	
	pop edi
	pop esi
	mov esp, ebp
	pop ebp
	ret
make_symbol endp

;arg1 - y
;arg2 - x
calcul_index proc
	push ebp
	mov ebp, esp
	
	mov eax, [ebp+arg1] ; eax = y
	mov ebx, [ebp+arg2] ; ebx = x
	
	mov ecx, 3 
	mul ecx  ; y*3
	add eax, ebx ; y*3+x
	
	mov esp, ebp
	pop ebp
	ret
calcul_index endp

;returneaza 0 - remiza
;returneaza 1 - castiga 0
;returneaza 2 - castiga X
verificare_castigator proc
	push ebp
	mov ebp, esp
	push esi
	push edi
	
	;verificam linie cu linie
	linie_1:
		lea esi, board ; esi = board[0]
		mov al, byte ptr [esi]  ; al = board[0]   
		
		inc esi  ; trecem la urm element
		mov bl, byte ptr [esi]  ; bl = board[1]  
		
		inc esi
		cmp al, bl
		jne linie_2
			mov cl, byte ptr [esi] ; bl = board[2]
			cmp cl, bl
			jne linie_2
				cmp cl, 0
				jne check_winner
		
	linie_2:
		inc esi
		mov al, byte ptr [esi]  ; al = board[3]   
		
		inc esi  ; trecem la urm element
		mov bl, byte ptr [esi]  ; bl = board[4]  
		inc esi
		
		cmp al, bl
		jne linie_3	
			mov cl, byte ptr [esi] ; bl = board[5]
			cmp cl, bl
			jne linie_3
				cmp cl, 0
				jne check_winner
		
	linie_3:
		inc esi
		mov al, byte ptr [esi]  ; al = board[6]   
		
		inc esi  ; trecem la urm element
		mov bl, byte ptr [esi]  ; bl = board[7]  
		inc esi
		
		cmp al, bl
		jne coloana_1
			mov cl, byte ptr [esi] ; bl = board[8]
			cmp cl, bl
			jne coloana_1
				cmp cl, 0
				jne check_winner
				
	;verificam fiecare coloana
		
	coloana_1:
		lea esi, board ; esi = board[0]
		push esi
		add esi, 3  ; esi = board[3]
		pop edi  ; edi = board[0]
		mov al, byte ptr[edi]  ; al = board[0]
		mov bl, byte ptr[esi] ; bl = board[3]
		
		cmp al, bl
		jne coloana_2
			add esi, 3 ; esi = board[6]
			mov cl, byte ptr [esi]  ; cl = board[6]
			cmp cl, bl
			jne coloana_2
				cmp cl, 0
				jne check_winner
		
	coloana_2:
		inc edi  ; trecem la board[1]
		push edi
		add edi, 3 ; edi = board[4]
		pop esi ; esi = board[1]
		mov al, byte ptr[esi] ; al = board[1]
		mov bl, byte ptr[edi] ; bl = board[4]
		
		cmp al, bl
		jne coloana_3
			add edi, 3 ; edi = board[7]
			mov cl, byte ptr [edi]  ; cl = board[7]
			cmp cl, bl
			jne coloana_3
				cmp cl, 0
				jne check_winner
				
	coloana_3:
		inc esi  ; trecem la board[2]
		push esi
		add esi, 3 ; esi = board[5]
		pop edi ; edi = board[2]
		mov al, byte ptr[edi] ; al = board[2]
		mov bl, byte ptr[esi] ; bl = board[5]
		
		cmp al, bl
		jne diagonala_1
			add esi, 3 ; esi = board[8]
			mov cl, byte ptr[esi] ; cl = board[8]
			cmp cl, bl
			jne diagonala_1
				cmp cl, 0
				jne check_winner
		
	;verificam diagonalele
	
	diagonala_1:
		lea esi, board ; esi = board[0]
		push esi
		add esi, 4 ; esi = board[4]
		pop edi ; edi = board[0]
		mov al, byte ptr[edi] ; al = board[0]
		mov bl, byte ptr[esi] ; bl = board[4]
		
		cmp al, bl
		jne diagonala_2
			add esi, 4
			mov cl, byte ptr[esi] ; cl = board[8]
			cmp cl, bl
			jne diagonala_2
				cmp cl, 0
				jne check_winner
				
	diagonala_2:
		add edi, 2 ; edi = board[2]
		mov al, byte ptr[edi] ; al = board[2]
		cmp al, bl
		jne no_winner
			add edi, 4 ; edi = board[6]
			mov cl, byte ptr[edi] ; cl = board[6]
			cmp bl, cl
			jne no_winner
				cmp cl, 0
				jne check_winner
				jmp no_winner
			
	check_winner:
		cmp cl, 1
		je winner_0
		cmp cl, 2
		je winner_X
		;remiza
		jmp no_winner
	
	winner_0:
		mov eax, 1
		mov stop_game, 1
		jmp exit_loop
		
	winner_X:
		mov eax, 2
		mov stop_game, 1
		jmp exit_loop
	
	no_winner:
		mov eax, 0
	
	exit_loop:
	pop edi
	pop esi
	mov esp, ebp
	pop ebp
	ret
verificare_castigator endp

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc 
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz click
	cmp eax, 2
	jz afisare_text ; nu s-a dat click pe nimic
	
	; initializam background-ul cu alb
	mov eax, my_width
	mov ebx, my_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
	click:
	
		mov eax, [ebp+arg2] ; eax = x - click
		mov ebx, [ebp+arg3] ;  ebx = y - click
		push ebx
		
		xor edx, edx
		sub eax, 50  ; x-click - 50 ; shiftam tabla la margine stanga
		mov ebx, 50
		div ebx  ; eax = (x-click - 50)  / 50
		mov ecx, eax ; ecx = x
		
		xor edx, edx ; edx = 0
		pop eax ; eax = y-click
		sub eax, 50  ; shiftam tabla la margine sus
		div ebx
		
		cmp ecx, 3  ;comparam x cu 3
		jge fail_click
		cmp eax, 3  ; comparam y cu 3
		jge fail_click
		
		cmp stop_game, 1 ; verificam daca a castigat cineva
		je afisare_text
		
		;desenam simbolul care urmeaza
		push eax
		push ecx
		call make_symbol
		add esp, 8
		
		;verificam castigatorul
		call verificare_castigator
		cmp eax, 1
		je castiga_0
		cmp eax, 2
		je castiga_X
		cmp eax, 0
		jmp afisare_text
		
	castiga_0:
		make_text_macro '0', area, 240, 120
		make_text_macro 'W', area, 260, 120
		make_text_macro 'O', area, 270, 120
		make_text_macro 'N', area, 280, 120
		jmp final_draw
		
	castiga_X:
		make_text_macro 'X', area, 240, 120
		make_text_macro 'W', area, 260, 120
		make_text_macro 'O', area, 270, 120
		make_text_macro 'N', area, 280, 120
		jmp final_draw
		
	fail_click:
		
	
	 trasare_careu:
		 vertical_line 100, 50, 154, 0390099h
		 vertical_line 101, 50, 154, 0390099h
		 vertical_line 151, 50, 154, 0390099h
		 vertical_line 152, 50, 154, 0390099h
		 horizontal_line 50, 100, 154, 0390099h
		 horizontal_line 50, 101, 154, 0390099h
		 horizontal_line 50, 151, 154, 0390099h
		 horizontal_line 50, 152, 154, 0390099h
		
	afisare_text:
		make_text_macro 'T', area, 5, 10
		make_text_macro 'I', area, 5, 30
		make_text_macro 'C', area, 5, 50
		
		make_text_macro 'T', area, 5, 90
		make_text_macro 'A', area, 5, 110
		make_text_macro 'C', area, 5, 130
		
		make_text_macro 'T', area, 5, 170
		make_text_macro 'O', area, 5, 190
		make_text_macro 'E', area, 5, 210
	
	final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	
	;alocam memorie pentru tabla de joc
	mov eax, my_width
	mov ebx, my_height
	mul ebx  ; eax = (width * height) - dimensiune tabla
	shl eax, 2 ; inmultim cu 4 (fiecare pixel ocupa un DW = 4 bytes)
	push eax 
	call malloc
	add esp, 4
	mov area, eax  ; area contine dimensiunea totala a tablei
	
	;apelam functia de desenare fereastra
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw  
	push area
	push my_height
	push my_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	push 0
	call exit
end start


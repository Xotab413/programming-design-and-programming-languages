.model small
.stack 256
JUMPS
locals
.data

handle dw 0					;file handle
tiles equ 2000				;quantity of tiles on screen
words equ 4000				;quantity of bytes on screen
screen db 4000 dup (00)		;screen array, contains ASCII's and colors
map db 2200 dup(0)			;map array
temp db 7 dup ('$')			;array for integer output
screen_start dw 0			;zero position in 0B800h
path db "map.txt", 0		;path to file with gamefield

;-----Strings-----
str_game_over db "GAME OVER$"
str_game_over_instruction db "press Q to quit or press R to try again$"
str_level_completed db "LEVEL COMPLETED$"
str_level_completed_instructions db "press Q to quit or press R to restart$"
str_player_lives db "Player lives: $"		;string for game stats information
str_enemies_left db "Enemies left: $"		;string for game stats information
str_start_game db "1. Start game$"			;strings for main menu
str_controls db "2. Controls$"
str_exit db "3. Exit$"

str_game_controls db "[w,a,s,d] - move, [space] - shoot, [r] - restart game$"
str_game_goal db "Your goal is to kill all enemy tanks or destroy enemy base$"
str_game_tip db "We cannot break metal, you can break walls and trees, and even run into trees$"
str_back_to_menu db "Press M to exit to menu$"
str_bonus_instruction1 db "Bonus increases your health by 1                       $"
output_pos_x db 0							;variable for convinient output
input db 0									;contains last inputed character

;-----Booleans-----
game_is_over dw 0							;bolean, present if player lives is 0
level_is_completed dw 0						;bolean, present if all enemies destroyed or base is damaged

rand dw 0									;contains last random number


;-----Player variables-----
p_lives_default dw 1				;start value of p_lives
p_lives dw 0						;amount of player lives
p_moving dw 0						;boolean, present if player can move for one tile
p_pos dw 0							;position of player on screen, index in screen array
p_direction db 0					;0[up], 1[right], 2[down], or 3[left]
p_directions db 'A', '>', 'V', '<'	;direction characters
p_bullet_pos dw 0					;position of player bullet
p_bullet_dir db 0					;direction of player bullet
p_bullet_exist db 0					;1 - bullet is present, 0 - not gl_game_is_present
p_base_blocks dw 0					;amount of player base blocks(tiles)
p_base_blocks_were dw 0				;amount of player base blocks(tiles) at the start of the level

;-----Enemies varaiables-----
e_quantity equ 20					;size of enemies arrays
e_count dw 0						;how many of enemies from array are present
e_poss dw 20 dup (0)				;array of enemies positions, same to p_pos
e_dirs dw 20 dup (0)				;array of enemies directions, same to p_direction
e_moved_by dw 20 dup (0)			;how many tiles each enemy has moved for, need for enemies behavior
e_awaited dw 20 dup(0)				;how many ticks each enemy has moved for, needed for difficulty
e_exist dw 20 dup (0)				;1 - if enemy is present, 0 if not
e_b_poss dw 20 dup (0)				;array of positions of enemies bullets
e_b_dirs dw 20 dup (0)				;array of directions of enemies bullets
e_b_exist dw 20 dup (0)				;1 - if enemy bullet is present, 0 if not
e_b_delay dw 20 dup (0)				;each enemy shoots after a random period of time
e_awaiter dw 16 					;enemy deffault wait ticks, used for difficulty

;-----Bonus variables-----
b_pos dw 0							;position of bonus
b_exist dw 0						;1 if bonus is present, 0 if not
b_await dw 0 						;delay for bonus spawn

;-----Constants-----
b_length equ 160					;[byte length] - how many characters are in one line
w_length equ 80						;[word length] - how many words are in one line
s_to_pass equ 480					;amount of characters reserved in the top of screen for game statistic
w_up_gap equ 240					;[words size gap in up durection]
	
;-----Colors-----
c_metal equ 78h
c_green equ 2h
c_black equ 0
c_cyan equ 3h
c_red equ 4h
c_wall equ 001		
c_e_bullet equ 9h		
c_base equ 24h
c_p_bullet equ c_red 
c_player equ c_green
c_enemy equ c_red
c_bonus equ c_red

;-----Symbols-----
s_bonus equ 3
s_empty equ '0'
s_wall equ 197
s_metal equ 178
s_tree equ 176
s_player db 41h
s_p_bullet equ 7					
s_base equ 127					    
s_e_bullet equ 7					
s_enemy equ 'X'						;Character that enemy gets after initialization
s_up equ 'A'						;Character of enemy or player moving up
s_right equ '>'						;Character of enemy or player moving right
s_down equ 'V'						;Character of enemy or player moving down
s_left equ '<'						;Character of enemy or player moving left
	
.code
jmp start

strlen macro stroke					;finds amount of characters before '$', returns length in cx
	push di 
	push es
	push cx
	mov ax, @data
	mov es, ax
	mov al, '$'
	mov di, offset stroke
	mov cx, 70h
	repne scasb						;repeat while not equal ( cmp with '$' ), decrement cx
	inc cx
	mov ax, 70h
	sub ax, cx
	pop cx
	pop es
	pop di 
endm strlen

out_str macro str, pos_x, pos_y, color 		;outputs string in specific position with specific color
	push ax
	push es
	push bx
	push dx
	push bp
	push cx
	
	mov ax, @data
	mov es, ax
	strlen str 
	mov cx, ax
	mov bp, offset str
	mov ah, 13h								;out a string with attribute
	mov al, 00h
	mov bl, color
	mov dh, pos_y
	mov dl, pos_x
	int 10h

	pop cx
	pop bp
	pop dx
	pop bx
	pop es
	pop ax
endm out_str

rand_screen_pos macro 						;generates random position on screen
	push cx 
	push bx
	mov cx, 80
	call next_rand							;new random from 0 to 79
	mov ax ,rand 
	mov bx, 2
	mul bx 									;convert random number to x cordinate
	mov cx, 25								;new random y
	call next_rand
	mov bx, rand
	mul bx 									;mul x and y to get position on screen
	pop bx
	pop cx
endm rand_screen_pos

rand_by macro border 						;generates rand below border
    push cx
    mov cx, border
    call next_rand    
    pop cx
endm rand_by

next_rand proc  							;generates rand below cx (linear congruential generator) X_n+1 = (a*Xn + c) mod m (where m is our range{in cx})
    push ax 								
    push bx 
    push dx   
    db 0fh, 31h								;rdtsc (It counts the number of CPU cycles since its reset and mov it to ax)
	mov  dx, ax
	in  ax, 40h
	mul  dx
    xchg ax, bx
    mov ax, rand
    add ax, bx
    mov bx, 13
    mul bx
    add ax, 3
    mov bx, cx
    xor dx, dx
    div bx  
    mov rand, dx 
    pop dx 
    pop bx 
    pop ax
    ret 
next_rand endp

render proc 								;calls all render functions and copies screen array in to 0B800h
	push si 
	push di
	
	call redraw_bonus
	call redraw_player
	call redraw_p_bullet
	call redraw_enemies
	call redraw_e_bullets
	
	mov cx, words
	sub cx, s_to_pass
	mov di, word ptr screen_start
	add di, s_to_pass
	mov si, offset screen
	cld
	rep movsb
	
	pop di 
	pop si
	ret
render endp
	
check_bullet_spawn_pos proc 				;checks position in front of player amd spawns bullet if position is empty
	push bx
	push ax
	push di

	mov bl, p_direction
	mov ax, p_pos
	call get_pos_by_dir						;gets position in front of player

	mov di, ax
	cmp screen[di], s_empty					
	jne not_empty_sp

	mov ax, p_pos 							;spawning bullet
	mov p_bullet_pos, ax
	mov bl, p_direction
	mov p_bullet_dir, bl
	mov p_bullet_exist, 1
	jmp check_bullet_sp_end

	not_empty_sp:
	cmp screen[di], s_tree					;if tree or wall are in front of player - destroy them
	je check_bullet_destroy_tile
	cmp screen[di], s_wall
	je check_bullet_destroy_tile

	cmp screen[di], s_up 					;if enemy is in front of player - destroy it
	je check_bullet_destroy_enemy
	cmp screen[di], s_right
	je check_bullet_destroy_enemy
	cmp screen[di], s_down
	je check_bullet_destroy_enemy
	cmp screen[di], s_left
	je check_bullet_destroy_enemy

	cmp screen[di], s_base 				;if player base is in front of player - destroy it
	je check_bullet_destroy_base
	jmp check_bullet_sp_end

	check_bullet_destroy_enemy:				;destroy enemy
	mov ax, di
	call dont_exist_with_pos
	jmp check_bullet_destroy_tile

	check_bullet_destroy_base:				;destroy base
	dec p_base_blocks
	jmp check_bullet_destroy_tile

	check_bullet_destroy_tile:				;destroy a tile
	mov screen[di], s_empty
	mov screen[di+1], c_black
	mov p_bullet_exist, 0
	jmp check_bullet_sp_end

	check_bullet_sp_end:
	pop di
	pop ax
	pop bx
	ret
check_bullet_spawn_pos endp

check_eb_spawn_pos proc 					;checks position in front of enemy and spawn bullet
	push ax 
	push bx 
	push di
	push si

	cmp e_b_exist[si], 1					;if bullet is not present - exit proc
	je check_eb_sp_end

	mov bx, e_dirs[si]
	mov ax, e_poss[si]
	call get_pos_by_dir						;get position in front of enemy
		
	mov di, ax
	cmp screen[di], s_empty					;spawn bullet if position is empty
	jne not_empty_eb_sp
		
	mov ax, e_poss[si]
	mov e_b_poss[si], ax
	mov ax, e_dirs[si]
	mov e_b_dirs[si], ax
	mov e_b_exist[si], 1
	jmp check_eb_sp_end
		
	not_empty_eb_sp:
	cmp screen[di], s_tree					;if wall, tree in front - destroy them 
	je check_eb_destroy_tile
	cmp screen[di], s_wall
	je check_eb_destroy_tile
	jmp check_eb_sp_end

	check_eb_destroy_base:
	dec p_base_blocks
	jmp check_eb_destroy_tile
		
	check_eb_destroy_tile:
	mov screen[di], s_empty
	mov screen[di+1], c_black
	mov e_b_exist[si], 0
	jmp check_eb_sp_end

	check_eb_sp_end:

	pop si 
	pop di 
	pop bx 
	pop ax
	ret
check_eb_spawn_pos endp 

get_pos_by_dir proc 						;calculates position in front of ax by direction in bl and returns this position in ax
;[get position by directon]					;bl - direction, ax - position; ret ax
	cmp bl, 0
	jne dir_not_0
	sub ax, b_length
	jmp get_tile_by_dir_end
	
	dir_not_0:
	cmp bl, 1
	jne dir_not_1
	add ax, 2
	jmp get_tile_by_dir_end

	dir_not_1:
	cmp bl, 2
	jne dir_not_2
	add ax, b_length
	jmp get_tile_by_dir_end

	dir_not_2:
	cmp bl, 3
	jne get_tile_by_dir_end
	sub ax, 2
	jmp get_tile_by_dir_end

	get_tile_by_dir_end:
	ret
get_pos_by_dir endp

update_game_status proc 					;updates game_is_over and level_is_completed
	push ax
	mov ax, p_base_blocks_were
	cmp p_base_blocks, ax 					;if base is damaged - game over
	jne ugs_level_is_completed
	cmp p_lives, 0							;if player lives equal 0 - game over
	je ugs_game_is_over
	cmp e_count, 0							;if no more enemies left - level is completed
	je ugs_level_is_completed
	jmp ugs_end

	ugs_level_is_completed:
	mov level_is_completed, 1
	jmp ugs_end

	ugs_game_is_over:
	mov game_is_over, 1
	jmp ugs_end

	ugs_end:
	pop ax
	ret
update_game_status endp 

update_player_symbol proc 					;updates player character by direction [A, >, V, <]
	push ax
	push di
	push cx 
	xor cx, cx
	xor di, di
	mov cl, p_direction
	update_symbol_loop:
	inc di
	loop update_symbol_loop
	mov ah, p_directions[di]
	mov s_player, ah
	pop cx
	pop di
	pop ax
	ret
update_player_symbol endp

update_player proc  						;updates player position and handles bonuses
	push ax
	push bx
	push di

	mov di, p_pos
	call erase_di_tile						;erase player in previous position
	cmp p_moving, 1
	jne update_player_end

	dec p_moving							;moved by one tile
	mov bl, p_direction
	mov ax, p_pos
	call get_pos_by_dir						;new position
	mov di, ax

	cmp screen[di], s_empty					;move to new position if it's empty
	jne up_not_empty
	mov p_pos, di
	jmp update_player_end

	up_not_empty:							
	cmp screen[di], s_tree					;smash tree in front of tank
	jne up_not_tree
	mov p_pos, di
	jmp update_player_end

	up_not_tree:
	cmp screen[di], s_bonus 				;obtain bonus
	jne up_not_bonus
	call apply_bonus 						;use bonus
	mov p_pos, di

	up_not_bonus:
	update_player_end:
	call update_player_symbol

	pop di
	pop bx
	pop ax 
	ret
update_player endp

update_p_bullet proc 						;updates position of player bullet
	push di
	push bx
	push ax

	cmp p_bullet_exist, 1					;updates position only if bullet is present
	jne update_p_b_end

	mov ax, p_bullet_pos
	mov bl, p_bullet_dir
	call get_pos_by_dir
	mov di, p_bullet_pos
	call erase_di_tile
	mov p_bullet_pos, ax

	update_p_b_end:
	pop ax
	pop bx
	pop di
	ret
update_p_bullet endp

update_e_bullets proc 						;updates position of enemies bullets
	push ax 
	push bx 
	push di
	push si 
	push cx 
	mov cx, e_quantity
	xor si, si 
	update_eb_loop:
		cmp e_b_exist[si], 1
		jne update_eb_loop_end

		mov di, e_b_poss[si]
		call erase_di_tile
		mov ax, e_b_poss[si]
		mov bx, e_b_dirs[si]
		call get_pos_by_dir
		
		mov e_b_poss[si], ax

		update_eb_loop_end:
		add si, 2
	loop update_eb_loop

	update_e_b_end:
	pop cx
	pop si
	pop di 
	pop bx
	pop ax
	ret 
update_e_bullets endp 

update_enemies proc 						;enemy move and shoot logic
	push cx
	push si
	push di
	push ax

	mov cx, e_quantity
	xor si, si
	update_each_enemy_loop:
		cmp e_exist[si], 1
		je ue_exist
		jmp ue_loop_end_for_dead

		ue_exist:
		call enemy_shoot

		mov di, e_poss[si]
		cmp screen[di], s_empty
		je e_cant_exist
		jmp ue_loop_begin

		e_cant_exist:
		mov ax, e_poss[si]
		call dont_exist_with_pos

		ue_loop_begin:
		mov ax, e_awaiter
		cmp e_awaited[si], ax				;enemy artificial slowdown
		jge ue_awaited
		jmp ue_loop_end

		ue_awaited:
		mov e_awaited[si], 0
		cmp e_moved_by[si], 8				;enemy random turn logic
		jl ue_loop_continue
 		
		mov e_moved_by[si], 0
		rand_by 4
		mov ax, rand
		mov e_dirs[si], ax
		jmp ue_loop_continue

		ue_loop_continue:
		mov ax, e_poss[si]
		mov bx, e_dirs[si]
		mov di, ax
		call erase_di_tile
		call get_pos_by_dir
		mov di, ax

		cmp di, p_pos 						;can't move into player
		je ue_not_empty

		push cx
		push si
		mov cx, e_quantity
		xor si, si
		update_eel_check_e_pos:
			cmp di, e_poss[si] 				;can't move into another enemy
			je ue_enemy_pos
			add si, 2
		loop update_eel_check_e_pos
		jmp ue_not_enemy_pos

		ue_enemy_pos:
		pop si
		pop cx
		jmp ue_not_empty

		ue_not_enemy_pos:
		pop si
		pop cx

		cmp screen[di], s_empty 			;move if position is empty
		jne ue_not_empty

		mov e_poss[si], ax
		inc e_moved_by[si]					;moved by one more tile
		jmp ue_loop_end_for_dead

		ue_not_empty:
		rand_by 4							;random turn
		mov ax, rand
		mov e_dirs[si], ax
		jmp ue_loop_end_for_dead
		ue_loop_end:
		inc e_awaited[si]
		ue_loop_end_for_dead:
	dec cx
	add si, 2
	jcxz end_e_update
	jmp update_each_enemy_loop
	end_e_update:
	pop ax
	pop di
	pop si
	pop cx
	ret
update_enemies endp

update proc 								;evokes all update functions and handle input
	push bx
	push ax
	push di
	push cx
	mov ah, 01h
	int 16h
	
	jnz keyboard_input						;if keyboard buffer isn't empty
	jmp update_continue
	keyboard_input:
	call get_key
	
	cmp input, 32							;[space] - shoot
	jne not_keySpace
	cmp p_bullet_exist, 1
	jne space_input
	jmp update_continue
	space_input:
	add rand, 1
	call check_bullet_spawn_pos
	jmp update_continue

	not_keySpace:
	mov p_moving, 1
	cmp input, 'w'							;[w] - move up
	jne not_keyW
	mov p_direction, 0
	jmp update_continue

	not_keyW:								
	cmp input, 's'							;[s] - move down
	jne not_keyS
	mov p_direction, 2
	jmp update_continue

	not_keyS:								
	cmp input, 'a'							;[a] - move left
	jne not_keyA
	mov p_direction, 3
	jmp update_continue

	not_keyA:					
	cmp input, 'd'							;[d] - move right
	jne not_keyD
	mov p_direction, 1
	jmp update_continue

	not_keyD:
	mov p_moving, 0
	cmp input, 'r'							;[r] - restart game
	je game_start
								
	update_continue:
	mov input, 0
	call update_player
	call update_p_bullet
	call update_enemies
	call update_e_bullets
	call update_game_status

	update_end:
	pop cx
	pop di
	pop ax
	pop bx
	ret
update endp

enemy_shoot proc 							;perform shoot by enemy
	push ax
	cmp e_b_delay[si], 0					;shooting delay
	jne e_shoot_awaiting
	call check_eb_spawn_pos
	rand_by 100
	mov ax, rand 
	mov e_b_delay[si], ax 					;new shooting delay
	jmp enemy_shoot_end

	e_shoot_awaiting:
	dec e_b_delay[si]
	jmp enemy_shoot_end 

	enemy_shoot_end:
	pop ax
	ret
enemy_shoot endp

spawn_bonus proc 							;spawn new bonus in random empty position
	push ax
	push di 
	cmp b_exist, 1
	je spawn_bonus_end
	cmp b_await, 0
	jne spawn_bonus_end

	mov b_await, 300

	spawn_bonus_in_empty:
		rand_screen_pos
		mov di, ax
		cmp screen[di], s_empty
		je sb_spawn_pos_found
	jmp spawn_bonus_in_empty

	sb_spawn_pos_found:
	mov b_pos, ax
	mov b_exist, 1

	spawn_bonus_end:
	dec b_await
	pop di
	pop ax
	ret
spawn_bonus endp

apply_bonus proc 							;apply bonus effect: add 1 health to player

	cmp b_exist, 1 							;only if bonus is present
	jne apply_bonus_end

	apply_bonus_begin:
	add p_lives, 1

	apply_bonus_end:
	mov b_exist, 0

	ret 
apply_bonus endp

kill_random_enemy proc 						;kills random enemy on screen
	push si
	push ax
	kre_another:
		rand_by e_quantity
		mov si, rand
		cmp e_exist[si], 1
	jne kre_another
	mov ax, e_poss[si]
	call dont_exist_with_pos
	pop ax
	pop si
	ret
kill_random_enemy endp

get_key proc 								;get user input
	mov ax, 0
	int 16h									;read symbol with wait
	cmp al, 0
	je get_extended
	mov input, al							;mov ascII symb of key
	jmp get_key_end
	get_extended:
	mov input, ah
	get_key_end:
	call clear_keyboard_buffer				;clear al unhandled input
	ret
get_key endp

redraw_player proc 							;draw player character in p_pos on screen
	push ax
	push bx
	push di

	mov di, p_pos
	mov ah, s_player
	mov al, c_player
	mov screen[di], ah
	mov screen[di+1], al

	pop di
	pop bx
	pop ax
	ret
redraw_player endp

redraw_p_bullet proc 						;draws bullet and handles bullet logic
	push di
	push bx
	push ax

	cmp p_bullet_exist, 1					;only if bullet is present
	je redraw_p_b_continue
	jmp redraw_p_b_end
	redraw_p_b_continue:

	mov di, p_bullet_pos
	cmp screen[di], s_empty					;draw bullet if tile is empty
	jne rpb_not_empty
	mov screen[di], s_p_bullet
	mov screen[di+1], c_p_bullet
	jmp redraw_p_b_end

	rpb_not_empty:							;destroy tile if it isn't empty
	cmp screen[di], s_tree
	je rpb_erase_tile
	cmp screen[di], s_up
	je rpb_erase_enemy
	cmp screen[di], s_right
	je rpb_erase_enemy
	cmp screen[di], s_down
	je rpb_erase_enemy
	cmp screen[di], s_left
	je rpb_erase_enemy
	cmp screen[di], s_enemy
	je rpb_erase_enemy
	cmp screen[di], s_base
	je rpb_destroy_base_block
	cmp screen[di], s_wall
	je rpb_erase_tile
	jmp rpb_destroy_bullet

	rpb_destroy_base_block:
	dec p_base_blocks						;destroy payer base block
	jmp rpb_erase_tile

	rpb_erase_enemy:
	cmp screen[di+1], c_player				;if it isn't player
	je rpb_erase_player
	mov ax, di
	call dont_exist_with_pos				;destroy enemy
	jmp rpb_erase_tile

	rpb_erase_player:
	dec p_lives 							;destroy player
	jmp rpb_erase_tile

	rpb_erase_tile:
	call erase_di_tile						;destroy tile
	jmp rpb_destroy_bullet

	rpb_destroy_bullet:
	mov p_bullet_exist, 0					;bullet isn't present
	redraw_p_b_end:
	pop ax
	pop bx
	pop di
	ret
redraw_p_bullet endp 

redraw_e_bullets proc 						;redraw enemies bullets
	push di
	push bx
	push ax
	push si
	push cx 
	mov cx, e_quantity
	xor si, si 
	redraw_eb_loop:
		cmp e_b_exist[si], 1				;redraw only if bullet is present
		jne redraw_eb_loop_end

		mov di, e_b_poss[si]
		cmp screen[di], s_empty				;if tile is empty - draw bullet
		jne reb_not_empty
		mov screen[di], s_p_bullet
		mov screen[di+1], c_p_bullet
		jmp redraw_eb_loop_end

		reb_not_empty:						;destroy tile if it's tree, wall or player
		cmp screen[di], s_tree
		je reb_erase_tile
		cmp screen[di], s_up
		je reb_erase_player
		cmp screen[di], s_right
		je reb_erase_player
		cmp screen[di], s_down
		je reb_erase_player
		cmp screen[di], s_left
		je reb_erase_player
		cmp screen[di], s_wall
		je reb_erase_tile
		jmp reb_destroy_bullet

		reb_erase_player:					;erase player
		cmp screen[di+1],c_player
		jne reb_destroy_bullet
		dec p_lives
		jmp reb_destroy_bullet

		reb_destroy_base_block:
		dec p_base_blocks					;erase player base
		jmp reb_erase_tile

		reb_erase_tile:
		call erase_di_tile					;erase tile
		jmp reb_destroy_bullet

		reb_destroy_bullet:
		mov e_b_exist[si], 0				;bullet isn't present
		jmp redraw_eb_loop_end

		redraw_eb_loop_end:
		add si, 2
	loop redraw_eb_loop
	redraw_eb_end:
	pop cx 
	pop si 
	pop ax
	pop bx
	pop di
	ret 
redraw_e_bullets endp 

redraw_enemies proc  						;draw enemy character according to enemy direction
	push di
	push si
	push cx
	push ax
	mov cx, e_quantity
	xor si, si
	redraw_each_enemy_loop:
		cmp e_exist[si], 0
		je re_before_end
		mov di, e_dirs[si]
		mov al, p_directions[di] 			;get direction character
		mov di, e_poss[si]
		mov screen[di], al
		mov screen[di+1], c_enemy

		re_before_end:
		add si, 2
	loop redraw_each_enemy_loop
	pop ax
	pop cx
	pop si
	pop di
	ret
redraw_enemies endp

redraw_bonus proc 							;draw bonus tile on screen
	push ax
	push bx
	push di

	cmp b_exist, 0
	je redraw_b_dont_exist
	mov di, b_pos
	mov ah, s_bonus
	mov al, c_bonus
	mov screen[di], ah
	mov screen[di+1], al

	redraw_b_dont_exist:

	pop di
	pop bx
	pop ax
	ret 
redraw_bonus endp 

erase_di_tile proc 							;erases tile with di position on screen
	mov screen[di], s_empty
	mov screen[di+1], c_black
	ret
erase_di_tile endp

clear_enemies proc 							;reset of enemy arrays
	push si
	push cx
	push di
	mov cx, e_quantity
	clear_enemies_loop:
		mov e_exist[si], 0
		mov di, e_b_poss[si]				;clear enemies positions on screen
		mov screen[di], s_empty 
		mov screen[di+1], c_black
		mov e_b_exist[si], 0
		add si, 2
		loop clear_enemies_loop
	mov e_count, 0
	pop di
	pop cx
	pop si 
	ret
clear_enemies endp

enemies_rand_directions proc 				;fill enemies direction array with random directions
	push si
	push cx
	mov cx, e_quantity
	xor si, si
	erd_loop:
		rand_by 4
		mov ax, rand
		mov e_dirs[si], ax
		add si, 2
		loop erd_loop
	pop cx
	pop si 
	ret
enemies_rand_directions endp

dont_exist_with_pos proc 					;destroy enemy with position equal ax
;ax - enemy pos
	push si
	push di

	call get_si_by_pos 						;get enemy index in arrays bu position
	mov di, e_poss[si]
	call erase_di_tile

	cmp e_b_exist[si], 0
	je dewp_bullet_dont_exist
	mov di, e_b_poss[si]					;erase bullet if it is present
	call erase_di_tile
	mov e_b_exist[si], 0

	dewp_bullet_dont_exist:
	mov e_exist[si], 0
	dec e_count

	pop di
	pop si 
	ret
dont_exist_with_pos endp

get_si_by_pos proc  						;return index in enemies arrays by position
;[get si index by position]
;ax - enemy pos
	push cx
	mov cx, e_quantity
	xor si, si
	get_si_by_pos_loop:
		cmp e_poss[si], ax 					;if position equals to ax - index founded
		je get_si_by_pos_endloop
		add si, 2
	loop get_si_by_pos_loop
	get_si_by_pos_endloop:
	pop cx 
	ret 
get_si_by_pos endp 


make_str_from_integer proc 					;converts integer in ax to 'temp' string
    push di 
    push dx
    push cx     
    push si
    push es   

    push ax

    push @data
    pop es 

	mov si, offset temp

    mov cx, 10      
    cmp ax, 0     
    jge make_str_loop 
    neg ax									;make negative number positive
    make_str_loop:
    xor dx, dx
    div cx 									;div ax by 10 to get last numeral
    xchg ax, dx
    add al, '0'								;convert integer to ascii
    mov [si], al 							;put ascii in array 'temp'
    xchg ax, dx      
    inc si
    or ax, ax
    jne make_str_loop						;continue while ax>0
    pop ax
    cmp ax, 0      
    jge end_makestr 						
    clc
    mov [si], '-'
    end_makestr: 

    push si
    pop di  
    dec di          
    mov si, offset temp 	
      
    push di
    push ax
    push bx

    cld    
    reverse_cycle:
        mov al, [si]  						;swapping symbols
        mov bl, [di]
        mov [si], bl
        mov [di], al

        dec di    							;moving borders towards each other
        inc si
        cmp si, di 
    jl reverse_cycle       					;if borders met -> ret  

    pop bx
    pop ax
    pop di    

    inc di
    mov [di], 0
    
    pop es
    pop si
    pop cx
    pop dx  
    pop di
    ret      
endp    

read_map proc 								;reads symbol map from file
	push dx
	push ax
	push bx
	push cx


	mov ax, 3D00h							;open existing file (in ax file handler)
	lea dx, path
	int 21h
	jc file_read_err	
                
    mov handle, ax 							;save file handle
	mov bx, handle
    mov ah, 3fh   							;fun - read from file
    lea dx, map								;buffer for data incoming
    mov cx, tiles       					;num of tiles to read
    int 21h

    mov handle, ax

    file_read_end: 							;close file
	mov ah,3eh
    int 21h

    pop cx
    pop bx
	pop ax
	pop dx
	ret
	file_read_err:
	jmp exit
read_map endp

convert_map proc 							;converts single chars from file to word screen symbols
	push cx
	push di
	push si
	push ax
	push bx
	mov cx, tiles 							;amount of single characters on screen
	sub cx, w_up_gap 						;sub symbols for gap in the top of screen
	xor di, di
	xor si, si
	xor bx, bx
	convert_loop:
		cmp map[si], 31 					;if the symbol is service ascii - skip it
		ja convert_continue
		inc si
		jmp convert_loop

		convert_continue:
		cmp map[si], '8' 					;convert '8' into wall char
		jne not_wall
		mov ah, s_wall
		mov al, c_wall
		jmp convert_map_symbol

		not_wall:
		cmp map[si], '3' 					;convert '3' into tree char
		jne not_tree
		mov ah, s_tree
		mov al, c_green
		jmp convert_map_symbol

		not_tree:
		cmp map[si], '6'  					;convert '6' into base char
		jne not_p_base
		mov ah, s_base
		mov al, c_base
		inc p_base_blocks
		inc p_base_blocks_were
		jmp convert_map_symbol

		not_p_base:
		cmp map[si], 'e' 					;convert 'e' into enemy char
		jne not_enemy
			push si
			xor ax, ax
			mov ax, e_count
			mov bx, 2
			mul bx
			mov si, ax
			mov e_poss[si], di 				;save enemy position
			mov e_exist[si], 1
			pop si
		mov ah, s_enemy
		mov al, c_enemy	
		add e_count, 1 						;increment enemy count
		jmp convert_map_symbol

		not_enemy:
		cmp map[si], 'p' 					;convert 'p' into player char
		jne not_player
		mov p_pos, di
		mov ah, s_player
		mov al, c_player
		jmp convert_map_symbol

		not_player:
		cmp map[si], '9' 					;convert '9' into metal, unbreakable char
		jne not_metal
		mov ah, s_metal
		mov al, c_metal
		jmp convert_map_symbol

		not_metal:
		convert_loop_inner_end:
		mov ah, '0' 						;if symbol is unhandled - fill char with emptyness
		mov al, c_black

		convert_map_symbol:
		add bx, 2
		mov screen[di], ah
		mov screen[di+1], al

		convert_loop_end:
		inc si
		add di, 2
		dec cx
		jcxz convert_map_end
		jmp convert_loop
		convert_map_end:
	pop bx
	pop ax
	pop si
	pop di
	pop cx
	ret
convert_map endp

refresh_game_variables proc 				;refresh all significant game variables, should be called before every start of the game
	push si
	push cx
	push ax
	push bx
	mov p_base_blocks, 0					;refresh player variables
	mov p_base_blocks_were, 0
	
	mov bx, [p_lives_default]
	mov p_lives, bx
	
	mov p_moving, 0
	mov p_direction, 0

	call clear_enemies 						;refresh enemy variables
	mov cx, e_quantity
	refresh_gv_loop:
		rand_by 150
		mov ax, rand
		mov e_b_delay[si], ax
		add si, 2
	loop refresh_gv_loop
	mov e_awaiter, 16

	mov game_is_over, 0
	mov level_is_completed, 0
	mov b_await, 100						;refresh 'bonus' variables

    pop bx
	pop ax
	pop cx
	pop si
	ret
refresh_game_variables endp

print_game_stats proc 						;output player lives, enemies amount and time
	push ax
	mov output_pos_x, 20
	out_str str_player_lives, output_pos_x, 1, c_green

	strlen str_player_lives
	add output_pos_x, al
	mov ax, p_lives
	call make_str_from_integer
	out_str temp, output_pos_x, 1, c_red

	strlen temp
	add output_pos_x, 5
	out_str str_enemies_left, output_pos_x, 1, c_green

	strlen str_enemies_left
	add output_pos_x, al 
	mov ax, e_count
	call make_str_from_integer
	out_str temp, output_pos_x, 1, c_red

	pop ax
	ret 
print_game_stats endp 

clear_keyboard_buffer proc 					;flushes stored in keyboard buffer characters
	push ax
	ckb_loop:
		mov ah, 01h							;check if buffer have symbol
		int 16h
		jz ckb_end
		mov ah, 00h 						;flush it
		int 16h
		jmp ckb_loop 						;repeat
	ckb_end:
	pop ax
	ret
clear_keyboard_buffer endp

wait_tick proc 								;wait one clock tick (1/18.2*second)
	push ax
	push cx
	push dx
	push bx
	xor ax, ax
	int 1ah									;get current clock ticks
	mov bx, dx
	wait_tick_loop:
		xor ax, ax
		int 1ah
		cmp dx, bx 							;repeat cycle while tiks are remaining the same
	je wait_tick_loop
	pop bx
	pop dx
	pop cx
	pop ax
	ret
wait_tick endp

game_over: 									;game over menu
	mov ax, 0003h
	int 10h 								;clear screen
	push 0B800h
	pop es

	game_over_outp:
	
	out_str str_game_over, 35, 11, c_red 	;output messages
	out_str str_game_over_instruction, 2, 20, c_green

	go_wait_loop:
		mov ah, 01h
		int 16h
		jz go_wait_loop
		call get_key 						;get user input
		cmp input, 'r'
		je game_over_to_start
		cmp input, 'q'
		je game_over_to_exit
		jmp go_wait_loop
	game_over_to_start:
	jmp game_start
	game_over_to_exit:
	jmp exit


level_completed: 							;level completed menu
	mov ax, 0003h
	int 10h 								;clear screen
	push 0B800h
	pop es

	level_complete_outp:
	
	out_str str_level_completed, 2, 11, c_green
	out_str str_level_completed_instructions, 2, 20, c_green

	lc_wait_loop:
		mov ah, 01h
		int 16h
		jz lc_wait_loop
		call get_key 						;get user input
		cmp input, 'r'
		je game_start
		cmp input, 'q'
		je exit
	jmp lc_wait_loop
	

controls_instructions: 						;outputs game controls and instructions
	mov ax, 0003h
	int 10h
	push 0B800h
	pop es
	
	out_str str_game_controls, 2, 1, c_cyan
	out_str str_game_goal, 2, 3, c_cyan
	out_str str_bonus_instruction1, 2, 5, c_cyan
	out_str str_game_tip, 2, 7, c_green
	out_str str_back_to_menu, 2, 9, c_green

	ci_wait_loop:
		mov ah, 01h
		int 16h
		jz ci_wait_loop
		call get_key
		cmp input, 'm' 					
 		je game_menu
	jmp ci_wait_loop


game_menu:									;main game menu
	mov ax, 0003h
	int 10h
	push 0B800h
	pop es

	out_str str_start_game, 2, 1, c_green  ;1. Start game
	out_str str_controls, 2, 2, c_cyan     ;2. Controls
	out_str str_exit, 2, 3, c_red          ;3. Exit

	gm_wait_loop: 						   ;get user input
		mov ah, 01h						   ;check is keyboard bufer is empty
		int 16h
		jz gm_wait_loop					   ;if not we're waiting
		call get_key
		cmp input, '1'
		je game_start
		cmp input, '2'
		je controls_instructions
		cmp input, '3'
		je exit
	jmp gm_wait_loop

	
start: 
	mov ax, @data
	mov ds, ax
	jmp game_menu

	game_start:
	mov ax, 0003h
	int 10h
	push 0B800h
	pop es	
	
	call refresh_game_variables				;refresh all significant variables
	call read_map							;read char map from file
	call convert_map 						;convert char map to word array
	call enemies_rand_directions 			;randomize start enemies directions

	game_loop:
		call spawn_bonus 					;spawns bonus in random position
		call render 						;render tiles
		call update 						;updates enemies, bullets, game stats, bonus and player
		call print_game_stats 				;outputs game stats
		call wait_tick 						;wait one tick to slow down the game

		cmp game_is_over, 0 				;check if game is over or level is completed
		je gl_game_is_present
		jmp game_over
		gl_game_is_present:
		cmp level_is_completed, 0
		je level_isnt_completed
		jmp level_completed
		level_isnt_completed:
	jmp game_loop


exit:
	mov ax, 0002h							;set cursor to default position
		int 10h
	mov ah, 4ch
	int 21h
end start

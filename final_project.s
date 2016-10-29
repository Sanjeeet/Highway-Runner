
# final project 243 
# Joo Hun Lee, Daniel Min (Station #55)

/* r2 = Flag for car position (0 == lane1,  1 == lane2, 2 == lane3, 3 == lane4)
   r3 = Counter for randomly generating obstacles at differnt lanes 
   r4 = Flag for game states (0 == Main Menu, 1 == Run Game, 2 == Game Won, 3 == Game Lost )
   r10 = Flag for obstacle positions (0 == lane1,  1 == lane2, 2 == lane3, 3 == lane4)
   r11 = Flag if okay to generate obstacle on a differnt lane (0 == not possible, 1 == possible)
   r22 = Score (Game Win when Score hits 20 ) */


.equ ADDR_VGA, 0x08000000 # VGA 
.equ ADDR_KEYBOARD, 0xFF200100 # Keyboard
.equ ADDR_TIMER, 0xFF202000 # Timer 
.equ ONE_SEC, 0x001e8480  # 2 million cycles per second (0.02s)
.equ DOWN_FOR_KEYBOARD, 0x00000072 
.equ UP_FOR_KEYBOARD,  0x00000075
.equ HOME_FOR_KEYBOARD, 0x0000006C
.equ ARROW, 0x000000E0 # For break codes 
.equ BREAK, 0x000000F0 # For break codes 
.equ INITIAL_STACK_POINTER, 0x03FFFFFC # 
.equ ADDR_7SEGS_LOW, 0xff200020	# 7 segment display 0-3

.data
main_menu: .incbin "main_menu.bin"
car:.incbin "car.bin"
background:.incbin "background.bin" # default background for our game 
obstacle:.incbin "obstacle.bin"
game_win: .incbin "game_win.bin" # background for once game is won 
game_over: .incbin "game_over.bin" # background for one game is lost 


.section .exceptions, "ax"
ISR:
rdctl et, ctl4  # see if IRQ7
srli et, et, 7
andi et, et, 0x01 
bne et, r0, KEYBOARD_INTERRUPT
br EXIT_ISR 


KEYBOARD_INTERRUPT: 

READ_ARROW: # for reading EO

ldwio et, 0(r6)
andi r20, et, 0x8000 # mask 
beq r20, r0, READ_ARROW # poll 
andi et, et, 0x00FF 

# check if right byte 
movia r16, ARROW
beq et, r16, READ_BREAK 
br EXIT_ISR


READ_BREAK: # for reading FO (the realease byte)

ldwio et, 0(r6)
andi r20, et, 0x8000 # mask 
beq r20, r0, READ_BREAK # poll 
andi et, et, 0x00FF 

# check if right byte 
movia r16, BREAK 
beq et, r16, READ_FOR_REAL
br EXIT_ISR

READ_FOR_REAL: # for reading which key got pressed 

ldwio et, 0(r6)
andi r20, et, 0x8000 # mask 
beq r20, r0, READ_FOR_REAL # poll 
andi et, et, 0x00FF 

movia r16, DOWN_FOR_KEYBOARD
beq et, r16, DOWN_TIME
movia r16,  UP_FOR_KEYBOARD
beq et, r16, UP_TIME
movia r16, HOME_FOR_KEYBOARD
beq et, r16, HOME_TIME 
br EXIT_ISR

DOWN_TIME:

movi et, 0x00 # currently on lane1
beq r2, et, GO_TO_LANE_2 # go to lane2 
movi et, 0x01 # currently on lane2 
beq r2, et, GO_TO_LANE_3 # go to lane3 
movi et, 0x02 # currently on lane3
beq r2, et, GO_TO_LANE_4 # go to  lane4 
movi et, 0x03 # currently on lane4
beq r2, et, GO_TO_LANE_4 # stay on lane4 
br EXIT_ISR

UP_TIME:
movi et, 0x00 # currently on lane1
beq r2, et, GO_TO_LANE_1 # stya on lane1 
movi et, 0x01 # currently on lane2
beq r2, et, GO_TO_LANE_1 # go to lane1
movi et, 0x02 # currently on lane3
beq r2, et, GO_TO_LANE_2 # go to lane2
movi et, 0x03  # currently on lane4
beq r2, et, GO_TO_LANE_3 # go to lane3 
br EXIT_ISR

# chaging values of the flag for car 
GO_TO_LANE_1:
movi r2, 0x00
br EXIT_ISR

GO_TO_LANE_2:
movi r2, 0x01
br EXIT_ISR

GO_TO_LANE_3:
movi r2, 0x02
br EXIT_ISR

GO_TO_LANE_4:
movi r2, 0x03
br EXIT_ISR

HOME_TIME:
movi r4, 0x01 
EXIT_ISR:


CLEAR_FIFO:
ldwio et, 0(r6)
srli et, et, 16 # mask 
bne et, r0, CLEAR_FIFO # poll 


addi ea, ea, -4
eret 

.text
.global main
main:
  movia sp, INITIAL_STACK_POINTER
  movia r5, ADDR_VGA
  movia r6, ADDR_KEYBOARD
  movia r7, ADDR_TIMER
  
  
  # initializing Keyboard
  movi r8, 0x01 
  stwio r8, 4(r6) 

  
  # enable the control registers for the interrupts 
  movi r8, 0b10000000 # ienable (IRQ7) 
  wrctl ctl3, r8 

  movi r8, 0x01
  wrctl ctl0, r8  # set PIE bit to 1
  
  movi r3, 0x0 # initialize counter 
  movi r4, 0x0 # initialize flag for game states 
  
  movia r12, main_menu
  call DRAW_FULL
  
  WAIT_FOR_START:
  beq r4, r0, WAIT_FOR_START

  /********************** WAIT FOR USER TO START ***********************/
  
  BEGIN_GAME:

  movi r2, 0x00 # car flag 
  movi r9, 0x00 # initialize r9 (used for x off set for obstacle every redraw ) -> for animation 
  movi r10, 0x00 # lane flag for obstacle 
  movi r11, 0x01  # obstacle can change lane 
  movi r22, 0x00  # initialize score 

	
  RUN_GAME:
  
  addi r3, r3, 3 # add 3 to counter every time 
   
  CHECK_COLLISION: # checking collision
  beq r15, r2, CHECK_COLLISION_NEXT
  br AFTER_COLLISION_CHECK
   
   CHECK_COLLISION_NEXT:
   movi r21, 360
   bge r9, r21, COLLISION
   br AFTER_COLLISION_CHECK
   
   COLLISION:
   movi r4, 3
   br AFTER_COLLISION_CHECK

   AFTER_COLLISION_CHECK:
   # AFTER CHECKING FOR COLLISION
   movi r8, 0x02 
   beq r4, r8, BEFORE_WIN
   movi r8, 0x03
   beq r4, r8, BEFORE_LOST

   
   
  # NO COLLISION ==> REDRAW
  call OBSTACLE_FLAG_HELP # deal with obstacle flags 
  addi r9, r9, 40 # obstacle off set each time (for animation purposes ) 
  
  movia r12, background
  call DRAW_FULL # redraw the back ground 
  call DRAW_CAR  # redraw the car 
  call DRAW_OBSTACLE # redraw the obstacle 

  call DISPLAY_SCORE # display score on HEX display 
  
  #TIMER 
  call TIMER_HELP # count then redraw after 0.02s
  br RUN_GAME
  
  
  BEFORE_WIN:
  movi r15, 0
  movi r2, 0
	
  GAME_WIN:
  movia r12, game_win
  call DRAW_FULL # but with a different picture, probably change r12 before calling the function 
  movi r8, 0x01
  bne r4, r8, GAME_WIN 
  br BEGIN_GAME
  
  BEFORE_LOST:
  movi r15, 0
  movi r2, 0
  
  GAME_LOST:
  movia r12, game_over
  call DRAW_FULL # with a different picture
  movi r8, 0x01
  bne r4, r8, GAME_LOST 
  br BEGIN_GAME 
  
	
/****************** FLAG HELPER FUNCTION *************************************/
  OBSTACLE_FLAG_HELP:
  beq r9, r0, CAN_CHANGE_LANE # if the offset is 0 (meaning the obstacle hit the end of the screen) 
  movi r11, 0x00 # 0 == can't draw obstacle on a different lane 
  br RETURN_DIR
  
  CAN_CHANGE_LANE:
  movi r11, 0x01 # 1 == can draw obstacle on a different lane 
  br RETURN_DIR
  
  RETURN_DIR:
  ret
  
	
/****************** TIMER FUNCTION *************************************/
TIMER_HELP:
  movi r8, %lo(ONE_SEC) # initialize the timer 
  stwio r8, 8(r7)
  movi r8, %hi(ONE_SEC)
  stwio r8, 12(r7)
  stwio r0, 0(r7)  # clear timer 
  movi r8, 0x04
  stwio r8, 4(r7) 

	
TIMER_HELPER:
  ldwio r8, 0(r7)
  andi r8, r8, 0x1
  beq r8, r0, TIMER_HELPER  # POLL FOR TIME OUT BIT == 1 
 
 
 ret 
	
/****************** 7-SEG FUNCTION *************************************/	
DISPLAY_SCORE:
	movia r8, ADDR_7SEGS_LOW
	
	
	movi r16, 0x00
	beq r22, r16, PRINT_0
	movi r16, 0x01
	beq r22, r16, PRINT_1
	movi r16, 0x02
	beq r22, r16, PRINT_2
	movi r16, 0x03
	beq r22, r16, PRINT_3
	movi r16, 0x04
	beq r22, r16, PRINT_4
	movi r16, 0x05
	beq r22, r16, PRINT_5
	movi r16, 0x06
	beq r22, r16, PRINT_6
	movi r16, 0x07
	beq r22, r16, PRINT_7
	movi r16, 0x08
	beq r22, r16, PRINT_8
	movi r16, 0x09
	beq r22, r16, PRINT_9
	movi r16, 0x0A
	beq r22, r16, PRINT_10
	movi r16, 0x0B
	beq r22, r16, PRINT_11
	movi r16, 0x0C
	beq r22, r16, PRINT_12
	movi r16, 0x0D
	beq r22, r16, PRINT_13
	movi r16, 0x0E
	beq r22, r16, PRINT_14
	movi r16, 0x0F
	beq r22, r16, PRINT_15
	movi r16, 0x010
	beq r22, r16, PRINT_16
	movi r16, 0x011
	beq r22, r16, PRINT_17
	movi r16, 0x012
	beq r22, r16, PRINT_18
	movi r16, 0x013
	beq r22, r16, PRINT_19
	movi r16, 0x014
	beq r22, r16, PRINT_20
	br GO_BACK
	
PRINT_0:
	movia r16, 0b00000000000000000011111100111111
br GO_BACK
PRINT_1:
	movia r16, 0b00000000000000000011111100000110
br GO_BACK
PRINT_2:
	movia r16, 0b00000000000000000011111101011011
br GO_BACK
PRINT_3:
	movia r16, 0b00000000000000000011111101001111
br GO_BACK
PRINT_4:
	movia r16, 0b00000000000000000011111101100110
br GO_BACK
PRINT_5:
	movia r16, 0b00000000000000000011111101101101
br GO_BACK
PRINT_6:
	movia r16, 0b00000000000000000011111101111101
br GO_BACK
PRINT_7:
	movia r16, 0b00000000000000000011111100100111
br GO_BACK
PRINT_8:
	movia r16, 0b00000000000000000011111101111111
br GO_BACK
PRINT_9:
	movia r16, 0b00000000000000000011111101101111
br GO_BACK
PRINT_10:
	movia r16, 0b00000000000000000000011000111111
br GO_BACK
PRINT_11:
	movia r16, 0b00000000000000000000011000000110
br GO_BACK
PRINT_12:
	movia r16, 0b00000000000000000000011001011011
br GO_BACK
PRINT_13:
	movia r16, 0b00000000000000000000011001001111
br GO_BACK
PRINT_14:
	movia r16, 0b00000000000000000000011001100110
br GO_BACK
PRINT_15:
	movia r16, 0b00000000000000000000011001101101
br GO_BACK
PRINT_16:
	movia r16, 0b00000000000000000000011001111101
br GO_BACK
PRINT_17:
	movia r16, 0b00000000000000000000011000100111
br GO_BACK
PRINT_18:
	movia r16, 0b00000000000000000000011001111111
br GO_BACK
PRINT_19:
	movia r16, 0b00000000000000000000011001101111
br GO_BACK
PRINT_20:
	movia r16, 0b00000000000000000101101100111111
	movi r4, 0x02 
br GO_BACK

	
GO_BACK:	
stwio r16, 0(r8) # write to the 7 seg display 
ret
  
/****************** FUNCTIONS FOR DRAWING TO VGA ****************/
# Main Menu
 DRAW_FULL:  # Draw images that occupy the whole screen (320*240)
 movia r5,ADDR_VGA
  addi sp, sp, -28	#Save registers in stack so they don't clobber
  stwio ra, 0(sp)
  stwio r19, 4(sp) 
  stwio r11, 8(sp) 
  stwio r13, 12(sp)  
  stwio r14, 16(sp)  
  stwio r17, 20(sp) 
  stwio r10, 24(sp)
  
  

  movia r11, 152978 
  add r12, r12, r11 #Since bmp stores data from bottom to top
  movi r13, 0	#Set flags and limits for drawing
  movi r14, 0
  movi r17, 240 #vertical limit (240 pixels)
  movi r19, 640 #horizontal limit (320 pixels * 2)
  
  X_LOOP:
  beq r13, r17, END_FULL #Return from subroutine when the picture has finished drawing
  beq r14, r19, Y_INC	#When one row has been draw, move down the next to the next row 
  ldhio r10, 0(r12)	
  sthio r10, 0(r5) 	#Load data from the bmp and store it in the pixel buffer
  addi r14, r14, 2	#Add 2 to horizontal flag
  addi r12, r12, 2	#Add 2 to the address in bmp
  addi r5, r5, 2	#Add 2 to the address in pixel buffer
  br X_LOOP		#Keep drawing pixels until one row has finished drawing
  
  Y_INC:
  subi r12, r12, 1280	#Move to the row above in the bmp
  addi r5, r5, 384	#Move to the next row in the pixel buffer
  addi r13, r13, 1	#Add 1 to the vertical flag
  movi r14, 0	
  br X_LOOP		#Go back to drawing row
  
END_FULL:
  ldwio ra, 0(sp)	#Restore register values
  ldwio r19, 4(sp) 
  ldwio r11, 8(sp) 
  ldwio r13, 12(sp)  
  ldwio r14, 16(sp)  
  ldwio r17, 20(sp)
  ldwio r10, 24(sp)  
  addi sp, sp, 28
  
ret

/****************************************************************/



#Car
DRAW_CAR:		# Draw car image (80*60)
  movia r5,ADDR_VGA

  addi sp, sp, -36  #Save registers in stack so they don't clobber
  stwio ra, 0(sp)
  stwio r12, 4(sp) 
  stwio r11, 8(sp) 
  stwio r13, 12(sp)  
  stwio r14, 16(sp)  
  stwio r17, 20(sp) 
  stwio r19, 24(sp)
  stwio r16, 28(sp)  
  stwio r10, 32(sp)
  
  
  movia r12, car
  movia r11, 7855
  
					#determine where the car should be drawn depending on
					#temporary flag r15
  # checking lane flags
  movi r14, 0x00
  beq r2, r14, LANE_1
  movi r14, 0x01
  beq r2, r14, LANE_2
  movi r14, 0x02
  beq r2, r14, LANE_3
  movi r14, 0x03
  beq r2, r14, LANE_4
  br CONTINUE
  
  LANE_1:
  movia r16, 2048
  br CONTINUE
  
  LANE_2:
  movia r16, 63488
  br CONTINUE
  
  LANE_3:
  movia r16, 124928
  br CONTINUE
  
  LANE_4:
  movia r16, 186368
  br CONTINUE
  
  
  CONTINUE:
  add r5, r5, r16
  add r12, r12, r11		#Since bmp stores data from bottom to top
  movi r13, 0     		#Set flags and limits for drawing
  movi r14, 0      
  movi r17, 50     #50 pixels high
  movi r19, 160    #80 pixels wide (80*2)
  
  CAR_X:
  beq r13, r17, END_CAR		#Return from subroutine when the picture has finished drawing
  beq r14, r19, CAR_INC_Y	#When one row has been draw, move down the next to the next row 
  ldhio r10, 0(r12)			
  sthio r10, 0(r5)			#Load data from the bmp and store it in the pixel buffer
  addi r14, r14, 2			#Add 2 to horizontal flag
  addi r12, r12, 2			#Add 2 to the address in bmp
  addi r5, r5, 2			#Add 2 to the address in pixel buffer
  br CAR_X					#Keep drawing pixels until one row has finished drawing
  
  CAR_INC_Y:
  subi r12, r12, 320	#Move to the row above in the bmp
  movi r14, 1024
  subi r14, r14, 160
  add r5, r5, r14	#Move to the next row in the pixel buffer
  addi r13, r13, 1	#Add 1 to the vertical flag
  movi r14, 0	
  br CAR_X			#Go back to drawing row
	
  END_CAR:
  ldwio ra, 0(sp)		#Restore register values
  ldwio r12, 4(sp) 
  ldwio r11, 8(sp) 
  ldwio r13, 12(sp)  
  ldwio r14, 16(sp)  
  ldwio r17, 20(sp) 
  ldwio r19, 24(sp)
  ldwio r16, 28(sp)  
  ldwio r10, 32(sp)
  addi sp, sp, 36
ret

/****************************************************************/

#Obstacle
DRAW_OBSTACLE:		#Draw obstacles (60*50)
  movia r5,ADDR_VGA

  addi sp, sp, -36
  stwio ra, 0(sp)			#Save registers in stack so they don't clobber
  stwio r12, 4(sp) 
  stwio r11, 8(sp) 
  stwio r13, 12(sp)  
  stwio r14, 16(sp)  
  stwio r17, 20(sp) 
  stwio r19, 24(sp) 
    stwio r16, 28(sp)  
	stwio r10, 32(sp)
  
  movia r12, obstacle
  movia r11, 5895
  ####
  movi r8, 0x00
  ldwio r14, 32(sp) # pre-call r10's value
  beq r14, r8, OBSTACLE_IN_LANE_1
  movi r8, 0x01
  beq r14, r8, OBSTACLE_IN_LANE_2
  movi r8, 0x02
  beq r14, r8, OBSTACLE_IN_LANE_3
  movi r8, 0x03
  beq r14, r8, OBSTACLE_IN_LANE_4
  br CONTINUE1

  
  OBSTACLE_IN_LANE_1:
  movi r14, 0x00
  stwio r14, 32(sp)
  movia r16, 2568		#Temporary obstacle position right most end of 2nd pixel row
  sub r16, r16, r9		#Set positions for obstacle depending on which lane it is in
movi r14, 520
  beq r9,  r14, RESET
  br CONTINUE1
  
  OBSTACLE_IN_LANE_2:
    movi r14, 0x01
  stwio r14, 32(sp)
  movia r16, 64008
    sub r16, r16, r9
  movi r14, 520
  beq r9,  r14, RESET
  br CONTINUE1		#(1024*2+520)  520 since (640-120 cuz picture is 60 pixels wide (60*2))
  
  OBSTACLE_IN_LANE_3:
    movi r14, 0x02
  stwio r14, 32(sp)
  movia r16, 125448
    sub r16, r16, r9
  movi r14, 520
  beq r9,  r14, RESET
  br CONTINUE1
  
  
  OBSTACLE_IN_LANE_4:
    movi r14, 0x03
  stwio r14, 32(sp)
  movia r16, 186888
    sub r16, r16, r9
  movi r14, 520
  beq r9,  r14, RESET
  br CONTINUE1
  
  
  #####
  
  RESET:
    addi r22, r22, 1 # score 
  
  andi r14, r3, 0b0011
  movi r8, 0x00
  beq r14, r8, SET_UP_OBSTACLE_IN_LANE_1
  movi r8, 0x01
  beq r14, r8, SET_UP_OBSTACLE_IN_LANE_2
  movi r8, 0x02
  beq r14, r8, SET_UP_OBSTACLE_IN_LANE_3
  movi r8, 0x03
  beq r14, r8, SET_UP_OBSTACLE_IN_LANE_4
  br CONTINUE1
  
  SET_UP_OBSTACLE_IN_LANE_1:
  movi r14, 0x00
  mov r15, r14
  stwio r14, 32(sp)
  movia r16, 2568
  movi r9, 0x00

  br CONTINUE1
  
  SET_UP_OBSTACLE_IN_LANE_2:
  movi r14, 0x01
  mov r15, r14
  stwio r14, 32(sp)
  movia r16, 64008
  movi r9, 0x00
  

	
  br CONTINUE1
  
  SET_UP_OBSTACLE_IN_LANE_3:
  movi r14, 0x02
  mov r15, r14
  stwio r14, 32(sp)
  movia r16, 125448
  movi r9, 0x00

	
  br CONTINUE1
  
  SET_UP_OBSTACLE_IN_LANE_4:
  movi r14, 0x03
  mov r15, r14
  stwio r14, 32(sp)
  movia r16, 186888
  movi r9, 0x00

	
  br CONTINUE1
  #####
  
  CONTINUE1:
  add r5, r5, r16
  add r12, r12, r11		#Since bmp stores data from bottom to top
  movi r13, 0     		#Set flags and limits for drawing
  movi r14, 0      
  movi r17, 50     		#50 pixels high
  movi r19, 120    		#60 pixels wide (60*2)
  
  OBSTACLE_X:
  beq r13, r17, END_OBSTACLE	#Return from subroutine when the picture has finished drawing
  beq r14, r19, OBSTACLE_INC_Y	#When one row has been draw, move down the next to the next row 
  ldhio r10, 0(r12)	
  sthio r10, 0(r5)				#Load data from the bmp and store it in the pixel buffer
  addi r14, r14, 2				#Add 2 to horizontal flag
  addi r12, r12, 2				#Add 2 to the address in bmp
  addi r5, r5, 2				#Add 2 to the address in pixel buffer
  br OBSTACLE_X					#Keep drawing pixels until one row has finished drawing
  
  OBSTACLE_INC_Y:
  subi r12, r12, 240			#Move to the row above in the bmp
  movi r14, 1024
  subi r14, r14, 120	
  add r5, r5, r14		#Move to the next row in the pixel buffer
  addi r13, r13, 1		#Add 1 to the vertical flag
  movi r14, 0
  br OBSTACLE_X			#Go back to drawing row
  
  END_OBSTACLE:
  ldwio ra, 0(sp)		#Restore register values
  ldwio r12, 4(sp) 
  ldwio r11, 8(sp) 
  ldwio r13, 12(sp)  
  ldwio r14, 16(sp)  
  ldwio r17, 20(sp) 
  ldwio r19, 24(sp) 
  ldwio r16, 28(sp)
  ldwio r10, 32(sp)
  addi sp, sp, 36
ret

/****************************************************************/


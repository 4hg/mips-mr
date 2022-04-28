.data
	.align 2
	magnitude: .word 6
	titleMessage: .asciiz "\nMind Reader Game\nAkhil, Manav, Luke, and Parth\n"
	promptUser: .asciiz "\nDoes your number exist in this card? (Y, N, y, n are valid answers): "
	newLine: .asciiz "\n"
	tab: .asciiz "\t"
	answerMessage: .asciiz "The number you thought of was "
	invalidInput: .asciiz "\nInvalid input, only valid input is Y, N, y, n: "
	card: .asciiz "\nCard #"
	restartMessage: .asciiz "\nDo you want to try again? (Y, N, y, n are valid answers): "

.text
main:	
	li $v0, 4
	la $a0, titleMessage #Print out the title message of the game and introducing the game
	syscall
	
	li $s0, 0
	lw  $s1, magnitude #Store the magnitude of the bit length in the register $s1
	
	
	li $s4, 1
	sllv $s4, $s4, $s1 # Register s4 will go through 1- the magnitude in s1
	
# While loop that iterates through every bit
while_loop:
	slt $t0, $s0, $s1
	addi $s0, $s0, 1
	bnez $t0, main_func
	j restart
	
main_func:
	li $a0, 0
	move $a1, $s1 # Move magnitude to register a1
	li $v0, 42
	syscall #Get random int range
	
	#Storing random integer in t1
	move $t1, $a0
		
	# Get 1 - the max magnitude in register s2
	li $s2, 1
	sllv $s2, $s2, $t1
		
	# Checking if the bit in s2 has already been used to print the card
	and $t0, $s2, $s3
	bnez $t0, main_func #Restart main function and get new integer if bit has already been used
		
	# Mark the bit as used
	or $s3, $s3, $s2
	
	# Print the corresponding number card
	move $a0, $s2
	move $a1, $s4
	jal card_printing
		
	# Prompt the user if their number was in the card
	li $v0, 4
	la $a0, promptUser
	syscall
		
	#Get the input of the user
	jal input
		
	# If the user responded with yes, restart the while loop
	beqz $v0, input_loop

	# Store the calculated user number
	or $s7, $s7, $s2
			
input_loop:
	# Print new line
	li $v0, 4
	la $a0, newLine
	syscall
		
	# Go back to the while loop and get the next number
	j while_loop
			
restart:
	# Print new line
	li $v0, 4
	la $a0, newLine
	syscall
	
	#Print the answer message	
	li $v0, 4
	la $a0, answerMessage
	syscall
		
	#Print the calculated user number (stored in register s7)
	li $v0, 1
	add $a0, $zero, $s7
	syscall
		
	#Print a new line
	li $v0, 4
	la $a0, newLine
	syscall
		
	# reset registers to 0
	li $t0, 0
	li $s0, 0
	li $s1, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0
	li $s5, 0
	li $s6, 0
	li $s7, 0
	
	# Ask the user if they want to restart the game
	li $v0, 4
	la $a0, restartMessage
	syscall

	# ask for the user for input
	jal input	
	bnez $v0, main #Restart the program if user input is yes

exit:
	#Exit the program
	li $v0,10
	syscall
	
input:
	#Shifting the stack back
	addi $sp, $sp, -4
	sw $ra, ($sp) #Get the return address to store
	
	#Read the character from the user
	li $v0, 12
	syscall
	
	# If user input is yes
	#Load the ascii value for Y
	li $t0, 89
	beq $v0, $t0, yes
	#Load the ascii value for y
	addi $t0, $t0, 32
	beq $v0, $t0, yes
	
	# If user input is no
	#Load the ascii value for N
	li $t0, 78
	beq $v0, $t0, no
	#Load the ascii value for n
	addi $t0, $t0, 32
	beq $v0, $t0, no
	
	# If user input is invalid, output error
	li $v0, 4
	la $a0, invalidInput
	syscall
		
	#Get input from user and increase the stack
	jal input
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
# If the user inputs yes
yes:
	li $v0, 1
	lw $ra, ($sp) #Load return address to stack pointer and increase stack
	addi $sp, $sp, 4
	jr $ra
	
# If the user inputs no
no:
	li $v0, 0
	lw $ra, ($sp) #Load return address to stack pointer and increase stack
	addi $sp, $sp, 4
	jr $ra
	
#Function used to print cards
card_printing:
	#Storing the register address
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	#Moving the values needed to the stack
	subi $sp, $sp, 32
	sw $s2, ($sp)
	sw $s4, 4($sp)
	sw $s5, 8($sp)
	sw $s6, 12($sp)
	sw $s7, 16($sp)
	sw $s1, 20($sp)
	sw $s0, 24($sp)
	sw $s7, 28($sp)
	
	#Get the card number
	move $a0, $s2
	jal find_card_number
	addi $s1, $v0, 1
	
	# Print the card
	li $v0, 4
	la $a0, card
	syscall
	
	#Print the card number
	li $v0, 1
	add $a0, $zero, $s1
	syscall
	
	#Print a new line
	li $v0, 4
	la $a0, newLine
	syscall
	
# Loop while the current index of printing numbers in the card is less than the maximum
while_loop_print:
	slt $t0, $s5, $s4
	bnez $t0, print
	j reload_stack
	
print:
	# Print the number if the bit of the number at that position is 1
	and $t1, $s5, $s2
	bne $t1, $s2, skip
	
	#Printing the number
	li $v0, 1
	add $a0, $zero, $s5
	syscall
		
	#Printing tab charcater
	li $v0, 4
	la $a0, tab
	syscall
		
	# Add one to the number counter of the line
	addi $s6, $s6, 1
		
	# if the number counter is equal to 8, then print new line and reset the counter
	slti $t1, $s6, 8
	bnez $t1, skip
		
	#Print a new line
	li $v0, 4
	la $a0, newLine
	syscall
		
	#Reset the counter
	li $s6, 0
	
skip:
	# Skip the number an go to the next number
	addi $s5, $s5, 1
	j while_loop_print
		
reload_stack:
	# Restart the stack
	lw $s2, ($sp)
	lw $s4, 4($sp)
	lw $s5, 8($sp)
	lw $s6, 12($sp)
	lw $s7, 16($sp)
	lw $s1, 20($sp)
	lw $s0, 24($sp)
	lw $s7, 28($sp)
	addi $sp, $sp, 32
		
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
find_card_number:
	#Storing the register address
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	li $v0, -1
	
loop:
	#Loop through every number until you find the number you are looking for
	beqz $a0, loop_exit
	addi $v0, $v0, 1
	srl $a0, $a0, 1
	j loop
			
loop_exit:
	#Getting the return address and exiting loop
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra 
addi r20, r0, 5 #set the value of the input
addi r4, r0, 5
subi r7, r0, 0 	#set the result to 0
ciclo: 
slei r5, r4, 1 
bnez r5, fine
subi r20,r4,1
jal ciclo
mul r6, r23, r4
slti r10, r4, 5
beqz r10,addio
jr r31	
fine: 	
addi r7, r0, 1
jr r31
addio:	
nop
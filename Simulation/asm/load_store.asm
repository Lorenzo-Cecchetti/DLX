addui r5,r0,2
addui r1, r0, 10
loop:
andi r2, r1, 1 
beqz r2,even
j odd
continue:
subui r1,r1,1
bnez r1,loop
j end
even:
sll r10,r1,r5
lw r3,0(r10)
sra r3,r3,r5
sw 0(r1),r3
j continue
odd:
sll r10,r1,r5
lbu r3,0(r10)
srl r3,r3,r5
sb 0(r1), r3
j continue
end: 
nop

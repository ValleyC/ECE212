/*Author - Lab Tech. Last edited on Jan 14, 2022 */
/*-----------------DO NOT MODIFY--------*/
.global TestAsmCall
.global printf
.global cr
.syntax unified

.text
TestAsmCall:
PUSH {lr}
/*--------------------------------------*/

/*-------Students write their code here ------------*/

.equ DataStart, 0x20001000
.equ ResultStart, 0x20003000

    LDR R0, =DataStart      @ R0 = pointer to input data
    LDR R1, =ResultStart    @ R1 = pointer to output data

Loop:
    LDR R2, [R0]            @ Load ASCII value from memory

    @ Check for Enter (0x0D) - exit condition
    CMP R2, #0x0D
    BEQ Done

    @ Check if 'A'-'Z' (0x41-0x5A) - uppercase
    CMP R2, #0x41
    BLO Invalid
    CMP R2, #0x5A
    BLS ToLower

    @ Check if 'a'-'z' (0x61-0x7A) - lowercase
    CMP R2, #0x61
    BLO Invalid
    CMP R2, #0x7A
    BLS ToUpper

    @ Otherwise invalid (greater than 'z')
    B Invalid

ToLower:
    ADD R2, R2, #0x20       @ Convert uppercase to lowercase
    B Store

ToUpper:
    SUB R2, R2, #0x20       @ Convert lowercase to uppercase
    B Store

Invalid:
    MOV R2, #0x2A           @ R2 = '*' (error code)

Store:
    STR R2, [R1]            @ Store result to output
    ADD R0, R0, #4          @ Next input address (+4 bytes)
    ADD R1, R1, #4          @ Next output address (+4 bytes)
    B Loop

Done:

/*-------Code ends here ---------------------*/

/*-----------------DO NOT MODIFY--------*/
POP {PC}

.data
/*--------------------------------------*/

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
.equ ResultStart, 0x20002000

    LDR R0, =DataStart      @ R0 = pointer to input data
    LDR R1, =ResultStart    @ R1 = pointer to output data

Loop:
    LDR R2, [R0]            @ Load ASCII value from memory

    @ Check for Enter (0x0D) - exit condition
    CMP R2, #0x0D
    BEQ Done

    @ Check if '0'-'9' (0x30-0x39)
    CMP R2, #0x30
    BLO Invalid
    CMP R2, #0x39
    BLS Digit

    @ Check if 'A'-'F' (0x41-0x46)
    CMP R2, #0x41
    BLO Invalid
    CMP R2, #0x46
    BLS UpperHex

    @ Check if 'a'-'f' (0x61-0x66)
    CMP R2, #0x61
    BLO Invalid
    CMP R2, #0x66
    BLS LowerHex

    @ Otherwise invalid (greater than 'f')
    B Invalid

Digit:
    SUB R2, R2, #0x30       @ Convert '0'-'9' to 0-9
    B Store

UpperHex:
    SUB R2, R2, #0x37       @ Convert 'A'-'F' to 10-15
    B Store

LowerHex:
    SUB R2, R2, #0x57       @ Convert 'a'-'f' to 10-15
    B Store

Invalid:
    MVN R2, #0              @ R2 = -1 (0xFFFFFFFF)

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

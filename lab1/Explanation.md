# Detailed Explanation of Part A Assembly Code

## Memory Layout Overview

Before diving into the code, let's understand how data is stored:

```
INPUT (0x20001000):                 OUTPUT (0x20002000):
Address      Value                  Address      Value
0x20001000   0x00000041 ('A')  -->  0x20002000   0x0000000A (10)
0x20001004   0x00000039 ('9')  -->  0x20002004   0x00000009 (9)
0x20001008   0x0000002B ('+')  -->  0x20002008   0xFFFFFFFF (-1)
0x2000100C   0x0000000D (Enter) --> Program exits
```

Each value takes 4 bytes (32 bits), even though ASCII only needs 1 byte.

---

## Section 1: Constants Definition

```assembly
.equ DataStart, 0x20001000
.equ ResultStart, 0x20002000
```

`.equ` creates named constants (like `#define` in C):
- `DataStart` = memory address where input ASCII characters are stored
- `ResultStart` = memory address where converted values will be stored

This makes code readable and easy to modify.

---

## Section 2: Initialize Pointers

```assembly
    LDR R0, =DataStart      @ R0 = pointer to input data
    LDR R1, =ResultStart    @ R1 = pointer to output data
```

| Register | Purpose | Initial Value |
|----------|---------|---------------|
| R0 | Points to current input location | 0x20001000 |
| R1 | Points to current output location | 0x20002000 |
| R2 | Holds the data we're working with | (loaded in loop) |

`LDR Rx, =value` loads a 32-bit address into a register.

The `@` symbol starts a comment (like `//` in C).

---

## Section 3: Main Loop Start

```assembly
Loop:
    LDR R2, [R0]            @ Load ASCII value from memory
```

`Loop:` is a label (a named location we can jump back to).

`LDR R2, [R0]` means:
- Go to the memory address stored in R0
- Read the 32-bit value there
- Put it into R2

Example: If R0 = 0x20001000 and memory at that address contains 0x00000041, then R2 becomes 0x00000041.

---

## Section 4: Check for Exit Condition

```assembly
    @ Check for Enter (0x0D) - exit condition
    CMP R2, #0x0D
    BEQ Done
```

`CMP R2, #0x0D` compares R2 with 0x0D (carriage return/Enter):
- Internally calculates R2 - 0x0D
- Sets CPU flags based on result (doesn't change R2)

`BEQ Done` means "Branch if Equal":
- If R2 == 0x0D, jump to the `Done` label
- If not equal, continue to next instruction

---

## Section 5: Check for Digits '0'-'9'

```assembly
    @ Check if '0'-'9' (0x30-0x39)
    CMP R2, #0x30
    BLO Invalid
    CMP R2, #0x39
    BLS Digit
```

ASCII values for digits:
| Character | ASCII Hex | ASCII Decimal |
|-----------|-----------|---------------|
| '0' | 0x30 | 48 |
| '9' | 0x39 | 57 |

The logic:

```
CMP R2, #0x30       @ Compare with '0'
BLO Invalid         @ If R2 < 0x30, it's invalid (Branch if LOwer)

CMP R2, #0x39       @ Compare with '9'  
BLS Digit           @ If R2 <= 0x39, it's a digit (Branch if Lower or Same)
```

If R2 is between 0x30 and 0x39 (inclusive), we know it's a digit.

---

## Section 6: Check for Uppercase Hex 'A'-'F'

```assembly
    @ Check if 'A'-'F' (0x41-0x46)
    CMP R2, #0x41
    BLO Invalid
    CMP R2, #0x46
    BLS UpperHex
```

ASCII values for uppercase hex letters:
| Character | ASCII Hex | Decimal Equivalent |
|-----------|-----------|-------------------|
| 'A' | 0x41 | 10 |
| 'F' | 0x46 | 15 |

If we reach this point, R2 is already > 0x39.

If R2 < 0x41, it's in the gap between '9' and 'A' (characters like ':', ';', '<', etc.) → invalid.

If R2 <= 0x46, it's 'A' through 'F' → valid uppercase hex.

---

## Section 7: Check for Lowercase Hex 'a'-'f'

```assembly
    @ Check if 'a'-'f' (0x61-0x66)
    CMP R2, #0x61
    BLO Invalid
    CMP R2, #0x66
    BLS LowerHex
    
    @ Otherwise invalid (greater than 'f')
    B Invalid
```

ASCII values for lowercase hex letters:
| Character | ASCII Hex | Decimal Equivalent |
|-----------|-----------|-------------------|
| 'a' | 0x61 | 10 |
| 'f' | 0x66 | 15 |

Same logic as uppercase. If R2 > 0x66, it falls through to `B Invalid`.

`B Invalid` is an unconditional branch (always jumps).

---

## Section 8: Conversion - Digits

```assembly
Digit:
    SUB R2, R2, #0x30       @ Convert '0'-'9' to 0-9
    B Store
```

To convert ASCII digit to its numeric value, subtract 0x30:

| ASCII Char | ASCII Value | - 0x30 | Result |
|------------|-------------|--------|--------|
| '0' | 0x30 | 0x30 - 0x30 | 0 |
| '5' | 0x35 | 0x35 - 0x30 | 5 |
| '9' | 0x39 | 0x39 - 0x30 | 9 |

`B Store` jumps to Store (skipping other conversion code).

---

## Section 9: Conversion - Uppercase Hex

```assembly
UpperHex:
    SUB R2, R2, #0x37       @ Convert 'A'-'F' to 10-15
    B Store
```

Why subtract 0x37?

| ASCII Char | ASCII Value | Desired Result | Calculation |
|------------|-------------|----------------|-------------|
| 'A' | 0x41 | 10 (0x0A) | 0x41 - 0x37 = 0x0A |
| 'B' | 0x42 | 11 (0x0B) | 0x42 - 0x37 = 0x0B |
| 'F' | 0x46 | 15 (0x0F) | 0x46 - 0x37 = 0x0F |

We need 'A' (0x41) to become 10. So: 0x41 - X = 10 → X = 0x41 - 0x0A = 0x37

---

## Section 10: Conversion - Lowercase Hex

```assembly
LowerHex:
    SUB R2, R2, #0x57       @ Convert 'a'-'f' to 10-15
    B Store
```

Why subtract 0x57?

| ASCII Char | ASCII Value | Desired Result | Calculation |
|------------|-------------|----------------|-------------|
| 'a' | 0x61 | 10 (0x0A) | 0x61 - 0x57 = 0x0A |
| 'b' | 0x62 | 11 (0x0B) | 0x62 - 0x57 = 0x0B |
| 'f' | 0x66 | 15 (0x0F) | 0x66 - 0x57 = 0x0F |

We need 'a' (0x61) to become 10. So: 0x61 - X = 10 → X = 0x61 - 0x0A = 0x57

---

## Section 11: Invalid Character Handling

```assembly
Invalid:
    MVN R2, #0              @ R2 = -1 (0xFFFFFFFF)
```

`MVN` means "Move NOT" (bitwise NOT):
- `MVN R2, #0` calculates NOT(0) = 0xFFFFFFFF
- In two's complement, 0xFFFFFFFF represents -1

This is the error code specified in the lab.

---

## Section 12: Store Result and Advance

```assembly
Store:
    STR R2, [R1]            @ Store result to output
    ADD R0, R0, #4          @ Next input address (+4 bytes)
    ADD R1, R1, #4          @ Next output address (+4 bytes)
    B Loop
```

`STR R2, [R1]` means:
- Take the value in R2
- Store it at the memory address in R1

`ADD R0, R0, #4` advances the input pointer by 4 bytes (one word).

`ADD R1, R1, #4` advances the output pointer by 4 bytes.

`B Loop` jumps back to process the next character.

---

## Section 13: Exit

```assembly
Done:
```

This is just a label. When we branch here, execution continues to `POP {PC}` which returns from the function.

---

## Complete Program Flow Diagram

```
        ┌─────────────────────────┐
        │   Initialize R0, R1    │
        └───────────┬─────────────┘
                    ▼
        ┌─────────────────────────┐
        │  Loop: Load R2 from    │◄─────────────┐
        │        memory [R0]     │              │
        └───────────┬─────────────┘              │
                    ▼                            │
        ┌─────────────────────────┐              │
        │   R2 == 0x0D (Enter)?  │──Yes──► Done │
        └───────────┬─────────────┘              │
                    │ No                         │
                    ▼                            │
        ┌─────────────────────────┐              │
        │   Is R2 a digit?       │──Yes──► Digit│
        │   (0x30-0x39)          │         SUB  │
        └───────────┬─────────────┘           │  │
                    │ No                      │  │
                    ▼                         │  │
        ┌─────────────────────────┐           │  │
        │   Is R2 uppercase hex? │──Yes──►Upper│  │
        │   (0x41-0x46)          │         SUB │  │
        └───────────┬─────────────┘           │  │
                    │ No                      │  │
                    ▼                         │  │
        ┌─────────────────────────┐           │  │
        │   Is R2 lowercase hex? │──Yes──►Lower│  │
        │   (0x61-0x66)          │         SUB │  │
        └───────────┬─────────────┘           │  │
                    │ No                      ▼  │
                    ▼                   ┌────────┤
        ┌─────────────────────────┐     │ Store: │
        │   Invalid: R2 = -1     │─────►│ STR R2 │
        └─────────────────────────┘     │ ADD R0 │
                                        │ ADD R1 │
                                        └────┬───┘
                                             │
                                             └────────┘
```

---

## Key ARM Instructions Summary

| Instruction | Meaning | Example |
|-------------|---------|---------|
| LDR Rx, =val | Load address into Rx | LDR R0, =0x20001000 |
| LDR Rx, [Ry] | Load from memory address in Ry | LDR R2, [R0] |
| STR Rx, [Ry] | Store Rx to memory address in Ry | STR R2, [R1] |
| CMP Rx, #val | Compare Rx with value | CMP R2, #0x30 |
| BEQ label | Branch if equal | BEQ Done |
| BLO label | Branch if lower (unsigned) | BLO Invalid |
| BLS label | Branch if lower or same | BLS Digit |
| B label | Unconditional branch | B Loop |
| SUB Rx, Rx, #val | Subtract value from Rx | SUB R2, R2, #0x30 |
| ADD Rx, Rx, #val | Add value to Rx | ADD R0, R0, #4 |
| MVN Rx, #val | Move NOT (bitwise inverse) | MVN R2, #0 |

---

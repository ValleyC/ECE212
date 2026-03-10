# ECE212 Lab 3 — Subroutines & Bubble Sort: TA Notes

---

## Table of Contents

1. [Big Picture](#big-picture)
2. [Helper Subroutines Cheat Sheet](#helper-subroutines-cheat-sheet)
3. [Calling Code Analysis (Lab3_L432KC.s)](#calling-code-analysis)
4. [Part A — Welcomeprompt](#part-a--welcomeprompt)
5. [Part B — Sort](#part-b--sort)
6. [Part C — Display](#part-c--display)
7. [Test Program Analysis](#test-program-analysis)
8. [Common Mistakes & What to Watch For](#common-mistakes--what-to-watch-for)
9. [Demo Checklist](#demo-checklist)

---

## Big Picture

Lab 3 is about **subroutines** and the **stack**. Students write three separate `.s` files that are called by an unmodifiable main program (`Lab3_L432KC.s`). The three subroutines work together to:

1. **Part A (Welcomeprompt)** — Collect user input: number of entries, lower/upper limits, and the actual numbers. Store them in memory. Pass the count (N.E.) back via the stack.
2. **Part B (Sort)** — Bubble sort the numbers in memory (smallest to largest).
3. **Part C (Display)** — Print the sorted numbers to the terminal.

### Key Concepts

| Concept | What Students Must Know |
|---------|------------------------|
| `BL` / `BX lr` | `BL label` saves return address in LR (r14), jumps to label. `BX lr` returns. |
| `PUSH` / `POP` | PUSH decrements SP then stores. POP loads then increments SP. LIFO order. |
| Callee preservation | The **callee** (subroutine) must save and restore ALL registers it uses. |
| r0-r3 are volatile | Every call to `printf`, `cr`, `value`, `getstring` **destroys r0-r3**. |
| Stack parameter passing | Data is passed between subroutines via the stack (not registers). |
| `POP {PC}` | Equivalent to `POP {lr}` + `BX lr` — pops the saved return address directly into the program counter. |

### Program Flow Diagram

```
Lab3_L432KC.s (main — DO NOT MODIFY)
│
├─ ldr r0, =0x20001000
├─ PUSH {0xFFFFFFFF}          ← flag on stack
├─ bl Welcomeprompt           ──→ Part A: collects input, replaces flag with N.E.
├─ POP {r4}                   ← r4 = N.E. now
│
├─ ldr r0, =0x20001000
├─ PUSH {r4}                  ← N.E. on stack
├─ bl Sort                    ──→ Part B: sorts data in memory
├─ POP {r4}                   ← r4 = N.E. (unchanged)
│
├─ PUSH {0x20001000}          ← memory address on stack
├─ PUSH {r4}                  ← N.E. on stack (on top)
├─ ldr r0, =0x20002000
├─ bl Display                 ──→ Part C: prints sorted numbers
├─ POP {r4}                   ← N.E.
└─ POP {r5}                   ← memory address
```

---

## Helper Subroutines Cheat Sheet

These are provided in `main_L432KC.c`. Students call them with `bl`.

| Subroutine | Entry (input) | Exit (output) | What it does | Clobbers |
|------------|---------------|---------------|--------------|----------|
| `printf` | r0 = address of string | — | Prints string to terminal (no newline) | r0-r3 |
| `cr` | — | — | Prints carriage return + line feed (newline) | r0-r3 |
| `value` | r0 = decimal number | — | Prints number as decimal (no newline) | r0-r3 |
| `getstring` | — | r0 = entered number | Reads a decimal number from keyboard | r0-r3 |

### Usage Pattern: Print a String

```arm
bl cr                   @ newline first (optional)
ldr r0, =MyString       @ load string address into r0
bl printf               @ print it
bl cr                   @ newline after
```

### Usage Pattern: Read a Number

```arm
bl getstring            @ waits for user input
mov r4, r0              @ IMMEDIATELY save result to r4-r7 (r0 will be clobbered)
```

### Usage Pattern: Print a Number

```arm
mov r0, r4              @ copy number into r0
bl value                @ prints the decimal value
bl cr                   @ newline after
```

> **Critical Rule**: r0-r3 are **destroyed** after every `bl printf/cr/value/getstring` call.
> Always move important values to r4-r7 immediately after `bl getstring`.
> Always reload r0 before `bl printf/value` if needed.

---

## Calling Code Analysis

### Full Annotated Code: `Lab3_L432KC.s`

```arm
TestAsmCall:
PUSH {lr}

@ ============ PART A ============
ldr r0, =0x20001000        @ r0 = base address where numbers will be stored
                            @ ** TAs WILL change this during demo **
ldr r4, =0xFFFFFFFF         @ r4 = placeholder flag
PUSH {r4}                   @ push flag onto stack
bl Welcomeprompt            @ call Part A
POP {r4}                    @ pop → r4 now has N.E. (Welcomeprompt replaced the flag)

@ ============ PART B ============
ldr r0, =0x20001000        @ r0 = base address (TAs will change this)
PUSH {r4}                   @ push N.E. onto stack
bl Sort                     @ call Part B
POP {r4}                    @ pop → r4 still has N.E. (Sort doesn't change it)

@ ============ PART C ============
ldr r5, =0x20001000        @ r5 = base address
PUSH {r5}                   @ push memory address onto stack (deeper)
PUSH {r4}                   @ push N.E. onto stack (on top)
ldr r0, =0x20002000        @ r0 = some buffer address (not the data address!)
bl Display                  @ call Part C
POP {r4}                    @ pop N.E.
POP {r5}                    @ pop memory address

POP {PC}                    @ return to C main
```

### What "TAs will change this during demo" Means

The TAs will modify the `ldr r0, =0x20001000` lines to a different address (e.g., `0x20003000`) to verify students didn't hardcode `0x20001000` inside their subroutines.

**If a student hardcodes**: Welcomeprompt stores data at 0x20001000, but Sort/Display get 0x20003000 from r0/stack → program crashes or displays garbage.

**Correct approach**: Students must save `r0` at the start of their subroutine and use it, never hardcode the address.

---

## Part A — Welcomeprompt

### Contract

| | Detail |
|---|--------|
| **Entry** | r0 = memory base address; Stack: `[0xFFFFFFFF]` (flag) on top |
| **Exit** | Stack: flag replaced with N.E.; Numbers stored at base address; All registers restored |
| **File** | `Lab3a_L432KC.s` |

### What It Must Do (Step by Step)

1. Print welcome message
2. Prompt for number of entries (validate: 3 ≤ N ≤ 10)
3. Prompt for lower limit, then upper limit (validate: lower < upper)
4. Prompt for each number (validate: lower ≤ number ≤ upper)
   - For the **last** number, print a different prompt ("Please enter the last number...")
5. Store each valid number to memory (base address from r0, each number = 1 word = 4 bytes)
6. Write N.E. to the stack flag position (replace 0xFFFFFFFF)
7. Restore all registers and return

### Stack Diagram — The Flag Replacement Mechanism

This is the trickiest concept in Lab 3. Let's trace it step by step.

**Step 1: Before `bl Welcomeprompt`** (in the caller)

```
            ┌─────────────────┐
  SP ──────>│   0xFFFFFFFF    │  ← flag pushed by caller
            ├─────────────────┤
            │      ...        │  ← other stuff below
            └─────────────────┘
```

**Step 2: Inside Welcomeprompt, after all PUSHes**

We push 9 registers: lr, r0, r1, r2, r3, r4, r5, r6, r7

```
            ┌─────────────────┐
  SP + 36 → │   0xFFFFFFFF    │  ← the flag (TARGET: we will overwrite this)
            ├─────────────────┤
  SP + 32 → │   lr (ret addr) │  ← saved by PUSH {lr}
            ├─────────────────┤
  SP + 28 → │   r0 (base addr)│  ← saved by PUSH {r0}
            ├─────────────────┤
  SP + 24 → │       r1        │
            ├─────────────────┤
  SP + 20 → │       r2        │
            ├─────────────────┤
  SP + 16 → │       r3        │
            ├─────────────────┤
  SP + 12 → │       r4        │
            ├─────────────────┤
  SP +  8 → │       r5        │
            ├─────────────────┤
  SP +  4 → │       r6        │
            ├─────────────────┤
  SP +  0 → │       r7        │  ← current SP points here
            └─────────────────┘
```

**Offset = 9 registers × 4 bytes = 36**

**Step 3: Replace the flag with N.E.**

```arm
str r4, [sp, #36]       @ write N.E. (in r4) to the flag's location
```

Now the stack looks the same except `SP + 36` contains N.E. instead of 0xFFFFFFFF.

**Step 4: POP everything and return**

```arm
POP {r7}  @ restores r7
POP {r6}  @ restores r6
...
POP {r0}  @ restores r0
POP {PC}  @ pops saved lr into PC → returns to caller
```

After all POPs, SP is back to pointing at the N.E. value:

```
            ┌─────────────────┐
  SP ──────>│     N.E.        │  ← was 0xFFFFFFFF, now holds the count
            ├─────────────────┤
            │      ...        │
            └─────────────────┘
```

**Step 5: Caller does `POP {r4}`**

```arm
POP {r4}                @ r4 = N.E. (5, for example)
```

The flag has been successfully replaced!

### Register Plan

| Register | Purpose | Notes |
|----------|---------|-------|
| r0 | Temp / parameter for helper calls | Clobbered by every bl call |
| r1-r3 | Unused (clobbered by helpers) | Don't store anything important here |
| r4 | Number of entries (N.E.) / later reused as countdown counter | Saved to stack flag before reuse |
| r5 | Memory base address | From r0 at entry |
| r6 | Lower limit | |
| r7 | Upper limit | |

### Solution Code

```arm
Welcomeprompt:
    @ ===== Callee Preservation: save lr and r0-r7 =====
    PUSH {lr}
    PUSH {r0}
    PUSH {r1}
    PUSH {r2}
    PUSH {r3}
    PUSH {r4}
    PUSH {r5}
    PUSH {r6}
    PUSH {r7}

    mov r5, r0              @ r5 = base memory address (from r0)
                            @   DO NOT hardcode 0x20001000!

    @ ===== Print Welcome Message =====
    bl cr
    ldr r0, =WelcomeMsg
    bl printf
    bl cr

    @ ===== Get Number of Entries (3 to 10) =====
GetEntries:
    ldr r0, =EntriesPrompt
    bl printf
    bl cr
    bl getstring            @ r0 = user input
    mov r4, r0              @ r4 = number of entries

    cmp r4, #3
    blt TooLow              @ if N.E. < 3: error
    cmp r4, #10
    bgt TooHigh             @ if N.E. > 10: error
    b GetLimits             @ valid → continue

TooLow:
    ldr r0, =TooLowMsg
    bl printf
    bl cr
    b GetEntries            @ re-prompt

TooHigh:
    ldr r0, =TooHighMsg
    bl printf
    bl cr
    b GetEntries            @ re-prompt

    @ ===== Get Lower and Upper Limits =====
GetLimits:
    ldr r0, =LowerPrompt
    bl printf
    bl cr
    bl getstring
    mov r6, r0              @ r6 = lower limit

    ldr r0, =UpperPrompt
    bl printf
    bl cr
    bl getstring
    mov r7, r0              @ r7 = upper limit

    cmp r6, r7
    bge LimitError          @ if lower >= upper: error
    b StartInput            @ valid → continue

LimitError:
    ldr r0, =LimitErrMsg
    bl printf
    bl cr
    b GetLimits             @ re-prompt both limits

    @ ===== Collect Numbers =====
StartInput:
    str r4, [sp, #36]       @ save N.E. to stack flag position
                            @   (replaces 0xFFFFFFFF with actual count)
    @ Now r4 is free to use as a countdown counter
    @ (N.E. is safely stored on the stack)

NumberLoop:
    cmp r4, #1
    beq LastNumber          @ last number → different prompt

    ldr r0, =NumberPrompt
    bl printf
    bl cr
    b GetNumber

LastNumber:
    ldr r0, =LastNumPrompt
    bl printf
    bl cr

GetNumber:
    bl getstring            @ r0 = user input
    cmp r0, r6              @ compare with lower limit
    blt RangeError
    cmp r0, r7              @ compare with upper limit
    bgt RangeError

    @ Valid number: store to memory and advance
    str r0, [r5], #4        @ store number, then r5 += 4 (post-increment)
    subs r4, #1             @ countdown--
    bne NumberLoop          @ if more numbers needed, loop
    b ExitA                 @ all done

RangeError:
    ldr r0, =RangeErrMsg
    bl printf
    bl cr
    b NumberLoop            @ re-prompt (counter not decremented)

    @ ===== Restore and Return =====
ExitA:
    POP {r7}
    POP {r6}
    POP {r5}
    POP {r4}
    POP {r3}
    POP {r2}
    POP {r1}
    POP {r0}
    POP {PC}                @ return to caller

.data
WelcomeMsg:
.string "Welcome to ECE212 Bubble Sorting Program"
EntriesPrompt:
.string "Please enter the number(3min-10max) of enteries followed by 'enter'"
TooLowMsg:
.string "Invalid entry, Please enter more than 2 entry"
TooHighMsg:
.string "Invalid entry, Please enter less than 11 entry"
LowerPrompt:
.string "Please enter the lower limit"
UpperPrompt:
.string "Please enter the upper limit"
LimitErrMsg:
.string "Error. Please enter the lower and upper limit again"
NumberPrompt:
.string "Please enter a number followed by 'enter'"
LastNumPrompt:
.string "Please enter the last number followed by 'enter'"
RangeErrMsg:
.string "Invalid!!! Number entered is not within the range"
```

### Walkthrough: Example Run with 5 Entries

User input shown in **bold**.

```
Welcome to ECE212 Bubble Sorting Program
Please enter the number(3min-10max) of enteries followed by 'enter'
**-1**
Invalid entry, Please enter more than 2 entry
Please enter the number(3min-10max) of enteries followed by 'enter'
**11**
Invalid entry, Please enter less than 11 entry
Please enter the number(3min-10max) of enteries followed by 'enter'
**5**                                          ← r4 = 5 (valid)
Please enter the lower limit
**10**
Please enter the upper limit
**0**
Error. Please enter the lower and upper limit again
Please enter the lower limit
**0**                                          ← r6 = 0
Please enter the upper limit
**10**                                         ← r7 = 10, and 0 < 10 ✓
Please enter a number followed by 'enter'     ← r4=5, not last
**-1**
Invalid!!! Number entered is not within the range
Please enter a number followed by 'enter'     ← r4 still 5
**9**                                          ← stored at [r5+0], r5+=4, r4=4
Please enter a number followed by 'enter'     ← r4=4, not last
**7**                                          ← stored at [r5+4], r5+=4, r4=3
Please enter a number followed by 'enter'     ← r4=3, not last
**5**                                          ← stored at [r5+8], r5+=4, r4=2
Please enter a number followed by 'enter'     ← r4=2, not last
**3**                                          ← stored at [r5+12], r5+=4, r4=1
Please enter the last number followed by 'enter'  ← r4=1, IS last
**1**                                          ← stored at [r5+16], r5+=4, r4=0 → exit
```

Memory after Part A (assuming base = 0x20001000):

```
0x20001000: 9
0x20001004: 7
0x20001008: 5
0x2000100C: 3
0x20001010: 1
```

Stack: N.E. = 5 (replaced the 0xFFFFFFFF flag).

---

## Part B — Sort

### Contract

| | Detail |
|---|--------|
| **Entry** | r0 = memory base address; Stack: `[N.E.]` on top |
| **Exit** | Stack: `[N.E.]` unchanged; Memory sorted smallest→largest; All registers restored |
| **File** | `Lab3b_L432KC.s` |

### Bubble Sort Algorithm

Bubble sort uses two nested loops:

- **Outer loop**: runs N times (one full pass per iteration)
- **Inner loop**: runs N-1 times per pass (compares adjacent pairs)

Each inner iteration: if `array[j] > array[j+1]`, swap them.

After each full pass, the largest unsorted element "bubbles" to the end.

### Visual Example (N=6)

```
Pass 1:  [5, 23, 7, 17, 200, 1]
          5<23 ok  23>7 swap  23>17 swap  23<200 ok  200>1 swap
          [5, 7, 17, 23, 1, 200]    ← 200 is now at the end

Pass 2:  [5, 7, 17, 23, 1, 200]
          5<7 ok  7<17 ok  17<23 ok  23>1 swap
          [5, 7, 17, 1, 23, 200]

Pass 3:  [5, 7, 17, 1, 23, 200]
          5<7 ok  7<17 ok  17>1 swap
          [5, 7, 1, 17, 23, 200]

... continues until sorted:
          [1, 5, 7, 17, 23, 200]
```

### Stack Diagram

Part B reads N.E. from the stack but does NOT modify it.

```
Before Sort's PUSHes:                 After Sort's PUSHes (9 registers):

  SP ──→ [N.E.]                         SP + 36 → [N.E.]      ← ldr r4, [sp, #36]
         [...]                          SP + 32 → [lr]
                                        SP + 28 → [r0]
                                        ...
                                        SP +  0 → [r7]
```

Sort only needs to **read** N.E. — no need to write back since it doesn't change.

### Register Plan

| Register | Purpose |
|----------|---------|
| r0, r1 | Current pair: array[j] and array[j+1] |
| r2 | (unused) |
| r3 | Pointer into array (current position) |
| r4 | N.E. (loaded from stack) |
| r5 | Base memory address (from r0) |
| r6 | Outer loop counter (counts down from N) |
| r7 | Inner loop counter (counts up from 1 to N-1) |

### Solution Code

```arm
Sort:
    @ ===== Callee Preservation =====
    PUSH {lr}
    PUSH {r0}
    PUSH {r1}
    PUSH {r2}
    PUSH {r3}
    PUSH {r4}
    PUSH {r5}
    PUSH {r6}
    PUSH {r7}

    mov r5, r0              @ r5 = base memory address
    ldr r4, [sp, #36]       @ r4 = N.E. from stack

    @ ===== Bubble Sort =====
    mov r6, r4              @ r6 = outer counter (N iterations)

OuterLoop:
    mov r7, #1              @ r7 = inner counter (starts at 1)
    mov r3, r5              @ r3 = pointer to current element (reset to base)

InnerLoop:
    ldr r0, [r3]            @ r0 = array[j]
    ldr r1, [r3, #4]        @ r1 = array[j+1]
    cmp r0, r1              @ compare current pair (signed)
    ble NoSwap              @ if array[j] <= array[j+1], no swap needed

    @ --- Swap ---
    str r1, [r3]            @ array[j] = array[j+1]
    str r0, [r3, #4]        @ array[j+1] = array[j]

NoSwap:
    add r3, #4              @ advance pointer to next pair
    add r7, #1              @ inner counter++
    cmp r7, r4              @ compare with N (we want N-1 comparisons)
    blt InnerLoop           @ if inner < N, continue inner loop

    subs r6, #1             @ outer counter--
    bgt OuterLoop           @ if outer > 0, continue outer loop

    @ ===== Restore and Return =====
    POP {r7}
    POP {r6}
    POP {r5}
    POP {r4}
    POP {r3}
    POP {r2}
    POP {r1}
    POP {r0}
    POP {PC}
```

### Why `ble` (Signed) and Not `bls` (Unsigned)?

The lab accepts negative numbers (getstring handles "all numbers, negative and positive"). So the comparison must be **signed**.

- `ble` = Branch if Less than or Equal (signed: checks Z=1 or N≠V)
- `bls` = Branch if Lower or Same (unsigned: checks C=0 or Z=1)

Example: comparing -5 and 3
- Signed: -5 < 3 → no swap (correct for ascending sort)
- Unsigned: -5 = 0xFFFFFFFB > 3 = 0x00000003 → WOULD swap (wrong!)

### Trace: Sort with Data [9, 7, 5, 3, 1]

```
Initial: [9, 7, 5, 3, 1]

Outer=5, Inner pass:
  9>7 swap → [7, 9, 5, 3, 1]
  9>5 swap → [7, 5, 9, 3, 1]
  9>3 swap → [7, 5, 3, 9, 1]
  9>1 swap → [7, 5, 3, 1, 9]

Outer=4, Inner pass:
  7>5 swap → [5, 7, 3, 1, 9]
  7>3 swap → [5, 3, 7, 1, 9]
  7>1 swap → [5, 3, 1, 7, 9]
  7<9 ok

Outer=3, Inner pass:
  5>3 swap → [3, 5, 1, 7, 9]
  5>1 swap → [3, 1, 5, 7, 9]
  5<7 ok
  7<9 ok

Outer=2, Inner pass:
  3>1 swap → [1, 3, 5, 7, 9]
  3<5 ok
  5<7 ok
  7<9 ok

Outer=1, Inner pass:
  1<3 ok  (no swaps needed)
  3<5 ok
  5<7 ok
  7<9 ok

Final: [1, 3, 5, 7, 9]  ✓
```

---

## Part C — Display

### Contract

| | Detail |
|---|--------|
| **Entry** | r0 = 0x20002000 (irrelevant buffer); Stack: `[N.E.]` on top, `[base addr]` below |
| **Exit** | Stack: **both** values must remain on stack; All registers restored |
| **File** | `Lab3c_L432KC.s` |

### Important: r0 is NOT the Data Address!

In the calling code:

```arm
ldr r5, =0x20001000
PUSH {r5}               @ push data address (deeper on stack)
PUSH {r4}               @ push N.E. (on top)
ldr r0, =0x20002000     @ r0 = some other address (NOT the data!)
bl Display
```

The data address (`0x20001000`) comes from the **stack**, not from r0. The test program's individual test (ChkSub3) doesn't even set r0 before calling Display. So **do not use r0 for the data address**.

### Stack Diagram

After Display's 9 PUSHes:

```
  SP + 40 → [0x20001000]   ← memory address (from caller's PUSH {r5})
  SP + 36 → [N.E.]         ← number of entries (from caller's PUSH {r4})
  SP + 32 → [lr]           ← return address
  SP + 28 → [r0]
  SP + 24 → [r1]
  SP + 20 → [r2]
  SP + 16 → [r3]
  SP + 12 → [r4]
  SP +  8 → [r5]
  SP +  4 → [r6]
  SP +  0 → [r7]           ← current SP
```

- `ldr r4, [sp, #36]` → reads N.E.
- `ldr r5, [sp, #40]` → reads memory base address

Both values stay on the stack (we only read them with `ldr`, never `POP`).

### Required Output

```
The numbers are sorted with bubblesort algorithm
The number of entries was 5
Sorted from smallest to biggest, the numbers are:
1
3
5
7
9
Program ended
```

### Register Plan

| Register | Purpose |
|----------|---------|
| r0 | Parameter for printf/value calls |
| r4 | N.E. (loaded from stack) |
| r5 | Memory base address (loaded from stack) |
| r6 | Byte offset into array (increments by 4) |
| r7 | Loop counter (counts down from N.E.) |

### Solution Code

```arm
Display:
    @ ===== Callee Preservation =====
    PUSH {lr}
    PUSH {r0}
    PUSH {r1}
    PUSH {r2}
    PUSH {r3}
    PUSH {r4}
    PUSH {r5}
    PUSH {r6}
    PUSH {r7}

    ldr r4, [sp, #36]       @ r4 = N.E. from stack
    ldr r5, [sp, #40]       @ r5 = memory base address from stack

    @ ===== Print Header =====
    bl cr
    ldr r0, =SortedMsg
    bl printf
    bl cr

    @ ===== Print Number of Entries =====
    ldr r0, =EntriesMsg
    bl printf
    mov r0, r4              @ r0 = N.E.
    bl value                @ print the number
    bl cr

    @ ===== Print Column Header =====
    ldr r0, =SortedHeader
    bl printf
    bl cr

    @ ===== Print Each Number =====
    mov r6, #0              @ r6 = byte offset (starts at 0)
    mov r7, r4              @ r7 = counter (counts down from N.E.)

PrintLoop:
    ldr r0, [r5, r6]       @ r0 = number at base + offset
    bl value                @ print it
    bl cr                   @ newline
    add r6, #4              @ advance to next word
    subs r7, #1             @ counter--
    bgt PrintLoop           @ if counter > 0, continue

    @ ===== Print End Message =====
    ldr r0, =EndMsg
    bl printf
    bl cr

    @ ===== Restore and Return =====
    POP {r7}
    POP {r6}
    POP {r5}
    POP {r4}
    POP {r3}
    POP {r2}
    POP {r1}
    POP {r0}
    POP {PC}

.data
SortedMsg:
.string "The numbers are sorted with bubblesort algorithm"
EntriesMsg:
.string "The number of entries was "
SortedHeader:
.string "Sorted from smallest to biggest, the numbers are:"
EndMsg:
.string "Program ended"
```

---

## Test Program Analysis

The test program (`Lab3TestProgram_L432KC/Lab3_L432KC.s`) provides a **menu-driven** interface to test each subroutine individually or all together.

### Menu Options

| Option | What it tests |
|--------|---------------|
| 1 | Welcomeprompt only |
| 2 | Sort only (using data from option 1) |
| 3 | Display only (using data from options 1+2) |
| 4 | All three in sequence |

### What the Test Program Checks

For **each** subroutine, the test program:

1. **Register Integrity**: Sets r4=0x44444444, r5=0x55555555, r6=0x66666666 before the call, then checks they're unchanged after. If any differ → prints `"Register not properly restored"`.

2. **Stack Integrity**: Saves SP before the call, then compares SP after. If different → prints `"Stack not properly restored"`.

3. **Functional Correctness**: For option 1, it prints the N.E. retrieved from the stack. For option 2, it prints the array before and after sorting.

### Test Code Walkthrough: ChkSub1 (Welcomeprompt)

```arm
ChkSub1:
    mov r4, sp              @ save current SP
    PUSH {r4}               @ push saved SP onto stack

    @ Set sentinel values in r4, r5, r6
    ldr r5, =#0x55555555
    ldr r6, =#0x66666666
    ldr r4, =#0x44444444

    @ ... print "Testing 1st subroutine" ...

    PUSH {r4}               @ push 0x44444444 as the flag (instead of 0xFFFFFFFF)
    ldr r0, =0x20001000
    bl Welcomeprompt        @ <-- student code runs here

    @ Check registers are preserved
    @ r4 should be 0x44444444, r5 should be 0x55555555, r6 should be 0x66666666
    @ If any mismatch → "Register not properly restored"

    POP {r6}                @ r6 = N.E. (Welcomeprompt replaced the flag)
    POP {r5}                @ r5 = saved SP
    cmp r5, sp              @ check stack is balanced
    @ If mismatch → "Stack not properly restored"

    @ Print "The Number of entries is " followed by r6
```

**Key insight**: The test uses `0x44444444` as the flag instead of `0xFFFFFFFF`. This proves the flag value doesn't matter — what matters is that Welcomeprompt overwrites whatever is at that stack position with N.E.

### Test Code: ChkSub2 (Sort)

- Prints array values before sort
- Calls Sort with sentinel registers (r4=0x44444444, r5=0x55555555, r6=0x66666666)
- Checks register and stack integrity after
- Prints array values after sort for visual verification

### Test Code: ChkSub3 (Display)

- Pushes `0x20001000` and N.E. onto stack
- Sets sentinel registers
- Calls Display (note: does NOT set r0 to 0x20002000)
- Checks register and stack integrity
- Verifies both stack values remain after Display returns

---

## Common Mistakes & What to Watch For

### 1. Hardcoding `0x20001000`

**Wrong:**
```arm
ldr r5, =0x20001000     @ hardcoded!
```

**Right:**
```arm
mov r5, r0              @ use the address passed in r0
```

The lecture slides show `.equ memstart, 0x20001000` — this is just for illustration. In the actual lab, TAs will change the address during the demo.

### 2. Forgetting to PUSH {lr}

Without saving the return address, the first `bl printf` or `bl cr` call **overwrites lr**, and `BX lr` will jump back to the wrong place (infinite loop or crash).

**Wrong:**
```arm
Welcomeprompt:
    bl cr                   @ this clobbers lr! Can never return properly.
    ...
    BX lr                   @ jumps to cr, not to the caller!
```

**Right:**
```arm
Welcomeprompt:
    PUSH {lr}               @ save return address first
    ...
    POP {PC}                @ return via saved lr
```

### 3. Using r0-r3 to Store Important Values

**Wrong:**
```arm
bl getstring
@ r0 = user input
bl cr                   @ CLOBBERS r0! User input is LOST.
cmp r0, #3              @ r0 is now garbage
```

**Right:**
```arm
bl getstring
mov r4, r0              @ save to r4 IMMEDIATELY
bl cr                   @ r0 clobbered, but r4 is safe
cmp r4, #3              @ use the saved copy
```

### 4. Wrong Stack Offset for `str`/`ldr`

The offset depends on **exactly how many registers were pushed**.

| Registers pushed | Offset to flag | Example |
|-----------------|----------------|---------|
| lr, r0-r7 (9) | #36 | `str r4, [sp, #36]` |
| lr, r4-r7 (5) | #20 | `str r4, [sp, #20]` |
| lr, r0-r11 (13) | #52 | `str r4, [sp, #52]` |

**Formula**: offset = (number of PUSHed registers) × 4

If a student pushes 8 registers and uses offset #36, they're writing to the wrong stack location. This corrupts either the saved lr or the flag, causing crashes.

### 5. POP Order Not Matching PUSH Order

The stack is LIFO. POP must be the **exact reverse** of PUSH.

**Wrong:**
```arm
PUSH {lr}
PUSH {r0}
PUSH {r4}
...
POP {r0}        @ WRONG: this pops r4's saved value into r0!
POP {r4}
POP {PC}
```

**Right:**
```arm
PUSH {lr}
PUSH {r0}
PUSH {r4}
...
POP {r4}        @ reverse order
POP {r0}
POP {PC}
```

### 6. Not Preserving ALL Used Registers

If the student uses r6 inside their subroutine but doesn't push/pop it, the test program will detect the modification and print "Register not properly restored".

### 7. Using Unsigned Branch in Sort

**Wrong:**
```arm
cmp r0, r1
bls NoSwap          @ unsigned: treats -1 as 0xFFFFFFFF (huge!)
```

**Right:**
```arm
cmp r0, r1
ble NoSwap          @ signed: treats -1 as -1 (correct)
```

### 8. Off-by-One in Bubble Sort

- Outer loop should run **N** times (not N-1)
- Inner loop should run **N-1** times (not N, which would read past the array)

If the inner loop runs N times, the last comparison reads `array[N]` which is beyond the data — could cause garbage comparisons or a hard fault.

### 9. Forgetting Post-Increment on Memory Store (Part A)

**Wrong:**
```arm
str r0, [r5]            @ stores to same address every time!
```

**Right:**
```arm
str r0, [r5], #4        @ stores, THEN adds 4 to r5 (post-increment)
```

Or equivalently:
```arm
str r0, [r5]
add r5, #4
```

### 10. Display: Using r0 Instead of Stack for Data Address

**Wrong:**
```arm
Display:
    mov r5, r0          @ r0 = 0x20002000, NOT the data address!
```

**Right:**
```arm
Display:
    PUSH {lr}
    ... push r0-r7 ...
    ldr r5, [sp, #40]   @ data address comes from the STACK
```

### 11. Display: Modifying Stack Values

Display must leave N.E. and the memory address on the stack. If a student POPs them inside Display, the caller's `POP {r4}` / `POP {r5}` will get wrong values.

**Right approach**: Use `ldr` with offset to READ from stack. Never POP the caller's values.

---

## Demo Checklist

### What TAs Test During Demo

#### Part A — Welcomeprompt
- [ ] Welcome message displayed
- [ ] Rejects N.E. < 3 with error message, re-prompts
- [ ] Rejects N.E. > 10 with error message, re-prompts
- [ ] Accepts N.E. = 3, 10, and values in between
- [ ] Prompts for lower and upper limits separately
- [ ] Rejects lower >= upper with error message, re-prompts both
- [ ] Rejects numbers outside [lower, upper] with error message, re-prompts
- [ ] Displays "last number" prompt for the final entry
- [ ] Stores numbers correctly at the memory address (verify in debugger)
- [ ] N.E. correctly passed back via stack

#### Part B — Sort
- [ ] Data sorted correctly (smallest at lowest address)
- [ ] Works with negative numbers
- [ ] Handles N.E. = 3 (minimum) and N.E. = 10 (maximum)

#### Part C — Display
- [ ] Prints number of entries
- [ ] Prints "sorted from smallest to biggest" header
- [ ] Prints all numbers in order
- [ ] Prints "Program ended"

#### General (All Parts)
- [ ] Registers preserved (test program checks r4, r5, r6)
- [ ] Stack properly restored (test program checks SP)
- [ ] Works when TAs change 0x20001000 to a different address
- [ ] Program runs correctly when "Test All" (option 4) is selected
- [ ] Program can run multiple times without issues (option 4 repeated)

### Address Change Test

During the demo, TAs change `0x20001000` to another address (e.g., `0x20003000`) in:
- `Lab3_L432KC.s` line 15 and line 20 (and line 24 for Display's push)

If the student hardcoded `0x20001000`, Part A will store data at the wrong address, and Parts B/C won't find the data.

### Edge Cases to Try

| Test | What It Checks |
|------|---------------|
| N.E. = 3 (minimum) | Boundary condition |
| N.E. = 10 (maximum) | Boundary condition |
| N.E. = 2 or 11 | Should be rejected |
| Lower = 5, Upper = 5 | Should be rejected (lower not strictly less than upper) |
| Lower = -10, Upper = 10 | Negative limits work |
| Enter -5 with limits [0, 10] | Should be rejected |
| All same numbers (e.g., 5,5,5) | Sort should handle (no swaps needed) |
| Already sorted input | Sort should work (no change) |
| Reverse sorted input | Sort must fully reverse |
| Negative numbers | Sort uses signed comparison |

---

## Quick Reference: Stack Offsets

Assuming the standard push pattern `PUSH {lr}, PUSH {r0} ... PUSH {r7}` (9 registers):

### Part A (Welcomeprompt)

```
[sp + 36] = 0xFFFFFFFF flag  →  write N.E. here with: str r4, [sp, #36]
```

### Part B (Sort)

```
[sp + 36] = N.E.  →  read with: ldr r4, [sp, #36]
```

### Part C (Display)

```
[sp + 36] = N.E.           →  read with: ldr r4, [sp, #36]
[sp + 40] = base address   →  read with: ldr r5, [sp, #40]
```

# ECE212 Lab 2 — Assembly Solutions & TA Notes

---

## Memory Layout (Opcode at `0x20001000`)

### Part A

```
0x20001000  [N]           ← size of arrays
0x20001004  [addr_arr1]   ← address of 1st array
0x20001008  [addr_arr2]   ← address of 2nd array
0x2000100C  [dest_part1]  ← dest: Register Indirect with Offset
0x20001010  [dest_part2]  ← dest: Indexed Register Indirect
0x20001014  [dest_part3]  ← dest: Post-increment Register Indirect
```

### Part B

```
0x20001000  [N]           ← number of data points
0x20001004  [addr_X]      ← address of X data
0x20001008  [addr_Y]      ← address of Y data
0x2000100C  [addr_temp]   ← temporary storage
0x20001010  [addr_final]  ← where to store final area
```

---

## Part A — Solution: `Lab2a_L432KC.s`

### Full file

```arm
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

    @ ==========================================================
    @  SETUP: Load all opcode parameters
    @ ==========================================================
    @
    @  Opcode block at 0x20001000 laid out as:
    @    [r0+0]  = N           (array size)
    @    [r0+4]  = addr arr1
    @    [r0+8]  = addr arr2
    @    [r0+12] = dest part1  (RI with Offset)
    @    [r0+16] = dest part2  (Indexed RI)
    @    [r0+20] = dest part3  (Post-increment RI)
    @
    ldr  r0, =0x20001000      @ r0 = base of opcode block
    ldr  r7, [r0]             @ r7 = N
    ldr  r1, [r0, #4]         @ r1 = base address of array 1
    ldr  r2, [r0, #8]         @ r2 = base address of array 2

    @ ==========================================================
    @  PART 1 — Register Indirect with Offset (first 3 only)
    @ ==========================================================
    @
    @  Addressing form:  LDR Rd, [Rn, #imm]
    @   - Effective addr = Rn + immediate
    @   - Rn is NOT modified
    @   - No loop: hardcoded offsets #0, #4, #8 for elements 0,1,2
    @
    ldr  r3, [r0, #12]        @ r3 = destination address (part 1)

    @ --- element 0 ---
    ldr  r5, [r1, #0]         @ r5 = arr1[0]   (base + 0)
    ldr  r6, [r2, #0]         @ r6 = arr2[0]   (base + 0)
    add  r5, r5, r6           @ r5 = arr1[0] + arr2[0]
    str  r5, [r3, #0]         @ dest[0] = sum

    @ --- element 1 ---
    ldr  r5, [r1, #4]         @ r5 = arr1[1]   (base + 4)
    ldr  r6, [r2, #4]         @ r6 = arr2[1]   (base + 4)
    add  r5, r5, r6
    str  r5, [r3, #4]         @ dest[1] = sum

    @ --- element 2 ---
    ldr  r5, [r1, #8]         @ r5 = arr1[2]   (base + 8)
    ldr  r6, [r2, #8]         @ r6 = arr2[2]   (base + 8)
    add  r5, r5, r6
    str  r5, [r3, #8]         @ dest[2] = sum

    @ ==========================================================
    @  PART 2 — Indexed Register Indirect (entire array)
    @ ==========================================================
    @
    @  Addressing form:  LDR Rd, [Rn, Rm]
    @   - Effective addr = Rn + Rm   (Rm is the index register)
    @   - Neither Rn nor Rm is auto-modified
    @   - r1,r2 stay as fixed base addresses throughout the loop
    @   - r9 is the index register: 0, 4, 8, 12, ...
    @
    ldr  r4, [r0, #16]        @ r4 = destination address (part 2)
    mov  r8, r7               @ r8 = loop counter = N
    mov  r9, #0               @ r9 = index register, starts at 0

Part2Loop:
    ldr  r5, [r1, r9]         @ r5 = arr1[index]  ← Indexed RI
    ldr  r6, [r2, r9]         @ r6 = arr2[index]  ← Indexed RI
    add  r5, r5, r6           @ sum
    str  r5, [r4, r9]         @ dest[index] = sum  ← Indexed RI
    add  r9, r9, #4           @ index += 4  (next word)
    sub  r8, r8, #1           @ counter--
    cmp  r8, #0
    bgt  Part2Loop

    @ ==========================================================
    @  PART 3 — Post-increment Register Indirect (entire array)
    @ ==========================================================
    @
    @  Addressing form:  LDR Rd, [Rn]  then  ADD Rn, #4
    @   - This simulates  LDR Rd, [Rn], #4  (post-increment)
    @   - Effective addr = Rn  (current value)
    @   - Then Rn is incremented: Rn = Rn + 4
    @   - The pointer itself walks forward each iteration
    @
    @  r1, r2 are still the original base addresses (Part 2
    @  never modified them), so we copy them to working pointers.
    @
    ldr  r3, [r0, #20]        @ r3 = destination address (part 3)
    mov  r4, r1               @ r4 = working ptr for arr1 (copy)
    mov  r5, r2               @ r5 = working ptr for arr2 (copy)
    mov  r8, r7               @ r8 = loop counter = N

Part3Loop:
    ldr  r6, [r4]             @ r6 = *ptr1        ← load
    add  r4, r4, #4           @ ptr1 += 4         ← post-increment
    ldr  r9, [r5]             @ r9 = *ptr2        ← load
    add  r5, r5, #4           @ ptr2 += 4         ← post-increment
    add  r6, r6, r9           @ r6 = sum
    str  r6, [r3]             @ *dest = sum       ← store
    add  r3, r3, #4           @ dest += 4         ← post-increment
    sub  r8, r8, #1           @ counter--
    cmp  r8, #0
    bgt  Part3Loop

/*-------Code ends here ---------------------*/

/*-----------------DO NOT MODIFY--------*/
POP {PC}

.data
/*--------------------------------------*/
```

### Register map

```
r0  = 0x20001000 (opcode base, set once, reused for all loads)
r1  = arr1 base address       ← stays constant across all 3 parts
r2  = arr2 base address       ← stays constant across all 3 parts
r3  = dest ptr (Part 1, Part 3)
r4  = dest ptr (Part 2) / arr1 working ptr (Part 3)
r5  = temp value / arr2 working ptr (Part 3)
r6  = temp value / sum
r7  = N  (array size, never modified)
r8  = loop counter            (high reg, Parts 2 & 3)
r9  = index register (Part 2) / temp (Part 3)   (high reg)
```

> **Critical design choice**: r1 and r2 are preserved through Part 2 because Indexed RI
> uses `[r1, r9]` — the base never changes. This lets Part 3 reuse them as starting
> points by copying to working pointers r4/r5.

### Key differences between the 3 parts at a glance

```
Part 1 (RI w/ Offset):   ldr r5, [r1, #0]     ← immediate offset, no loop
                          ldr r5, [r1, #4]
                          ldr r5, [r1, #8]

Part 2 (Indexed RI):     ldr r5, [r1, r9]     ← register index, loop
                          add r9, r9, #4       ← only index changes

Part 3 (Post-inc RI):    ldr r6, [r4]          ← plain load, loop
                          add r4, r4, #4        ← pointer itself changes
```

---

## Part A — Expected Results

### Default DataStorage (N=9)

```
arr1 = {1, 2, 3, 4, 5, 6, 7, 8, 9}
arr2 = {9, 8, 7, 6, 5, 4, 3, 2, 1}
sums = {10, 10, 10, 10, 10, 10, 10, 10, 10}

Part 1 → 10 10 10
Part 2 → 10 10 10 10 10 10 10 10 10
Part 3 → 10 10 10 10 10 10 10 10 10
```

### DataStorage1 (N=6)

```
arr1 = {0xA, 0xB, 0xC, 0xD, 0xE, 0xF}
arr2 = {0xF, 0xE, 0xD, 0xC, 0xB, 0xA}
sums = {25, 25, 25, 25, 25, 25}
```

### DataStorage2 (N=12) — primary demo test case

```
arr1 = {0x5A, 0x7B, 0x4C, 0x8D, 0x3E, 0x4F, 0xA5, 0xB6, 0xC4, 0xD3, 0xE4, 0xF7}
arr2 = {0x5F, 0x4E, 0x4D, 0x7C, 0x5B, 0x5A, 0xA5, 0xB4, 0xC3, 0xD4, 0xE4, 0xF2}
sums = {185, 201, 153, 265, 153, 169, 330, 362, 391, 423, 456, 489}

Part 1 → 185 201 153
Part 2 → 185 201 153 265 153 169 330 362 391 423 456 489
```

> Matches the screenshot on page 1 of the lab PDF.

### DataStorage3 (N=5, signed 32-bit values)

```
arr1 = {0xFFFFFF5A, 0x7B, 0xFFFFFF4C, 0x8D, 0xFFFFFF3E}  (-166, 123, -180, 141, -194)
arr2 = {0xFFFFFF5F, 0x4E, 0xFFFFFF4D, 0x7C, 0xFFFFFF5B}  (-161,  78, -179, 124, -165)
sums (signed) = {-327, 201, -359, 265, -359}
sums (hex)    = {0xFFFFFEB9, 0xC9, 0xFFFFFE99, 0x109, 0xFFFFFE99}
```

> ADD doesn't care about signedness — binary addition is the same. This test verifies that.

---

## Part B — Solution: `Lab2b_L432KC.s`

### Algorithm overview

```
Trapezoidal rule:
                    N-1
    Area = (1/2) *   Σ   dx_k * (y[k+1] + y[k])
                    k=0

    where dx_k = x[k+1] - x[k]  ∈ {1, 2, 4}

Implementation (Method 2 — accumulate then halve):
  1. For each trapezoid k = 0..N-2:
       term = (y[k+1] + y[k]) * dx_k     ← multiply via LSL
       accumulator += term
  2. result = accumulator / 2             ← divide via LSR
  3. if accumulator was odd, result += 1  ← round up
```

### Full file

```arm
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

    @ ==========================================================
    @  SETUP: Load opcode parameters
    @ ==========================================================
    @
    @  [r0+0]  = N            (number of data points)
    @  [r0+4]  = addr of X    (X data array)
    @  [r0+8]  = addr of Y    (Y data array)
    @  [r0+12] = addr temp    (scratch memory)
    @  [r0+16] = addr final   (store result here)
    @
    ldr  r0, =0x20001000
    ldr  r7, [r0]             @ r7 = N (number of data points)
    ldr  r1, [r0, #4]         @ r1 = pointer to X data
    ldr  r2, [r0, #8]         @ r2 = pointer to Y data
    ldr  r3, [r0, #12]        @ r3 = temp storage address
    ldr  r4, [r0, #16]        @ r4 = final value address

    @ --- Initialize accumulator at temp to 0 ---
    movs r5, #0
    str  r5, [r3]             @ *temp = 0

    @ --- Number of trapezoids = N - 1 ---
    sub  r7, r7, #1           @ r7 = loop counter

    @ ==========================================================
    @  MAIN LOOP — one iteration per trapezoid
    @ ==========================================================
    @
    @  For each pair (k, k+1):
    @    1. dx  = x[k+1] - x[k]          → r6
    @    2. sum = y[k]   + y[k+1]         → r5
    @    3. Multiply sum by dx via LSL    → r5
    @    4. Accumulate into temp memory
    @    5. Advance r1, r2 by 4
    @
TrapLoop:

    @ --- Step 1: compute dx ---
    ldr  r5, [r1]             @ r5 = x[k]
    ldr  r6, [r1, #4]         @ r6 = x[k+1]
    sub  r6, r6, r5           @ r6 = dx = x[k+1] - x[k]

    @ --- Step 2: compute y[k] + y[k+1] ---
    ldr  r5, [r2]             @ r5 = y[k]
    ldr  r8, [r2, #4]         @ r8 = y[k+1]
    add  r5, r5, r8           @ r5 = y[k] + y[k+1]

    @ --- Step 3: multiply sum_y by dx ---
    @
    @  dx is guaranteed to be 1, 2, or 4.
    @  MUL is forbidden — use LSL instead:
    @    dx=1 → no shift (×1)
    @    dx=2 → LSL #1   (×2)
    @    dx=4 → LSL #2   (×4)
    @
    cmp  r6, #1
    beq  MultDone             @ dx=1: r5 already correct
    cmp  r6, #2
    beq  MultBy2
    @ else dx=4
    lsl  r5, r5, #2           @ r5 = sum_y × 4
    b    MultDone
MultBy2:
    lsl  r5, r5, #1           @ r5 = sum_y × 2
MultDone:

    @ --- Step 4: accumulate ---
    ldr  r8, [r3]             @ r8 = running total (from temp)
    add  r8, r8, r5           @ r8 += dx * sum_y
    str  r8, [r3]             @ store back to temp

    @ --- Step 5: advance pointers ---
    add  r1, r1, #4           @ X ptr → next point
    add  r2, r2, #4           @ Y ptr → next point

    @ --- loop control ---
    subs r7, r7, #1           @ counter-- (sets flags)
    bgt  TrapLoop             @ if counter > 0, repeat

    @ ==========================================================
    @  FINALIZE — divide by 2 and round up
    @ ==========================================================
    @
    @  We accumulated  Σ dx*(y[k]+y[k+1])  which is 2× the area.
    @  Divide by 2 with LSR.  If the sum was odd (LSB=1),
    @  that means there's a 0.5 remainder — round up by adding 1.
    @
    ldr  r5, [r3]             @ r5 = raw accumulated total
    and  r6, r5, #1           @ r6 = r5 & 1  (0 or 1 = remainder)
    lsr  r5, r5, #1           @ r5 = total / 2  (truncated)
    add  r5, r5, r6           @ r5 += remainder  (round up if odd)

    @ --- Store final result ---
    str  r5, [r4]             @ *final = area

/*-------Code ends here ---------------------*/

/*-----------------DO NOT MODIFY--------*/
POP {PC}

.data
/*--------------------------------------*/
```

### Register map

```
r0  = 0x20001000 (opcode base, used only during setup)
r1  = X data pointer          ← advances +4 each iteration
r2  = Y data pointer          ← advances +4 each iteration
r3  = temp storage address    (accumulator lives in memory here)
r4  = final value address     (write result here at end)
r5  = multi-purpose temp      (x[k], sum_y, shifted product, final result)
r6  = dx / remainder
r7  = loop counter            (N-1, decrements to 0)
r8  = y[k+1] / running total (high register)
```

### Execution trace — DataStorage4 (first 3 iterations)

```
Setup: N=51 → counter=50, X@0x20002000, Y@0x20003000, temp@0x20004000
       *temp = 0

Iteration k=0:
  x[0]=0, x[1]=1   → dx=1
  y[0]=0, y[1]=1   → sum_y=1
  dx=1 → no shift  → product=1
  *temp = 0 + 1 = 1

Iteration k=1:
  x[1]=1, x[2]=2   → dx=1
  y[1]=1, y[2]=4   → sum_y=5
  dx=1 → no shift  → product=5
  *temp = 1 + 5 = 6

Iteration k=2:
  x[2]=2, x[3]=3   → dx=1
  y[2]=4, y[3]=9   → sum_y=13
  dx=1 → no shift  → product=13
  *temp = 6 + 13 = 19

  ...  (47 more iterations)

After loop: *temp = 83350
  83350 & 1 = 0  → no remainder
  83350 >> 1 = 41675
  Result = 41675  ✓
```

### Execution trace — DataStorage6 (first 3 iterations, showing varying dx)

```
Setup: N=51 → counter=50, X@0x20002000, Y@0x20003000

Iteration k=0:
  x[0]=0, x[1]=2   → dx=2
  y[0]=0, y[1]=4   → sum_y=4
  dx=2 → LSL #1    → product=8
  *temp = 0 + 8 = 8

Iteration k=1:
  x[1]=2, x[2]=3   → dx=1
  y[1]=4, y[2]=9   → sum_y=13
  dx=1 → no shift  → product=13
  *temp = 8 + 13 = 21

Iteration k=2:
  x[2]=3, x[3]=7   → dx=4
  y[2]=9, y[3]=49  → sum_y=58
  dx=4 → LSL #2    → product=232
  *temp = 21 + 232 = 253

  ...

After loop: *temp = 887686
  887686 & 1 = 0  → no remainder
  887686 >> 1 = 443843
  Result = 443843  ✓
```

---

## Part B — Expected Results

| Test Case | N | X range | dx | Raw sum | **Result** | Theoretical | Error |
|-----------|---|---------|-----|---------|------------|-------------|-------|
| DataStorage4 | 51 | 0–50 | 1 (constant) | 83,350 | **41,675** | 41,666.667 | 0.020% |
| DataStorage5 | 51 | 0–80 | {1,2} | 341,420 | **170,710** | 170,666.667 | 0.025% |
| DataStorage6 | 51 | 0–110 | {1,2,4} | 887,686 | **443,843** | 443,666.667 | 0.040% |

All test cases: **y = x²**, theoretical integral = x³/3.

---

## Common Mistakes to Watch For

### Part A

1. **Using a loop for Part 1** — should be 3 explicit LDR/ADD/STR blocks with `#0, #4, #8`
2. **Using `[r1, #imm]` instead of `[r1, r9]` for Part 2** — that's not Indexed RI, it's still RI with Offset
3. **Modifying r1/r2 in Part 2** — kills Part 3; Indexed RI must keep base addresses intact
4. **Incrementing by 1 instead of 4** — each word is 4 bytes
5. **Swapping Part 2 and Part 3 logic** — Part 2: base fixed + index moves; Part 3: pointer moves

### Part B

1. **Using MUL** — forbidden; must use LSL
2. **Assuming constant dx** — only works for DS4; DS5/DS6 have varying dx
3. **Loop runs N times instead of N-1** — N points = N-1 trapezoids
4. **Dividing by 2 inside the loop** — loses fractional precision each iteration
5. **Not rounding up** — if raw sum is odd, LSR truncates; must add 1
6. **LSR vs LSL confusion** — LSL multiplies (shift left), LSR divides (shift right)
7. **Only advancing Y pointer, forgetting X** — both must `add #4` each iteration

---

## Lab Report Questions — Quick Answers

**Q1: Advantages/limitations of each addressing mode?**

| Mode | Advantage | Limitation |
|------|-----------|------------|
| RI with Offset | Simple, one instruction, no extra register | Offset is fixed/immediate; limited range (0–4095) |
| Indexed RI | Flexible runtime index; base preserved for reuse | Needs an extra register for the index |
| Post-increment RI | Efficient sequential access; pointer auto-advances | Destroys original base address |

**Q2: Do addressing modes affect CCR/APSR flags?**

**No.** LDR/STR instructions do not modify N, Z, C, V flags. Only arithmetic instructions with `S` suffix (ADDS, SUBS) or CMP/TST modify flags.

**Q3: What is f(x)? Percent error?**

**f(x) = x²** for all three test cases. Errors: DS4 = 0.020%, DS5 = 0.025%, DS6 = 0.040%.

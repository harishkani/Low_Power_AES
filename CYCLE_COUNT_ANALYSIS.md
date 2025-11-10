# AES Core Clock Cycle Analysis

## Complete Cycle Count Breakdown

### ENCRYPTION PATH

#### 1. KEY_EXPAND State
```
Operation: Load all 44 round key words
- word_addr 0 → 43: 44 cycles (1 cycle per word)
Total: 44 cycles
```

#### 2. ROUND0 State (Initial AddRoundKey)
```
Operation: XOR state with first round key
- Column 0: 1 cycle
- Column 1: 1 cycle
- Column 2: 1 cycle
- Column 3: 1 cycle
Total: 4 cycles
```

#### 3. ROUNDS 1-10 (Main Encryption Rounds)

**Per Round:**
- **ENC_SUB state:**
  - SubBytes column 0: 1 cycle
  - SubBytes column 1: 1 cycle
  - SubBytes column 2: 1 cycle
  - SubBytes column 3: 1 cycle
  - Subtotal: 4 cycles

- **ENC_SHIFT_MIX state:**
  - ShiftRows + MixColumns (or skip MixColumns in round 10) + AddRoundKey column 0: 1 cycle
  - ShiftRows + MixColumns + AddRoundKey column 1: 1 cycle
  - ShiftRows + MixColumns + AddRoundKey column 2: 1 cycle
  - ShiftRows + MixColumns + AddRoundKey column 3: 1 cycle
  - Subtotal: 4 cycles

**Total per round: 4 + 4 = 8 cycles**

**All 10 rounds: 10 × 8 = 80 cycles**

#### 4. DONE State
```
Operation: Set ready flag and output result
Total: 1 cycle
```

### ENCRYPTION TOTAL: 44 + 4 + 80 + 1 = **129 cycles**

---

### DECRYPTION PATH

#### 1. KEY_EXPAND State
```
Same as encryption
Total: 44 cycles
```

#### 2. ROUND0 State
```
Same as encryption
Total: 4 cycles
```

#### 3. ROUNDS 1-10 (Main Decryption Rounds)

**Rounds 1-9 (per round):**

- **DEC_SHIFT_SUB state:**
  - Phase 0: Apply InvShiftRows to entire state: 1 cycle
  - Phase 1: InvSubBytes column by column:
    - Column 0: 1 cycle
    - Column 1: 1 cycle
    - Column 2: 1 cycle
    - Column 3: 1 cycle
  - Subtotal: 5 cycles

- **DEC_ADD_MIX state:**
  - Phase 0: AddRoundKey column by column:
    - Column 0: 1 cycle
    - Column 1: 1 cycle
    - Column 2: 1 cycle
    - Column 3: 1 cycle
  - Phase 1: InvMixColumns column by column:
    - Column 0: 1 cycle
    - Column 1: 1 cycle
    - Column 2: 1 cycle
    - Column 3: 1 cycle
  - Subtotal: 8 cycles

**Total per round (1-9): 5 + 8 = 13 cycles**

**Round 10 (Last Round - No InvMixColumns):**

- **DEC_SHIFT_SUB state:**
  - Same as rounds 1-9
  - Subtotal: 5 cycles

- **DEC_ADD_MIX state:**
  - Phase 0: AddRoundKey only (4 cycles)
  - Phase 1: SKIPPED (is_last_round = true, goes to DONE)
  - Subtotal: 4 cycles

**Total for round 10: 5 + 4 = 9 cycles**

**All rounds: (9 × 13) + 9 = 117 + 9 = 126 cycles**

#### 4. DONE State
```
Same as encryption
Total: 1 cycle
```

### DECRYPTION TOTAL: 44 + 4 + 126 + 1 = **175 cycles**

---

## Summary Table

| Operation | Encryption | Decryption | Difference |
|-----------|------------|------------|------------|
| Key Expansion | 44 cycles | 44 cycles | 0 |
| Round 0 (AddRoundKey) | 4 cycles | 4 cycles | 0 |
| Rounds 1-9 | 72 cycles (9×8) | 117 cycles (9×13) | +45 |
| Round 10 | 8 cycles | 9 cycles | +1 |
| Done | 1 cycle | 1 cycle | 0 |
| **TOTAL** | **129 cycles** | **175 cycles** | **+46 cycles** |

## Why Decryption Takes More Cycles?

### Encryption (8 cycles per round):
- SubBytes: 4 cycles (column-wise)
- ShiftRows + MixColumns + AddRoundKey: 4 cycles (combined, column-wise)

### Decryption (13 cycles per round):
- InvShiftRows: 1 cycle (entire state at once)
- InvSubBytes: 4 cycles (column-wise)
- AddRoundKey: 4 cycles (column-wise)
- InvMixColumns: 4 cycles (column-wise)

**Key Difference:**
- Encryption combines ShiftRows, MixColumns, and AddRoundKey in a single pass (4 cycles)
- Decryption requires separate phases: InvShiftRows (1), InvSubBytes (4), AddRoundKey (4), InvMixColumns (4)
- This architectural choice trades area efficiency for decryption performance

## Performance at Different Clock Frequencies

| Clock Frequency | Encryption Time | Decryption Time | Throughput (Enc) |
|-----------------|-----------------|-----------------|------------------|
| 100 MHz | 1.29 µs | 1.75 µs | 775,194 blocks/s |
| 150 MHz | 0.86 µs | 1.17 µs | 1,162,791 blocks/s |
| 200 MHz | 0.65 µs | 0.88 µs | 1,550,388 blocks/s |

## Data Rate Calculation (Encryption)

```
Clock: 100 MHz
Cycles: 129
Block size: 128 bits

Throughput = (100 × 10⁶ Hz) / 129 cycles = 775,194 blocks/second
Data rate = 775,194 × 128 bits = 99.2 Mbps
```

## Latency Breakdown (at 100 MHz)

### Encryption:
```
Key Expansion:  440 ns (34.1%)
Round 0:         40 ns (3.1%)
Rounds 1-10:    800 ns (62.0%)
Done:            10 ns (0.8%)
─────────────────────────────
Total:        1,290 ns (100%)
```

### Decryption:
```
Key Expansion:  440 ns (25.1%)
Round 0:         40 ns (2.3%)
Rounds 1-10:  1,260 ns (72.0%)
Done:            10 ns (0.6%)
─────────────────────────────
Total:        1,750 ns (100%)
```

## Optimization Notes

### Current Design Trade-offs:
1. **Area-efficient:** Column-wise processing reduces hardware
2. **Predictable timing:** Constant cycle count (SCA resistance)
3. **Shared resources:** Same hardware for all columns

### Potential Optimizations (if needed):
1. **Parallel processing:** Process all 4 columns simultaneously
   - Encryption: 129 → ~53 cycles (2.4× faster)
   - Decryption: 175 → ~62 cycles (2.8× faster)
   - Cost: 4× hardware resources

2. **Pipelined rounds:** Start next block before current finishes
   - Throughput: 1 block per 8-13 cycles (steady state)
   - Latency: Still 129/175 cycles
   - Cost: 11× registers (pipeline stages)

3. **Key expansion caching:** Reuse keys for multiple blocks
   - Reduces to: 85 cycles (enc) / 131 cycles (dec) per block
   - Saves: 44 cycles when key doesn't change
   - Cost: 1408 bits storage for all round keys

## Comparison with Other Implementations

| Implementation | Cycles (Enc) | Cycles (Dec) | Area (GE) | Notes |
|----------------|--------------|--------------|-----------|-------|
| **Your Design** | **129** | **175** | ~15,000 | Column-wise |
| Typical compact | 160-200 | 160-200 | ~13,000 | Byte-wise |
| Fast parallel | 11-12 | 11-12 | ~50,000 | Fully parallel |
| Ultra-compact | 200-250 | 200-250 | ~8,000 | Bit-serial |

Your design offers a good balance between area and performance!

## Verification on FPGA

To measure actual cycle count on your Nexys A7 board:

1. Add a cycle counter to aes_fpga_top.v:
```verilog
reg [15:0] cycle_counter;
always @(posedge clk) begin
    if (start)
        cycle_counter <= 0;
    else if (!ready)
        cycle_counter <= cycle_counter + 1;
end
```

2. Display cycle_counter on 7-segment when ready=1

This will show you the actual measured cycle count!

# AES Design Optimization Analysis
## Competing with State-of-the-Art Implementations

---

## 1. Current Design Performance Profile

### **Architecture Overview**
- **Type:** Sequential, column-wise processing
- **Target:** Low-power IoT/embedded applications
- **FPGA:** Artix-7 (Nexys A7-100T)
- **Clock:** 100 MHz
- **Area:** ~50,000 GE (estimated)

### **Performance Metrics**
| Metric | Encryption | Decryption |
|--------|-----------|-----------|
| Clock Cycles | 129 | 175 |
| Latency @ 100MHz | 1.29 µs | 1.75 µs |
| Throughput | 99.2 Mbps | 73.1 Mbps |
| Blocks/second | 775,194 | 571,429 |

### **Current Implementation Category**
- **Research Category:** Ultra-low-area, register-based implementations
- **Key Features:**
  - On-the-fly key expansion (saves 1280 bits storage)
  - Shared MixColumns for encryption/decryption
  - Column-wise processing (reduces combinational logic)
  - No Block RAM usage

---

## 2. State-of-the-Art Benchmarks

### **High-Throughput Implementations (Artix-7)**

| Implementation | Frequency | Throughput | Cycles/Block | Architecture |
|---------------|-----------|------------|--------------|--------------|
| **SOTA Pipelined** | 565 MHz | 72.32 Gbps | 1 (pipelined) | Fully pipelined |
| **Optimized 2020** | 244 MHz | 30.48 Gbps | ~10 | Sub-pipelined |
| **High-Speed 2024** | 400+ MHz | 40+ Gbps | ~12 | Loop-unrolled |
| **Current Design** | 100 MHz | 0.099 Gbps | 129 | Sequential |

### **Performance Gap**
- **Throughput:** 300-730x slower than SOTA
- **Frequency:** 2.5-5.6x slower clock speed
- **Latency:** Similar cycles but lower frequency

### **Low-Power/Area Implementations**

| Category | Typical Performance | Typical Area | Power |
|----------|-------------------|--------------|-------|
| Ultra-compact | 50-150 Mbps | 10-30k GE | Very Low |
| Balanced | 500-2000 Mbps | 40-80k GE | Low |
| High-throughput | 10-100 Gbps | 100-300k GE | Medium-High |
| **Current Design** | 99 Mbps | ~50k GE | Very Low |

---

## 3. Optimization Opportunities

### **Category A: Architecture-Level (High Impact)**

#### **A1. Pipelining Strategy**
**Current:** Sequential state machine with column-by-column processing

**Optimization Options:**

**Option 1: Inner Round Pipelining** (Conservative)
- Pipeline within each round (SubBytes → ShiftRows → MixColumns)
- Insert registers between operations
- **Expected Gain:** 2-3x throughput, 1.5-2x area increase
- **Estimated Performance:** 200-300 Mbps @ 150-200 MHz

**Option 2: Outer Round Pipelining** (Moderate)
- Unroll rounds 1-10 with pipeline registers
- Each round becomes a pipeline stage
- **Expected Gain:** 10x throughput, 8-10x area increase
- **Estimated Performance:** 1-2 Gbps @ 200-250 MHz

**Option 3: Full Loop Unrolling + Sub-pipelining** (Aggressive)
- Completely unroll all rounds
- Add sub-pipeline stages within each round
- **Expected Gain:** 100-300x throughput, 20-30x area increase
- **Estimated Performance:** 10-30 Gbps @ 300-500 MHz

#### **A2. Parallel Processing**
**Current:** 32-bit column-wise processing (serialized)

**Optimization:**
- Process all 4 columns in parallel
- Instantiate 4x SubBytes modules
- Instantiate 4x MixColumns modules
- **Expected Gain:** ~4x throughput, ~3.5x area increase
- **Estimated Performance:** ~400 Mbps @ 100 MHz, 60 Gbps with pipelining

#### **A3. Key Expansion Strategy**
**Current:** Pre-compute all 44 round keys before encryption (44 cycles overhead)

**Optimization Options:**
1. **Parallel Key Expansion:** Generate keys concurrently with round operations
   - **Saves:** 40-44 cycles (encryption only 85-89 cycles)
   - **Cost:** Additional key expansion logic duplication
   - **Gain:** ~34% latency reduction

2. **Cached Round Keys:** Store computed keys for repeated operations
   - **Benefit:** 44 cycles saved on subsequent encryptions with same key
   - **Cost:** 1408 bits storage (defeats low-area goal)

---

### **Category B: Module-Level (Medium Impact)**

#### **B1. S-Box Optimization**
**Current:** Instantiated modules using composite field arithmetic

**Optimization Options:**

1. **LUT-based S-Box** (Speed-optimized)
   - Use Block RAM for S-box lookup
   - **Gain:** Faster operation, simpler timing
   - **Cost:** Uses BRAM resources (defeats register-only design)
   - **Performance:** 1-2 cycle S-box vs current combinational

2. **Optimized Composite Field** (Area-optimized)
   - Use latest FPGA-friendly S-box designs (2025 research)
   - 3.125% less gate-area demonstrated
   - **Gain:** 3-5% area reduction
   - **Cost:** Redesign effort

3. **Pipelined S-Box** (Throughput-optimized)
   - Break composite field into pipeline stages
   - **Gain:** Higher frequency possible
   - **Cost:** Increased latency, more registers

#### **B2. MixColumns Optimization**
**Current:** Shared decomposition matrix for encryption/decryption

**Optimization:**
1. **Separate Enc/Dec MixColumns**
   - Dedicated paths for each mode
   - **Gain:** 15-20% faster MixColumns operation
   - **Cost:** ~10% area increase (lose sharing benefit)

2. **Constant Multiplication Optimization**
   - Optimize GF(2^8) multipliers using FPGA-specific primitives
   - **Gain:** 10-15% area reduction or speed improvement
   - **Cost:** Platform-specific code

---

### **Category C: Implementation-Level (Low-Medium Impact)**

#### **C1. State Storage Optimization**
**Current:** 44 individual 32-bit registers for round keys

**Optimization:**
1. **Shift Register Implementation**
   - Use SRL32 primitives (Xilinx-specific)
   - **Gain:** 30-40% register reduction
   - **Cost:** Platform-specific, may limit flexibility

2. **Block RAM Storage**
   - Store round keys in BRAM instead of registers
   - **Gain:** Massive register savings (~1400 FFs freed)
   - **Cost:** Uses 1 BRAM18, contradicts design goal

#### **C2. Clock Frequency Optimization**
**Current:** 100 MHz (conservative)

**Optimization:**
1. **Critical Path Analysis & Optimization**
   - Identify and optimize longest combinational path
   - **Target:** 200-300 MHz (2-3x current)
   - **Methods:**
     - Register insertion at critical boundaries
     - Operator restructuring
     - Retiming
   - **Gain:** 2-3x throughput with same architecture
   - **Cost:** Increased pipeline depth, higher latency

2. **Multi-cycle Path Constraints**
   - Allow multi-cycle paths for non-critical operations
   - **Gain:** Higher overall frequency
   - **Cost:** Slight complexity in timing constraints

#### **C3. Control Logic Optimization**
**Current:** 4-bit state machine with phase counters

**Optimization:**
1. **One-hot State Encoding**
   - Faster state transitions
   - **Gain:** 10-15% frequency improvement
   - **Cost:** More state registers (negligible)

2. **Finite State Machine with Datapath (FSMD)**
   - Optimize control/datapath partitioning
   - **Gain:** Better synthesis results
   - **Cost:** Redesign effort

---

## 4. Optimization Strategy Roadmap

### **Strategy 1: Conservative (Low-Power Focus)**
**Goal:** 2-3x performance improvement, minimal area increase

**Optimizations:**
1. ✓ Parallel column processing (4x columns simultaneously)
2. ✓ Parallel key expansion with round operations
3. ✓ Clock frequency optimization to 200 MHz
4. ✓ One-hot state encoding
5. ✓ Critical path optimization

**Expected Results:**
- Throughput: 600-800 Mbps
- Area: 65-80k GE (~1.5x increase)
- Latency: 400-500 ns
- Power: Low (still suitable for IoT)

**Category:** Optimized low-power implementation

---

### **Strategy 2: Balanced (Performance-Area Tradeoff)**
**Goal:** 20-30x performance improvement, moderate area increase

**Optimizations:**
1. ✓ All Strategy 1 optimizations
2. ✓ Inner round pipelining (2-stage per round)
3. ✓ Separate encryption/decryption datapaths
4. ✓ LUT-based S-boxes (1 BRAM)
5. ✓ Optimized MixColumns constants

**Expected Results:**
- Throughput: 2-3 Gbps
- Area: 150-200k GE (~3-4x increase)
- Latency: 300-400 ns
- Power: Medium-Low
- Frequency: 300 MHz

**Category:** Balanced general-purpose implementation

---

### **Strategy 3: Aggressive (High-Throughput)**
**Goal:** 100-300x performance improvement, compete with SOTA

**Optimizations:**
1. ✓ Full round unrolling (11 round stages)
2. ✓ Sub-pipelining within each round (3-4 stages)
3. ✓ Parallel column processing (all 4 columns)
4. ✓ Separate enc/dec cores
5. ✓ BRAM-based key storage
6. ✓ Optimized S-box with pipelining
7. ✓ Retiming and register balancing
8. ✓ Clock frequency target: 400-500 MHz

**Expected Results:**
- Throughput: 20-40 Gbps
- Area: 800k-1.5M GE (~16-30x increase)
- Latency: 100-200 ns (pipelined, 1 block/cycle steady-state)
- Power: Medium-High
- Frequency: 400-500 MHz

**Category:** High-throughput datacenter/network implementation

---

## 5. Recommended Approach

### **Phase 1: Quick Wins (1-2 weeks)**
Focus on low-hanging fruit for immediate improvement:

1. **Parallel Column Processing**
   - Modify state machine to process all 4 columns simultaneously
   - Instantiate 4x SubBytes, 4x MixColumns modules
   - **Expected gain:** 3-4x throughput
   - **Complexity:** Medium

2. **Overlapped Key Expansion**
   - Start encryption while key expansion in progress
   - Pipeline round key generation
   - **Expected gain:** 30% latency reduction
   - **Complexity:** Medium

3. **Clock Optimization**
   - Analyze critical paths
   - Insert pipeline registers at bottlenecks
   - Target 200 MHz operation
   - **Expected gain:** 2x throughput
   - **Complexity:** Low-Medium

**Combined Phase 1 Gain:** 6-8x performance (600-800 Mbps)

---

### **Phase 2: Architectural Enhancement (2-4 weeks)**
Build on Phase 1 with deeper changes:

1. **Inner Round Pipelining**
   - 2-stage pipeline per round: (SubBytes+ShiftRows) → (MixColumns+AddRoundKey)
   - **Expected gain:** Additional 2-3x on top of Phase 1
   - **Complexity:** High

2. **Dedicated Enc/Dec Paths**
   - Remove mode multiplexing overhead
   - **Expected gain:** 20% improvement
   - **Complexity:** Medium

**Combined Phase 1+2 Gain:** 15-20x performance (1.5-2 Gbps)

---

### **Phase 3: Full Optimization (4-8 weeks)**
Only if high-throughput is required:

1. **Full Loop Unrolling**
2. **Deep Sub-pipelining**
3. **Advanced optimizations**

**Combined Gain:** 100-300x performance (10-30 Gbps)

---

## 6. Comparison with SOTA After Optimization

### **After Phase 1 (Conservative)**
| Metric | Current | Phase 1 | SOTA Low-Power | Gap |
|--------|---------|---------|----------------|-----|
| Throughput | 99 Mbps | 600-800 Mbps | 500-2000 Mbps | Competitive |
| Area | 50k GE | 70-80k GE | 40-80k GE | Competitive |
| Power | Very Low | Low | Low | Competitive |

**Outcome:** Competitive with low-power SOTA implementations

---

### **After Phase 2 (Balanced)**
| Metric | Current | Phase 2 | SOTA Balanced | Gap |
|--------|---------|---------|---------------|-----|
| Throughput | 99 Mbps | 1.5-2 Gbps | 2-10 Gbps | Close |
| Area | 50k GE | 150-200k GE | 100-300k GE | Competitive |
| Frequency | 100 MHz | 300 MHz | 300-500 MHz | Close |

**Outcome:** Competitive with balanced SOTA implementations

---

### **After Phase 3 (Aggressive)**
| Metric | Current | Phase 3 | SOTA High-Perf | Gap |
|--------|---------|---------|----------------|-----|
| Throughput | 99 Mbps | 20-40 Gbps | 30-100 Gbps | Competitive |
| Area | 50k GE | 0.8-1.5M GE | 0.5-2M GE | Competitive |
| Frequency | 100 MHz | 400-500 MHz | 400-600 MHz | Competitive |

**Outcome:** Competitive with high-throughput SOTA implementations

---

## 7. Key Takeaways

### **Can We Compete?**
**YES**, but it depends on the target category:

1. **Low-Power IoT:** Current design is already good, Phase 1 makes it excellent
2. **Balanced General-Purpose:** Phase 2 optimizations needed
3. **High-Throughput Network:** Phase 3 required, fundamentally different architecture

### **Design Philosophy Trade-off**
The current design optimizes for:
- ✓ Ultra-low area
- ✓ Register-based (no BRAM)
- ✓ Low power
- ✗ Throughput

SOTA designs optimize for:
- ✗ Large area acceptable
- ✓ Use all FPGA resources (BRAM, DSP)
- ✗ Higher power acceptable
- ✓ Maximum throughput

### **Recommendation**
**Start with Phase 1** to make the design competitive in the low-power category while maintaining its core advantages. This achieves:
- 6-8x performance improvement
- Minimal area increase
- Maintains low-power benefits
- Still register-based
- 2-4 week effort

**Then reassess** based on application requirements whether Phase 2/3 is needed.

---

## 8. Next Steps

1. **Decision:** Choose optimization strategy (Phase 1, 2, or 3)
2. **Implementation:** Begin with highest-impact optimizations
3. **Verification:** Test each optimization incrementally
4. **Benchmarking:** Compare against SOTA using standard metrics
5. **Publication:** Document novel optimizations for academic contribution

Would you like me to proceed with implementing Phase 1 optimizations?

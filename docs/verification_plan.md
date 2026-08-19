# Verification Plan - Synchronous FIFO with AXI4-Lite Wrapper

## 1. Scope and Objectives

This document describes the verification strategy for the synchronous FIFO core (`fifo_sync`) and its AXI4-Lite wrapper (`axil_fifo`).

**Verified components:**

- `fifo_sync` - synchronous FIFO core (FWFT, extra-MSB pointer full/empty detection)
- `axil_fifo` - AXI4-Lite slave wrapper (3-register map, write/read FSMs, SLVERR generation)

**Verification levels:**

| Level | Target | Method |
|-------|--------|--------|
| Core | `fifo_sync` | SVA assertions, self-checking scoreboard, constrained-random stimulus |
| Integration | `axil_fifo` + `fifo_sync` | AXI VIP, self-checking deterministic tests, functional coverage |

**Objectives:**

1. Prove data integrity (no loss, no corruption) through write→FIFO→read chains.
2. Verify full/empty flag correctness under random stimulus.
3. Verify error behavior (write-when-full, read-when-empty) at both core and AXI levels.
4. Measure functional coverage of both FIFO internal states and AXI protocol usage.

---

## 2. Verification Methods and Tools

| Method | Tool | Role |
|--------|------|------|
| SVA assertions | Xilinx XSim | Cycle-accurate property checks on core signals |
| Self-checking scoreboard | SystemVerilog reference queue | Data integrity verification under random stimulus |
| Constrained-random stimulus | `$urandom` in testbench | Generate diverse FIFO state sequences |
| Functional coverage | `covergroup` in XSim | Measure coverage of core states and AXI protocol |
| AXI VIP | Xilinx AXI Verification IP | Protocol-compliant AXI master, protocol checkers |
| Deterministic AXI tests | Self-checking testbench + VIP | Register access, response codes, error paths |

---

## 3. Feature-to-Method Mapping

### 3.1 FIFO Core

| Feature | Verified By |
|---------|-------------|
| Full/empty correctness | SVA `!(full && empty)`, scoreboard checks |
| Write accepted only when not full | SVA `wr_err == (wr_en && full)`, scoreboard |
| Read accepted only when not empty | SVA `rd_err == (rd_en && empty)`, scoreboard |
| Write pointer frozen when writing to full | SVA `(wr_en && full) |=> (wr_ptr == $past(wr_ptr))` |
| Read pointer frozen when reading from empty | SVA `(rd_en && empty) |=> (rd_ptr == $past(rd_ptr))` |
| FWFT: data appears 1 cycle after writing into empty FIFO | SVA `(wr_en && empty) |=> (rd_data == $past(wr_data))` |
| FWFT: head data valid when not empty | Scoreboard reference queue |
| Data integrity (any sequence) | Scoreboard reference queue |
| Pointer wrap-around | Functional coverage (`cp_wr_wrap`, `cp_rd_wrap`) + scoreboard |
| Occupancy levels (0-4) | Functional coverage on reference queue size |

### 3.2 AXI4-Lite Wrapper

| Feature | Verified By |
|---------|-------------|
| Register map decode (`0x00`, `0x04`, `0x08`) | AXI VIP deterministic tests, functional coverage |
| Write to `FIFO_WR` pushes into FIFO | AXI VIP Test 1 + Test 2 (read-back) |
| Read from `FIFO_RD` pops head | AXI VIP Test 2 |
| Read from `FIFO_STATUS` returns flags | AXI VIP Test 3 |
| Write to full FIFO → SLVERR | AXI VIP Test 5 |
| Read from empty FIFO → SLVERR | AXI VIP Test 4 |
| AW and W channel independence | Write FSM with separate `aw_done`/`w_done` flags, AXI VIP |
| Reset behavior (READY low after reset) | `reset_released` counter, VIP protocol checks |
| Response codes (OKAY / SLVERR) | AXI VIP self-checking, functional coverage |

---

## 4. Deliberately Excluded Items and Rationale

| Item | Rationale |
|------|-----------|
| `wr_ptr + 1` SVA assertion (pointer increment) | XSim does not support `$past` with cast/arithmetic in this context. Data integrity is already covered by scoreboard. |
| Burst-4 write coverage bin (`burst_4`) | Not explicitly targeted; data integrity of consecutive writes is already verified by scoreboard. |
| Occupancy coverage levels 0-4 targeted as bins | Trivially covered - FIFO fills one entry at a time, so reaching `full` necessarily passes through all intermediate levels. |
| AXI write-address bins for read-only/reserved addresses | Excluded via `ignore_bins` - these are not valid write targets by spec, so their absence is expected, not a coverage gap. |
| `rd_err_r` register in read FSM | Removed - RRESP must be valid in the same cycle as RVALID; register delayed it. Combinational logic used instead. |
| `wr_err_r` register in write FSM | Kept - BRESP is on a separate cycle (RESP state), so a register to hold the error from WRITE state is correct. |

---

## 5. Known Limitations and Assumptions

| Limitation | Impact |
|------------|--------|
| `S_AXI_WSTRB` ignored (full-word writes assumed) | Byte-level writes not supported. Acceptable for FIFO data storage. |
| `S_AXI_AWPROT` / `S_AXI_ARPROT` not supported | No protection signal handling. AXI4-Lite allows slave to ignore. |
| `ADDR_WIDTH` set to 32 in both RTL and wrapper TB | Decode uses `addr[3:2]`, so only 4 bits are functionally relevant. |
| `PtrWidth` used before declaration warning in SVA checker | Cosmetic; does not affect functional behavior. |
| `wr_en`/`rd_en` not blocked when full/empty at core level | Core relies on `wr_err`/`rd_err` to signal illegal access. Error propagated to AXI SLVERR in wrapper. |
| `reset_released` counter holds READY low for 2 cycles | Satisfies AXI VIP reset protocol check. |

---

## 6. Results Summary

### 6.1 FIFO Core Simulation

| Metric | Value |
|--------|-------|
| Stimulus cycles | 200 random |
| Data integrity checks | All passed (no mismatch) |
| SVA assertion failures | None |

### 6.2 AXI Wrapper Simulation

| Test | Scenario | Expected | Result |
|------|----------|----------|--------|
| 1 | Write `0xDEADBEEF` to `FIFO_WR` | OKAY | PASS |
| 2 | Read from `FIFO_RD` | `0xDEADBEEF`, OKAY | PASS |
| 3 | Read `FIFO_STATUS` (FIFO empty at this point: one write + one read) | `0x1`, OKAY | PASS |
| 4 | Read from empty FIFO | SLVERR | PASS |
| 5 | Fill FIFO (4 writes), then write | Last write SLVERR | PASS |

### 6.3 Functional Coverage

| Coverage Group | Result |
|----------------|--------|
| FIFO core coverpoints | 100% |
| FIFO core crosses | 100% |
| AXI address decode | 100% (after `ignore_bins`) |
| AXI response codes | 100% |

### 6.4 AXI VIP Protocol Checks

- All VIP end-of-simulation protocol checks: **CLEAN**
- No VALID/READY handshake violations
- No reset protocol violations (after `reset_released` counter added)

---

## 7. Verification Environment Structure

tb_selfcheck.sv - FIFO core self-checking testbench (random stimulus + scoreboard)
tb_axil_fifo.sv - AXI wrapper testbench (AXI VIP + deterministic tests + coverage)
fifo_sync_sva.sv - SVA checker module (bound to fifo_sync)
axil_fifo.sv - AXI4-Lite wrapper RTL
fifo_sync.sv - FIFO core RTL

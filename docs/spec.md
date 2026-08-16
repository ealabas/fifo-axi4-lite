# Synchronous FIFO — Design Specification

## 1. Overview

This project implements a synchronous FIFO. A FIFO behaves like the queue data structure in software: first in, first out. It can be used in any design that needs to move data between two sides. It balances transfers between a transmitter and a receiver when their input and output rates differ. The FIFO also exposes full and empty status so the surrounding logic knows when it is safe to write or read.

## 2. Features

- Parameterizable data width.
- Parameterizable depth, constrained to powers of two.
- Full and empty status flags.
- Single clock domain (synchronous operation).
- First-word fall-through (FWFT) read: the head-of-queue data is presented on the output before a read is requested.
- Write and read error outputs.

## 3. Parameters

|Parameter|Default|Range / constraint|Description|
|---|---|---|---|
|WIDTH|32|2 to 64|Data width in bits|
|DEPTH|4|2 to 8, power of two|Number of FIFO entries; must be a power of two because of the pointer wrap scheme|

## 4. Interface / port list

|Signal|Direction|Width|Description|
|---|---|---|---|
|clk|input|1|System clock; all logic synchronous to its rising edge|
|rst_n|input|1|Active-low synchronous reset|
|wr_en|input|1|Write request|
|wr_data|input|WIDTH|Data to write|
|rd_en|input|1|Read request|
|rd_data|output|WIDTH|Read data; head of the queue (FWFT)|
|full|output|1|Asserted when the FIFO is full|
|empty|output|1|Asserted when the FIFO is empty|
|wr_err|output|1|Write error: write requested while full|
|rd_err|output|1|Read error: read requested while empty|

## 5. Reset behavior

Reset is synchronous, so every flop resets on the same clock edge, which suits a single-clock block. Immediately after reset, `full` is 0 and `empty` is 1, both the write and read pointers point to entry 0, `rd_data` is 0, and both error signals (`wr_err`, `rd_err`) are 0.

## 6. Full / empty generation

The design uses a write pointer and a read pointer, each `log2(DEPTH) + 1` bits wide. The extra most-significant bit (MSB) distinguishes full from empty; the lower bits address the memory. The FIFO is empty when the two pointers are exactly equal. When a pointer reaches the end of the memory it wraps around, and because the depth is a power of two, the MSB toggles automatically as part of the increment. The FIFO is full when the address (lower) bits of the two pointers are equal but their MSBs differ.

## 7. Write operation

When a write is accepted, `wr_data` is written to the address given by the lower bits of the write pointer, and the write pointer increments by one; on wrap-around its MSB toggles automatically. If `wr_en` is asserted while `full` is set, the write is rejected: `wr_err` is asserted and the write pointer does not change. `wr_err` is combinational, so it becomes active in the same cycle as the request.

## 8. Read operation and read latency

This block uses first-word fall-through (FWFT): whenever the FIFO is not empty, `rd_data` continuously presents the head-of-queue word (the entry at the read pointer), even before `rd_en` is asserted. Asserting `rd_en` while the FIFO is not empty advances the read pointer, so the next head-of-queue word appears on `rd_data` on the following cycle.

When the FIFO is empty, `rd_data` is 0, even if `rd_en` is not asserted. Asserting `rd_en` while empty sets `rd_err` and has no other effect; `rd_err` is combinational, so it is active in the same cycle as the request.

There is no same-cycle forwarding path: when a word is written into an empty FIFO, it appears on `rd_data` one cycle later (one cycle of fill latency).

## 9. Simultaneous read and write

When the FIFO is neither full nor empty and both `rd_en` and `wr_en` are asserted in the same cycle, both operations proceed and the occupancy is unchanged: `rd_data` returns the old head value, and the new word is written behind it. When the FIFO is empty, the read is rejected (`rd_err`) and the write is accepted. When the FIFO is full, the write is rejected (`wr_err`) and the read is accepted.

## 10. Corner cases / boundary conditions

- Write when full: `wr_err` is asserted and all state holds its value.
- Read when empty: `rd_err` is asserted and `rd_data` becomes 0; other state holds its value.
- Pointer wrap-around: each pointer's MSB toggles automatically on its own wrap; because the depth is a power of two, incrementing the pointer wraps the address bits naturally.
- Back-to-back writes: each cycle writes to the write pointer's location and increments it, until the FIFO becomes full; the next write is rejected (`wr_err`) and state holds.
- Back-to-back reads: each cycle advances the read pointer, until the FIFO becomes empty; the next read is rejected (`rd_err`), `rd_data` becomes 0, and other state holds.

## 11. Assumptions and limitations

- The FIFO is synchronous and works correctly only within a single clock domain; cross-domain use requires the asynchronous FIFO variant.
- DEPTH must be a power of two.
- No error correction is performed on the data.
- The AXI4-Lite interface is out of scope here and will be added later as a separate module.

## 12. Design decisions log

- Full/empty via an extra MSB pointer bit rather than a counter, for design simplicity.
- DEPTH constrained to a power of two, as required by the pointer wrap scheme.
- FWFT read, to reduce read latency.
- Explicit error outputs, to make illegal read/write attempts visible.
- On a simultaneous read and write: when full, the write is rejected and the read is accepted; when empty, the read is rejected and the write is accepted.
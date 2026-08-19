# Synchronous FIFO with AXI4-Lite Wrapper

A from-scratch implementation of a synchronous FIFO core and its AXI4-Lite slave wrapper, built in SystemVerilog and verified with Xilinx Vivado XSim and AXI VIP. The wrapper is packaged as a reusable Vivado IP.

The project is a complete IP development exercise: specification, RTL design, assertion-based verification, constrained-random testing, functional coverage, protocol-level integration testing, and IP packaging.

---

A FIFO (first-in, first-out) buffer is a hardware queue. It decouples a producer and a consumer that operate at different instantaneous rates. Data is pushed into the FIFO when the producer writes, and popped out when the consumer reads. Full and empty flags tell the surrounding logic when writes and reads are safe.

This project contains two layers:

| Layer | Module | Description |
|-------|--------|-------------|
| Core | `fifo_sync` | Synchronous FIFO with first-word fall-through (FWFT) read, configurable width and depth |
| Integration | `axil_fifo` | AXI4-Lite slave wrapper that exposes the FIFO through a 3-register memory-mapped interface |

The FIFO core has a simple native interface (`wr_en`, `rd_en`, `wr_data`, `rd_data`, `full`, `empty`, `wr_err`, `rd_err`). The AXI wrapper translates this into a standard AXI4-Lite register map, so a processor can use the FIFO by reading and writing addresses.

---

## Features

### FIFO Core (`fifo_sync`)

- Parameterizable `WIDTH` and `DEPTH`
- Single clock domain, synchronous operation
- First-word fall-through (FWFT) read behavior
- Full and empty status flags
- Separate write and read error outputs
- Full/empty detection via extra-MSB pointer method
- `DEPTH` constrained to powers of two

### AXI4-Lite Wrapper (`axil_fifo`)

- Standard AXI4-Lite slave interface
- 3-register memory-mapped access:
  - `0x00` `FIFO_WR` - write data (write pushes into FIFO)
  - `0x04` `FIFO_RD` - read data (read pops head of FIFO)
  - `0x08` `FIFO_STATUS` - empty/full flags
- SLVERR response on write-when-full and read-when-empty
- Independent AW and W channel handling
- Reset protocol compliant with AXI VIP checks
- Packaged as a reusable Vivado IP

---

## Repository Structure

```
fifo-axi4-lite/
├── rtl/
│   ├── fifo_sync.sv          # FIFO core RTL
│   └── axil_fifo.sv          # AXI4-Lite wrapper RTL
├── sva/
│   └── fifo_sync_sva.sv      # SVA checker (bound to fifo_sync)
├── tb/
│   ├── tb_selfcheck.sv       # FIFO core self-checking testbench
│   └── tb_axil_fifo.sv       # AXI wrapper testbench (AXI VIP)
├── ip_repo/
│   ├── component.xml         # Packaged IP definition
│   ├── src/                  # IP source RTL
│   └── xgui/                 # IP customization GUI
├── docs/
│   ├── spec.md               # Design specification
│   └── verification_plan.md              # Verification plan
└── README.md
```

---

## IP Packaging

The AXI4-Lite wrapper is packaged as a Vivado IP, ready for use in block designs.

**To use in a Vivado project:**

1. In Vivado, go to **Settings → IP → Repository**
2. Add the `ip_repo` folder from this project
3. In a Block Design, use **Add IP** and search for `axil_fifo`

**Customization parameters:**

| Parameter | Default | Description |
|-----------|---------|-------------|
| `WIDTH` | 32 | Data width in bits |
| `DEPTH` | 4 | FIFO depth (must be a power of two) |

---

## Verification Summary

| Method | Target | Tool |
|--------|--------|------|
| SVA assertions | FIFO core | Xilinx XSim |
| Self-checking scoreboard | Data integrity | SystemVerilog reference queue |
| Constrained-random stimulus | FIFO core | `$urandom` |
| Functional coverage | FIFO + AXI | `covergroup` |
| AXI VIP protocol checks | AXI wrapper | Xilinx AXI Verification IP |

All tests pass. 6 SVA assertions, 200 random cycles, 5 AXI VIP scenarios, VIP protocol checks clean. Functional coverage is 100% for meaningful bins. AXI VIP protocol checks are clean.

For full details, see `docs/verification_plan.md`.

---

## Design Decisions

- **FWFT read** - reduces read latency; head data is already on `rd_data` before `rd_en` is asserted
- **Extra-MSB pointer full/empty detection** - simpler than an occupancy counter
- **Separate write and read register addresses** - keeps AXI side effects distinct
- **Error reporting via AXI SLVERR** - makes illegal accesses visible to software
- **`DEPTH` as power of two** - required for natural pointer wrap-around

---

## Limitations

- Single clock domain only (no CDC)
- `S_AXI_WSTRB` ignored (full-word writes assumed)
- `S_AXI_AWPROT` / `S_AXI_ARPROT` not supported
- No byte-level write support

---

## Tools

- Xilinx Vivado 2024.2 (XSim, AXI VIP, IP Packager)
- SystemVerilog (IEEE 1800)

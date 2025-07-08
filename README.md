
# SPI Protocol Verification using SystemVerilog Assertions (SVA)

## Overview

This project implements and verifies a simplified SPI-like serial communication protocol using **SystemVerilog Assertions (SVA)**. The design and testbench are adapted from exercises in the **Cadence Labs Manual** and executed on **EDA Playground**.

The verification is **assertion-based**, where different types of transactions (legal and illegal) are triggered and checked for protocol conformance using sequences, properties, and assertions.

---

## Key Features

- **SPI-style protocol** with `frame`, `serial`, and `suspend` signals.
- **Legal Transactions**:
  - Configuration (`txno = 1`)
  - Start (`txno = 2`)
  - Read (`txno = 3`)
- **Illegal Transactions**:
  - Short Frame (`txno = 4`)
  - Long Frame (`txno = 5`)
  - Invalid Header (`txno = 6`)
- **Suspend-Aware Read Transaction** (`txno = 7`)

Each transaction is selected dynamically via a `txno` control and validated using **SystemVerilog Assertions**.

---

## File Structure


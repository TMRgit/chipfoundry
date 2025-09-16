# Project: Interrupt-Capable, Auto-Reload Timer Peripheral for Microwatt CPU (ChipFoundry Design Challenge)

## Overview
This project enhances the Microwatt POWER CPU by integrating a memory-mapped timer peripheral supporting both periodic (auto-reload) mode and interrupt generation. The timer is accessible from software to enable time-keeping, event scheduling, and system tick functionalities. It demonstrates typical SoC extension for embedded applications.

## Key Features
- 32-bit memory-mapped timer register
- Auto-reload (periodic) operation mode
- Optional one-shot mode
- Configurable timer start/stop and reload value via control register
- Hardware interrupt signal asserted to CPU when timer expires
- Status register for timer running, interrupt pending, and overflow
- Fully documented register map
- Includes testbench (Verilog), simulation demo, and example C usage
- Clean diagrams and reproducible setup for ChipFoundry/OpenFrame flow

## Register Map
| Offset | Register     | Description                       |
|--------|--------------|------------------------------------|  
| 0x00   | TIMER_COUNT  | Current timer value (RW)           |
| 0x04   | TIMER_CTRL   | Control (start/stop, mode, clear)  |
| 0x08   | TIMER_RELOAD | Reload value (RW)                  |
| 0x0C   | TIMER_STAT   | Status (interrupt, overflow)       |

## Example Use Cases
- Software-driven delays and periodic events
- RTOS or bare-metal OS system tick timer
- Simple alarm/event triggering via interrupt

## Block Diagram
(Includes diagram showing connection of timer to Microwatt CPU bus and interrupt line.)

## Simulation & Demo
- Provided Verilog testbench covers normal, auto-reload, and interrupt cases
- Example bus transactions: set reload, start timer, wait for interrupt, read value
- C code provided for bare-metal demo
- Simulation waveforms and screenshot(s) included

## Setup & Repo Instructions
1. Clone the repo (template already includes OpenFrame setup)
2. Edit/insert timer Verilog in /verilog and update wrapper as needed
3. Run simulation with testbench in /verilog/testbench
4. Synthesize and implement using OpenLane:
   - `make setup`
   - `make user_proj_timer`
   - `make openframe_project_wrapper`
5. Follow README instructions for expected output, demo scripts, and verification

## Documentation & Licensing
- Full documentation in /docs
- Open-source (Apache-2.0)

## AI Usage
(If AI/LLM/generative tools are used for any code or doc generation, logs are provided per challenge guidelines.)

## Authors & Credits
- (Your Name, contributors, template references, etc.)

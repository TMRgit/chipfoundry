# Proposal: Performance Counter Peripheral for Microwatt CPU Profiling

### Project Summary

This project proposes the design and integration of a simple, memory-mapped performance counter peripheral for the Microwatt POWER CPU. The peripheral will provide a pair of 64-bit counters: a free-running **cycle counter** and an **instruction-retired counter**. This will enable developers to perform precise, low-overhead performance profiling of their software, helping to identify bottlenecks and optimize critical code paths within the Microwatt ecosystem.

---

### Motivation

For any serious software development, the ability to answer "How fast is my code?" is crucial. Professional CPU architectures include hardware performance counters as a standard feature. By adding this capability to Microwatt, we significantly mature the platform, turning it from just a CPU core into a more analyzable and professional development target. This tool empowers developers to make data-driven decisions, calculate key metrics like Cycles Per Instruction (CPI), and quantitatively measure the impact of their optimizations.

---

### Core Features

* **Memory-mapped** register interface for easy software access.
* A **64-bit free-running cycle counter** that increments every clock cycle.
* A **64-bit instruction-retired counter** that increments only when the CPU successfully completes an instruction.
* A simple control register to enable, disable, and reset the counters.

---

### High-Level Block Diagram



The peripheral connects to the Microwatt system bus for register access. It also requires a single signal tap from the CPU core's pipeline (e.g., an `instruction_retired` pulse) to accurately count completed instructions.

---

### Implementation Outline

1.  Design the dual-counter peripheral in Verilog. The logic is minimal and primarily consists of two 64-bit registers with enable logic.
2.  Integrate the module into the OpenFrame user project, connecting its registers to the memory map.
3.  Identify and connect the appropriate signal from the Microwatt core to the instruction-retired counter's increment logic.
4.  Develop a testbench to verify that the counters increment correctly under various conditions (e.g., during CPU stalls, the cycle counter should increment while the instruction counter does not).
5.  Write a sample C program demonstrating how to use the peripheral to benchmark a function and calculate its average CPI.
6.  Document the register map and provide clear instructions for other developers on how to use the tool for their own projects.

---

### Expected Outcome

The result will be a lightweight, powerful, and easy-to-use profiling tool for the Microwatt CPU. This project delivers not just a piece of hardware, but a foundational capability that enhances the value and usability of the Microwatt core for the entire open-source community.

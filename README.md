# QX Core 🔄

[![Language: Rust](https://img.shields.io/badge/Language-Rust-orange.svg)](https://www.rust-lang.org/)
[![License: MIT / Apache-2.0](https://img.shields.io/badge/License-MIT_|_Apache_2.0-blue.svg)](LICENSE)

**QX Core** is a high-throughput, low-latency distributed queuing and event-streaming substrate engineered in Rust.

---

## 🌟 Key Features

* **Lock-Free Messaging Primitives:** High-performance multi-producer single-consumer (MPSC) and broadcast channels with zero lock contention.
* **Memory-Mapped Ring Buffers:** Ultra-fast append-only persistence using `mmap`, avoiding OS context-switch overhead during high-frequency writes.
* **Dynamic Backpressure:** Prevents consumer starvation and memory ballooning via adaptive sliding-window flow control.
* **Sub-Millisecond P99 Latency:** Deterministic processing ideal for mission-critical robotics, defense telemetry, and event routing.

---

## 📜 License
Licensed under MIT or Apache-2.0.

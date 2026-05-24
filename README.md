# LockingSafe

LockingSafe is an FPGA-based digital security system developed using the Xilinx BASYS 3 board. The system simulates a password-protected safe where a user enters a code via a keypad, and the FPGA controls hardware components such as a servo motor and buzzer to represent locking and unlocking states.

The project demonstrates core digital design concepts including finite state machines, sequential logic, hardware input processing, and real-time control of FPGA-connected components.

---

## Overview

LockingSafe operates as a secure entry system. The user inputs a numeric password using a keypad, and the FPGA validates the input against a stored code to determine whether access is granted.

---

## Hardware Components

- Xilinx BASYS 3 FPGA board  
- Keypad input module  
- Servo motor (locking mechanism)  
- Buzzer (audio feedback for success/failure)  
- On-board display (status output)

---

## Functionality

- User enters a numeric password via keypad  
- FPGA processes and validates the input  
- If the password is correct:
  - Servo motor unlocks the safe  
  - Success feedback is triggered  
- If the password is incorrect:
  - Buzzer activates as an error signal  
  - Safe remains locked  

---

## Source Files

All main source files can be found in: safe/safe.srcs/sources_1/new


These files implement:
- Keypad input handling  
- Finite state machine (FSM) control logic  
- Servo motor control  
- Buzzer output logic  
- System timing and reset behaviour  

---

## Key Concepts

- Finite State Machine (FSM) design  
- Sequential logic systems  
- FPGA hardware interfacing  
- Input debouncing and validation  
- Embedded digital control systems  

---

## How to Run

This project requires a Xilinx BASYS 3 FPGA board.

1. Open the project in Xilinx Vivado  
2. Synthesize and implement the design  
3. Program the FPGA  
4. Interact using the keypad input system  

---

## Notes

- This is a hardware-only project and requires the BASYS 3 board to run  
- Designed as an academic digital systems engineering project  
- System behaviour depends on FPGA clock configuration and timing constraints  

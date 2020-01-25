# mimax-vm

> Not started working on this project, this is just a readme file for now.

Dies ist ein VM für die "mima-x" Architektur aus der GBI Vorlesung.

Die VM ist in [Nim](https://nim-lang.org) geschrieben, nicht in JavaScript wie ihr [Vorgänger](https://git.jannik.ml/mima-vm). Da Nim sowohl, C/C++ als auch JavaScript als compile target hat kann man leicht verschiedene frontends für die VM bauen. Es wird eine Webversion geben, welche einem erlaubt Assembly einzugeben und dieses auszuführen und dabei den State der VM zu debuggen. Diese Features sollten auch mit der Native-compilten Version funktionieren mit etwas Gluecode.

## Building

```sh
nimble build
./mimax-vm
```

## Mima-X

### Instructions

Die Mima-X Instructions sind zum größtenteil einfach Mima Instructions, aber es gibt einige neue, die Mima vorher nicht hatte.

Alte Instructions:
- LDC: a = arg
- LDV: a = mem[arg]
- STV: mem[arg] = a
- LDIV: a = mem[mem[arg]]
- STIV: mem[mem[arg]] = a
- ADD: a = a + mem[arg]
- AND: a = a & mem[arg]
- OR: a = a | mem[arg]
- XOR: a = a ^ mem[arg]
- NOT: a = ~a
- RAR: ...
- EQL: a = a == mem[arg] ? R1 : 0
- JMP: iar = arg
- JMN: iar = a == R1 ? mem[arg] : iar
- HALT: halt

Neue Instructions:
- CALL: ra = iar; iar = arg
- RET: iar = ra
- LDVR: a = mem[reg + arg] (Syntax: `LDVR <arg> (<reg>)`)
- STVR: mem[reg + arg] = a (Syntax: `STVR <arg> (<reg>)`)
- LDSP: a = sp
- STSP: sp = a
- ADC: a = a + arg


### Registers

- IR: Instruction Register
- RA: Return Address
- IAR: Instruction Address Register (PC)
- A: Accumulator
- 1: One (filled with all 1's)
- SP: Stack Pointer
- FP: Frame Pointer (callstack)
- SAR: Storage Address Register
- SDR: Storage Data Register
- X: X Register (ALU)
- Y: Y Register (ALU)
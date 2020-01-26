# mimax-vm

> **WIP**: Not anywhere near completion. Work hasn't even started on most things.

Dies ist ein VM für die "mima-x" Architektur aus der GBI Vorlesung.

Die VM ist in [Nim](https://nim-lang.org) geschrieben, nicht in JavaScript wie ihr [Vorgänger](https://git.jannik.ml/mima-vm). Da Nim sowohl, C/C++ als auch JavaScript als compile target hat kann man leicht verschiedene frontends für die VM bauen. Es wird eine Webversion geben, welche einem erlaubt Assembly einzugeben und dieses auszuführen und dabei den State der VM zu debuggen. Diese Features sollten auch mit der Native-compilten Version funktionieren mit etwas Gluecode.

## Compilen

```sh
nimble build
./mimax-vm
```

## Benutzung

**usage**: `mimax-vm <optional flags> <file>`

**flags**:
```
  -b, --bin           Use binary representation as input
  -c, --compile       Compile to binary representation
  -v, --version       Print version
  -d, --debug         Enable debugging features (breakpoints, stepping through code, ...)
  -D, --disassemble   Disassemble binary representation
```

## Mima-X

### Beispielcode

Programme können entweder als Binärdatei oder als Textdatei ausgeführt werden.

```x86
        ldc 7
        call %push
        
push:   stvr 0 (sp)   ; this pushes the value of the accumulator to the stack
        ldsp
        adc 1
        stsp
        ret

pop:    ldsp          ; this pops the top-most value of the stack
        adc -1
        stsp
        ret

top:    ldvr -1 (sp)  ; this loads the top-most value of the stack into the accumulator
        ret
```

Die `test.bin.mimax`-Datei ist eine Binärversion von `test.mimax`

Am besten erstellt man eine Binärdatei direkt mit mimax-vm mit der "-c"-flag (compile).

Ansonsten kann man auch selber Binärdateien mit einem Hexeditor erstellen, nur muss man dabei immer sehr viel aufpassen keine Fehler zu machen. Was einigermaßen gut funktioniert ist eine Kombination aus [xxd](https://linux.die.net/man/1/xxd) einem Editor:

1. `cat file.bin > xxd > file` um ein hexdump einer vorhandenen Datei zu erhalten
2. Datei mit Editor der Wahl editieren
3. `cat file > xxd -r > file.bin` um xxd zu sagen, dass er den hexdump wieder in eine Binärdatei umwandeln soll

Alternativ in vim: `:%!xxd` und dann `:%!xxd -r`

Was wichtig bei selbsterstellten Binärdateien ist, ist dass sie den korrekten Header haben, sie müssen mit `mimax\0` starten (das ist ein Nullterminator am Ende).

### Instructions

Die Mima-X Instructions sind zum größtenteil einfach Mima Instructions, aber es gibt einige neue, die Mima vorher nicht hatte.

Alte Instructions:
- LDC: `a = arg`
- LDV: `a = mem[arg]`
- STV: `mem[arg] = a`
- LDIV: `a = mem[mem[arg]]`
- STIV: `mem[mem[arg]] = a`
- ADD: `a = a + mem[arg]`
- AND: `a = a & mem[arg]`
- OR: `a = a | mem[arg]`
- XOR: `a = a ^ mem[arg]`
- NOT: `a = ~a`
- RAR: ` = a >> 1 (no zero-fill)`
- EQL: `a = a == mem[arg] ? R1 : 0`
- JMP: `iar = arg`
- JMN: `iar = a == R1 ? mem[arg] : iar`
- HALT: `halt`

Neue Instructions:
- CALL: `ra = iar; iar = arg`
- RET: `iar = ra`
- LDVR: `a = mem[memp[reg] + arg] (Syntax: `LDVR <arg> (<reg>)`)`
- STVR: `mem[mem[reg] + arg] = a (Syntax: `STVR <arg> (<reg>)`)`
- LDSP: `a = sp`
- STSP: `sp = a`
- ADC: `a = a + arg`


### Register

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

### Opcodes

> Opcodes für alle Instructions die Argumente haben

| opcode | mnemonic |
| ------ | -------- |
| `0x00` |   LDC    |
| `0x01` |   LDV    |
| `0x02` |   STV    |
| `0x03` |   ADD    |
| `0x04` |   AND    |
| `0x05` |   OR     |
| `0x06` |   XOR    |
| `0x07` |   EQL    |
| `0x08` |   JMP    |
| `0x09` |   JMN    |
| `0x0a` |   LDIV   |
| `0x0b` |   STIV   |
| `0x0c` |    ?     |
| `0x0d` |    ?     |
| `0x0e` |    -     |
| `0x0f` | extended op code |

Alle Instructions ohne Argumente teilen sich einen "*Prefix*" (`0x0f`). Der Prefix weißt also auf einen sogenannten "**extended OP-Code**" hin.

> Opcodes für alle Instructions ohne Argumente (incl. Prefix)

| opcode | mnemonic |
| ------ | -------- |
| `0xf0` |   HALT   |
| `0xf1` |   NOT    |
| `0xf2` |   RAR    |

> Das sind alle "offiziellen" op codes die man finden kann, alle anderen Instructions haben keine angaben / gibt es in der "original version" nicht (welche soweit ich weiß von 2004 ist). Eine kleine Ausnahme davon ist eventuell `call`, was vorher unter dem Namen `JMS` (jump to subroutine) bekannt war. (*)

Die fehlenden Opcodes sind:
- CALL*
- RET
- LDVR
- STVR
- LDSP
- STSP
- ADC

wobei `RET`, `LDSP` und `STSP` zu den extended op-codes gehören würden, da sie keine Argumente nehmen und `CALL`, `ADC` und alle Varianten von `LDVR` und `STVR` zu den normalen op codes gehören würden, was aber ein kleines Problem mit sich bringt: Es gibt nur 3 verbleibende Opcodes, also müsste man noch eine Kategorie an extended op-codes hinzufügen. Dafür würde sich eventuell `0x0e` anbieten.
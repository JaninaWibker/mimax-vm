# mimax-vm

> **WIP**: Not anywhere near completion.

Dies ist ein VM für die "mima-x" Architektur aus der GBI Vorlesung.

Die VM ist in [Nim](https://nim-lang.org) geschrieben, nicht in JavaScript wie ihr [Vorgänger](https://git.jannik.ml/mima-vm). Da Nim sowohl, C/C++ als auch JavaScript als compile target hat kann man leicht verschiedene frontends für die VM bauen. Es wird eine Webversion geben, welche einem erlaubt Assembly einzugeben und dieses auszuführen und dabei den State der VM zu debuggen. Diese Features sollten auch mit der Native-compilten Version funktionieren mit etwas Gluecode.

## Compilen

```sh
nimble build
./mimax-vm
```

## Benutzung

```
usage: mimax-vm <optional flags> <file>

flags:
  -b, --bin           Use binary representation as input
  -c, --compile       Compile to binary representation
  -v, --version       Print version
  -d, --debug         Enable debugging features (breakpoints, stepping through code, ...)
  -D, --disassemble   Disassemble binary representation
  -A, --alt-mima      Use slightly different mima instruction set
```

## Mima-X

### Beispielcode

Programme können entweder als Binärdatei oder als Textdatei ausgeführt werden.

```x86
        ldc 7
        call %push
        halt
        
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
| `0x0c` |  *CALL*  |
| `0x0d` |  *ADC*   |
| `0x0e` | *extended opcodes 2* |
| `0x0f` | extended opcodes 1 |

Alle Instructions ohne Argumente teilen sich einen "*Präfix*" (`0x0f`). Der Präfix weißt also auf einen sogenannten "**extended OP-Code**" hin. Zudem gibt es noch die Instructions mit dem Präfix `0x0e`, welche die verschiedenen Versionen von `LDVR` und `STVR` sind

> Opcodes für alle Instructions ohne Argumente (incl. Präfix)

| opcode | mnemonic |
| ------ | -------- |
| `0xf0` |   HALT   |
| `0xf1` |   NOT    |
| `0xf2` |   RAR    |
| `0xf3` |  *RET*   |
| `0xf4` |  *LDSP*  |
| `0xf5` |  *STSP*  |
| `0xf6` |  *LDFP*  |
| `0xf7` |  *STFP*  |
| `0xf8` |  *LDRA*  |
| `0xf9` |  *STRA*  |
|  ...   |    -     |

> Opcodes für alle Varianten von `LDVR` und `STVR`

| opcode | mnemonic    |
| ------ | ----------- |
| `0xe0` |  *LDVR*\*   |
| `0xe1` |     -       |
| `0xe2` |     -       |
| `0xe3` |     -       |
| `0xe4` |     -       |
| `0xe5` | *LDVR (RA)* |
| `0xe6` | *LDVR (SP)* |
| `0xe7` | *LDVR (FP)* |
| `0xe8` |  *STVR*\*   |
| `0xe9` |     -       |
| `0xea` |     -       |
| `0xeb` |     -       |
| `0xec` |     -       |
| `0xed` | *STVR (RA)* |
| `0xee` | *STVR (SP)* |
| `0xef` | *STVR (FP)* |

**\***: Intern benötigter Befehl, welcher aber nicht normal verwendbar ist, trotzdem gibt es, bzw. genau deshalb gibt es, einen zugeordneten Opcode.

> Die "offizielen" opcodes für sind normal geschrieben, die "inoffiziellen" in *kursiv*. Es gibt für viele Befehle Opcodes, aber nicht unbedingt für alle, für diese wurde dann ein sinnvoller Wert gewählt.
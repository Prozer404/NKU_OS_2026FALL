set pagination off
set confirm off
set architecture riscv:rv64
file bin/kernel
target remote localhost:1235
hbreak *0x80200000
continue
printf "BEFORE paging: pc=%#lx satp=%#lx\n", $pc, $satp
x/3i $pc
hbreak kern_init
continue
delete breakpoints
printf "AFTER paging: pc=%#lx satp=%#lx\n", $pc, $satp
set $root = (unsigned long long)&boot_page_table_sv39
set $root_pa = (($satp & 0xfffffffffff) << 12)
set $va = (unsigned long long)&kern_init
set $vpn2 = (($va >> 30) & 511)
set $pte = *(unsigned long long *)($root + 8 * $vpn2)
set $pa = (($pte >> 10) << 12) | ($va & 0x3fffffff)
printf "ROOT va=%#lx pa=%#lx\n", $root, $root_pa
printf "TRANSLATION va=%#lx vpn2=%lu pte=%#lx pa=%#lx\n", $va, $vpn2, $pte, $pa
printf "Root identity entry[2]:\n"
x/gx ($root + 16)
printf "Root high entry[511]:\n"
x/gx ($root + 4088)
printf "Instruction at virtual PC and identity alias:\n"
x/i $va
x/i $pa
if $root_pa != ($root - 0xffffffff40000000)
    quit 1
end
if $pte != 0x200000cf
    quit 1
end
if $pa != ($va - 0xffffffff40000000)
    quit 1
end
printf "[GDB] Sv39 root leaf translation: PASS\n"
python
import gdb
import re
pc = int(gdb.parse_and_eval('$pc'))
instructions = gdb.selected_frame().architecture().disassemble(pc, pc + 128)
selected = None
for insn in instructions:
    match = re.search(r'\bsd\s+(\w+),(-?\d+)\((\w+)\)', insn['asm'])
    if match:
        selected = (insn, match)
        break
if selected is None:
    raise gdb.GdbError('No sd instruction found in kern_init prologue')
insn, match = selected
gdb.execute('tbreak *%#x' % insn['addr'])
gdb.execute('continue')
source, displacement, base = match.groups()
mask = (1 << 64) - 1
va = (int(gdb.parse_and_eval('$' + base)) + int(displacement)) & mask
value = int(gdb.parse_and_eval('$' + source)) & mask
root = int(gdb.parse_and_eval('$root'))
inferior = gdb.selected_inferior()
pte = int.from_bytes(bytes(inferior.read_memory(root + ((va >> 30) & 511) * 8, 8)), 'little')
pa = ((pte >> 10) << 12) | (va & 0x3fffffff)
gdb.write('STORE %s at pc=%#x: va=%#x pte=%#x pa=%#x value=%#x\n' % (insn['asm'], insn['addr'], va, pte, pa, value))
if pa != (va - 0xffffffff40000000) & mask:
    raise gdb.GdbError('Store translation mismatch')
gdb.execute('stepi')
observed = int.from_bytes(bytes(inferior.read_memory(pa, 8)), 'little')
if observed != value:
    raise gdb.GdbError('Store result mismatch')
gdb.write('[GDB] sd effective address and stored physical bytes: PASS\n')
end
detach
quit

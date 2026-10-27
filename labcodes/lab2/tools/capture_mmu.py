"""Run guest GDB observation; does not claim host-QEMU source stepping."""
import subprocess
import time

with open('mmu-qemu.log', 'w') as log:
    qemu = subprocess.Popen([
        'qemu-system-riscv64', '-machine', 'virt', '-nographic',
        '-bios', 'default', '-kernel', 'bin/ucore.img',
        '-S', '-gdb', 'tcp:127.0.0.1:1235',
    ], stdout=log, stderr=subprocess.STDOUT)
    try:
        time.sleep(0.5)
        result = subprocess.run([
            'gdb-multiarch', '-batch', '-x', 'tools/mmu.gdb',
        ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=30)
        print(result.stdout)
        if result.returncode or '[GDB] Sv39 root leaf translation: PASS' not in result.stdout:
            raise SystemExit(result.returncode or 1)
    finally:
        qemu.terminate()
        qemu.wait(timeout=5)

# Lab2：物理内存和页表

实现目录保持在 `lab2/lab2_new`，没有覆盖 Lab1。

## 上传与运行

将本目录整体上传至 Linux 虚拟机，例如放在 `~/nku-os/labcodes/lab2`。进入该目录执行：

```sh
make clean
make -j2
make qemu
# 看完输出后按 Ctrl+A，再按 X 退出 QEMU
make grade
```

启动会依次执行 Best-Fit 原有检查、Buddy 自测、Buddy 上的 SLUB 自测，随后恢复 Best-Fit 并再次检查及执行 SLUB 自测。最后当前分配器为 Best-Fit。看到所有 PASS 后内核停留在正常的无限循环中，不会自动退出。

`make grade` 本次实际为 20/20；评分只覆盖页初始化与 Best-Fit，不代表 Buddy/SLUB 由官方评分覆盖。原评分脚本仅将启动方式改为 `-kernel` 以适配当前固件，未改变评分条件。

## 文件

- `实验报告2.md`：实现说明、全部思考题答案、测试与局限。
- `prompts/实现与测试Prompt.md`：六份实现/测试 Prompt 和两次启动兼容修复 Prompt。
- `kern/mm/pmm.c`：页描述符布局和物理空闲区初始化。
- `kern/mm/best_fit_pmm.c`：Best-Fit，保留两个原测试。
- `kern/mm/buddy_pmm.c/.h`：Buddy 和自测。
- `kern/mm/slub.c/.h`：简化 SLUB 和自测。
- `verification/`：真实构建、QEMU 运行、评分与 GDB 日志。
- `调试补充.md`：GDB 复现与 QEMU 源码调试步骤。

## GDB 地址翻译复现

需要 `gdb-multiarch`（含 Python 支持）和端口 1235 空闲：

```sh
make -j2
python3 tools/capture_mmu.py
```

脚本会启动自己的 QEMU，观察分页前后寄存器、根页表大页项，并执行一条实际 `sd` 指令检查物理别名中的写入结果，然后退出自己的 QEMU。没有重编译 QEMU，也没有模拟宿主机源码单步调试。

## 提交前核对

学号注释采用既有 Lab1 报告作者的 `2411156`，请根据实际小组分工核对。报告保留待填写的本次分工；没有编造分工或截图。提交时可将整个目录改名为 `lab2` 放入 `labcodes`。密码没有写入源码和报告。

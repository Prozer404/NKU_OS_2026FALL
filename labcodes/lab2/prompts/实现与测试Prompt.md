# Lab2 实现与测试 Prompt 记录

本文件在实现前建立，以下为本次实际采用的任务规格。AI 工具：Codex 桌面应用；模型：GPT-6（系统标识）。学号注释沿用既有报告作者 2411156，提交前请核对。

## 1. 物理内存初始化

[PROMPT]
在实际工程 kern/mm/pmm.c 的 lab2 function1 位置实现 page_init，保持其他框架和评分工具不变。保留 lab2 标记，将 YOUR CODE 标记为 2411156。不得硬编码空闲页数。

[RELY]
以工程 pmm.h、memlayout.h、dtb.h、mmu.h 为准。设备树接口 get_memory_base/get_memory_size；DRAM_BASE、PHYSICAL_MEMORY_END、PHYSICAL_MEMORY_OFFSET、PGSIZE；pages/npage/nbase/va_pa_offset；PADDR、pa2page、SetPageReserved、init_memmap；链接符号 end。

[GUARANTEE]
实现 static void page_init(void)，默认接入 best_fit_pmm_manager。

[SPECIFICATION]
Pre-Condition：设备树已解析，管理器 init 已执行，启动分页已开启。
Post-Condition：先设置地址偏移，验证设备树起点、长度、加法溢出和框架固定 DRAM 基址，内存上界截断到框架支持范围并向下对齐；npage 是物理页号上界而非页数。Page 数组从 end 向上对齐处开始，必须在写入描述符前验证整个数组位于可管理内存中。初始化所有描述符为 reserved、零引用、零 property；仅将数组结束之后按页对齐的完整页交给管理器。无效信息 panic，没有完整空闲页则不调用 init_memmap。输出实际探测范围和管理范围。

## 2. Best-Fit

[PROMPT]
参考 default_pmm.c 实现完整 best_fit_pmm.c，保留 basic_check/best_fit_check 的原文；实现管理器注册并在 pmm.c 中默认选用。

[RELY]
struct pmm_manager、free_area_t、Page、list.h 和现有两个测试的状态约定；测试直接引用 free_list、nr_free。

[GUARANTEE]
init/init_memmap/alloc_pages/free_pages/nr_free_pages 及 best_fit_pmm_manager，check 指向原 best_fit_check。

[SPECIFICATION]
Pre-Condition：分配/释放 n>0，释放区间由调用方合法持有。
Post-Condition：空闲块按物理地址排序；分配选择最小的足够大块，同大小选低地址，必要时拆分；释放后合并前后相邻块。维护 nr_free、块头 property、PageProperty 与零引用；分配失败返回 NULL 且状态不变。允许释放此前连续持有的若干相邻分配区间，兼容现有测试。算法不要求复杂度优化。

## 3. Buddy 实现 Prompt

[PROMPT]
新增 buddy_pmm.c/.h，实现无动态元数据分配的伙伴系统，接入现有 pmm_manager。默认启动先检查 Best-Fit，再重新初始化物理内存检查 Buddy，完成后恢复 Best-Fit。切换必须在无存活分配和无 SLUB 缓存时进行。

[RELY]
现有 Page 数组、page2ppn、nbase/npage、list.h；使用独立分阶链表和 Page 空闲块头标记，不改变 Page 结构和原有测试。

[GUARANTEE]
buddy_pmm_manager 完整接口；支持原请求页数释放；实际占用向上取整至二次幂。

[SPECIFICATION]
初始化任意页数区间时拆成按绝对物理页号对齐的二次幂块，不越界。分配查找足够阶并递归拆分，记录分配头和实际大小；空闲页数按实际占用扣除。释放验证头和阶，伙伴号通过绝对 PPN 异或块大小计算，只合并同阶且空闲的真正伙伴。不能用普通相邻关系代替伙伴关系。超大请求返回 NULL；拒绝零请求。文档说明不支持任意拆分释放和非法指针释放。

## 4. Buddy 测试 Prompt

[PROMPT]
为上述 Buddy 设计独立 check，不复用 Best-Fit 的精确页数假设，加入真实物理页分配及独立小型描述符场景，使用 assert 验证结果，不修改评分工具。

[RELY]
Buddy 的内部链表与管理函数，Page 结构；现有内核无需 libc 的断言工具。

[GUARANTEE]
启动自动执行；测试退出时所有页回收，空闲总量与初值一致。

[SPECIFICATION]
覆盖 1/3/5 页请求及实际取整计数、不重叠、失败状态不变、伙伴合并、相邻非伙伴不能错误合并、不规则起点和长度、分配耗尽与回收。检查所有空闲链表的块尺寸、绝对 PPN 对齐及总量。小型隔离场景不得污染真实 Page 描述符和管理器全局状态。

## 5. SLUB 实现 Prompt

[PROMPT]
新增 slub.c/.h，实现体现缓存、slab 和对象空闲链表的简化 SLUB；底层使用当前 alloc_pages/free_pages。单核启动自测，无并发要求。

[RELY]
PGSIZE、PADDR、page2pa、pa2page、va_pa_offset、list.h；页分配器可能是 Best-Fit 或 Buddy。

[GUARANTEE]
void *kmalloc(size_t)、void kfree(void *)、void slub_check(void)。固定大小类 16 到 2048 字节；大对象使用连续页；slab 头记录归属、对象数、页数及类型。

[SPECIFICATION]
返回至少 16 字节对齐的对象。0 和超出上限请求返回 NULL；kfree(NULL) 无操作；小对象来自单页 slab，对象空闲链表内嵌对象；用 partial 链表寻找有空闲对象的 slab，满 slab 移出，重新出现空闲对象时加回。最后一个对象释放后归还整页。大对象包含头部，记录原始请求页数以兼容 Buddy 的取整释放。防止大小运算溢出。非法释放不属于接口契约，但可检出的非对象起点和重复释放应断言。明确这是教学简化版，非 Linux 完整 SLUB。

## 6. SLUB 测试 Prompt

[PROMPT]
为上述 SLUB 编写内核自测，分别在 Buddy 和 Best-Fit 下运行。不要只检查非空指针，要写入与核对数据，并检查底层空闲页恢复。

[RELY]
kmalloc/kfree、nr_free_pages、assert、memset。测试指针数组必须使用静态存储，避免耗尽内核 8KiB 栈。

[GUARANTEE]
slub_check 覆盖全部大小类和边界、跨 slab、释放复用、大对象以及失败路径，结束无存活缓存和对象。

[SPECIFICATION]
覆盖 0、16/17、32/33 等大小边界，2048/2049、大于一页请求、最大整数失败；检查对齐、各对象数据独立保持、逆序/交错释放、部分释放后分配、多个 slab、NULL 释放。全部释放后 nr_free_pages 恢复初值。失败请求不消耗页面。

## 验证后补充 Prompt：固件启动兼容

实测 OpenSBI 1.3 在原 -device loader 启动方式下 Next Address 为 0，未进入内核。请仅将 Makefile 的 qemu/debug/test 启动参数以及 tools/grade.sh 的对应启动参数换为标准 -kernel 镜像方式；评分断言、分数、注入逻辑和 Best-Fit 原测试必须保持不变。修复后重新编译、运行自测和 make grade。

## 验证后补充 Prompt：分页切换取指异常

QEMU 8.2.2 异常日志显示 csrw satp 后在低地址 0x80200038 发生 exec_page_fault。反汇编和 entry.S 表明根页表只映射高地址，当前低地址 PC 尚未跳转。请在根页表索引 2 添加 0x80000000 起的 1GiB 恒等映射，保留索引 511 的高地址映射，页表仍为 512 项且 4KiB 对齐。解释这是启动过渡映射，不是用户态隔离方案。重新验证。

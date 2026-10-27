
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0205ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	7c450513          	addi	a0,a0,1988 # ffffffffc0202810 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	7ce50513          	addi	a0,a0,1998 # ffffffffc0202830 <etext+0x26>
ffffffffc020006a:	0e0000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	79c58593          	addi	a1,a1,1948 # ffffffffc020280a <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	7da50513          	addi	a0,a0,2010 # ffffffffc0202850 <etext+0x46>
ffffffffc020007e:	0cc000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00007597          	auipc	a1,0x7
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0207018 <free_area>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	7e650513          	addi	a0,a0,2022 # ffffffffc0202870 <etext+0x66>
ffffffffc0200092:	0b8000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00008597          	auipc	a1,0x8
ffffffffc020009a:	c9658593          	addi	a1,a1,-874 # ffffffffc0207d2c <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	7f250513          	addi	a0,a0,2034 # ffffffffc0202890 <etext+0x86>
ffffffffc02000a6:	0a4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00008797          	auipc	a5,0x8
ffffffffc02000ae:	08178793          	addi	a5,a5,129 # ffffffffc020812b <end+0x3ff>
ffffffffc02000b2:	00000717          	auipc	a4,0x0
ffffffffc02000b6:	02470713          	addi	a4,a4,36 # ffffffffc02000d6 <kern_init>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00002517          	auipc	a0,0x2
ffffffffc02000ce:	7e650513          	addi	a0,a0,2022 # ffffffffc02028b0 <etext+0xa6>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a89d                	j	ffffffffc020014a <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00007517          	auipc	a0,0x7
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0207018 <free_area>
ffffffffc02000de:	00008617          	auipc	a2,0x8
ffffffffc02000e2:	c4e60613          	addi	a2,a2,-946 # ffffffffc0207d2c <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	70a020ef          	jal	ffffffffc02027f8 <memset>
    dtb_init();
ffffffffc02000f2:	13a000ef          	jal	ffffffffc020022c <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	12c000ef          	jal	ffffffffc0200222 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00003517          	auipc	a0,0x3
ffffffffc02000fe:	48650513          	addi	a0,a0,1158 # ffffffffc0203580 <etext+0xd76>
ffffffffc0200102:	07c000ef          	jal	ffffffffc020017e <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	223010ef          	jal	ffffffffc0201b2c <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1141                	addi	sp,sp,-16
ffffffffc0200112:	e022                	sd	s0,0(sp)
ffffffffc0200114:	e406                	sd	ra,8(sp)
ffffffffc0200116:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200118:	10c000ef          	jal	ffffffffc0200224 <cons_putc>
    (*cnt) ++;
ffffffffc020011c:	401c                	lw	a5,0(s0)
}
ffffffffc020011e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c01c                	sw	a5,0(s0)
}
ffffffffc0200124:	6402                	ld	s0,0(sp)
ffffffffc0200126:	0141                	addi	sp,sp,16
ffffffffc0200128:	8082                	ret

ffffffffc020012a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012a:	1101                	addi	sp,sp,-32
ffffffffc020012c:	862a                	mv	a2,a0
ffffffffc020012e:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200130:	00000517          	auipc	a0,0x0
ffffffffc0200134:	fe050513          	addi	a0,a0,-32 # ffffffffc0200110 <cputch>
ffffffffc0200138:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013a:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013c:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013e:	290020ef          	jal	ffffffffc02023ce <vprintfmt>
    return cnt;
}
ffffffffc0200142:	60e2                	ld	ra,24(sp)
ffffffffc0200144:	4532                	lw	a0,12(sp)
ffffffffc0200146:	6105                	addi	sp,sp,32
ffffffffc0200148:	8082                	ret

ffffffffc020014a <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014a:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014c:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc0200150:	f42e                	sd	a1,40(sp)
ffffffffc0200152:	f832                	sd	a2,48(sp)
ffffffffc0200154:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200156:	862a                	mv	a2,a0
ffffffffc0200158:	004c                	addi	a1,sp,4
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb650513          	addi	a0,a0,-74 # ffffffffc0200110 <cputch>
ffffffffc0200162:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200164:	ec06                	sd	ra,24(sp)
ffffffffc0200166:	e0ba                	sd	a4,64(sp)
ffffffffc0200168:	e4be                	sd	a5,72(sp)
ffffffffc020016a:	e8c2                	sd	a6,80(sp)
ffffffffc020016c:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020016e:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200170:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200172:	25c020ef          	jal	ffffffffc02023ce <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200176:	60e2                	ld	ra,24(sp)
ffffffffc0200178:	4512                	lw	a0,4(sp)
ffffffffc020017a:	6125                	addi	sp,sp,96
ffffffffc020017c:	8082                	ret

ffffffffc020017e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017e:	1101                	addi	sp,sp,-32
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	e822                	sd	s0,16(sp)
ffffffffc0200184:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200186:	00054503          	lbu	a0,0(a0)
ffffffffc020018a:	c905                	beqz	a0,ffffffffc02001ba <cputs+0x3c>
ffffffffc020018c:	e426                	sd	s1,8(sp)
ffffffffc020018e:	00178493          	addi	s1,a5,1
ffffffffc0200192:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc0200194:	090000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200198:	00044503          	lbu	a0,0(s0)
ffffffffc020019c:	87a2                	mv	a5,s0
ffffffffc020019e:	0405                	addi	s0,s0,1
ffffffffc02001a0:	f975                	bnez	a0,ffffffffc0200194 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a2:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc02001a4:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a6:	0027841b          	addiw	s0,a5,2
ffffffffc02001aa:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001ac:	078000ef          	jal	ffffffffc0200224 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b0:	60e2                	ld	ra,24(sp)
ffffffffc02001b2:	8522                	mv	a0,s0
ffffffffc02001b4:	6442                	ld	s0,16(sp)
ffffffffc02001b6:	6105                	addi	sp,sp,32
ffffffffc02001b8:	8082                	ret
    cons_putc(c);
ffffffffc02001ba:	4529                	li	a0,10
ffffffffc02001bc:	068000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001c0:	4405                	li	s0,1
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	8522                	mv	a0,s0
ffffffffc02001c6:	6442                	ld	s0,16(sp)
ffffffffc02001c8:	6105                	addi	sp,sp,32
ffffffffc02001ca:	8082                	ret

ffffffffc02001cc <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001cc:	00008317          	auipc	t1,0x8
ffffffffc02001d0:	b0c30313          	addi	t1,t1,-1268 # ffffffffc0207cd8 <is_panic>
ffffffffc02001d4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d8:	715d                	addi	sp,sp,-80
ffffffffc02001da:	ec06                	sd	ra,24(sp)
ffffffffc02001dc:	f436                	sd	a3,40(sp)
ffffffffc02001de:	f83a                	sd	a4,48(sp)
ffffffffc02001e0:	fc3e                	sd	a5,56(sp)
ffffffffc02001e2:	e0c2                	sd	a6,64(sp)
ffffffffc02001e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e6:	000e0363          	beqz	t3,ffffffffc02001ec <__panic+0x20>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001ea:	a001                	j	ffffffffc02001ea <__panic+0x1e>
    is_panic = 1;
ffffffffc02001ec:	4785                	li	a5,1
ffffffffc02001ee:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001f2:	e822                	sd	s0,16(sp)
ffffffffc02001f4:	103c                	addi	a5,sp,40
ffffffffc02001f6:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f8:	862e                	mv	a2,a1
ffffffffc02001fa:	85aa                	mv	a1,a0
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	6e450513          	addi	a0,a0,1764 # ffffffffc02028e0 <etext+0xd6>
    va_start(ap, fmt);
ffffffffc0200204:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200206:	f45ff0ef          	jal	ffffffffc020014a <cprintf>
    vcprintf(fmt, ap);
ffffffffc020020a:	65a2                	ld	a1,8(sp)
ffffffffc020020c:	8522                	mv	a0,s0
ffffffffc020020e:	f1dff0ef          	jal	ffffffffc020012a <vcprintf>
    cprintf("\n");
ffffffffc0200212:	00002517          	auipc	a0,0x2
ffffffffc0200216:	6ee50513          	addi	a0,a0,1774 # ffffffffc0202900 <etext+0xf6>
ffffffffc020021a:	f31ff0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc020021e:	6442                	ld	s0,16(sp)
ffffffffc0200220:	b7e9                	j	ffffffffc02001ea <__panic+0x1e>

ffffffffc0200222 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200222:	8082                	ret

ffffffffc0200224 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200224:	0ff57513          	zext.b	a0,a0
ffffffffc0200228:	5200206f          	j	ffffffffc0202748 <sbi_console_putchar>

ffffffffc020022c <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020022c:	711d                	addi	sp,sp,-96
    cprintf("DTB Init\n");
ffffffffc020022e:	00002517          	auipc	a0,0x2
ffffffffc0200232:	6da50513          	addi	a0,a0,1754 # ffffffffc0202908 <etext+0xfe>
void dtb_init(void) {
ffffffffc0200236:	ec86                	sd	ra,88(sp)
ffffffffc0200238:	e8a2                	sd	s0,80(sp)
    cprintf("DTB Init\n");
ffffffffc020023a:	f11ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023e:	00007597          	auipc	a1,0x7
ffffffffc0200242:	dc25b583          	ld	a1,-574(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200246:	00002517          	auipc	a0,0x2
ffffffffc020024a:	6d250513          	addi	a0,a0,1746 # ffffffffc0202918 <etext+0x10e>
ffffffffc020024e:	efdff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200252:	00007417          	auipc	s0,0x7
ffffffffc0200256:	db640413          	addi	s0,s0,-586 # ffffffffc0207008 <boot_dtb>
ffffffffc020025a:	600c                	ld	a1,0(s0)
ffffffffc020025c:	00002517          	auipc	a0,0x2
ffffffffc0200260:	6cc50513          	addi	a0,a0,1740 # ffffffffc0202928 <etext+0x11e>
ffffffffc0200264:	ee7ff0ef          	jal	ffffffffc020014a <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200268:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026a:	00002517          	auipc	a0,0x2
ffffffffc020026e:	6d650513          	addi	a0,a0,1750 # ffffffffc0202940 <etext+0x136>
    if (boot_dtb == 0) {
ffffffffc0200272:	12070d63          	beqz	a4,ffffffffc02003ac <dtb_init+0x180>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200276:	57f5                	li	a5,-3
ffffffffc0200278:	07fa                	slli	a5,a5,0x1e
ffffffffc020027a:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020027c:	431c                	lw	a5,0(a4)
ffffffffc020027e:	f456                	sd	s5,40(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200280:	00ff0637          	lui	a2,0xff0
ffffffffc0200284:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200288:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028c:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200290:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200294:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200298:	6ac1                	lui	s5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029a:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029c:	8ec9                	or	a3,a3,a0
ffffffffc020029e:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002a2:	1afd                	addi	s5,s5,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc02002a4:	0157f7b3          	and	a5,a5,s5
ffffffffc02002a8:	8dd5                	or	a1,a1,a3
ffffffffc02002aa:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002ac:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b0:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002b2:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed81c1>
ffffffffc02002b6:	0ef59f63          	bne	a1,a5,ffffffffc02003b4 <dtb_init+0x188>
ffffffffc02002ba:	471c                	lw	a5,8(a4)
ffffffffc02002bc:	4754                	lw	a3,12(a4)
ffffffffc02002be:	fc4e                	sd	s3,56(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c0:	0087d99b          	srliw	s3,a5,0x8
ffffffffc02002c4:	0086d41b          	srliw	s0,a3,0x8
ffffffffc02002c8:	0186951b          	slliw	a0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002cc:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d0:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d4:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002dc:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e0:	0109999b          	slliw	s3,s3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e4:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e8:	8c71                	and	s0,s0,a2
ffffffffc02002ea:	00c9f9b3          	and	s3,s3,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	01156533          	or	a0,a0,a7
ffffffffc02002f2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002f6:	0105e633          	or	a2,a1,a6
ffffffffc02002fa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002fe:	8c49                	or	s0,s0,a0
ffffffffc0200300:	0156f6b3          	and	a3,a3,s5
ffffffffc0200304:	00c9e9b3          	or	s3,s3,a2
ffffffffc0200308:	0157f7b3          	and	a5,a5,s5
ffffffffc020030c:	8c55                	or	s0,s0,a3
ffffffffc020030e:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200312:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200314:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200316:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200318:	0209d993          	srli	s3,s3,0x20
ffffffffc020031c:	e4a6                	sd	s1,72(sp)
ffffffffc020031e:	e0ca                	sd	s2,64(sp)
ffffffffc0200320:	ec5e                	sd	s7,24(sp)
ffffffffc0200322:	e862                	sd	s8,16(sp)
ffffffffc0200324:	e466                	sd	s9,8(sp)
ffffffffc0200326:	e06a                	sd	s10,0(sp)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200328:	f852                	sd	s4,48(sp)
    int in_memory_node = 0;
ffffffffc020032a:	4b81                	li	s7,0
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020032c:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020032e:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200330:	00ff0cb7          	lui	s9,0xff0
        switch (token) {
ffffffffc0200334:	4c0d                	li	s8,3
ffffffffc0200336:	4911                	li	s2,4
ffffffffc0200338:	4d05                	li	s10,1
ffffffffc020033a:	4489                	li	s1,2
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033c:	0009a703          	lw	a4,0(s3)
ffffffffc0200340:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200344:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200348:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020034c:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200350:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200354:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200358:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0196f6b3          	and	a3,a3,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200362:	8fd5                	or	a5,a5,a3
ffffffffc0200364:	00eaf733          	and	a4,s5,a4
ffffffffc0200368:	8fd9                	or	a5,a5,a4
ffffffffc020036a:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020036c:	09878263          	beq	a5,s8,ffffffffc02003f0 <dtb_init+0x1c4>
ffffffffc0200370:	00fc6963          	bltu	s8,a5,ffffffffc0200382 <dtb_init+0x156>
ffffffffc0200374:	05a78963          	beq	a5,s10,ffffffffc02003c6 <dtb_init+0x19a>
ffffffffc0200378:	00979763          	bne	a5,s1,ffffffffc0200386 <dtb_init+0x15a>
ffffffffc020037c:	4b81                	li	s7,0
ffffffffc020037e:	89d2                	mv	s3,s4
ffffffffc0200380:	bf75                	j	ffffffffc020033c <dtb_init+0x110>
ffffffffc0200382:	ff278ee3          	beq	a5,s2,ffffffffc020037e <dtb_init+0x152>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200386:	00002517          	auipc	a0,0x2
ffffffffc020038a:	68250513          	addi	a0,a0,1666 # ffffffffc0202a08 <etext+0x1fe>
ffffffffc020038e:	dbdff0ef          	jal	ffffffffc020014a <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200392:	64a6                	ld	s1,72(sp)
ffffffffc0200394:	6906                	ld	s2,64(sp)
ffffffffc0200396:	79e2                	ld	s3,56(sp)
ffffffffc0200398:	7a42                	ld	s4,48(sp)
ffffffffc020039a:	7aa2                	ld	s5,40(sp)
ffffffffc020039c:	6be2                	ld	s7,24(sp)
ffffffffc020039e:	6c42                	ld	s8,16(sp)
ffffffffc02003a0:	6ca2                	ld	s9,8(sp)
ffffffffc02003a2:	6d02                	ld	s10,0(sp)
ffffffffc02003a4:	00002517          	auipc	a0,0x2
ffffffffc02003a8:	69c50513          	addi	a0,a0,1692 # ffffffffc0202a40 <etext+0x236>
}
ffffffffc02003ac:	6446                	ld	s0,80(sp)
ffffffffc02003ae:	60e6                	ld	ra,88(sp)
ffffffffc02003b0:	6125                	addi	sp,sp,96
    cprintf("DTB init completed\n");
ffffffffc02003b2:	bb61                	j	ffffffffc020014a <cprintf>
}
ffffffffc02003b4:	6446                	ld	s0,80(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003b6:	7aa2                	ld	s5,40(sp)
}
ffffffffc02003b8:	60e6                	ld	ra,88(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003ba:	00002517          	auipc	a0,0x2
ffffffffc02003be:	5a650513          	addi	a0,a0,1446 # ffffffffc0202960 <etext+0x156>
}
ffffffffc02003c2:	6125                	addi	sp,sp,96
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003c4:	b359                	j	ffffffffc020014a <cprintf>
                int name_len = strlen(name);
ffffffffc02003c6:	8552                	mv	a0,s4
ffffffffc02003c8:	39a020ef          	jal	ffffffffc0202762 <strlen>
ffffffffc02003cc:	89aa                	mv	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003ce:	4619                	li	a2,6
ffffffffc02003d0:	00002597          	auipc	a1,0x2
ffffffffc02003d4:	5b858593          	addi	a1,a1,1464 # ffffffffc0202988 <etext+0x17e>
ffffffffc02003d8:	8552                	mv	a0,s4
                int name_len = strlen(name);
ffffffffc02003da:	2981                	sext.w	s3,s3
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003dc:	3f4020ef          	jal	ffffffffc02027d0 <strncmp>
ffffffffc02003e0:	e111                	bnez	a0,ffffffffc02003e4 <dtb_init+0x1b8>
                    in_memory_node = 1;
ffffffffc02003e2:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e4:	0a11                	addi	s4,s4,4
ffffffffc02003e6:	9a4e                	add	s4,s4,s3
ffffffffc02003e8:	ffca7a13          	andi	s4,s4,-4
        switch (token) {
ffffffffc02003ec:	89d2                	mv	s3,s4
ffffffffc02003ee:	b7b9                	j	ffffffffc020033c <dtb_init+0x110>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f0:	0049a783          	lw	a5,4(s3)
ffffffffc02003f4:	f05a                	sd	s6,32(sp)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f6:	0089a683          	lw	a3,8(s3)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003fa:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02003fe:	01879b1b          	slliw	s6,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200402:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200406:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020040a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020040e:	00cb6b33          	or	s6,s6,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200412:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200416:	0087979b          	slliw	a5,a5,0x8
ffffffffc020041a:	00eb6b33          	or	s6,s6,a4
ffffffffc020041e:	00faf7b3          	and	a5,s5,a5
ffffffffc0200422:	00fb6b33          	or	s6,s6,a5
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200426:	00c98a13          	addi	s4,s3,12
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020042a:	2b01                	sext.w	s6,s6
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042c:	000b9c63          	bnez	s7,ffffffffc0200444 <dtb_init+0x218>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200430:	1b02                	slli	s6,s6,0x20
ffffffffc0200432:	020b5b13          	srli	s6,s6,0x20
ffffffffc0200436:	0a0d                	addi	s4,s4,3
ffffffffc0200438:	9a5a                	add	s4,s4,s6
ffffffffc020043a:	ffca7a13          	andi	s4,s4,-4
                break;
ffffffffc020043e:	7b02                	ld	s6,32(sp)
        switch (token) {
ffffffffc0200440:	89d2                	mv	s3,s4
ffffffffc0200442:	bded                	j	ffffffffc020033c <dtb_init+0x110>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200444:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200448:	0186979b          	slliw	a5,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020044c:	0186d71b          	srliw	a4,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200450:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200454:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200458:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020045c:	8fd9                	or	a5,a5,a4
ffffffffc020045e:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200462:	8d5d                	or	a0,a0,a5
ffffffffc0200464:	00daf6b3          	and	a3,s5,a3
ffffffffc0200468:	8d55                	or	a0,a0,a3
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020046a:	1502                	slli	a0,a0,0x20
ffffffffc020046c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020046e:	00002597          	auipc	a1,0x2
ffffffffc0200472:	52258593          	addi	a1,a1,1314 # ffffffffc0202990 <etext+0x186>
ffffffffc0200476:	9522                	add	a0,a0,s0
ffffffffc0200478:	320020ef          	jal	ffffffffc0202798 <strcmp>
ffffffffc020047c:	f955                	bnez	a0,ffffffffc0200430 <dtb_init+0x204>
ffffffffc020047e:	47bd                	li	a5,15
ffffffffc0200480:	fb67f8e3          	bgeu	a5,s6,ffffffffc0200430 <dtb_init+0x204>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200484:	00c9b783          	ld	a5,12(s3)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200488:	0149b703          	ld	a4,20(s3)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020048c:	00002517          	auipc	a0,0x2
ffffffffc0200490:	50c50513          	addi	a0,a0,1292 # ffffffffc0202998 <etext+0x18e>
           fdt32_to_cpu(x >> 32);
ffffffffc0200494:	4207d693          	srai	a3,a5,0x20
ffffffffc0200498:	42075813          	srai	a6,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020049c:	0187d39b          	srliw	t2,a5,0x18
ffffffffc02004a0:	0186d29b          	srliw	t0,a3,0x18
ffffffffc02004a4:	01875f9b          	srliw	t6,a4,0x18
ffffffffc02004a8:	01885f1b          	srliw	t5,a6,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ac:	0087d49b          	srliw	s1,a5,0x8
ffffffffc02004b0:	0087541b          	srliw	s0,a4,0x8
ffffffffc02004b4:	01879e9b          	slliw	t4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0107d59b          	srliw	a1,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004bc:	01869e1b          	slliw	t3,a3,0x18
ffffffffc02004c0:	0187131b          	slliw	t1,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107561b          	srliw	a2,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0188189b          	slliw	a7,a6,0x18
ffffffffc02004cc:	83e1                	srli	a5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	8361                	srli	a4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d4:	0108581b          	srliw	a6,a6,0x10
ffffffffc02004d8:	005e6e33          	or	t3,t3,t0
ffffffffc02004dc:	01e8e8b3          	or	a7,a7,t5
ffffffffc02004e0:	0088181b          	slliw	a6,a6,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e4:	0104949b          	slliw	s1,s1,0x10
ffffffffc02004e8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	0085959b          	slliw	a1,a1,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	0086969b          	slliw	a3,a3,0x8
ffffffffc02004f8:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fc:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	00daf6b3          	and	a3,s5,a3
ffffffffc0200504:	007eeeb3          	or	t4,t4,t2
ffffffffc0200508:	01f36333          	or	t1,t1,t6
ffffffffc020050c:	01c7e7b3          	or	a5,a5,t3
ffffffffc0200510:	00caf633          	and	a2,s5,a2
ffffffffc0200514:	01176733          	or	a4,a4,a7
ffffffffc0200518:	00baf5b3          	and	a1,s5,a1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020051c:	0194f4b3          	and	s1,s1,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200520:	010afab3          	and	s5,s5,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	01947433          	and	s0,s0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200528:	01d4e4b3          	or	s1,s1,t4
ffffffffc020052c:	00646433          	or	s0,s0,t1
ffffffffc0200530:	8fd5                	or	a5,a5,a3
ffffffffc0200532:	01576733          	or	a4,a4,s5
ffffffffc0200536:	8c51                	or	s0,s0,a2
ffffffffc0200538:	8ccd                	or	s1,s1,a1
           fdt32_to_cpu(x >> 32);
ffffffffc020053a:	1782                	slli	a5,a5,0x20
ffffffffc020053c:	1702                	slli	a4,a4,0x20
ffffffffc020053e:	9381                	srli	a5,a5,0x20
ffffffffc0200540:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200542:	1482                	slli	s1,s1,0x20
ffffffffc0200544:	1402                	slli	s0,s0,0x20
ffffffffc0200546:	8cdd                	or	s1,s1,a5
ffffffffc0200548:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020054a:	c01ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020054e:	85a6                	mv	a1,s1
ffffffffc0200550:	00002517          	auipc	a0,0x2
ffffffffc0200554:	46850513          	addi	a0,a0,1128 # ffffffffc02029b8 <etext+0x1ae>
ffffffffc0200558:	bf3ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020055c:	01445613          	srli	a2,s0,0x14
ffffffffc0200560:	85a2                	mv	a1,s0
ffffffffc0200562:	00002517          	auipc	a0,0x2
ffffffffc0200566:	46e50513          	addi	a0,a0,1134 # ffffffffc02029d0 <etext+0x1c6>
ffffffffc020056a:	be1ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020056e:	009405b3          	add	a1,s0,s1
ffffffffc0200572:	15fd                	addi	a1,a1,-1
ffffffffc0200574:	00002517          	auipc	a0,0x2
ffffffffc0200578:	47c50513          	addi	a0,a0,1148 # ffffffffc02029f0 <etext+0x1e6>
ffffffffc020057c:	bcfff0ef          	jal	ffffffffc020014a <cprintf>
        memory_base = mem_base;
ffffffffc0200580:	7b02                	ld	s6,32(sp)
ffffffffc0200582:	00007797          	auipc	a5,0x7
ffffffffc0200586:	7697b323          	sd	s1,1894(a5) # ffffffffc0207ce8 <memory_base>
        memory_size = mem_size;
ffffffffc020058a:	00007797          	auipc	a5,0x7
ffffffffc020058e:	7487bb23          	sd	s0,1878(a5) # ffffffffc0207ce0 <memory_size>
ffffffffc0200592:	b501                	j	ffffffffc0200392 <dtb_init+0x166>

ffffffffc0200594 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200594:	00007517          	auipc	a0,0x7
ffffffffc0200598:	75453503          	ld	a0,1876(a0) # ffffffffc0207ce8 <memory_base>
ffffffffc020059c:	8082                	ret

ffffffffc020059e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc020059e:	00007517          	auipc	a0,0x7
ffffffffc02005a2:	74253503          	ld	a0,1858(a0) # ffffffffc0207ce0 <memory_size>
ffffffffc02005a6:	8082                	ret

ffffffffc02005a8 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005a8:	00007797          	auipc	a5,0x7
ffffffffc02005ac:	a7078793          	addi	a5,a5,-1424 # ffffffffc0207018 <free_area>
ffffffffc02005b0:	e79c                	sd	a5,8(a5)
ffffffffc02005b2:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005b4:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005b8:	8082                	ret

ffffffffc02005ba <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005ba:	00007517          	auipc	a0,0x7
ffffffffc02005be:	a6e56503          	lwu	a0,-1426(a0) # ffffffffc0207028 <free_area+0x10>
ffffffffc02005c2:	8082                	ret

ffffffffc02005c4 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02005c4:	c179                	beqz	a0,ffffffffc020068a <best_fit_alloc_pages+0xc6>
    if (n > nr_free) {
ffffffffc02005c6:	00007597          	auipc	a1,0x7
ffffffffc02005ca:	a5258593          	addi	a1,a1,-1454 # ffffffffc0207018 <free_area>
ffffffffc02005ce:	0105a883          	lw	a7,16(a1)
ffffffffc02005d2:	862a                	mv	a2,a0
ffffffffc02005d4:	02089793          	slli	a5,a7,0x20
ffffffffc02005d8:	9381                	srli	a5,a5,0x20
ffffffffc02005da:	04a7ee63          	bltu	a5,a0,ffffffffc0200636 <best_fit_alloc_pages+0x72>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005de:	659c                	ld	a5,8(a1)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005e0:	04b78b63          	beq	a5,a1,ffffffffc0200636 <best_fit_alloc_pages+0x72>
    struct Page *page = NULL;
ffffffffc02005e4:	4501                	li	a0,0
        if (p->property >= n && (page == NULL || p->property < page->property)) {
ffffffffc02005e6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02005ea:	02071693          	slli	a3,a4,0x20
ffffffffc02005ee:	9281                	srli	a3,a3,0x20
ffffffffc02005f0:	02c6ef63          	bltu	a3,a2,ffffffffc020062e <best_fit_alloc_pages+0x6a>
ffffffffc02005f4:	ed19                	bnez	a0,ffffffffc0200612 <best_fit_alloc_pages+0x4e>
        struct Page *p = le2page(le, page_link);
ffffffffc02005f6:	fe878513          	addi	a0,a5,-24
            if (p->property == n) {
ffffffffc02005fa:	04d60063          	beq	a2,a3,ffffffffc020063a <best_fit_alloc_pages+0x76>
ffffffffc02005fe:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200600:	02b78d63          	beq	a5,a1,ffffffffc020063a <best_fit_alloc_pages+0x76>
        if (p->property >= n && (page == NULL || p->property < page->property)) {
ffffffffc0200604:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200608:	02071693          	slli	a3,a4,0x20
ffffffffc020060c:	9281                	srli	a3,a3,0x20
ffffffffc020060e:	02c6e063          	bltu	a3,a2,ffffffffc020062e <best_fit_alloc_pages+0x6a>
ffffffffc0200612:	01052803          	lw	a6,16(a0)
ffffffffc0200616:	ff0760e3          	bltu	a4,a6,ffffffffc02005f6 <best_fit_alloc_pages+0x32>
ffffffffc020061a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020061c:	00b78f63          	beq	a5,a1,ffffffffc020063a <best_fit_alloc_pages+0x76>
        if (p->property >= n && (page == NULL || p->property < page->property)) {
ffffffffc0200620:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200624:	02071693          	slli	a3,a4,0x20
ffffffffc0200628:	9281                	srli	a3,a3,0x20
ffffffffc020062a:	fec6f6e3          	bgeu	a3,a2,ffffffffc0200616 <best_fit_alloc_pages+0x52>
ffffffffc020062e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200630:	fab79be3          	bne	a5,a1,ffffffffc02005e6 <best_fit_alloc_pages+0x22>
    if (page != NULL) {
ffffffffc0200634:	e119                	bnez	a0,ffffffffc020063a <best_fit_alloc_pages+0x76>
        return NULL;
ffffffffc0200636:	4501                	li	a0,0
ffffffffc0200638:	8082                	ret
        if (page->property > n) {
ffffffffc020063a:	01052803          	lw	a6,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc020063e:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200640:	7114                	ld	a3,32(a0)
ffffffffc0200642:	02081793          	slli	a5,a6,0x20
ffffffffc0200646:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200648:	e714                	sd	a3,8(a4)
    next->prev = prev;
ffffffffc020064a:	e298                	sd	a4,0(a3)
            p->property = page->property - n;
ffffffffc020064c:	0006031b          	sext.w	t1,a2
        if (page->property > n) {
ffffffffc0200650:	02f67563          	bgeu	a2,a5,ffffffffc020067a <best_fit_alloc_pages+0xb6>
            struct Page *p = page + n;
ffffffffc0200654:	00261793          	slli	a5,a2,0x2
ffffffffc0200658:	97b2                	add	a5,a5,a2
ffffffffc020065a:	078e                	slli	a5,a5,0x3
ffffffffc020065c:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc020065e:	6790                	ld	a2,8(a5)
            p->property = page->property - n;
ffffffffc0200660:	4068083b          	subw	a6,a6,t1
ffffffffc0200664:	0107a823          	sw	a6,16(a5)
            SetPageProperty(p);
ffffffffc0200668:	00266613          	ori	a2,a2,2
ffffffffc020066c:	e790                	sd	a2,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc020066e:	01878613          	addi	a2,a5,24
    prev->next = next->prev = elm;
ffffffffc0200672:	e290                	sd	a2,0(a3)
ffffffffc0200674:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200676:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200678:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc020067a:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc020067c:	406888bb          	subw	a7,a7,t1
ffffffffc0200680:	0115a823          	sw	a7,16(a1)
        ClearPageProperty(page);
ffffffffc0200684:	9bf5                	andi	a5,a5,-3
ffffffffc0200686:	e51c                	sd	a5,8(a0)
}
ffffffffc0200688:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc020068a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020068c:	00002697          	auipc	a3,0x2
ffffffffc0200690:	3cc68693          	addi	a3,a3,972 # ffffffffc0202a58 <etext+0x24e>
ffffffffc0200694:	00002617          	auipc	a2,0x2
ffffffffc0200698:	3cc60613          	addi	a2,a2,972 # ffffffffc0202a60 <etext+0x256>
ffffffffc020069c:	03100593          	li	a1,49
ffffffffc02006a0:	00002517          	auipc	a0,0x2
ffffffffc02006a4:	3d850513          	addi	a0,a0,984 # ffffffffc0202a78 <etext+0x26e>
best_fit_alloc_pages(size_t n) {
ffffffffc02006a8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02006aa:	b23ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02006ae <best_fit_check>:
    free_page(p1);
    free_page(p2);
}

static void
best_fit_check(void) {
ffffffffc02006ae:	715d                	addi	sp,sp,-80
ffffffffc02006b0:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02006b2:	00007417          	auipc	s0,0x7
ffffffffc02006b6:	96640413          	addi	s0,s0,-1690 # ffffffffc0207018 <free_area>
ffffffffc02006ba:	641c                	ld	a5,8(s0)
ffffffffc02006bc:	e486                	sd	ra,72(sp)
ffffffffc02006be:	fc26                	sd	s1,56(sp)
ffffffffc02006c0:	f84a                	sd	s2,48(sp)
ffffffffc02006c2:	f44e                	sd	s3,40(sp)
ffffffffc02006c4:	f052                	sd	s4,32(sp)
ffffffffc02006c6:	ec56                	sd	s5,24(sp)
ffffffffc02006c8:	e85a                	sd	s6,16(sp)
ffffffffc02006ca:	e45e                	sd	s7,8(sp)
ffffffffc02006cc:	e062                	sd	s8,0(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006ce:	28878263          	beq	a5,s0,ffffffffc0200952 <best_fit_check+0x2a4>
    int count = 0, total = 0;
ffffffffc02006d2:	4481                	li	s1,0
ffffffffc02006d4:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02006d6:	ff07b703          	ld	a4,-16(a5)
ffffffffc02006da:	8b09                	andi	a4,a4,2
ffffffffc02006dc:	26070f63          	beqz	a4,ffffffffc020095a <best_fit_check+0x2ac>
        count++, total += p->property;
ffffffffc02006e0:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006e4:	679c                	ld	a5,8(a5)
ffffffffc02006e6:	2905                	addiw	s2,s2,1
ffffffffc02006e8:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006ea:	fe8796e3          	bne	a5,s0,ffffffffc02006d6 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02006ee:	89a6                	mv	s3,s1
ffffffffc02006f0:	430010ef          	jal	ffffffffc0201b20 <nr_free_pages>
ffffffffc02006f4:	35351363          	bne	a0,s3,ffffffffc0200a3a <best_fit_check+0x38c>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006f8:	4505                	li	a0,1
ffffffffc02006fa:	40e010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc02006fe:	8a2a                	mv	s4,a0
ffffffffc0200700:	36050d63          	beqz	a0,ffffffffc0200a7a <best_fit_check+0x3cc>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200704:	4505                	li	a0,1
ffffffffc0200706:	402010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc020070a:	89aa                	mv	s3,a0
ffffffffc020070c:	34050763          	beqz	a0,ffffffffc0200a5a <best_fit_check+0x3ac>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200710:	4505                	li	a0,1
ffffffffc0200712:	3f6010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc0200716:	8aaa                	mv	s5,a0
ffffffffc0200718:	2e050163          	beqz	a0,ffffffffc02009fa <best_fit_check+0x34c>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020071c:	253a0f63          	beq	s4,s3,ffffffffc020097a <best_fit_check+0x2cc>
ffffffffc0200720:	24aa0d63          	beq	s4,a0,ffffffffc020097a <best_fit_check+0x2cc>
ffffffffc0200724:	24a98b63          	beq	s3,a0,ffffffffc020097a <best_fit_check+0x2cc>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200728:	000a2783          	lw	a5,0(s4)
ffffffffc020072c:	26079763          	bnez	a5,ffffffffc020099a <best_fit_check+0x2ec>
ffffffffc0200730:	0009a783          	lw	a5,0(s3)
ffffffffc0200734:	26079363          	bnez	a5,ffffffffc020099a <best_fit_check+0x2ec>
ffffffffc0200738:	411c                	lw	a5,0(a0)
ffffffffc020073a:	26079063          	bnez	a5,ffffffffc020099a <best_fit_check+0x2ec>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020073e:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0200742:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac4fa1>
ffffffffc0200746:	07b2                	slli	a5,a5,0xc
ffffffffc0200748:	ccd78793          	addi	a5,a5,-819
ffffffffc020074c:	07b2                	slli	a5,a5,0xc
ffffffffc020074e:	00007717          	auipc	a4,0x7
ffffffffc0200752:	5d273703          	ld	a4,1490(a4) # ffffffffc0207d20 <pages>
ffffffffc0200756:	ccd78793          	addi	a5,a5,-819
ffffffffc020075a:	40ea06b3          	sub	a3,s4,a4
ffffffffc020075e:	07b2                	slli	a5,a5,0xc
ffffffffc0200760:	868d                	srai	a3,a3,0x3
ffffffffc0200762:	ccd78793          	addi	a5,a5,-819
ffffffffc0200766:	02f686b3          	mul	a3,a3,a5
ffffffffc020076a:	00003597          	auipc	a1,0x3
ffffffffc020076e:	11e5b583          	ld	a1,286(a1) # ffffffffc0203888 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200772:	00007617          	auipc	a2,0x7
ffffffffc0200776:	5a663603          	ld	a2,1446(a2) # ffffffffc0207d18 <npage>
ffffffffc020077a:	0632                	slli	a2,a2,0xc
ffffffffc020077c:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc020077e:	06b2                	slli	a3,a3,0xc
ffffffffc0200780:	22c6fd63          	bgeu	a3,a2,ffffffffc02009ba <best_fit_check+0x30c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200784:	40e986b3          	sub	a3,s3,a4
ffffffffc0200788:	868d                	srai	a3,a3,0x3
ffffffffc020078a:	02f686b3          	mul	a3,a3,a5
ffffffffc020078e:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200790:	06b2                	slli	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200792:	3ec6f463          	bgeu	a3,a2,ffffffffc0200b7a <best_fit_check+0x4cc>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200796:	40e50733          	sub	a4,a0,a4
ffffffffc020079a:	870d                	srai	a4,a4,0x3
ffffffffc020079c:	02f707b3          	mul	a5,a4,a5
ffffffffc02007a0:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc02007a2:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02007a4:	3ac7fb63          	bgeu	a5,a2,ffffffffc0200b5a <best_fit_check+0x4ac>
    assert(alloc_page() == NULL);
ffffffffc02007a8:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02007aa:	00043c03          	ld	s8,0(s0)
ffffffffc02007ae:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02007b2:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02007b6:	e400                	sd	s0,8(s0)
ffffffffc02007b8:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02007ba:	00007797          	auipc	a5,0x7
ffffffffc02007be:	8607a723          	sw	zero,-1938(a5) # ffffffffc0207028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02007c2:	346010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc02007c6:	36051a63          	bnez	a0,ffffffffc0200b3a <best_fit_check+0x48c>
    free_page(p0);
ffffffffc02007ca:	4585                	li	a1,1
ffffffffc02007cc:	8552                	mv	a0,s4
ffffffffc02007ce:	346010ef          	jal	ffffffffc0201b14 <free_pages>
    free_page(p1);
ffffffffc02007d2:	4585                	li	a1,1
ffffffffc02007d4:	854e                	mv	a0,s3
ffffffffc02007d6:	33e010ef          	jal	ffffffffc0201b14 <free_pages>
    free_page(p2);
ffffffffc02007da:	4585                	li	a1,1
ffffffffc02007dc:	8556                	mv	a0,s5
ffffffffc02007de:	336010ef          	jal	ffffffffc0201b14 <free_pages>
    assert(nr_free == 3);
ffffffffc02007e2:	4818                	lw	a4,16(s0)
ffffffffc02007e4:	478d                	li	a5,3
ffffffffc02007e6:	32f71a63          	bne	a4,a5,ffffffffc0200b1a <best_fit_check+0x46c>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007ea:	4505                	li	a0,1
ffffffffc02007ec:	31c010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc02007f0:	89aa                	mv	s3,a0
ffffffffc02007f2:	30050463          	beqz	a0,ffffffffc0200afa <best_fit_check+0x44c>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007f6:	4505                	li	a0,1
ffffffffc02007f8:	310010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc02007fc:	8aaa                	mv	s5,a0
ffffffffc02007fe:	2c050e63          	beqz	a0,ffffffffc0200ada <best_fit_check+0x42c>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200802:	4505                	li	a0,1
ffffffffc0200804:	304010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc0200808:	8a2a                	mv	s4,a0
ffffffffc020080a:	2a050863          	beqz	a0,ffffffffc0200aba <best_fit_check+0x40c>
    assert(alloc_page() == NULL);
ffffffffc020080e:	4505                	li	a0,1
ffffffffc0200810:	2f8010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc0200814:	28051363          	bnez	a0,ffffffffc0200a9a <best_fit_check+0x3ec>
    free_page(p0);
ffffffffc0200818:	4585                	li	a1,1
ffffffffc020081a:	854e                	mv	a0,s3
ffffffffc020081c:	2f8010ef          	jal	ffffffffc0201b14 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200820:	641c                	ld	a5,8(s0)
ffffffffc0200822:	1a878c63          	beq	a5,s0,ffffffffc02009da <best_fit_check+0x32c>
    assert((p = alloc_page()) == p0);
ffffffffc0200826:	4505                	li	a0,1
ffffffffc0200828:	2e0010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc020082c:	52a99763          	bne	s3,a0,ffffffffc0200d5a <best_fit_check+0x6ac>
    assert(alloc_page() == NULL);
ffffffffc0200830:	4505                	li	a0,1
ffffffffc0200832:	2d6010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc0200836:	50051263          	bnez	a0,ffffffffc0200d3a <best_fit_check+0x68c>
    assert(nr_free == 0);
ffffffffc020083a:	481c                	lw	a5,16(s0)
ffffffffc020083c:	4c079f63          	bnez	a5,ffffffffc0200d1a <best_fit_check+0x66c>
    free_page(p);
ffffffffc0200840:	854e                	mv	a0,s3
ffffffffc0200842:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200844:	01843023          	sd	s8,0(s0)
ffffffffc0200848:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020084c:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200850:	2c4010ef          	jal	ffffffffc0201b14 <free_pages>
    free_page(p1);
ffffffffc0200854:	4585                	li	a1,1
ffffffffc0200856:	8556                	mv	a0,s5
ffffffffc0200858:	2bc010ef          	jal	ffffffffc0201b14 <free_pages>
    free_page(p2);
ffffffffc020085c:	4585                	li	a1,1
ffffffffc020085e:	8552                	mv	a0,s4
ffffffffc0200860:	2b4010ef          	jal	ffffffffc0201b14 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200864:	4515                	li	a0,5
ffffffffc0200866:	2a2010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc020086a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020086c:	48050763          	beqz	a0,ffffffffc0200cfa <best_fit_check+0x64c>
    assert(!PageProperty(p0));
ffffffffc0200870:	651c                	ld	a5,8(a0)
ffffffffc0200872:	8b89                	andi	a5,a5,2
ffffffffc0200874:	46079363          	bnez	a5,ffffffffc0200cda <best_fit_check+0x62c>
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200878:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020087a:	00043b03          	ld	s6,0(s0)
ffffffffc020087e:	00843a83          	ld	s5,8(s0)
ffffffffc0200882:	e000                	sd	s0,0(s0)
ffffffffc0200884:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200886:	282010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc020088a:	42051863          	bnez	a0,ffffffffc0200cba <best_fit_check+0x60c>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc020088e:	4589                	li	a1,2
ffffffffc0200890:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200894:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200898:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc020089c:	00006797          	auipc	a5,0x6
ffffffffc02008a0:	7807a623          	sw	zero,1932(a5) # ffffffffc0207028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc02008a4:	270010ef          	jal	ffffffffc0201b14 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc02008a8:	8562                	mv	a0,s8
ffffffffc02008aa:	4585                	li	a1,1
ffffffffc02008ac:	268010ef          	jal	ffffffffc0201b14 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02008b0:	4511                	li	a0,4
ffffffffc02008b2:	256010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc02008b6:	3e051263          	bnez	a0,ffffffffc0200c9a <best_fit_check+0x5ec>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02008ba:	0309b783          	ld	a5,48(s3)
ffffffffc02008be:	8b89                	andi	a5,a5,2
ffffffffc02008c0:	3a078d63          	beqz	a5,ffffffffc0200c7a <best_fit_check+0x5cc>
ffffffffc02008c4:	0389a703          	lw	a4,56(s3)
ffffffffc02008c8:	4789                	li	a5,2
ffffffffc02008ca:	3af71863          	bne	a4,a5,ffffffffc0200c7a <best_fit_check+0x5cc>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008ce:	4505                	li	a0,1
ffffffffc02008d0:	238010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc02008d4:	8a2a                	mv	s4,a0
ffffffffc02008d6:	38050263          	beqz	a0,ffffffffc0200c5a <best_fit_check+0x5ac>
    assert(alloc_pages(2) != NULL);
ffffffffc02008da:	4509                	li	a0,2
ffffffffc02008dc:	22c010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc02008e0:	34050d63          	beqz	a0,ffffffffc0200c3a <best_fit_check+0x58c>
    assert(p0 + 4 == p1);
ffffffffc02008e4:	334c1b63          	bne	s8,s4,ffffffffc0200c1a <best_fit_check+0x56c>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008e8:	854e                	mv	a0,s3
ffffffffc02008ea:	4595                	li	a1,5
ffffffffc02008ec:	228010ef          	jal	ffffffffc0201b14 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008f0:	4515                	li	a0,5
ffffffffc02008f2:	216010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc02008f6:	89aa                	mv	s3,a0
ffffffffc02008f8:	30050163          	beqz	a0,ffffffffc0200bfa <best_fit_check+0x54c>
    assert(alloc_page() == NULL);
ffffffffc02008fc:	4505                	li	a0,1
ffffffffc02008fe:	20a010ef          	jal	ffffffffc0201b08 <alloc_pages>
ffffffffc0200902:	2c051c63          	bnez	a0,ffffffffc0200bda <best_fit_check+0x52c>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200906:	481c                	lw	a5,16(s0)
ffffffffc0200908:	2a079963          	bnez	a5,ffffffffc0200bba <best_fit_check+0x50c>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020090c:	4595                	li	a1,5
ffffffffc020090e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200910:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200914:	01643023          	sd	s6,0(s0)
ffffffffc0200918:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020091c:	1f8010ef          	jal	ffffffffc0201b14 <free_pages>
    return listelm->next;
ffffffffc0200920:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200922:	00878963          	beq	a5,s0,ffffffffc0200934 <best_fit_check+0x286>
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0200926:	ff87a703          	lw	a4,-8(a5)
ffffffffc020092a:	679c                	ld	a5,8(a5)
ffffffffc020092c:	397d                	addiw	s2,s2,-1
ffffffffc020092e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200930:	fe879be3          	bne	a5,s0,ffffffffc0200926 <best_fit_check+0x278>
    }
    assert(count == 0);
ffffffffc0200934:	26091363          	bnez	s2,ffffffffc0200b9a <best_fit_check+0x4ec>
    assert(total == 0);
ffffffffc0200938:	e0ed                	bnez	s1,ffffffffc0200a1a <best_fit_check+0x36c>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
}
ffffffffc020093a:	60a6                	ld	ra,72(sp)
ffffffffc020093c:	6406                	ld	s0,64(sp)
ffffffffc020093e:	74e2                	ld	s1,56(sp)
ffffffffc0200940:	7942                	ld	s2,48(sp)
ffffffffc0200942:	79a2                	ld	s3,40(sp)
ffffffffc0200944:	7a02                	ld	s4,32(sp)
ffffffffc0200946:	6ae2                	ld	s5,24(sp)
ffffffffc0200948:	6b42                	ld	s6,16(sp)
ffffffffc020094a:	6ba2                	ld	s7,8(sp)
ffffffffc020094c:	6c02                	ld	s8,0(sp)
ffffffffc020094e:	6161                	addi	sp,sp,80
ffffffffc0200950:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200952:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200954:	4481                	li	s1,0
ffffffffc0200956:	4901                	li	s2,0
ffffffffc0200958:	bb61                	j	ffffffffc02006f0 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc020095a:	00002697          	auipc	a3,0x2
ffffffffc020095e:	13668693          	addi	a3,a3,310 # ffffffffc0202a90 <etext+0x286>
ffffffffc0200962:	00002617          	auipc	a2,0x2
ffffffffc0200966:	0fe60613          	addi	a2,a2,254 # ffffffffc0202a60 <etext+0x256>
ffffffffc020096a:	0cf00593          	li	a1,207
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	10a50513          	addi	a0,a0,266 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200976:	857ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020097a:	00002697          	auipc	a3,0x2
ffffffffc020097e:	1a668693          	addi	a3,a3,422 # ffffffffc0202b20 <etext+0x316>
ffffffffc0200982:	00002617          	auipc	a2,0x2
ffffffffc0200986:	0de60613          	addi	a2,a2,222 # ffffffffc0202a60 <etext+0x256>
ffffffffc020098a:	09d00593          	li	a1,157
ffffffffc020098e:	00002517          	auipc	a0,0x2
ffffffffc0200992:	0ea50513          	addi	a0,a0,234 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200996:	837ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020099a:	00002697          	auipc	a3,0x2
ffffffffc020099e:	1ae68693          	addi	a3,a3,430 # ffffffffc0202b48 <etext+0x33e>
ffffffffc02009a2:	00002617          	auipc	a2,0x2
ffffffffc02009a6:	0be60613          	addi	a2,a2,190 # ffffffffc0202a60 <etext+0x256>
ffffffffc02009aa:	09e00593          	li	a1,158
ffffffffc02009ae:	00002517          	auipc	a0,0x2
ffffffffc02009b2:	0ca50513          	addi	a0,a0,202 # ffffffffc0202a78 <etext+0x26e>
ffffffffc02009b6:	817ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009ba:	00002697          	auipc	a3,0x2
ffffffffc02009be:	1ce68693          	addi	a3,a3,462 # ffffffffc0202b88 <etext+0x37e>
ffffffffc02009c2:	00002617          	auipc	a2,0x2
ffffffffc02009c6:	09e60613          	addi	a2,a2,158 # ffffffffc0202a60 <etext+0x256>
ffffffffc02009ca:	0a000593          	li	a1,160
ffffffffc02009ce:	00002517          	auipc	a0,0x2
ffffffffc02009d2:	0aa50513          	addi	a0,a0,170 # ffffffffc0202a78 <etext+0x26e>
ffffffffc02009d6:	ff6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009da:	00002697          	auipc	a3,0x2
ffffffffc02009de:	23668693          	addi	a3,a3,566 # ffffffffc0202c10 <etext+0x406>
ffffffffc02009e2:	00002617          	auipc	a2,0x2
ffffffffc02009e6:	07e60613          	addi	a2,a2,126 # ffffffffc0202a60 <etext+0x256>
ffffffffc02009ea:	0b900593          	li	a1,185
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	08a50513          	addi	a0,a0,138 # ffffffffc0202a78 <etext+0x26e>
ffffffffc02009f6:	fd6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009fa:	00002697          	auipc	a3,0x2
ffffffffc02009fe:	10668693          	addi	a3,a3,262 # ffffffffc0202b00 <etext+0x2f6>
ffffffffc0200a02:	00002617          	auipc	a2,0x2
ffffffffc0200a06:	05e60613          	addi	a2,a2,94 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200a0a:	09b00593          	li	a1,155
ffffffffc0200a0e:	00002517          	auipc	a0,0x2
ffffffffc0200a12:	06a50513          	addi	a0,a0,106 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200a16:	fb6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(total == 0);
ffffffffc0200a1a:	00002697          	auipc	a3,0x2
ffffffffc0200a1e:	32668693          	addi	a3,a3,806 # ffffffffc0202d40 <etext+0x536>
ffffffffc0200a22:	00002617          	auipc	a2,0x2
ffffffffc0200a26:	03e60613          	addi	a2,a2,62 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200a2a:	11100593          	li	a1,273
ffffffffc0200a2e:	00002517          	auipc	a0,0x2
ffffffffc0200a32:	04a50513          	addi	a0,a0,74 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200a36:	f96ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a3a:	00002697          	auipc	a3,0x2
ffffffffc0200a3e:	06668693          	addi	a3,a3,102 # ffffffffc0202aa0 <etext+0x296>
ffffffffc0200a42:	00002617          	auipc	a2,0x2
ffffffffc0200a46:	01e60613          	addi	a2,a2,30 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200a4a:	0d200593          	li	a1,210
ffffffffc0200a4e:	00002517          	auipc	a0,0x2
ffffffffc0200a52:	02a50513          	addi	a0,a0,42 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200a56:	f76ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a5a:	00002697          	auipc	a3,0x2
ffffffffc0200a5e:	08668693          	addi	a3,a3,134 # ffffffffc0202ae0 <etext+0x2d6>
ffffffffc0200a62:	00002617          	auipc	a2,0x2
ffffffffc0200a66:	ffe60613          	addi	a2,a2,-2 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200a6a:	09a00593          	li	a1,154
ffffffffc0200a6e:	00002517          	auipc	a0,0x2
ffffffffc0200a72:	00a50513          	addi	a0,a0,10 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200a76:	f56ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a7a:	00002697          	auipc	a3,0x2
ffffffffc0200a7e:	04668693          	addi	a3,a3,70 # ffffffffc0202ac0 <etext+0x2b6>
ffffffffc0200a82:	00002617          	auipc	a2,0x2
ffffffffc0200a86:	fde60613          	addi	a2,a2,-34 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200a8a:	09900593          	li	a1,153
ffffffffc0200a8e:	00002517          	auipc	a0,0x2
ffffffffc0200a92:	fea50513          	addi	a0,a0,-22 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200a96:	f36ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a9a:	00002697          	auipc	a3,0x2
ffffffffc0200a9e:	14e68693          	addi	a3,a3,334 # ffffffffc0202be8 <etext+0x3de>
ffffffffc0200aa2:	00002617          	auipc	a2,0x2
ffffffffc0200aa6:	fbe60613          	addi	a2,a2,-66 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200aaa:	0b600593          	li	a1,182
ffffffffc0200aae:	00002517          	auipc	a0,0x2
ffffffffc0200ab2:	fca50513          	addi	a0,a0,-54 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200ab6:	f16ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aba:	00002697          	auipc	a3,0x2
ffffffffc0200abe:	04668693          	addi	a3,a3,70 # ffffffffc0202b00 <etext+0x2f6>
ffffffffc0200ac2:	00002617          	auipc	a2,0x2
ffffffffc0200ac6:	f9e60613          	addi	a2,a2,-98 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200aca:	0b400593          	li	a1,180
ffffffffc0200ace:	00002517          	auipc	a0,0x2
ffffffffc0200ad2:	faa50513          	addi	a0,a0,-86 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200ad6:	ef6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ada:	00002697          	auipc	a3,0x2
ffffffffc0200ade:	00668693          	addi	a3,a3,6 # ffffffffc0202ae0 <etext+0x2d6>
ffffffffc0200ae2:	00002617          	auipc	a2,0x2
ffffffffc0200ae6:	f7e60613          	addi	a2,a2,-130 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200aea:	0b300593          	li	a1,179
ffffffffc0200aee:	00002517          	auipc	a0,0x2
ffffffffc0200af2:	f8a50513          	addi	a0,a0,-118 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200af6:	ed6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200afa:	00002697          	auipc	a3,0x2
ffffffffc0200afe:	fc668693          	addi	a3,a3,-58 # ffffffffc0202ac0 <etext+0x2b6>
ffffffffc0200b02:	00002617          	auipc	a2,0x2
ffffffffc0200b06:	f5e60613          	addi	a2,a2,-162 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200b0a:	0b200593          	li	a1,178
ffffffffc0200b0e:	00002517          	auipc	a0,0x2
ffffffffc0200b12:	f6a50513          	addi	a0,a0,-150 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200b16:	eb6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 3);
ffffffffc0200b1a:	00002697          	auipc	a3,0x2
ffffffffc0200b1e:	0e668693          	addi	a3,a3,230 # ffffffffc0202c00 <etext+0x3f6>
ffffffffc0200b22:	00002617          	auipc	a2,0x2
ffffffffc0200b26:	f3e60613          	addi	a2,a2,-194 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200b2a:	0b000593          	li	a1,176
ffffffffc0200b2e:	00002517          	auipc	a0,0x2
ffffffffc0200b32:	f4a50513          	addi	a0,a0,-182 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200b36:	e96ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b3a:	00002697          	auipc	a3,0x2
ffffffffc0200b3e:	0ae68693          	addi	a3,a3,174 # ffffffffc0202be8 <etext+0x3de>
ffffffffc0200b42:	00002617          	auipc	a2,0x2
ffffffffc0200b46:	f1e60613          	addi	a2,a2,-226 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200b4a:	0ab00593          	li	a1,171
ffffffffc0200b4e:	00002517          	auipc	a0,0x2
ffffffffc0200b52:	f2a50513          	addi	a0,a0,-214 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200b56:	e76ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b5a:	00002697          	auipc	a3,0x2
ffffffffc0200b5e:	06e68693          	addi	a3,a3,110 # ffffffffc0202bc8 <etext+0x3be>
ffffffffc0200b62:	00002617          	auipc	a2,0x2
ffffffffc0200b66:	efe60613          	addi	a2,a2,-258 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200b6a:	0a200593          	li	a1,162
ffffffffc0200b6e:	00002517          	auipc	a0,0x2
ffffffffc0200b72:	f0a50513          	addi	a0,a0,-246 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200b76:	e56ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b7a:	00002697          	auipc	a3,0x2
ffffffffc0200b7e:	02e68693          	addi	a3,a3,46 # ffffffffc0202ba8 <etext+0x39e>
ffffffffc0200b82:	00002617          	auipc	a2,0x2
ffffffffc0200b86:	ede60613          	addi	a2,a2,-290 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200b8a:	0a100593          	li	a1,161
ffffffffc0200b8e:	00002517          	auipc	a0,0x2
ffffffffc0200b92:	eea50513          	addi	a0,a0,-278 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200b96:	e36ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(count == 0);
ffffffffc0200b9a:	00002697          	auipc	a3,0x2
ffffffffc0200b9e:	19668693          	addi	a3,a3,406 # ffffffffc0202d30 <etext+0x526>
ffffffffc0200ba2:	00002617          	auipc	a2,0x2
ffffffffc0200ba6:	ebe60613          	addi	a2,a2,-322 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200baa:	11000593          	li	a1,272
ffffffffc0200bae:	00002517          	auipc	a0,0x2
ffffffffc0200bb2:	eca50513          	addi	a0,a0,-310 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200bb6:	e16ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 0);
ffffffffc0200bba:	00002697          	auipc	a3,0x2
ffffffffc0200bbe:	08e68693          	addi	a3,a3,142 # ffffffffc0202c48 <etext+0x43e>
ffffffffc0200bc2:	00002617          	auipc	a2,0x2
ffffffffc0200bc6:	e9e60613          	addi	a2,a2,-354 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200bca:	10500593          	li	a1,261
ffffffffc0200bce:	00002517          	auipc	a0,0x2
ffffffffc0200bd2:	eaa50513          	addi	a0,a0,-342 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200bd6:	df6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bda:	00002697          	auipc	a3,0x2
ffffffffc0200bde:	00e68693          	addi	a3,a3,14 # ffffffffc0202be8 <etext+0x3de>
ffffffffc0200be2:	00002617          	auipc	a2,0x2
ffffffffc0200be6:	e7e60613          	addi	a2,a2,-386 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200bea:	0ff00593          	li	a1,255
ffffffffc0200bee:	00002517          	auipc	a0,0x2
ffffffffc0200bf2:	e8a50513          	addi	a0,a0,-374 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200bf6:	dd6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200bfa:	00002697          	auipc	a3,0x2
ffffffffc0200bfe:	11668693          	addi	a3,a3,278 # ffffffffc0202d10 <etext+0x506>
ffffffffc0200c02:	00002617          	auipc	a2,0x2
ffffffffc0200c06:	e5e60613          	addi	a2,a2,-418 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200c0a:	0fe00593          	li	a1,254
ffffffffc0200c0e:	00002517          	auipc	a0,0x2
ffffffffc0200c12:	e6a50513          	addi	a0,a0,-406 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200c16:	db6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200c1a:	00002697          	auipc	a3,0x2
ffffffffc0200c1e:	0e668693          	addi	a3,a3,230 # ffffffffc0202d00 <etext+0x4f6>
ffffffffc0200c22:	00002617          	auipc	a2,0x2
ffffffffc0200c26:	e3e60613          	addi	a2,a2,-450 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200c2a:	0f600593          	li	a1,246
ffffffffc0200c2e:	00002517          	auipc	a0,0x2
ffffffffc0200c32:	e4a50513          	addi	a0,a0,-438 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200c36:	d96ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(2) != NULL);
ffffffffc0200c3a:	00002697          	auipc	a3,0x2
ffffffffc0200c3e:	0ae68693          	addi	a3,a3,174 # ffffffffc0202ce8 <etext+0x4de>
ffffffffc0200c42:	00002617          	auipc	a2,0x2
ffffffffc0200c46:	e1e60613          	addi	a2,a2,-482 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200c4a:	0f500593          	li	a1,245
ffffffffc0200c4e:	00002517          	auipc	a0,0x2
ffffffffc0200c52:	e2a50513          	addi	a0,a0,-470 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200c56:	d76ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c5a:	00002697          	auipc	a3,0x2
ffffffffc0200c5e:	06e68693          	addi	a3,a3,110 # ffffffffc0202cc8 <etext+0x4be>
ffffffffc0200c62:	00002617          	auipc	a2,0x2
ffffffffc0200c66:	dfe60613          	addi	a2,a2,-514 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200c6a:	0f400593          	li	a1,244
ffffffffc0200c6e:	00002517          	auipc	a0,0x2
ffffffffc0200c72:	e0a50513          	addi	a0,a0,-502 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200c76:	d56ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c7a:	00002697          	auipc	a3,0x2
ffffffffc0200c7e:	01e68693          	addi	a3,a3,30 # ffffffffc0202c98 <etext+0x48e>
ffffffffc0200c82:	00002617          	auipc	a2,0x2
ffffffffc0200c86:	dde60613          	addi	a2,a2,-546 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200c8a:	0f200593          	li	a1,242
ffffffffc0200c8e:	00002517          	auipc	a0,0x2
ffffffffc0200c92:	dea50513          	addi	a0,a0,-534 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200c96:	d36ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c9a:	00002697          	auipc	a3,0x2
ffffffffc0200c9e:	fe668693          	addi	a3,a3,-26 # ffffffffc0202c80 <etext+0x476>
ffffffffc0200ca2:	00002617          	auipc	a2,0x2
ffffffffc0200ca6:	dbe60613          	addi	a2,a2,-578 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200caa:	0f100593          	li	a1,241
ffffffffc0200cae:	00002517          	auipc	a0,0x2
ffffffffc0200cb2:	dca50513          	addi	a0,a0,-566 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200cb6:	d16ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cba:	00002697          	auipc	a3,0x2
ffffffffc0200cbe:	f2e68693          	addi	a3,a3,-210 # ffffffffc0202be8 <etext+0x3de>
ffffffffc0200cc2:	00002617          	auipc	a2,0x2
ffffffffc0200cc6:	d9e60613          	addi	a2,a2,-610 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200cca:	0e500593          	li	a1,229
ffffffffc0200cce:	00002517          	auipc	a0,0x2
ffffffffc0200cd2:	daa50513          	addi	a0,a0,-598 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200cd6:	cf6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cda:	00002697          	auipc	a3,0x2
ffffffffc0200cde:	f8e68693          	addi	a3,a3,-114 # ffffffffc0202c68 <etext+0x45e>
ffffffffc0200ce2:	00002617          	auipc	a2,0x2
ffffffffc0200ce6:	d7e60613          	addi	a2,a2,-642 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200cea:	0dc00593          	li	a1,220
ffffffffc0200cee:	00002517          	auipc	a0,0x2
ffffffffc0200cf2:	d8a50513          	addi	a0,a0,-630 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200cf6:	cd6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 != NULL);
ffffffffc0200cfa:	00002697          	auipc	a3,0x2
ffffffffc0200cfe:	f5e68693          	addi	a3,a3,-162 # ffffffffc0202c58 <etext+0x44e>
ffffffffc0200d02:	00002617          	auipc	a2,0x2
ffffffffc0200d06:	d5e60613          	addi	a2,a2,-674 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200d0a:	0db00593          	li	a1,219
ffffffffc0200d0e:	00002517          	auipc	a0,0x2
ffffffffc0200d12:	d6a50513          	addi	a0,a0,-662 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200d16:	cb6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 0);
ffffffffc0200d1a:	00002697          	auipc	a3,0x2
ffffffffc0200d1e:	f2e68693          	addi	a3,a3,-210 # ffffffffc0202c48 <etext+0x43e>
ffffffffc0200d22:	00002617          	auipc	a2,0x2
ffffffffc0200d26:	d3e60613          	addi	a2,a2,-706 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200d2a:	0bf00593          	li	a1,191
ffffffffc0200d2e:	00002517          	auipc	a0,0x2
ffffffffc0200d32:	d4a50513          	addi	a0,a0,-694 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200d36:	c96ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d3a:	00002697          	auipc	a3,0x2
ffffffffc0200d3e:	eae68693          	addi	a3,a3,-338 # ffffffffc0202be8 <etext+0x3de>
ffffffffc0200d42:	00002617          	auipc	a2,0x2
ffffffffc0200d46:	d1e60613          	addi	a2,a2,-738 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200d4a:	0bd00593          	li	a1,189
ffffffffc0200d4e:	00002517          	auipc	a0,0x2
ffffffffc0200d52:	d2a50513          	addi	a0,a0,-726 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200d56:	c76ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d5a:	00002697          	auipc	a3,0x2
ffffffffc0200d5e:	ece68693          	addi	a3,a3,-306 # ffffffffc0202c28 <etext+0x41e>
ffffffffc0200d62:	00002617          	auipc	a2,0x2
ffffffffc0200d66:	cfe60613          	addi	a2,a2,-770 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200d6a:	0bc00593          	li	a1,188
ffffffffc0200d6e:	00002517          	auipc	a0,0x2
ffffffffc0200d72:	d0a50513          	addi	a0,a0,-758 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200d76:	c56ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200d7a <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d7a:	1141                	addi	sp,sp,-16
ffffffffc0200d7c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d7e:	14058d63          	beqz	a1,ffffffffc0200ed8 <best_fit_free_pages+0x15e>
    for (; p != base + n; p ++) {
ffffffffc0200d82:	00259713          	slli	a4,a1,0x2
ffffffffc0200d86:	972e                	add	a4,a4,a1
ffffffffc0200d88:	070e                	slli	a4,a4,0x3
ffffffffc0200d8a:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200d8e:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200d90:	cf09                	beqz	a4,ffffffffc0200daa <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d92:	6798                	ld	a4,8(a5)
ffffffffc0200d94:	8b0d                	andi	a4,a4,3
ffffffffc0200d96:	12071163          	bnez	a4,ffffffffc0200eb8 <best_fit_free_pages+0x13e>
        p->flags = 0;
ffffffffc0200d9a:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d9e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200da2:	02878793          	addi	a5,a5,40
ffffffffc0200da6:	fef696e3          	bne	a3,a5,ffffffffc0200d92 <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200daa:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200dae:	00006617          	auipc	a2,0x6
ffffffffc0200db2:	26a60613          	addi	a2,a2,618 # ffffffffc0207018 <free_area>
ffffffffc0200db6:	4a18                	lw	a4,16(a2)
    base->property = n;
ffffffffc0200db8:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0200dba:	661c                	ld	a5,8(a2)
    SetPageProperty(base);
ffffffffc0200dbc:	0028e693          	ori	a3,a7,2
    base->property = n;
ffffffffc0200dc0:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200dc2:	e514                	sd	a3,8(a0)
    nr_free += n;
ffffffffc0200dc4:	9f2d                	addw	a4,a4,a1
ffffffffc0200dc6:	ca18                	sw	a4,16(a2)
    if (list_empty(&free_list)) {
ffffffffc0200dc8:	00c79763          	bne	a5,a2,ffffffffc0200dd6 <best_fit_free_pages+0x5c>
ffffffffc0200dcc:	a0bd                	j	ffffffffc0200e3a <best_fit_free_pages+0xc0>
    return listelm->next;
ffffffffc0200dce:	6794                	ld	a3,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200dd0:	06c68e63          	beq	a3,a2,ffffffffc0200e4c <best_fit_free_pages+0xd2>
ffffffffc0200dd4:	87b6                	mv	a5,a3
            struct Page* page = le2page(le, page_link);
ffffffffc0200dd6:	fe878713          	addi	a4,a5,-24
ffffffffc0200dda:	86ba                	mv	a3,a4
            if (base < page) {
ffffffffc0200ddc:	fee579e3          	bgeu	a0,a4,ffffffffc0200dce <best_fit_free_pages+0x54>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200de0:	0007b803          	ld	a6,0(a5)
                list_add_before(le, &(base->page_link));
ffffffffc0200de4:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200de8:	e398                	sd	a4,0(a5)
ffffffffc0200dea:	00e83423          	sd	a4,8(a6)
    elm->next = next;
ffffffffc0200dee:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200df0:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200df4:	02c80563          	beq	a6,a2,ffffffffc0200e1e <best_fit_free_pages+0xa4>
        if (p + p->property == base) {
ffffffffc0200df8:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200dfc:	fe880713          	addi	a4,a6,-24
        if (p + p->property == base) {
ffffffffc0200e00:	020e1313          	slli	t1,t3,0x20
ffffffffc0200e04:	02035313          	srli	t1,t1,0x20
ffffffffc0200e08:	00231693          	slli	a3,t1,0x2
ffffffffc0200e0c:	969a                	add	a3,a3,t1
ffffffffc0200e0e:	068e                	slli	a3,a3,0x3
ffffffffc0200e10:	96ba                	add	a3,a3,a4
ffffffffc0200e12:	06d50263          	beq	a0,a3,ffffffffc0200e76 <best_fit_free_pages+0xfc>
    if (le != &free_list) {
ffffffffc0200e16:	fe878693          	addi	a3,a5,-24
ffffffffc0200e1a:	00c78d63          	beq	a5,a2,ffffffffc0200e34 <best_fit_free_pages+0xba>
        if (base + base->property == p) {
ffffffffc0200e1e:	490c                	lw	a1,16(a0)
ffffffffc0200e20:	02059613          	slli	a2,a1,0x20
ffffffffc0200e24:	9201                	srli	a2,a2,0x20
ffffffffc0200e26:	00261713          	slli	a4,a2,0x2
ffffffffc0200e2a:	9732                	add	a4,a4,a2
ffffffffc0200e2c:	070e                	slli	a4,a4,0x3
ffffffffc0200e2e:	972a                	add	a4,a4,a0
ffffffffc0200e30:	06e68163          	beq	a3,a4,ffffffffc0200e92 <best_fit_free_pages+0x118>
}
ffffffffc0200e34:	60a2                	ld	ra,8(sp)
ffffffffc0200e36:	0141                	addi	sp,sp,16
ffffffffc0200e38:	8082                	ret
ffffffffc0200e3a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200e3c:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200e40:	e398                	sd	a4,0(a5)
ffffffffc0200e42:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200e44:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e46:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200e48:	0141                	addi	sp,sp,16
ffffffffc0200e4a:	8082                	ret
    return listelm->prev;
ffffffffc0200e4c:	883e                	mv	a6,a5
        if (p + p->property == base) {
ffffffffc0200e4e:	ff882e03          	lw	t3,-8(a6)
                list_add(le, &(base->page_link));
ffffffffc0200e52:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200e56:	e794                	sd	a3,8(a5)
        if (p + p->property == base) {
ffffffffc0200e58:	020e1313          	slli	t1,t3,0x20
ffffffffc0200e5c:	02035313          	srli	t1,t1,0x20
ffffffffc0200e60:	e214                	sd	a3,0(a2)
ffffffffc0200e62:	00231693          	slli	a3,t1,0x2
ffffffffc0200e66:	969a                	add	a3,a3,t1
ffffffffc0200e68:	068e                	slli	a3,a3,0x3
    elm->prev = prev;
ffffffffc0200e6a:	ed1c                	sd	a5,24(a0)
    elm->next = next;
ffffffffc0200e6c:	f110                	sd	a2,32(a0)
ffffffffc0200e6e:	96ba                	add	a3,a3,a4
    elm->prev = prev;
ffffffffc0200e70:	87b2                	mv	a5,a2
ffffffffc0200e72:	fad512e3          	bne	a0,a3,ffffffffc0200e16 <best_fit_free_pages+0x9c>
            p->property += base->property;
ffffffffc0200e76:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e7a:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200e7e:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200e82:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200e86:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200e8a:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200e8e:	853a                	mv	a0,a4
ffffffffc0200e90:	b759                	j	ffffffffc0200e16 <best_fit_free_pages+0x9c>
            base->property += p->property;
ffffffffc0200e92:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200e96:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e9a:	0007b803          	ld	a6,0(a5)
ffffffffc0200e9e:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200ea0:	9ead                	addw	a3,a3,a1
ffffffffc0200ea2:	c914                	sw	a3,16(a0)
            ClearPageProperty(p);
ffffffffc0200ea4:	9b75                	andi	a4,a4,-3
ffffffffc0200ea6:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200eaa:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200eac:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200eb0:	01063023          	sd	a6,0(a2)
ffffffffc0200eb4:	0141                	addi	sp,sp,16
ffffffffc0200eb6:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200eb8:	00002697          	auipc	a3,0x2
ffffffffc0200ebc:	e9868693          	addi	a3,a3,-360 # ffffffffc0202d50 <etext+0x546>
ffffffffc0200ec0:	00002617          	auipc	a2,0x2
ffffffffc0200ec4:	ba060613          	addi	a2,a2,-1120 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200ec8:	05400593          	li	a1,84
ffffffffc0200ecc:	00002517          	auipc	a0,0x2
ffffffffc0200ed0:	bac50513          	addi	a0,a0,-1108 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200ed4:	af8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(n > 0);
ffffffffc0200ed8:	00002697          	auipc	a3,0x2
ffffffffc0200edc:	b8068693          	addi	a3,a3,-1152 # ffffffffc0202a58 <etext+0x24e>
ffffffffc0200ee0:	00002617          	auipc	a2,0x2
ffffffffc0200ee4:	b8060613          	addi	a2,a2,-1152 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200ee8:	05100593          	li	a1,81
ffffffffc0200eec:	00002517          	auipc	a0,0x2
ffffffffc0200ef0:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200ef4:	ad8ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200ef8 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200ef8:	1141                	addi	sp,sp,-16
ffffffffc0200efa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200efc:	c9d5                	beqz	a1,ffffffffc0200fb0 <best_fit_init_memmap+0xb8>
    for (; p != base + n; p ++) {
ffffffffc0200efe:	00259713          	slli	a4,a1,0x2
ffffffffc0200f02:	972e                	add	a4,a4,a1
ffffffffc0200f04:	070e                	slli	a4,a4,0x3
ffffffffc0200f06:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200f0a:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200f0c:	cf11                	beqz	a4,ffffffffc0200f28 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200f0e:	6798                	ld	a4,8(a5)
ffffffffc0200f10:	8b05                	andi	a4,a4,1
ffffffffc0200f12:	c341                	beqz	a4,ffffffffc0200f92 <best_fit_init_memmap+0x9a>
        p->flags = p->property = 0;
ffffffffc0200f14:	0007a823          	sw	zero,16(a5)
ffffffffc0200f18:	0007b423          	sd	zero,8(a5)
ffffffffc0200f1c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f20:	02878793          	addi	a5,a5,40
ffffffffc0200f24:	fed795e3          	bne	a5,a3,ffffffffc0200f0e <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200f28:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200f2a:	00006697          	auipc	a3,0x6
ffffffffc0200f2e:	0ee68693          	addi	a3,a3,238 # ffffffffc0207018 <free_area>
ffffffffc0200f32:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200f34:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0200f36:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200f38:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc0200f3c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f3e:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f40:	9f2d                	addw	a4,a4,a1
ffffffffc0200f42:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f44:	00d79763          	bne	a5,a3,ffffffffc0200f52 <best_fit_init_memmap+0x5a>
ffffffffc0200f48:	a01d                	j	ffffffffc0200f6e <best_fit_init_memmap+0x76>
    return listelm->next;
ffffffffc0200f4a:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200f4c:	02d70a63          	beq	a4,a3,ffffffffc0200f80 <best_fit_init_memmap+0x88>
ffffffffc0200f50:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f52:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200f56:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f4a <best_fit_init_memmap+0x52>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f5a:	6398                	ld	a4,0(a5)
                list_add_before(le, &(base->page_link));
ffffffffc0200f5c:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f60:	e394                	sd	a3,0(a5)
}
ffffffffc0200f62:	60a2                	ld	ra,8(sp)
ffffffffc0200f64:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200f66:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f68:	ed18                	sd	a4,24(a0)
ffffffffc0200f6a:	0141                	addi	sp,sp,16
ffffffffc0200f6c:	8082                	ret
ffffffffc0200f6e:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200f70:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f74:	e398                	sd	a4,0(a5)
ffffffffc0200f76:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200f78:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f7a:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200f7c:	0141                	addi	sp,sp,16
ffffffffc0200f7e:	8082                	ret
ffffffffc0200f80:	60a2                	ld	ra,8(sp)
                list_add(le, &(base->page_link));
ffffffffc0200f82:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f86:	e798                	sd	a4,8(a5)
ffffffffc0200f88:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc0200f8a:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc0200f8c:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200f8e:	0141                	addi	sp,sp,16
ffffffffc0200f90:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200f92:	00002697          	auipc	a3,0x2
ffffffffc0200f96:	de668693          	addi	a3,a3,-538 # ffffffffc0202d78 <etext+0x56e>
ffffffffc0200f9a:	00002617          	auipc	a2,0x2
ffffffffc0200f9e:	ac660613          	addi	a2,a2,-1338 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200fa2:	45dd                	li	a1,23
ffffffffc0200fa4:	00002517          	auipc	a0,0x2
ffffffffc0200fa8:	ad450513          	addi	a0,a0,-1324 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200fac:	a20ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(n > 0);
ffffffffc0200fb0:	00002697          	auipc	a3,0x2
ffffffffc0200fb4:	aa868693          	addi	a3,a3,-1368 # ffffffffc0202a58 <etext+0x24e>
ffffffffc0200fb8:	00002617          	auipc	a2,0x2
ffffffffc0200fbc:	aa860613          	addi	a2,a2,-1368 # ffffffffc0202a60 <etext+0x256>
ffffffffc0200fc0:	45d1                	li	a1,20
ffffffffc0200fc2:	00002517          	auipc	a0,0x2
ffffffffc0200fc6:	ab650513          	addi	a0,a0,-1354 # ffffffffc0202a78 <etext+0x26e>
ffffffffc0200fca:	a02ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200fce <buddy_init>:
static size_t free_count;

static size_t block_size(unsigned order) { return (size_t)1 << order; }

static void buddy_init(void) {
    for (unsigned i = 0; i <= MAX_ORDER; ++i) {
ffffffffc0200fce:	00006797          	auipc	a5,0x6
ffffffffc0200fd2:	15a78793          	addi	a5,a5,346 # ffffffffc0207128 <areas>
ffffffffc0200fd6:	00006717          	auipc	a4,0x6
ffffffffc0200fda:	28270713          	addi	a4,a4,642 # ffffffffc0207258 <objects.0>
    elm->prev = elm->next = elm;
ffffffffc0200fde:	e79c                	sd	a5,8(a5)
ffffffffc0200fe0:	e39c                	sd	a5,0(a5)
ffffffffc0200fe2:	07c1                	addi	a5,a5,16
ffffffffc0200fe4:	fee79de3          	bne	a5,a4,ffffffffc0200fde <buddy_init+0x10>
        list_init(&areas[i]);
    }
    free_count = 0;
ffffffffc0200fe8:	00007797          	auipc	a5,0x7
ffffffffc0200fec:	d007b423          	sd	zero,-760(a5) # ffffffffc0207cf0 <free_count>
}
ffffffffc0200ff0:	8082                	ret

ffffffffc0200ff2 <buddy_nr_free_pages>:
        ++order;
    }
    put_block(base, order);
}

static size_t buddy_nr_free_pages(void) { return free_count; }
ffffffffc0200ff2:	00007517          	auipc	a0,0x7
ffffffffc0200ff6:	cfe53503          	ld	a0,-770(a0) # ffffffffc0207cf0 <free_count>
ffffffffc0200ffa:	8082                	ret

ffffffffc0200ffc <check_lists>:
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ffc:	fcccd8b7          	lui	a7,0xfcccd
ffffffffc0201000:	ccd88893          	addi	a7,a7,-819 # fffffffffccccccd <end+0x3cac4fa1>
ffffffffc0201004:	08b2                	slli	a7,a7,0xc
ffffffffc0201006:	ccd88893          	addi	a7,a7,-819
ffffffffc020100a:	08b2                	slli	a7,a7,0xc
ffffffffc020100c:	ccd88893          	addi	a7,a7,-819

static void check_lists(void) {
ffffffffc0201010:	1141                	addi	sp,sp,-16
ffffffffc0201012:	08b2                	slli	a7,a7,0xc
ffffffffc0201014:	e406                	sd	ra,8(sp)
ffffffffc0201016:	00007e97          	auipc	t4,0x7
ffffffffc020101a:	d0aebe83          	ld	t4,-758(t4) # ffffffffc0207d20 <pages>
ffffffffc020101e:	00003e17          	auipc	t3,0x3
ffffffffc0201022:	86ae3e03          	ld	t3,-1942(t3) # ffffffffc0203888 <nbase>
ffffffffc0201026:	00006817          	auipc	a6,0x6
ffffffffc020102a:	10280813          	addi	a6,a6,258 # ffffffffc0207128 <areas>
    size_t total = 0;
    for (unsigned order = 0; order <= MAX_ORDER; ++order) {
ffffffffc020102e:	4f01                	li	t5,0
    size_t total = 0;
ffffffffc0201030:	4581                	li	a1,0
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc0201032:	4385                	li	t2,1
ffffffffc0201034:	52fd                	li	t0,-1
        list_entry_t *le = &areas[order];
        while ((le = list_next(le)) != &areas[order]) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p) && !(p->flags & ALLOC_HEAD));
ffffffffc0201036:	4309                	li	t1,2
ffffffffc0201038:	ccd88893          	addi	a7,a7,-819
    for (unsigned order = 0; order <= MAX_ORDER; ++order) {
ffffffffc020103c:	4fcd                	li	t6,19
    return listelm->next;
ffffffffc020103e:	00883703          	ld	a4,8(a6)
        while ((le = list_next(le)) != &areas[order]) {
ffffffffc0201042:	02e80f63          	beq	a6,a4,ffffffffc0201080 <check_lists+0x84>
ffffffffc0201046:	01e29533          	sll	a0,t0,t5
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc020104a:	01e39633          	sll	a2,t2,t5
ffffffffc020104e:	fff54513          	not	a0,a0
            assert(PageProperty(p) && !(p->flags & ALLOC_HEAD));
ffffffffc0201052:	ff073683          	ld	a3,-16(a4)
            struct Page *p = le2page(le, page_link);
ffffffffc0201056:	fe870793          	addi	a5,a4,-24
            assert(PageProperty(p) && !(p->flags & ALLOC_HEAD));
ffffffffc020105a:	8a99                	andi	a3,a3,6
ffffffffc020105c:	02669f63          	bne	a3,t1,ffffffffc020109a <check_lists+0x9e>
            assert(p->property == block_size(order));
ffffffffc0201060:	ff876683          	lwu	a3,-8(a4)
ffffffffc0201064:	04c69b63          	bne	a3,a2,ffffffffc02010ba <check_lists+0xbe>
ffffffffc0201068:	41d787b3          	sub	a5,a5,t4
ffffffffc020106c:	878d                	srai	a5,a5,0x3
ffffffffc020106e:	031787b3          	mul	a5,a5,a7
ffffffffc0201072:	97f2                	add	a5,a5,t3
            assert((page2ppn(p) & (block_size(order) - 1)) == 0);
ffffffffc0201074:	8fe9                	and	a5,a5,a0
ffffffffc0201076:	e3b5                	bnez	a5,ffffffffc02010da <check_lists+0xde>
ffffffffc0201078:	6718                	ld	a4,8(a4)
            total += p->property;
ffffffffc020107a:	95b2                	add	a1,a1,a2
        while ((le = list_next(le)) != &areas[order]) {
ffffffffc020107c:	fd071be3          	bne	a4,a6,ffffffffc0201052 <check_lists+0x56>
    for (unsigned order = 0; order <= MAX_ORDER; ++order) {
ffffffffc0201080:	2f05                	addiw	t5,t5,1
ffffffffc0201082:	0841                	addi	a6,a6,16
ffffffffc0201084:	fbff1de3          	bne	t5,t6,ffffffffc020103e <check_lists+0x42>
        }
    }
    assert(total == free_count);
ffffffffc0201088:	00007797          	auipc	a5,0x7
ffffffffc020108c:	c687b783          	ld	a5,-920(a5) # ffffffffc0207cf0 <free_count>
ffffffffc0201090:	06b79563          	bne	a5,a1,ffffffffc02010fa <check_lists+0xfe>
}
ffffffffc0201094:	60a2                	ld	ra,8(sp)
ffffffffc0201096:	0141                	addi	sp,sp,16
ffffffffc0201098:	8082                	ret
            assert(PageProperty(p) && !(p->flags & ALLOC_HEAD));
ffffffffc020109a:	00002697          	auipc	a3,0x2
ffffffffc020109e:	d0668693          	addi	a3,a3,-762 # ffffffffc0202da0 <etext+0x596>
ffffffffc02010a2:	00002617          	auipc	a2,0x2
ffffffffc02010a6:	9be60613          	addi	a2,a2,-1602 # ffffffffc0202a60 <etext+0x256>
ffffffffc02010aa:	06800593          	li	a1,104
ffffffffc02010ae:	00002517          	auipc	a0,0x2
ffffffffc02010b2:	d2250513          	addi	a0,a0,-734 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc02010b6:	916ff0ef          	jal	ffffffffc02001cc <__panic>
            assert(p->property == block_size(order));
ffffffffc02010ba:	00002697          	auipc	a3,0x2
ffffffffc02010be:	d2e68693          	addi	a3,a3,-722 # ffffffffc0202de8 <etext+0x5de>
ffffffffc02010c2:	00002617          	auipc	a2,0x2
ffffffffc02010c6:	99e60613          	addi	a2,a2,-1634 # ffffffffc0202a60 <etext+0x256>
ffffffffc02010ca:	06900593          	li	a1,105
ffffffffc02010ce:	00002517          	auipc	a0,0x2
ffffffffc02010d2:	d0250513          	addi	a0,a0,-766 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc02010d6:	8f6ff0ef          	jal	ffffffffc02001cc <__panic>
            assert((page2ppn(p) & (block_size(order) - 1)) == 0);
ffffffffc02010da:	00002697          	auipc	a3,0x2
ffffffffc02010de:	d3668693          	addi	a3,a3,-714 # ffffffffc0202e10 <etext+0x606>
ffffffffc02010e2:	00002617          	auipc	a2,0x2
ffffffffc02010e6:	97e60613          	addi	a2,a2,-1666 # ffffffffc0202a60 <etext+0x256>
ffffffffc02010ea:	06a00593          	li	a1,106
ffffffffc02010ee:	00002517          	auipc	a0,0x2
ffffffffc02010f2:	ce250513          	addi	a0,a0,-798 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc02010f6:	8d6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(total == free_count);
ffffffffc02010fa:	00002697          	auipc	a3,0x2
ffffffffc02010fe:	d4668693          	addi	a3,a3,-698 # ffffffffc0202e40 <etext+0x636>
ffffffffc0201102:	00002617          	auipc	a2,0x2
ffffffffc0201106:	95e60613          	addi	a2,a2,-1698 # ffffffffc0202a60 <etext+0x256>
ffffffffc020110a:	06e00593          	li	a1,110
ffffffffc020110e:	00002517          	auipc	a0,0x2
ffffffffc0201112:	cc250513          	addi	a0,a0,-830 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc0201116:	8b6ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc020111a <buddy_free_pages.part.0>:
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc020111a:	1141                	addi	sp,sp,-16
ffffffffc020111c:	e406                	sd	ra,8(sp)
    while (block_size(order) < n) { ++order; }
ffffffffc020111e:	4785                	li	a5,1
ffffffffc0201120:	10b7fd63          	bgeu	a5,a1,ffffffffc020123a <buddy_free_pages.part.0+0x120>
    unsigned order = 0;
ffffffffc0201124:	4681                	li	a3,0
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc0201126:	4705                	li	a4,1
    while (block_size(order) < n) { ++order; }
ffffffffc0201128:	2685                	addiw	a3,a3,1
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc020112a:	00d717b3          	sll	a5,a4,a3
    while (block_size(order) < n) { ++order; }
ffffffffc020112e:	feb7ede3          	bltu	a5,a1,ffffffffc0201128 <buddy_free_pages.part.0+0xe>
    assert((base->flags & ALLOC_HEAD) && !PageProperty(base));
ffffffffc0201132:	6518                	ld	a4,8(a0)
ffffffffc0201134:	4611                	li	a2,4
ffffffffc0201136:	00677593          	andi	a1,a4,6
ffffffffc020113a:	10c59363          	bne	a1,a2,ffffffffc0201240 <buddy_free_pages.part.0+0x126>
    assert(base->property == block_size(order));
ffffffffc020113e:	01056603          	lwu	a2,16(a0)
ffffffffc0201142:	10f61f63          	bne	a2,a5,ffffffffc0201260 <buddy_free_pages.part.0+0x146>
    free_count += block_size(order);
ffffffffc0201146:	00007597          	auipc	a1,0x7
ffffffffc020114a:	baa58593          	addi	a1,a1,-1110 # ffffffffc0207cf0 <free_count>
ffffffffc020114e:	6190                	ld	a2,0(a1)
    base->flags &= ~ALLOC_HEAD;
ffffffffc0201150:	9b6d                	andi	a4,a4,-5
ffffffffc0201152:	e518                	sd	a4,8(a0)
    free_count += block_size(order);
ffffffffc0201154:	97b2                	add	a5,a5,a2
ffffffffc0201156:	e19c                	sd	a5,0(a1)
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc0201158:	4605                	li	a2,1
    base->property = 0;
ffffffffc020115a:	00052823          	sw	zero,16(a0)
    while (order < MAX_ORDER) {
ffffffffc020115e:	47c5                	li	a5,17
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc0201160:	00d61633          	sll	a2,a2,a3
    while (order < MAX_ORDER) {
ffffffffc0201164:	0ad7e063          	bltu	a5,a3,ffffffffc0201204 <buddy_free_pages.part.0+0xea>
ffffffffc0201168:	fcccd8b7          	lui	a7,0xfcccd
ffffffffc020116c:	ccd88893          	addi	a7,a7,-819 # fffffffffccccccd <end+0x3cac4fa1>
ffffffffc0201170:	08b2                	slli	a7,a7,0xc
ffffffffc0201172:	ccd88893          	addi	a7,a7,-819
ffffffffc0201176:	08b2                	slli	a7,a7,0xc
ffffffffc0201178:	ccd88893          	addi	a7,a7,-819
ffffffffc020117c:	08b2                	slli	a7,a7,0xc
ffffffffc020117e:	00007317          	auipc	t1,0x7
ffffffffc0201182:	ba233303          	ld	t1,-1118(t1) # ffffffffc0207d20 <pages>
ffffffffc0201186:	00002597          	auipc	a1,0x2
ffffffffc020118a:	7025b583          	ld	a1,1794(a1) # ffffffffc0203888 <nbase>
        if (other < nbase || other >= npage || block_size(order) > npage - other) {
ffffffffc020118e:	00007e17          	auipc	t3,0x7
ffffffffc0201192:	b8ae3e03          	ld	t3,-1142(t3) # ffffffffc0207d18 <npage>
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc0201196:	4e85                	li	t4,1
ffffffffc0201198:	ccd88893          	addi	a7,a7,-819
    while (order < MAX_ORDER) {
ffffffffc020119c:	4f49                	li	t5,18
ffffffffc020119e:	a0b9                	j	ffffffffc02011ec <buddy_free_pages.part.0+0xd2>
        if (other < nbase || other >= npage || block_size(order) > npage - other) {
ffffffffc02011a0:	07c7f163          	bgeu	a5,t3,ffffffffc0201202 <buddy_free_pages.part.0+0xe8>
ffffffffc02011a4:	40fe0733          	sub	a4,t3,a5
ffffffffc02011a8:	04c76d63          	bltu	a4,a2,ffffffffc0201202 <buddy_free_pages.part.0+0xe8>
        struct Page *partner = pages + other - nbase;
ffffffffc02011ac:	8f8d                	sub	a5,a5,a1
ffffffffc02011ae:	00279713          	slli	a4,a5,0x2
ffffffffc02011b2:	97ba                	add	a5,a5,a4
ffffffffc02011b4:	078e                	slli	a5,a5,0x3
ffffffffc02011b6:	979a                	add	a5,a5,t1
        if (!PageProperty(partner) || partner->property != block_size(order)) {
ffffffffc02011b8:	6798                	ld	a4,8(a5)
ffffffffc02011ba:	00277813          	andi	a6,a4,2
ffffffffc02011be:	04080263          	beqz	a6,ffffffffc0201202 <buddy_free_pages.part.0+0xe8>
ffffffffc02011c2:	0107e803          	lwu	a6,16(a5)
ffffffffc02011c6:	03061e63          	bne	a2,a6,ffffffffc0201202 <buddy_free_pages.part.0+0xe8>
    __list_del(listelm->prev, listelm->next);
ffffffffc02011ca:	0187b803          	ld	a6,24(a5)
ffffffffc02011ce:	7390                	ld	a2,32(a5)
        ClearPageProperty(partner);
ffffffffc02011d0:	9b75                	andi	a4,a4,-3
    prev->next = next;
ffffffffc02011d2:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc02011d6:	01063023          	sd	a6,0(a2)
ffffffffc02011da:	e798                	sd	a4,8(a5)
        partner->property = 0;
ffffffffc02011dc:	0007a823          	sw	zero,16(a5)
        if (partner < base) { base = partner; }
ffffffffc02011e0:	00a7f363          	bgeu	a5,a0,ffffffffc02011e6 <buddy_free_pages.part.0+0xcc>
ffffffffc02011e4:	853e                	mv	a0,a5
        ++order;
ffffffffc02011e6:	2685                	addiw	a3,a3,1
    while (order < MAX_ORDER) {
ffffffffc02011e8:	05e68563          	beq	a3,t5,ffffffffc0201232 <buddy_free_pages.part.0+0x118>
ffffffffc02011ec:	406507b3          	sub	a5,a0,t1
ffffffffc02011f0:	878d                	srai	a5,a5,0x3
ffffffffc02011f2:	031787b3          	mul	a5,a5,a7
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc02011f6:	00de9633          	sll	a2,t4,a3
ffffffffc02011fa:	97ae                	add	a5,a5,a1
        ppn_t other = page2ppn(base) ^ block_size(order);
ffffffffc02011fc:	8fb1                	xor	a5,a5,a2
        if (other < nbase || other >= npage || block_size(order) > npage - other) {
ffffffffc02011fe:	fab7f1e3          	bgeu	a5,a1,ffffffffc02011a0 <buddy_free_pages.part.0+0x86>
    SetPageProperty(p);
ffffffffc0201202:	6518                	ld	a4,8(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201204:	02069793          	slli	a5,a3,0x20
ffffffffc0201208:	01c7d693          	srli	a3,a5,0x1c
ffffffffc020120c:	00006797          	auipc	a5,0x6
ffffffffc0201210:	f1c78793          	addi	a5,a5,-228 # ffffffffc0207128 <areas>
ffffffffc0201214:	97b6                	add	a5,a5,a3
ffffffffc0201216:	6794                	ld	a3,8(a5)
ffffffffc0201218:	00276713          	ori	a4,a4,2
ffffffffc020121c:	e518                	sd	a4,8(a0)
    p->property = block_size(order);
ffffffffc020121e:	c910                	sw	a2,16(a0)
    list_add(&areas[order], &p->page_link);
ffffffffc0201220:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201224:	e298                	sd	a4,0(a3)
}
ffffffffc0201226:	60a2                	ld	ra,8(sp)
ffffffffc0201228:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020122a:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc020122c:	ed1c                	sd	a5,24(a0)
ffffffffc020122e:	0141                	addi	sp,sp,16
ffffffffc0201230:	8082                	ret
    SetPageProperty(p);
ffffffffc0201232:	6518                	ld	a4,8(a0)
ffffffffc0201234:	00040637          	lui	a2,0x40
ffffffffc0201238:	b7f1                	j	ffffffffc0201204 <buddy_free_pages.part.0+0xea>
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc020123a:	4785                	li	a5,1
    unsigned order = 0;
ffffffffc020123c:	4681                	li	a3,0
ffffffffc020123e:	bdd5                	j	ffffffffc0201132 <buddy_free_pages.part.0+0x18>
    assert((base->flags & ALLOC_HEAD) && !PageProperty(base));
ffffffffc0201240:	00002697          	auipc	a3,0x2
ffffffffc0201244:	c1868693          	addi	a3,a3,-1000 # ffffffffc0202e58 <etext+0x64e>
ffffffffc0201248:	00002617          	auipc	a2,0x2
ffffffffc020124c:	81860613          	addi	a2,a2,-2024 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201250:	04900593          	li	a1,73
ffffffffc0201254:	00002517          	auipc	a0,0x2
ffffffffc0201258:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc020125c:	f71fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(base->property == block_size(order));
ffffffffc0201260:	00002697          	auipc	a3,0x2
ffffffffc0201264:	c3068693          	addi	a3,a3,-976 # ffffffffc0202e90 <etext+0x686>
ffffffffc0201268:	00001617          	auipc	a2,0x1
ffffffffc020126c:	7f860613          	addi	a2,a2,2040 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201270:	04a00593          	li	a1,74
ffffffffc0201274:	00002517          	auipc	a0,0x2
ffffffffc0201278:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc020127c:	f51fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0201280 <buddy_free_pages>:
    assert(n > 0 && n <= block_size(MAX_ORDER));
ffffffffc0201280:	fff58793          	addi	a5,a1,-1
ffffffffc0201284:	00040737          	lui	a4,0x40
ffffffffc0201288:	00e7f363          	bgeu	a5,a4,ffffffffc020128e <buddy_free_pages+0xe>
ffffffffc020128c:	b579                	j	ffffffffc020111a <buddy_free_pages.part.0>
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc020128e:	1141                	addi	sp,sp,-16
    assert(n > 0 && n <= block_size(MAX_ORDER));
ffffffffc0201290:	00002697          	auipc	a3,0x2
ffffffffc0201294:	c2868693          	addi	a3,a3,-984 # ffffffffc0202eb8 <etext+0x6ae>
ffffffffc0201298:	00001617          	auipc	a2,0x1
ffffffffc020129c:	7c860613          	addi	a2,a2,1992 # ffffffffc0202a60 <etext+0x256>
ffffffffc02012a0:	04600593          	li	a1,70
ffffffffc02012a4:	00002517          	auipc	a0,0x2
ffffffffc02012a8:	b2c50513          	addi	a0,a0,-1236 # ffffffffc0202dd0 <etext+0x5c6>
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc02012ac:	e406                	sd	ra,8(sp)
    assert(n > 0 && n <= block_size(MAX_ORDER));
ffffffffc02012ae:	f1ffe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02012b2 <buddy_init_memmap.part.0>:
    for (size_t i = 0; i < n; ++i) {
ffffffffc02012b2:	c5e1                	beqz	a1,ffffffffc020137a <buddy_init_memmap.part.0+0xc8>
ffffffffc02012b4:	87aa                	mv	a5,a0
ffffffffc02012b6:	4681                	li	a3,0
        assert(PageReserved(base + i));
ffffffffc02012b8:	6798                	ld	a4,8(a5)
ffffffffc02012ba:	8b05                	andi	a4,a4,1
ffffffffc02012bc:	c361                	beqz	a4,ffffffffc020137c <buddy_init_memmap.part.0+0xca>
        base[i].flags = base[i].property = 0;
ffffffffc02012be:	0007a823          	sw	zero,16(a5)
ffffffffc02012c2:	0007b423          	sd	zero,8(a5)
        base[i].ref = 0;
ffffffffc02012c6:	0007a023          	sw	zero,0(a5)
    for (size_t i = 0; i < n; ++i) {
ffffffffc02012ca:	0685                	addi	a3,a3,1
ffffffffc02012cc:	02878793          	addi	a5,a5,40
ffffffffc02012d0:	feb694e3          	bne	a3,a1,ffffffffc02012b8 <buddy_init_memmap.part.0+0x6>
ffffffffc02012d4:	fcccde37          	lui	t3,0xfcccd
ffffffffc02012d8:	ccde0e13          	addi	t3,t3,-819 # fffffffffccccccd <end+0x3cac4fa1>
    free_count += n;
ffffffffc02012dc:	00007717          	auipc	a4,0x7
ffffffffc02012e0:	a1470713          	addi	a4,a4,-1516 # ffffffffc0207cf0 <free_count>
ffffffffc02012e4:	0e32                	slli	t3,t3,0xc
ffffffffc02012e6:	631c                	ld	a5,0(a4)
ffffffffc02012e8:	ccde0e13          	addi	t3,t3,-819
ffffffffc02012ec:	0e32                	slli	t3,t3,0xc
ffffffffc02012ee:	ccde0e13          	addi	t3,t3,-819
ffffffffc02012f2:	97ae                	add	a5,a5,a1
ffffffffc02012f4:	0e32                	slli	t3,t3,0xc
ffffffffc02012f6:	e31c                	sd	a5,0(a4)
ffffffffc02012f8:	00007297          	auipc	t0,0x7
ffffffffc02012fc:	a282b283          	ld	t0,-1496(t0) # ffffffffc0207d20 <pages>
ffffffffc0201300:	00002f97          	auipc	t6,0x2
ffffffffc0201304:	588fbf83          	ld	t6,1416(t6) # ffffffffc0203888 <nbase>
ffffffffc0201308:	00006f17          	auipc	t5,0x6
ffffffffc020130c:	e20f0f13          	addi	t5,t5,-480 # ffffffffc0207128 <areas>
ffffffffc0201310:	ccde0e13          	addi	t3,t3,-819
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc0201314:	4805                	li	a6,1
               (page2ppn(base) & (block_size(order) - 1)) != 0) {
ffffffffc0201316:	537d                	li	t1,-1
        base += block_size(order);
ffffffffc0201318:	02800e93          	li	t4,40
ffffffffc020131c:	405508b3          	sub	a7,a0,t0
ffffffffc0201320:	4038d893          	srai	a7,a7,0x3
ffffffffc0201324:	03c888b3          	mul	a7,a7,t3
        unsigned order = MAX_ORDER;
ffffffffc0201328:	47c9                	li	a5,18
ffffffffc020132a:	98fe                	add	a7,a7,t6
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc020132c:	00f816b3          	sll	a3,a6,a5
ffffffffc0201330:	863e                	mv	a2,a5
        while (block_size(order) > n ||
ffffffffc0201332:	00d5e963          	bltu	a1,a3,ffffffffc0201344 <buddy_init_memmap.part.0+0x92>
               (page2ppn(base) & (block_size(order) - 1)) != 0) {
ffffffffc0201336:	00f31733          	sll	a4,t1,a5
ffffffffc020133a:	fff74713          	not	a4,a4
ffffffffc020133e:	01177733          	and	a4,a4,a7
        while (block_size(order) > n ||
ffffffffc0201342:	c319                	beqz	a4,ffffffffc0201348 <buddy_init_memmap.part.0+0x96>
            --order;
ffffffffc0201344:	37fd                	addiw	a5,a5,-1
ffffffffc0201346:	b7dd                	j	ffffffffc020132c <buddy_init_memmap.part.0+0x7a>
    __list_add(elm, listelm, listelm->next);
ffffffffc0201348:	02079893          	slli	a7,a5,0x20
    SetPageProperty(p);
ffffffffc020134c:	6518                	ld	a4,8(a0)
ffffffffc020134e:	01c8d793          	srli	a5,a7,0x1c
ffffffffc0201352:	97fa                	add	a5,a5,t5
ffffffffc0201354:	0087b883          	ld	a7,8(a5)
ffffffffc0201358:	00276713          	ori	a4,a4,2
ffffffffc020135c:	e518                	sd	a4,8(a0)
    p->property = block_size(order);
ffffffffc020135e:	c914                	sw	a3,16(a0)
    list_add(&areas[order], &p->page_link);
ffffffffc0201360:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201364:	00e8b023          	sd	a4,0(a7)
ffffffffc0201368:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020136a:	03153023          	sd	a7,32(a0)
    elm->prev = prev;
ffffffffc020136e:	ed1c                	sd	a5,24(a0)
        base += block_size(order);
ffffffffc0201370:	00ce9633          	sll	a2,t4,a2
        n -= block_size(order);
ffffffffc0201374:	8d95                	sub	a1,a1,a3
        base += block_size(order);
ffffffffc0201376:	9532                	add	a0,a0,a2
    while (n != 0) {
ffffffffc0201378:	f1d5                	bnez	a1,ffffffffc020131c <buddy_init_memmap.part.0+0x6a>
ffffffffc020137a:	8082                	ret
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc020137c:	1141                	addi	sp,sp,-16
        assert(PageReserved(base + i));
ffffffffc020137e:	00002697          	auipc	a3,0x2
ffffffffc0201382:	b6268693          	addi	a3,a3,-1182 # ffffffffc0202ee0 <etext+0x6d6>
ffffffffc0201386:	00001617          	auipc	a2,0x1
ffffffffc020138a:	6da60613          	addi	a2,a2,1754 # ffffffffc0202a60 <etext+0x256>
ffffffffc020138e:	45f1                	li	a1,28
ffffffffc0201390:	00002517          	auipc	a0,0x2
ffffffffc0201394:	a4050513          	addi	a0,a0,-1472 # ffffffffc0202dd0 <etext+0x5c6>
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0201398:	e406                	sd	ra,8(sp)
        assert(PageReserved(base + i));
ffffffffc020139a:	e33fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc020139e <buddy_init_memmap>:
    assert(n > 0);
ffffffffc020139e:	c191                	beqz	a1,ffffffffc02013a2 <buddy_init_memmap+0x4>
ffffffffc02013a0:	bf09                	j	ffffffffc02012b2 <buddy_init_memmap.part.0>
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc02013a2:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02013a4:	00001697          	auipc	a3,0x1
ffffffffc02013a8:	6b468693          	addi	a3,a3,1716 # ffffffffc0202a58 <etext+0x24e>
ffffffffc02013ac:	00001617          	auipc	a2,0x1
ffffffffc02013b0:	6b460613          	addi	a2,a2,1716 # ffffffffc0202a60 <etext+0x256>
ffffffffc02013b4:	45e9                	li	a1,26
ffffffffc02013b6:	00002517          	auipc	a0,0x2
ffffffffc02013ba:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0202dd0 <etext+0x5c6>
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc02013be:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02013c0:	e0dfe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02013c4 <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc02013c4:	c175                	beqz	a0,ffffffffc02014a8 <buddy_alloc_pages+0xe4>
    if (n > free_count || n > block_size(MAX_ORDER)) {
ffffffffc02013c6:	00007297          	auipc	t0,0x7
ffffffffc02013ca:	92a28293          	addi	t0,t0,-1750 # ffffffffc0207cf0 <free_count>
ffffffffc02013ce:	0002bf83          	ld	t6,0(t0)
ffffffffc02013d2:	0cafe663          	bltu	t6,a0,ffffffffc020149e <buddy_alloc_pages+0xda>
ffffffffc02013d6:	000407b7          	lui	a5,0x40
ffffffffc02013da:	0ca7e263          	bltu	a5,a0,ffffffffc020149e <buddy_alloc_pages+0xda>
    while (block_size(want) < n) { ++want; }
ffffffffc02013de:	4785                	li	a5,1
ffffffffc02013e0:	0cf50163          	beq	a0,a5,ffffffffc02014a2 <buddy_alloc_pages+0xde>
    unsigned want = 0, found;
ffffffffc02013e4:	4601                	li	a2,0
    while (block_size(want) < n) { ++want; }
ffffffffc02013e6:	2605                	addiw	a2,a2,1
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc02013e8:	00c79333          	sll	t1,a5,a2
    while (block_size(want) < n) { ++want; }
ffffffffc02013ec:	fea36de3          	bltu	t1,a0,ffffffffc02013e6 <buddy_alloc_pages+0x22>
    for (found = want; found <= MAX_ORDER; ++found) {
ffffffffc02013f0:	47c9                	li	a5,18
ffffffffc02013f2:	0ac7e663          	bltu	a5,a2,ffffffffc020149e <buddy_alloc_pages+0xda>
ffffffffc02013f6:	87b2                	mv	a5,a2
ffffffffc02013f8:	00006697          	auipc	a3,0x6
ffffffffc02013fc:	d3068693          	addi	a3,a3,-720 # ffffffffc0207128 <areas>
ffffffffc0201400:	45cd                	li	a1,19
ffffffffc0201402:	a021                	j	ffffffffc020140a <buddy_alloc_pages+0x46>
ffffffffc0201404:	2785                	addiw	a5,a5,1 # 40001 <kern_entry-0xffffffffc01bffff>
ffffffffc0201406:	08b78c63          	beq	a5,a1,ffffffffc020149e <buddy_alloc_pages+0xda>
        if (!list_empty(&areas[found])) { break; }
ffffffffc020140a:	02079513          	slli	a0,a5,0x20
ffffffffc020140e:	01c55713          	srli	a4,a0,0x1c
ffffffffc0201412:	9736                	add	a4,a4,a3
ffffffffc0201414:	00873803          	ld	a6,8(a4)
ffffffffc0201418:	fee806e3          	beq	a6,a4,ffffffffc0201404 <buddy_alloc_pages+0x40>
    __list_del(listelm->prev, listelm->next);
ffffffffc020141c:	00083883          	ld	a7,0(a6)
ffffffffc0201420:	00883583          	ld	a1,8(a6)
    ClearPageProperty(p);
ffffffffc0201424:	ff083703          	ld	a4,-16(a6)
    struct Page *p = le2page(list_next(&areas[found]), page_link);
ffffffffc0201428:	fe880513          	addi	a0,a6,-24
    prev->next = next;
ffffffffc020142c:	00b8b423          	sd	a1,8(a7)
    next->prev = prev;
ffffffffc0201430:	0115b023          	sd	a7,0(a1)
    ClearPageProperty(p);
ffffffffc0201434:	9b75                	andi	a4,a4,-3
ffffffffc0201436:	fee83823          	sd	a4,-16(a6)
    while (found > want) {
ffffffffc020143a:	04f67763          	bgeu	a2,a5,ffffffffc0201488 <buddy_alloc_pages+0xc4>
ffffffffc020143e:	37fd                	addiw	a5,a5,-1
ffffffffc0201440:	02079593          	slli	a1,a5,0x20
ffffffffc0201444:	01c5d713          	srli	a4,a1,0x1c
ffffffffc0201448:	96ba                	add	a3,a3,a4
        put_block(p + block_size(found), found);
ffffffffc020144a:	02800f13          	li	t5,40
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc020144e:	4e85                	li	t4,1
ffffffffc0201450:	a011                	j	ffffffffc0201454 <buddy_alloc_pages+0x90>
ffffffffc0201452:	37fd                	addiw	a5,a5,-1
        put_block(p + block_size(found), found);
ffffffffc0201454:	00ff1733          	sll	a4,t5,a5
ffffffffc0201458:	972a                	add	a4,a4,a0
    SetPageProperty(p);
ffffffffc020145a:	670c                	ld	a1,8(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc020145c:	0086b883          	ld	a7,8(a3)
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc0201460:	00fe9e33          	sll	t3,t4,a5
    SetPageProperty(p);
ffffffffc0201464:	0025e593          	ori	a1,a1,2
ffffffffc0201468:	e70c                	sd	a1,8(a4)
    p->property = block_size(order);
ffffffffc020146a:	01c72823          	sw	t3,16(a4)
    list_add(&areas[order], &p->page_link);
ffffffffc020146e:	01870593          	addi	a1,a4,24
    prev->next = next->prev = elm;
ffffffffc0201472:	00b8b023          	sd	a1,0(a7)
ffffffffc0201476:	e68c                	sd	a1,8(a3)
    elm->prev = prev;
ffffffffc0201478:	ef14                	sd	a3,24(a4)
    elm->next = next;
ffffffffc020147a:	03173023          	sd	a7,32(a4)
    while (found > want) {
ffffffffc020147e:	16c1                	addi	a3,a3,-16
ffffffffc0201480:	fcf619e3          	bne	a2,a5,ffffffffc0201452 <buddy_alloc_pages+0x8e>
    p->flags |= ALLOC_HEAD;
ffffffffc0201484:	ff083703          	ld	a4,-16(a6)
ffffffffc0201488:	00476713          	ori	a4,a4,4
    free_count -= block_size(want);
ffffffffc020148c:	406f8fb3          	sub	t6,t6,t1
    p->property = block_size(want);
ffffffffc0201490:	fe682c23          	sw	t1,-8(a6)
    p->flags |= ALLOC_HEAD;
ffffffffc0201494:	fee83823          	sd	a4,-16(a6)
    free_count -= block_size(want);
ffffffffc0201498:	01f2b023          	sd	t6,0(t0)
    return p;
ffffffffc020149c:	8082                	ret
        return NULL;
ffffffffc020149e:	4501                	li	a0,0
}
ffffffffc02014a0:	8082                	ret
static size_t block_size(unsigned order) { return (size_t)1 << order; }
ffffffffc02014a2:	4305                	li	t1,1
    unsigned want = 0, found;
ffffffffc02014a4:	4601                	li	a2,0
ffffffffc02014a6:	bf81                	j	ffffffffc02013f6 <buddy_alloc_pages+0x32>
static struct Page *buddy_alloc_pages(size_t n) {
ffffffffc02014a8:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02014aa:	00001697          	auipc	a3,0x1
ffffffffc02014ae:	5ae68693          	addi	a3,a3,1454 # ffffffffc0202a58 <etext+0x24e>
ffffffffc02014b2:	00001617          	auipc	a2,0x1
ffffffffc02014b6:	5ae60613          	addi	a2,a2,1454 # ffffffffc0202a60 <etext+0x256>
ffffffffc02014ba:	02e00593          	li	a1,46
ffffffffc02014be:	00002517          	auipc	a0,0x2
ffffffffc02014c2:	91250513          	addi	a0,a0,-1774 # ffffffffc0202dd0 <etext+0x5c6>
static struct Page *buddy_alloc_pages(size_t n) {
ffffffffc02014c6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02014c8:	d05fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02014cc <buddy_check>:

static void buddy_check(void) {
ffffffffc02014cc:	7161                	addi	sp,sp,-432
ffffffffc02014ce:	f6de                	sd	s7,360(sp)
    size_t before = free_count;
    struct Page *a = buddy_alloc_pages(1);
ffffffffc02014d0:	4505                	li	a0,1
    size_t before = free_count;
ffffffffc02014d2:	00007b97          	auipc	s7,0x7
ffffffffc02014d6:	81eb8b93          	addi	s7,s7,-2018 # ffffffffc0207cf0 <free_count>
static void buddy_check(void) {
ffffffffc02014da:	f706                	sd	ra,424(sp)
ffffffffc02014dc:	ef26                	sd	s1,408(sp)
ffffffffc02014de:	eb4a                	sd	s2,400(sp)
ffffffffc02014e0:	f2e2                	sd	s8,352(sp)
ffffffffc02014e2:	f322                	sd	s0,416(sp)
ffffffffc02014e4:	e74e                	sd	s3,392(sp)
ffffffffc02014e6:	e352                	sd	s4,384(sp)
ffffffffc02014e8:	fed6                	sd	s5,376(sp)
ffffffffc02014ea:	fada                	sd	s6,368(sp)
ffffffffc02014ec:	eee6                	sd	s9,344(sp)
ffffffffc02014ee:	eaea                	sd	s10,336(sp)
ffffffffc02014f0:	e6ee                	sd	s11,328(sp)
    size_t before = free_count;
ffffffffc02014f2:	000bbc03          	ld	s8,0(s7)
    struct Page *a = buddy_alloc_pages(1);
ffffffffc02014f6:	ecfff0ef          	jal	ffffffffc02013c4 <buddy_alloc_pages>
ffffffffc02014fa:	892a                	mv	s2,a0
    struct Page *b = buddy_alloc_pages(3);
ffffffffc02014fc:	450d                	li	a0,3
ffffffffc02014fe:	ec7ff0ef          	jal	ffffffffc02013c4 <buddy_alloc_pages>
ffffffffc0201502:	84aa                	mv	s1,a0
    struct Page *c = buddy_alloc_pages(5);
ffffffffc0201504:	4515                	li	a0,5
ffffffffc0201506:	ebfff0ef          	jal	ffffffffc02013c4 <buddy_alloc_pages>
    assert(a && b && c);
ffffffffc020150a:	32090b63          	beqz	s2,ffffffffc0201840 <buddy_check+0x374>
ffffffffc020150e:	32048963          	beqz	s1,ffffffffc0201840 <buddy_check+0x374>
ffffffffc0201512:	842a                	mv	s0,a0
ffffffffc0201514:	32050663          	beqz	a0,ffffffffc0201840 <buddy_check+0x374>
    assert(free_count == before - 13);
ffffffffc0201518:	000bb783          	ld	a5,0(s7)
ffffffffc020151c:	ff3c0713          	addi	a4,s8,-13
ffffffffc0201520:	30f71063          	bne	a4,a5,ffffffffc0201820 <buddy_check+0x354>
    assert(a + 1 <= b || b + 4 <= a);
ffffffffc0201524:	02890793          	addi	a5,s2,40
ffffffffc0201528:	00f4f663          	bgeu	s1,a5,ffffffffc0201534 <buddy_check+0x68>
ffffffffc020152c:	0a048713          	addi	a4,s1,160
ffffffffc0201530:	26e96863          	bltu	s2,a4,ffffffffc02017a0 <buddy_check+0x2d4>
    assert(a + 1 <= c || c + 8 <= a);
ffffffffc0201534:	22f46263          	bltu	s0,a5,ffffffffc0201758 <buddy_check+0x28c>
    assert(b + 4 <= c || c + 8 <= b);
ffffffffc0201538:	0a048793          	addi	a5,s1,160
ffffffffc020153c:	00f47663          	bgeu	s0,a5,ffffffffc0201548 <buddy_check+0x7c>
ffffffffc0201540:	14040793          	addi	a5,s0,320
ffffffffc0201544:	3af4ee63          	bltu	s1,a5,ffffffffc0201900 <buddy_check+0x434>
    assert(n > 0 && n <= block_size(MAX_ORDER));
ffffffffc0201548:	458d                	li	a1,3
ffffffffc020154a:	8526                	mv	a0,s1
ffffffffc020154c:	bcfff0ef          	jal	ffffffffc020111a <buddy_free_pages.part.0>
ffffffffc0201550:	4585                	li	a1,1
ffffffffc0201552:	854a                	mv	a0,s2
ffffffffc0201554:	bc7ff0ef          	jal	ffffffffc020111a <buddy_free_pages.part.0>
ffffffffc0201558:	4595                	li	a1,5
ffffffffc020155a:	8522                	mv	a0,s0
ffffffffc020155c:	bbfff0ef          	jal	ffffffffc020111a <buddy_free_pages.part.0>
    size_t held = free_count;
    assert(buddy_alloc_pages(~(size_t)0) == NULL && free_count == held);
    buddy_free_pages(b, 3);
    buddy_free_pages(a, 1);
    buddy_free_pages(c, 5);
    assert(free_count == before);
ffffffffc0201560:	000bb783          	ld	a5,0(s7)
ffffffffc0201564:	37879e63          	bne	a5,s8,ffffffffc02018e0 <buddy_check+0x414>
    check_lists();
ffffffffc0201568:	a95ff0ef          	jal	ffffffffc0200ffc <check_lists>

    // Reserve a real, aligned arena, then temporarily isolate the allocator.
    struct Page *arena = buddy_alloc_pages(64);
ffffffffc020156c:	04000513          	li	a0,64
ffffffffc0201570:	e55ff0ef          	jal	ffffffffc02013c4 <buddy_alloc_pages>
ffffffffc0201574:	8b2a                	mv	s6,a0
    assert(arena != NULL);
ffffffffc0201576:	34050563          	beqz	a0,ffffffffc02018c0 <buddy_check+0x3f4>
ffffffffc020157a:	00006497          	auipc	s1,0x6
ffffffffc020157e:	bae48493          	addi	s1,s1,-1106 # ffffffffc0207128 <areas>
ffffffffc0201582:	0800                	addi	s0,sp,16
ffffffffc0201584:	00006a97          	auipc	s5,0x6
ffffffffc0201588:	cd4a8a93          	addi	s5,s5,-812 # ffffffffc0207258 <objects.0>
ffffffffc020158c:	8722                	mv	a4,s0
ffffffffc020158e:	87a6                	mv	a5,s1
    list_entry_t saved[MAX_ORDER + 1];
    for (unsigned i = 0; i <= MAX_ORDER; ++i) { saved[i] = areas[i]; }
ffffffffc0201590:	6390                	ld	a2,0(a5)
ffffffffc0201592:	6794                	ld	a3,8(a5)
ffffffffc0201594:	07c1                	addi	a5,a5,16
ffffffffc0201596:	e310                	sd	a2,0(a4)
ffffffffc0201598:	e714                	sd	a3,8(a4)
ffffffffc020159a:	0741                	addi	a4,a4,16
ffffffffc020159c:	ff579ae3          	bne	a5,s5,ffffffffc0201590 <buddy_check+0xc4>
    size_t saved_count = free_count;
ffffffffc02015a0:	000bb783          	ld	a5,0(s7)
ffffffffc02015a4:	e43e                	sd	a5,8(sp)
ffffffffc02015a6:	00006797          	auipc	a5,0x6
ffffffffc02015aa:	b8278793          	addi	a5,a5,-1150 # ffffffffc0207128 <areas>
    elm->prev = elm->next = elm;
ffffffffc02015ae:	e79c                	sd	a5,8(a5)
ffffffffc02015b0:	e39c                	sd	a5,0(a5)
    for (unsigned i = 0; i <= MAX_ORDER; ++i) {
ffffffffc02015b2:	07c1                	addi	a5,a5,16
ffffffffc02015b4:	ff579de3          	bne	a5,s5,ffffffffc02015ae <buddy_check+0xe2>
    free_count = 0;
ffffffffc02015b8:	6a05                	lui	s4,0x1
ffffffffc02015ba:	008b0913          	addi	s2,s6,8
ffffffffc02015be:	a08a0a13          	addi	s4,s4,-1528 # a08 <kern_entry-0xffffffffc01ff5f8>
ffffffffc02015c2:	00006797          	auipc	a5,0x6
ffffffffc02015c6:	7207b723          	sd	zero,1838(a5) # ffffffffc0207cf0 <free_count>
    buddy_init();
    for (unsigned i = 0; i < 64; ++i) {
ffffffffc02015ca:	8dda                	mv	s11,s6
ffffffffc02015cc:	9a5a                	add	s4,s4,s6
    free_count = 0;
ffffffffc02015ce:	87ca                	mv	a5,s2
        arena[i].flags = 0;
        SetPageReserved(arena + i);
ffffffffc02015d0:	4705                	li	a4,1
ffffffffc02015d2:	e398                	sd	a4,0(a5)
    for (unsigned i = 0; i < 64; ++i) {
ffffffffc02015d4:	02878793          	addi	a5,a5,40
ffffffffc02015d8:	ff479de3          	bne	a5,s4,ffffffffc02015d2 <buddy_check+0x106>
    }
    // Adjacent pages at PPN+1 and PPN+2 are not a buddy pair.
    buddy_init_memmap(arena + 1, 2);
ffffffffc02015dc:	028b0993          	addi	s3,s6,40
    assert(n > 0);
ffffffffc02015e0:	854e                	mv	a0,s3
ffffffffc02015e2:	4589                	li	a1,2
ffffffffc02015e4:	ccfff0ef          	jal	ffffffffc02012b2 <buddy_init_memmap.part.0>
    assert(buddy_alloc_pages(2) == NULL && free_count == 2);
ffffffffc02015e8:	4509                	li	a0,2
ffffffffc02015ea:	ddbff0ef          	jal	ffffffffc02013c4 <buddy_alloc_pages>
ffffffffc02015ee:	2a051963          	bnez	a0,ffffffffc02018a0 <buddy_check+0x3d4>
ffffffffc02015f2:	000bb703          	ld	a4,0(s7)
ffffffffc02015f6:	4789                	li	a5,2
ffffffffc02015f8:	2af71463          	bne	a4,a5,ffffffffc02018a0 <buddy_check+0x3d4>
    check_lists();
ffffffffc02015fc:	a01ff0ef          	jal	ffffffffc0200ffc <check_lists>
ffffffffc0201600:	00006797          	auipc	a5,0x6
ffffffffc0201604:	b2878793          	addi	a5,a5,-1240 # ffffffffc0207128 <areas>
ffffffffc0201608:	e79c                	sd	a5,8(a5)
ffffffffc020160a:	e39c                	sd	a5,0(a5)
    for (unsigned i = 0; i <= MAX_ORDER; ++i) {
ffffffffc020160c:	07c1                	addi	a5,a5,16
ffffffffc020160e:	ff579de3          	bne	a5,s5,ffffffffc0201608 <buddy_check+0x13c>
    free_count = 0;
ffffffffc0201612:	00006797          	auipc	a5,0x6
ffffffffc0201616:	6c07bf23          	sd	zero,1758(a5) # ffffffffc0207cf0 <free_count>

    buddy_init();
    for (unsigned i = 0; i < 64; ++i) { SetPageReserved(arena + i); }
ffffffffc020161a:	00093783          	ld	a5,0(s2)
ffffffffc020161e:	02890913          	addi	s2,s2,40
ffffffffc0201622:	0017e793          	ori	a5,a5,1
ffffffffc0201626:	fcf93c23          	sd	a5,-40(s2)
ffffffffc020162a:	ff4918e3          	bne	s2,s4,ffffffffc020161a <buddy_check+0x14e>
    assert(n > 0);
ffffffffc020162e:	45fd                	li	a1,31
ffffffffc0201630:	854e                	mv	a0,s3
ffffffffc0201632:	00006917          	auipc	s2,0x6
ffffffffc0201636:	9fe90913          	addi	s2,s2,-1538 # ffffffffc0207030 <single.0>
ffffffffc020163a:	c79ff0ef          	jal	ffffffffc02012b2 <buddy_init_memmap.part.0>
    buddy_init_memmap(arena + 1, 31);
    static struct Page *single[31];
    for (unsigned i = 0; i < 31; ++i) {
ffffffffc020163e:	8d4a                	mv	s10,s2
ffffffffc0201640:	4c81                	li	s9,0
        single[i] = buddy_alloc_pages(1);
        assert(single[i] >= arena + 1 && single[i] < arena + 32);
ffffffffc0201642:	500b0a13          	addi	s4,s6,1280
    for (unsigned i = 0; i < 31; ++i) {
ffffffffc0201646:	4afd                	li	s5,31
        single[i] = buddy_alloc_pages(1);
ffffffffc0201648:	4505                	li	a0,1
ffffffffc020164a:	d7bff0ef          	jal	ffffffffc02013c4 <buddy_alloc_pages>
ffffffffc020164e:	00ad3023          	sd	a0,0(s10)
        assert(single[i] >= arena + 1 && single[i] < arena + 32);
ffffffffc0201652:	17356763          	bltu	a0,s3,ffffffffc02017c0 <buddy_check+0x2f4>
ffffffffc0201656:	17457563          	bgeu	a0,s4,ffffffffc02017c0 <buddy_check+0x2f4>
        for (unsigned j = 0; j < i; ++j) { assert(single[i] != single[j]); }
ffffffffc020165a:	87ca                	mv	a5,s2
ffffffffc020165c:	0e0c8b63          	beqz	s9,ffffffffc0201752 <buddy_check+0x286>
ffffffffc0201660:	6398                	ld	a4,0(a5)
ffffffffc0201662:	10e50f63          	beq	a0,a4,ffffffffc0201780 <buddy_check+0x2b4>
ffffffffc0201666:	07a1                	addi	a5,a5,8
ffffffffc0201668:	ffa79ce3          	bne	a5,s10,ffffffffc0201660 <buddy_check+0x194>
    for (unsigned i = 0; i < 31; ++i) {
ffffffffc020166c:	2c85                	addiw	s9,s9,1 # ff0001 <kern_entry-0xffffffffbf20ffff>
ffffffffc020166e:	00878d13          	addi	s10,a5,8
ffffffffc0201672:	fd5c9be3          	bne	s9,s5,ffffffffc0201648 <buddy_check+0x17c>
    }
    assert(free_count == 0 && buddy_alloc_pages(1) == NULL);
ffffffffc0201676:	000bb783          	ld	a5,0(s7)
ffffffffc020167a:	18079363          	bnez	a5,ffffffffc0201800 <buddy_check+0x334>
ffffffffc020167e:	4505                	li	a0,1
ffffffffc0201680:	d45ff0ef          	jal	ffffffffc02013c4 <buddy_alloc_pages>
ffffffffc0201684:	16051e63          	bnez	a0,ffffffffc0201800 <buddy_check+0x334>
ffffffffc0201688:	00006997          	auipc	s3,0x6
ffffffffc020168c:	a9898993          	addi	s3,s3,-1384 # ffffffffc0207120 <single.0+0xf0>
    assert(n > 0 && n <= block_size(MAX_ORDER));
ffffffffc0201690:	0009b503          	ld	a0,0(s3)
ffffffffc0201694:	4585                	li	a1,1
ffffffffc0201696:	a85ff0ef          	jal	ffffffffc020111a <buddy_free_pages.part.0>
    for (unsigned i = 31; i > 0; --i) { buddy_free_pages(single[i - 1], 1); }
ffffffffc020169a:	87ce                	mv	a5,s3
ffffffffc020169c:	19e1                	addi	s3,s3,-8
ffffffffc020169e:	ff2799e3          	bne	a5,s2,ffffffffc0201690 <buddy_check+0x1c4>
    assert(free_count == 31 && buddy_alloc_pages(32) == NULL);
ffffffffc02016a2:	000bb703          	ld	a4,0(s7)
ffffffffc02016a6:	47fd                	li	a5,31
ffffffffc02016a8:	12f71c63          	bne	a4,a5,ffffffffc02017e0 <buddy_check+0x314>
ffffffffc02016ac:	02000513          	li	a0,32
ffffffffc02016b0:	d15ff0ef          	jal	ffffffffc02013c4 <buddy_alloc_pages>
ffffffffc02016b4:	12051663          	bnez	a0,ffffffffc02017e0 <buddy_check+0x314>
    a = buddy_alloc_pages(16);
ffffffffc02016b8:	4541                	li	a0,16
ffffffffc02016ba:	d0bff0ef          	jal	ffffffffc02013c4 <buddy_alloc_pages>
    assert(a == arena + 16);
ffffffffc02016be:	280b0793          	addi	a5,s6,640
ffffffffc02016c2:	1aa79f63          	bne	a5,a0,ffffffffc0201880 <buddy_check+0x3b4>
    assert(n > 0 && n <= block_size(MAX_ORDER));
ffffffffc02016c6:	45c1                	li	a1,16
ffffffffc02016c8:	a53ff0ef          	jal	ffffffffc020111a <buddy_free_pages.part.0>
    buddy_free_pages(a, 16);
    check_lists();
ffffffffc02016cc:	931ff0ef          	jal	ffffffffc0200ffc <check_lists>
    for (unsigned i = 0; i <= MAX_ORDER; ++i) { areas[i] = saved[i]; }
ffffffffc02016d0:	13040693          	addi	a3,s0,304
ffffffffc02016d4:	6018                	ld	a4,0(s0)
ffffffffc02016d6:	641c                	ld	a5,8(s0)
ffffffffc02016d8:	0441                	addi	s0,s0,16
ffffffffc02016da:	e098                	sd	a4,0(s1)
ffffffffc02016dc:	e49c                	sd	a5,8(s1)
ffffffffc02016de:	04c1                	addi	s1,s1,16
ffffffffc02016e0:	fed41ae3          	bne	s0,a3,ffffffffc02016d4 <buddy_check+0x208>
    free_count = saved_count;
ffffffffc02016e4:	6722                	ld	a4,8(sp)
ffffffffc02016e6:	6785                	lui	a5,0x1
ffffffffc02016e8:	a0078793          	addi	a5,a5,-1536 # a00 <kern_entry-0xffffffffc01ff600>
ffffffffc02016ec:	00ebb023          	sd	a4,0(s7)
    for (unsigned i = 0; i < 64; ++i) {
ffffffffc02016f0:	97da                	add	a5,a5,s6
        arena[i].flags = arena[i].property = 0;
ffffffffc02016f2:	000da823          	sw	zero,16(s11)
ffffffffc02016f6:	000db423          	sd	zero,8(s11)
        arena[i].ref = 0;
ffffffffc02016fa:	000da023          	sw	zero,0(s11)
    for (unsigned i = 0; i < 64; ++i) {
ffffffffc02016fe:	028d8d93          	addi	s11,s11,40
ffffffffc0201702:	ffb798e3          	bne	a5,s11,ffffffffc02016f2 <buddy_check+0x226>
    }
    arena->flags = ALLOC_HEAD;
ffffffffc0201706:	4791                	li	a5,4
ffffffffc0201708:	00fb3423          	sd	a5,8(s6)
    arena->property = 64;
ffffffffc020170c:	04000793          	li	a5,64
ffffffffc0201710:	00fb2823          	sw	a5,16(s6)
    assert(n > 0 && n <= block_size(MAX_ORDER));
ffffffffc0201714:	04000593          	li	a1,64
ffffffffc0201718:	855a                	mv	a0,s6
ffffffffc020171a:	a01ff0ef          	jal	ffffffffc020111a <buddy_free_pages.part.0>
    buddy_free_pages(arena, 64);
    assert(free_count == before);
ffffffffc020171e:	000bb783          	ld	a5,0(s7)
ffffffffc0201722:	13879f63          	bne	a5,s8,ffffffffc0201860 <buddy_check+0x394>
    check_lists();
ffffffffc0201726:	8d7ff0ef          	jal	ffffffffc0200ffc <check_lists>
    cprintf("[Buddy] rounding, splitting, merging, exhaustion, irregular range: PASS\n");
}
ffffffffc020172a:	741a                	ld	s0,416(sp)
ffffffffc020172c:	70ba                	ld	ra,424(sp)
ffffffffc020172e:	64fa                	ld	s1,408(sp)
ffffffffc0201730:	695a                	ld	s2,400(sp)
ffffffffc0201732:	69ba                	ld	s3,392(sp)
ffffffffc0201734:	6a1a                	ld	s4,384(sp)
ffffffffc0201736:	7af6                	ld	s5,376(sp)
ffffffffc0201738:	7b56                	ld	s6,368(sp)
ffffffffc020173a:	7bb6                	ld	s7,360(sp)
ffffffffc020173c:	7c16                	ld	s8,352(sp)
ffffffffc020173e:	6cf6                	ld	s9,344(sp)
ffffffffc0201740:	6d56                	ld	s10,336(sp)
ffffffffc0201742:	6db6                	ld	s11,328(sp)
    cprintf("[Buddy] rounding, splitting, merging, exhaustion, irregular range: PASS\n");
ffffffffc0201744:	00002517          	auipc	a0,0x2
ffffffffc0201748:	96450513          	addi	a0,a0,-1692 # ffffffffc02030a8 <etext+0x89e>
}
ffffffffc020174c:	615d                	addi	sp,sp,432
    cprintf("[Buddy] rounding, splitting, merging, exhaustion, irregular range: PASS\n");
ffffffffc020174e:	9fdfe06f          	j	ffffffffc020014a <cprintf>
    for (unsigned i = 0; i < 31; ++i) {
ffffffffc0201752:	0d21                	addi	s10,s10,8
ffffffffc0201754:	4c85                	li	s9,1
ffffffffc0201756:	bdcd                	j	ffffffffc0201648 <buddy_check+0x17c>
    assert(a + 1 <= c || c + 8 <= a);
ffffffffc0201758:	14040793          	addi	a5,s0,320
ffffffffc020175c:	dcf97ee3          	bgeu	s2,a5,ffffffffc0201538 <buddy_check+0x6c>
ffffffffc0201760:	00001697          	auipc	a3,0x1
ffffffffc0201764:	7e868693          	addi	a3,a3,2024 # ffffffffc0202f48 <etext+0x73e>
ffffffffc0201768:	00001617          	auipc	a2,0x1
ffffffffc020176c:	2f860613          	addi	a2,a2,760 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201770:	07900593          	li	a1,121
ffffffffc0201774:	00001517          	auipc	a0,0x1
ffffffffc0201778:	65c50513          	addi	a0,a0,1628 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc020177c:	a51fe0ef          	jal	ffffffffc02001cc <__panic>
        for (unsigned j = 0; j < i; ++j) { assert(single[i] != single[j]); }
ffffffffc0201780:	00002697          	auipc	a3,0x2
ffffffffc0201784:	89868693          	addi	a3,a3,-1896 # ffffffffc0203018 <etext+0x80e>
ffffffffc0201788:	00001617          	auipc	a2,0x1
ffffffffc020178c:	2d860613          	addi	a2,a2,728 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201790:	09a00593          	li	a1,154
ffffffffc0201794:	00001517          	auipc	a0,0x1
ffffffffc0201798:	63c50513          	addi	a0,a0,1596 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc020179c:	a31fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(a + 1 <= b || b + 4 <= a);
ffffffffc02017a0:	00001697          	auipc	a3,0x1
ffffffffc02017a4:	78868693          	addi	a3,a3,1928 # ffffffffc0202f28 <etext+0x71e>
ffffffffc02017a8:	00001617          	auipc	a2,0x1
ffffffffc02017ac:	2b860613          	addi	a2,a2,696 # ffffffffc0202a60 <etext+0x256>
ffffffffc02017b0:	07800593          	li	a1,120
ffffffffc02017b4:	00001517          	auipc	a0,0x1
ffffffffc02017b8:	61c50513          	addi	a0,a0,1564 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc02017bc:	a11fe0ef          	jal	ffffffffc02001cc <__panic>
        assert(single[i] >= arena + 1 && single[i] < arena + 32);
ffffffffc02017c0:	00002697          	auipc	a3,0x2
ffffffffc02017c4:	82068693          	addi	a3,a3,-2016 # ffffffffc0202fe0 <etext+0x7d6>
ffffffffc02017c8:	00001617          	auipc	a2,0x1
ffffffffc02017cc:	29860613          	addi	a2,a2,664 # ffffffffc0202a60 <etext+0x256>
ffffffffc02017d0:	09900593          	li	a1,153
ffffffffc02017d4:	00001517          	auipc	a0,0x1
ffffffffc02017d8:	5fc50513          	addi	a0,a0,1532 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc02017dc:	9f1fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(free_count == 31 && buddy_alloc_pages(32) == NULL);
ffffffffc02017e0:	00002697          	auipc	a3,0x2
ffffffffc02017e4:	88068693          	addi	a3,a3,-1920 # ffffffffc0203060 <etext+0x856>
ffffffffc02017e8:	00001617          	auipc	a2,0x1
ffffffffc02017ec:	27860613          	addi	a2,a2,632 # ffffffffc0202a60 <etext+0x256>
ffffffffc02017f0:	09e00593          	li	a1,158
ffffffffc02017f4:	00001517          	auipc	a0,0x1
ffffffffc02017f8:	5dc50513          	addi	a0,a0,1500 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc02017fc:	9d1fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(free_count == 0 && buddy_alloc_pages(1) == NULL);
ffffffffc0201800:	00002697          	auipc	a3,0x2
ffffffffc0201804:	83068693          	addi	a3,a3,-2000 # ffffffffc0203030 <etext+0x826>
ffffffffc0201808:	00001617          	auipc	a2,0x1
ffffffffc020180c:	25860613          	addi	a2,a2,600 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201810:	09c00593          	li	a1,156
ffffffffc0201814:	00001517          	auipc	a0,0x1
ffffffffc0201818:	5bc50513          	addi	a0,a0,1468 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc020181c:	9b1fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(free_count == before - 13);
ffffffffc0201820:	00001697          	auipc	a3,0x1
ffffffffc0201824:	6e868693          	addi	a3,a3,1768 # ffffffffc0202f08 <etext+0x6fe>
ffffffffc0201828:	00001617          	auipc	a2,0x1
ffffffffc020182c:	23860613          	addi	a2,a2,568 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201830:	07700593          	li	a1,119
ffffffffc0201834:	00001517          	auipc	a0,0x1
ffffffffc0201838:	59c50513          	addi	a0,a0,1436 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc020183c:	991fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(a && b && c);
ffffffffc0201840:	00001697          	auipc	a3,0x1
ffffffffc0201844:	6b868693          	addi	a3,a3,1720 # ffffffffc0202ef8 <etext+0x6ee>
ffffffffc0201848:	00001617          	auipc	a2,0x1
ffffffffc020184c:	21860613          	addi	a2,a2,536 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201850:	07600593          	li	a1,118
ffffffffc0201854:	00001517          	auipc	a0,0x1
ffffffffc0201858:	57c50513          	addi	a0,a0,1404 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc020185c:	971fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(free_count == before);
ffffffffc0201860:	00001697          	auipc	a3,0x1
ffffffffc0201864:	72868693          	addi	a3,a3,1832 # ffffffffc0202f88 <etext+0x77e>
ffffffffc0201868:	00001617          	auipc	a2,0x1
ffffffffc020186c:	1f860613          	addi	a2,a2,504 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201870:	0ac00593          	li	a1,172
ffffffffc0201874:	00001517          	auipc	a0,0x1
ffffffffc0201878:	55c50513          	addi	a0,a0,1372 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc020187c:	951fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(a == arena + 16);
ffffffffc0201880:	00002697          	auipc	a3,0x2
ffffffffc0201884:	81868693          	addi	a3,a3,-2024 # ffffffffc0203098 <etext+0x88e>
ffffffffc0201888:	00001617          	auipc	a2,0x1
ffffffffc020188c:	1d860613          	addi	a2,a2,472 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201890:	0a000593          	li	a1,160
ffffffffc0201894:	00001517          	auipc	a0,0x1
ffffffffc0201898:	53c50513          	addi	a0,a0,1340 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc020189c:	931fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(buddy_alloc_pages(2) == NULL && free_count == 2);
ffffffffc02018a0:	00001697          	auipc	a3,0x1
ffffffffc02018a4:	71068693          	addi	a3,a3,1808 # ffffffffc0202fb0 <etext+0x7a6>
ffffffffc02018a8:	00001617          	auipc	a2,0x1
ffffffffc02018ac:	1b860613          	addi	a2,a2,440 # ffffffffc0202a60 <etext+0x256>
ffffffffc02018b0:	09000593          	li	a1,144
ffffffffc02018b4:	00001517          	auipc	a0,0x1
ffffffffc02018b8:	51c50513          	addi	a0,a0,1308 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc02018bc:	911fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(arena != NULL);
ffffffffc02018c0:	00001697          	auipc	a3,0x1
ffffffffc02018c4:	6e068693          	addi	a3,a3,1760 # ffffffffc0202fa0 <etext+0x796>
ffffffffc02018c8:	00001617          	auipc	a2,0x1
ffffffffc02018cc:	19860613          	addi	a2,a2,408 # ffffffffc0202a60 <etext+0x256>
ffffffffc02018d0:	08500593          	li	a1,133
ffffffffc02018d4:	00001517          	auipc	a0,0x1
ffffffffc02018d8:	4fc50513          	addi	a0,a0,1276 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc02018dc:	8f1fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(free_count == before);
ffffffffc02018e0:	00001697          	auipc	a3,0x1
ffffffffc02018e4:	6a868693          	addi	a3,a3,1704 # ffffffffc0202f88 <etext+0x77e>
ffffffffc02018e8:	00001617          	auipc	a2,0x1
ffffffffc02018ec:	17860613          	addi	a2,a2,376 # ffffffffc0202a60 <etext+0x256>
ffffffffc02018f0:	08000593          	li	a1,128
ffffffffc02018f4:	00001517          	auipc	a0,0x1
ffffffffc02018f8:	4dc50513          	addi	a0,a0,1244 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc02018fc:	8d1fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(b + 4 <= c || c + 8 <= b);
ffffffffc0201900:	00001697          	auipc	a3,0x1
ffffffffc0201904:	66868693          	addi	a3,a3,1640 # ffffffffc0202f68 <etext+0x75e>
ffffffffc0201908:	00001617          	auipc	a2,0x1
ffffffffc020190c:	15860613          	addi	a2,a2,344 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201910:	07a00593          	li	a1,122
ffffffffc0201914:	00001517          	auipc	a0,0x1
ffffffffc0201918:	4bc50513          	addi	a0,a0,1212 # ffffffffc0202dd0 <etext+0x5c6>
ffffffffc020191c:	8b1fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0201920 <page_init>:
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
}

//lab2 function1 2411156
static void page_init(void) {
ffffffffc0201920:	7179                	addi	sp,sp,-48
ffffffffc0201922:	f406                	sd	ra,40(sp)
ffffffffc0201924:	f022                	sd	s0,32(sp)
ffffffffc0201926:	ec26                	sd	s1,24(sp)
ffffffffc0201928:	e84a                	sd	s2,16(sp)
ffffffffc020192a:	e44e                	sd	s3,8(sp)
ffffffffc020192c:	e052                	sd	s4,0(sp)
    extern char end[];
    uint64_t base = get_memory_base(), size = get_memory_size();
ffffffffc020192e:	c67fe0ef          	jal	ffffffffc0200594 <get_memory_base>
ffffffffc0201932:	842a                	mv	s0,a0
ffffffffc0201934:	c6bfe0ef          	jal	ffffffffc020059e <get_memory_size>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201938:	5775                	li	a4,-3
ffffffffc020193a:	077a                	slli	a4,a4,0x1e
    if (base != DRAM_BASE || size == 0 || size > ~(uint64_t)0 - base) {
ffffffffc020193c:	4785                	li	a5,1
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020193e:	00006697          	auipc	a3,0x6
ffffffffc0201942:	3ce6b923          	sd	a4,978(a3) # ffffffffc0207d10 <va_pa_offset>
    if (base != DRAM_BASE || size == 0 || size > ~(uint64_t)0 - base) {
ffffffffc0201946:	07fe                	slli	a5,a5,0x1f
ffffffffc0201948:	14f41363          	bne	s0,a5,ffffffffc0201a8e <page_init+0x16e>
ffffffffc020194c:	800007b7          	lui	a5,0x80000
ffffffffc0201950:	fff50713          	addi	a4,a0,-1
ffffffffc0201954:	17f9                	addi	a5,a5,-2 # ffffffff7ffffffe <kern_entry-0x40200002>
ffffffffc0201956:	85aa                	mv	a1,a0
ffffffffc0201958:	12e7eb63          	bltu	a5,a4,ffffffffc0201a8e <page_init+0x16e>
        panic("invalid DTB physical memory range");
    }
    uint64_t reported_end = base + size;
    uintptr_t limit = reported_end < PHYSICAL_MEMORY_END ?
ffffffffc020195c:	47c5                	li	a5,17
    uint64_t reported_end = base + size;
ffffffffc020195e:	942a                	add	s0,s0,a0
    uintptr_t limit = reported_end < PHYSICAL_MEMORY_END ?
ffffffffc0201960:	07ee                	slli	a5,a5,0x1b
ffffffffc0201962:	0e87e463          	bltu	a5,s0,ffffffffc0201a4a <page_init+0x12a>
                      reported_end : PHYSICAL_MEMORY_END;
    limit = ROUNDDOWN(limit, PGSIZE);
ffffffffc0201966:	76fd                	lui	a3,0xfffff
    if (limit <= KERNEL_BEGIN_PADDR) {
ffffffffc0201968:	40100793          	li	a5,1025
    limit = ROUNDDOWN(limit, PGSIZE);
ffffffffc020196c:	8c75                	and	s0,s0,a3
    if (limit <= KERNEL_BEGIN_PADDR) {
ffffffffc020196e:	07d6                	slli	a5,a5,0x15
ffffffffc0201970:	1687f463          	bgeu	a5,s0,ffffffffc0201ad8 <page_init+0x1b8>
        panic("physical memory does not contain the kernel");
    }
    npage = PPN(limit);
ffffffffc0201974:	00007497          	auipc	s1,0x7
ffffffffc0201978:	3b748493          	addi	s1,s1,951 # ffffffffc0208d2b <end+0xfff>
ffffffffc020197c:	00c45713          	srli	a4,s0,0xc
ffffffffc0201980:	00006a17          	auipc	s4,0x6
ffffffffc0201984:	398a0a13          	addi	s4,s4,920 # ffffffffc0207d18 <npage>
ffffffffc0201988:	8cf5                	and	s1,s1,a3
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc020198a:	00006997          	auipc	s3,0x6
ffffffffc020198e:	39698993          	addi	s3,s3,918 # ffffffffc0207d20 <pages>
    npage = PPN(limit);
ffffffffc0201992:	00ea3023          	sd	a4,0(s4)
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc0201996:	0099b023          	sd	s1,0(s3)
    uintptr_t array_pa = PADDR(pages);
ffffffffc020199a:	c02007b7          	lui	a5,0xc0200
ffffffffc020199e:	12f4e063          	bltu	s1,a5,ffffffffc0201abe <page_init+0x19e>
ffffffffc02019a2:	478d                	li	a5,3
ffffffffc02019a4:	07fa                	slli	a5,a5,0x1e
    size_t count = npage - nbase;
ffffffffc02019a6:	fff80937          	lui	s2,0xfff80
    uintptr_t array_pa = PADDR(pages);
ffffffffc02019aa:	97a6                	add	a5,a5,s1
    size_t count = npage - nbase;
ffffffffc02019ac:	993a                	add	s2,s2,a4
    if (array_pa >= limit || count > (limit - array_pa) / sizeof(struct Page)) {
ffffffffc02019ae:	0e87fc63          	bgeu	a5,s0,ffffffffc0201aa6 <page_init+0x186>
ffffffffc02019b2:	57f5                	li	a5,-3
ffffffffc02019b4:	07fa                	slli	a5,a5,0x1e
ffffffffc02019b6:	8f85                	sub	a5,a5,s1
ffffffffc02019b8:	97a2                	add	a5,a5,s0
ffffffffc02019ba:	02800693          	li	a3,40
ffffffffc02019be:	02d7d7b3          	divu	a5,a5,a3
ffffffffc02019c2:	0f27e263          	bltu	a5,s2,ffffffffc0201aa6 <page_init+0x186>
ffffffffc02019c6:	00271793          	slli	a5,a4,0x2
ffffffffc02019ca:	97ba                	add	a5,a5,a4
ffffffffc02019cc:	fec006b7          	lui	a3,0xfec00
ffffffffc02019d0:	078e                	slli	a5,a5,0x3
ffffffffc02019d2:	96a6                	add	a3,a3,s1
ffffffffc02019d4:	96be                	add	a3,a3,a5
        panic("not enough memory for Page descriptors");
    }
    for (size_t i = 0; i < count; ++i) {
        pages[i].flags = 0;
        SetPageReserved(pages + i);
ffffffffc02019d6:	4605                	li	a2,1
    if (array_pa >= limit || count > (limit - array_pa) / sizeof(struct Page)) {
ffffffffc02019d8:	87a6                	mv	a5,s1
        pages[i].property = 0;
        set_page_ref(pages + i, 0);
        list_init(&pages[i].page_link);
ffffffffc02019da:	01878713          	addi	a4,a5,24 # ffffffffc0200018 <kern_entry+0x18>
        SetPageReserved(pages + i);
ffffffffc02019de:	e790                	sd	a2,8(a5)
        pages[i].property = 0;
ffffffffc02019e0:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02019e4:	0007a023          	sw	zero,0(a5)
ffffffffc02019e8:	f398                	sd	a4,32(a5)
ffffffffc02019ea:	ef98                	sd	a4,24(a5)
    for (size_t i = 0; i < count; ++i) {
ffffffffc02019ec:	02878793          	addi	a5,a5,40
ffffffffc02019f0:	fed795e3          	bne	a5,a3,ffffffffc02019da <page_init+0xba>
    }
    cprintf("physical memory map:\n  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n",
ffffffffc02019f4:	800006b7          	lui	a3,0x80000
ffffffffc02019f8:	4605                	li	a2,1
ffffffffc02019fa:	fff6c693          	not	a3,a3
ffffffffc02019fe:	96ae                	add	a3,a3,a1
ffffffffc0201a00:	067e                	slli	a2,a2,0x1f
ffffffffc0201a02:	00001517          	auipc	a0,0x1
ffffffffc0201a06:	7c650513          	addi	a0,a0,1990 # ffffffffc02031c8 <etext+0x9be>
ffffffffc0201a0a:	f40fe0ef          	jal	ffffffffc020014a <cprintf>
            size, base, reported_end - 1);
    cprintf("  managed end: 0x%016lx (exclusive)\n", limit);
ffffffffc0201a0e:	85a2                	mv	a1,s0
ffffffffc0201a10:	00001517          	auipc	a0,0x1
ffffffffc0201a14:	7f850513          	addi	a0,a0,2040 # ffffffffc0203208 <etext+0x9fe>
ffffffffc0201a18:	f32fe0ef          	jal	ffffffffc020014a <cprintf>
    uintptr_t free_begin = ROUNDUP(array_pa + count * sizeof(struct Page), PGSIZE);
ffffffffc0201a1c:	000c0737          	lui	a4,0xc0
ffffffffc0201a20:	0705                	addi	a4,a4,1 # c0001 <kern_entry-0xffffffffc013ffff>
ffffffffc0201a22:	00291793          	slli	a5,s2,0x2
ffffffffc0201a26:	0732                	slli	a4,a4,0xc
ffffffffc0201a28:	177d                	addi	a4,a4,-1
ffffffffc0201a2a:	97ca                	add	a5,a5,s2
ffffffffc0201a2c:	94ba                	add	s1,s1,a4
ffffffffc0201a2e:	078e                	slli	a5,a5,0x3
ffffffffc0201a30:	97a6                	add	a5,a5,s1
ffffffffc0201a32:	777d                	lui	a4,0xfffff
ffffffffc0201a34:	8ff9                	and	a5,a5,a4
    if (free_begin < limit) {
ffffffffc0201a36:	0087ec63          	bltu	a5,s0,ffffffffc0201a4e <page_init+0x12e>
        init_memmap(pa2page(free_begin), (limit - free_begin) / PGSIZE);
    }
}
ffffffffc0201a3a:	70a2                	ld	ra,40(sp)
ffffffffc0201a3c:	7402                	ld	s0,32(sp)
ffffffffc0201a3e:	64e2                	ld	s1,24(sp)
ffffffffc0201a40:	6942                	ld	s2,16(sp)
ffffffffc0201a42:	69a2                	ld	s3,8(sp)
ffffffffc0201a44:	6a02                	ld	s4,0(sp)
ffffffffc0201a46:	6145                	addi	sp,sp,48
ffffffffc0201a48:	8082                	ret
    uintptr_t limit = reported_end < PHYSICAL_MEMORY_END ?
ffffffffc0201a4a:	843e                	mv	s0,a5
ffffffffc0201a4c:	bf29                	j	ffffffffc0201966 <page_init+0x46>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201a4e:	000a3703          	ld	a4,0(s4)
ffffffffc0201a52:	00c7d693          	srli	a3,a5,0xc
ffffffffc0201a56:	08e6fd63          	bgeu	a3,a4,ffffffffc0201af0 <page_init+0x1d0>
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201a5a:	fff80737          	lui	a4,0xfff80
ffffffffc0201a5e:	96ba                	add	a3,a3,a4
ffffffffc0201a60:	00269713          	slli	a4,a3,0x2
ffffffffc0201a64:	0009b503          	ld	a0,0(s3)
ffffffffc0201a68:	9736                	add	a4,a4,a3
        init_memmap(pa2page(free_begin), (limit - free_begin) / PGSIZE);
ffffffffc0201a6a:	40f405b3          	sub	a1,s0,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0201a6e:	00006697          	auipc	a3,0x6
ffffffffc0201a72:	28a6b683          	ld	a3,650(a3) # ffffffffc0207cf8 <pmm_manager>
}
ffffffffc0201a76:	7402                	ld	s0,32(sp)
ffffffffc0201a78:	70a2                	ld	ra,40(sp)
ffffffffc0201a7a:	64e2                	ld	s1,24(sp)
ffffffffc0201a7c:	6942                	ld	s2,16(sp)
ffffffffc0201a7e:	69a2                	ld	s3,8(sp)
ffffffffc0201a80:	6a02                	ld	s4,0(sp)
    pmm_manager->init_memmap(base, n);
ffffffffc0201a82:	6a94                	ld	a3,16(a3)
ffffffffc0201a84:	070e                	slli	a4,a4,0x3
ffffffffc0201a86:	81b1                	srli	a1,a1,0xc
ffffffffc0201a88:	953a                	add	a0,a0,a4
}
ffffffffc0201a8a:	6145                	addi	sp,sp,48
    pmm_manager->init_memmap(base, n);
ffffffffc0201a8c:	8682                	jr	a3
        panic("invalid DTB physical memory range");
ffffffffc0201a8e:	00001617          	auipc	a2,0x1
ffffffffc0201a92:	68260613          	addi	a2,a2,1666 # ffffffffc0203110 <etext+0x906>
ffffffffc0201a96:	04800593          	li	a1,72
ffffffffc0201a9a:	00001517          	auipc	a0,0x1
ffffffffc0201a9e:	69e50513          	addi	a0,a0,1694 # ffffffffc0203138 <etext+0x92e>
ffffffffc0201aa2:	f2afe0ef          	jal	ffffffffc02001cc <__panic>
        panic("not enough memory for Page descriptors");
ffffffffc0201aa6:	00001617          	auipc	a2,0x1
ffffffffc0201aaa:	6fa60613          	addi	a2,a2,1786 # ffffffffc02031a0 <etext+0x996>
ffffffffc0201aae:	05600593          	li	a1,86
ffffffffc0201ab2:	00001517          	auipc	a0,0x1
ffffffffc0201ab6:	68650513          	addi	a0,a0,1670 # ffffffffc0203138 <etext+0x92e>
ffffffffc0201aba:	f12fe0ef          	jal	ffffffffc02001cc <__panic>
    uintptr_t array_pa = PADDR(pages);
ffffffffc0201abe:	86a6                	mv	a3,s1
ffffffffc0201ac0:	00001617          	auipc	a2,0x1
ffffffffc0201ac4:	6b860613          	addi	a2,a2,1720 # ffffffffc0203178 <etext+0x96e>
ffffffffc0201ac8:	05300593          	li	a1,83
ffffffffc0201acc:	00001517          	auipc	a0,0x1
ffffffffc0201ad0:	66c50513          	addi	a0,a0,1644 # ffffffffc0203138 <etext+0x92e>
ffffffffc0201ad4:	ef8fe0ef          	jal	ffffffffc02001cc <__panic>
        panic("physical memory does not contain the kernel");
ffffffffc0201ad8:	00001617          	auipc	a2,0x1
ffffffffc0201adc:	67060613          	addi	a2,a2,1648 # ffffffffc0203148 <etext+0x93e>
ffffffffc0201ae0:	04f00593          	li	a1,79
ffffffffc0201ae4:	00001517          	auipc	a0,0x1
ffffffffc0201ae8:	65450513          	addi	a0,a0,1620 # ffffffffc0203138 <etext+0x92e>
ffffffffc0201aec:	ee0fe0ef          	jal	ffffffffc02001cc <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201af0:	00001617          	auipc	a2,0x1
ffffffffc0201af4:	74060613          	addi	a2,a2,1856 # ffffffffc0203230 <etext+0xa26>
ffffffffc0201af8:	06a00593          	li	a1,106
ffffffffc0201afc:	00001517          	auipc	a0,0x1
ffffffffc0201b00:	75450513          	addi	a0,a0,1876 # ffffffffc0203250 <etext+0xa46>
ffffffffc0201b04:	ec8fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0201b08 <alloc_pages>:
    return pmm_manager->alloc_pages(n);
ffffffffc0201b08:	00006797          	auipc	a5,0x6
ffffffffc0201b0c:	1f07b783          	ld	a5,496(a5) # ffffffffc0207cf8 <pmm_manager>
ffffffffc0201b10:	6f9c                	ld	a5,24(a5)
ffffffffc0201b12:	8782                	jr	a5

ffffffffc0201b14 <free_pages>:
    pmm_manager->free_pages(base, n);
ffffffffc0201b14:	00006797          	auipc	a5,0x6
ffffffffc0201b18:	1e47b783          	ld	a5,484(a5) # ffffffffc0207cf8 <pmm_manager>
ffffffffc0201b1c:	739c                	ld	a5,32(a5)
ffffffffc0201b1e:	8782                	jr	a5

ffffffffc0201b20 <nr_free_pages>:
    return pmm_manager->nr_free_pages();
ffffffffc0201b20:	00006797          	auipc	a5,0x6
ffffffffc0201b24:	1d87b783          	ld	a5,472(a5) # ffffffffc0207cf8 <pmm_manager>
ffffffffc0201b28:	779c                	ld	a5,40(a5)
ffffffffc0201b2a:	8782                	jr	a5

ffffffffc0201b2c <pmm_init>:

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201b2c:	1101                	addi	sp,sp,-32
ffffffffc0201b2e:	e426                	sd	s1,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201b30:	00002497          	auipc	s1,0x2
ffffffffc0201b34:	a7048493          	addi	s1,s1,-1424 # ffffffffc02035a0 <best_fit_pmm_manager>
void pmm_init(void) {
ffffffffc0201b38:	e04a                	sd	s2,0(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b3a:	0004b903          	ld	s2,0(s1)
void pmm_init(void) {
ffffffffc0201b3e:	ec06                	sd	ra,24(sp)
ffffffffc0201b40:	e822                	sd	s0,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b42:	85ca                	mv	a1,s2
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201b44:	00006417          	auipc	s0,0x6
ffffffffc0201b48:	1b440413          	addi	s0,s0,436 # ffffffffc0207cf8 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b4c:	00001517          	auipc	a0,0x1
ffffffffc0201b50:	71450513          	addi	a0,a0,1812 # ffffffffc0203260 <etext+0xa56>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201b54:	e004                	sd	s1,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b56:	df4fe0ef          	jal	ffffffffc020014a <cprintf>
    pmm_manager->init();
ffffffffc0201b5a:	601c                	ld	a5,0(s0)
ffffffffc0201b5c:	679c                	ld	a5,8(a5)
ffffffffc0201b5e:	9782                	jalr	a5
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
ffffffffc0201b60:	dc1ff0ef          	jal	ffffffffc0201920 <page_init>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201b64:	601c                	ld	a5,0(s0)
ffffffffc0201b66:	7b9c                	ld	a5,48(a5)
ffffffffc0201b68:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201b6a:	00001517          	auipc	a0,0x1
ffffffffc0201b6e:	70e50513          	addi	a0,a0,1806 # ffffffffc0203278 <etext+0xa6e>
ffffffffc0201b72:	dd8fe0ef          	jal	ffffffffc020014a <cprintf>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0201b76:	00002797          	auipc	a5,0x2
ffffffffc0201b7a:	a6278793          	addi	a5,a5,-1438 # ffffffffc02035d8 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b7e:	638c                	ld	a1,0(a5)
ffffffffc0201b80:	00001517          	auipc	a0,0x1
ffffffffc0201b84:	6e050513          	addi	a0,a0,1760 # ffffffffc0203260 <etext+0xa56>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0201b88:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b8a:	dc0fe0ef          	jal	ffffffffc020014a <cprintf>
    pmm_manager->init();
ffffffffc0201b8e:	601c                	ld	a5,0(s0)
ffffffffc0201b90:	679c                	ld	a5,8(a5)
ffffffffc0201b92:	9782                	jalr	a5
    page_init();
ffffffffc0201b94:	d8dff0ef          	jal	ffffffffc0201920 <page_init>
    pmm_manager->check();
ffffffffc0201b98:	601c                	ld	a5,0(s0)
ffffffffc0201b9a:	7b9c                	ld	a5,48(a5)
ffffffffc0201b9c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201b9e:	00001517          	auipc	a0,0x1
ffffffffc0201ba2:	6da50513          	addi	a0,a0,1754 # ffffffffc0203278 <etext+0xa6e>
ffffffffc0201ba6:	da4fe0ef          	jal	ffffffffc020014a <cprintf>
    slub_check();
ffffffffc0201baa:	510000ef          	jal	ffffffffc02020ba <slub_check>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201bae:	85ca                	mv	a1,s2
ffffffffc0201bb0:	00001517          	auipc	a0,0x1
ffffffffc0201bb4:	6b050513          	addi	a0,a0,1712 # ffffffffc0203260 <etext+0xa56>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201bb8:	e004                	sd	s1,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201bba:	d90fe0ef          	jal	ffffffffc020014a <cprintf>
    pmm_manager->init();
ffffffffc0201bbe:	601c                	ld	a5,0(s0)
ffffffffc0201bc0:	679c                	ld	a5,8(a5)
ffffffffc0201bc2:	9782                	jalr	a5
    page_init();
ffffffffc0201bc4:	d5dff0ef          	jal	ffffffffc0201920 <page_init>
    pmm_manager->check();
ffffffffc0201bc8:	601c                	ld	a5,0(s0)
ffffffffc0201bca:	7b9c                	ld	a5,48(a5)
ffffffffc0201bcc:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201bce:	00001517          	auipc	a0,0x1
ffffffffc0201bd2:	6aa50513          	addi	a0,a0,1706 # ffffffffc0203278 <etext+0xa6e>
ffffffffc0201bd6:	d74fe0ef          	jal	ffffffffc020014a <cprintf>
    slub_check();
ffffffffc0201bda:	4e0000ef          	jal	ffffffffc02020ba <slub_check>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201bde:	00004597          	auipc	a1,0x4
ffffffffc0201be2:	42258593          	addi	a1,a1,1058 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201be6:	00006797          	auipc	a5,0x6
ffffffffc0201bea:	12b7b123          	sd	a1,290(a5) # ffffffffc0207d08 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201bee:	c02007b7          	lui	a5,0xc0200
ffffffffc0201bf2:	02f5e863          	bltu	a1,a5,ffffffffc0201c22 <pmm_init+0xf6>
}
ffffffffc0201bf6:	6442                	ld	s0,16(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201bf8:	00006797          	auipc	a5,0x6
ffffffffc0201bfc:	1187b783          	ld	a5,280(a5) # ffffffffc0207d10 <va_pa_offset>
}
ffffffffc0201c00:	60e2                	ld	ra,24(sp)
ffffffffc0201c02:	64a2                	ld	s1,8(sp)
ffffffffc0201c04:	6902                	ld	s2,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201c06:	40f587b3          	sub	a5,a1,a5
ffffffffc0201c0a:	00006717          	auipc	a4,0x6
ffffffffc0201c0e:	0ef73b23          	sd	a5,246(a4) # ffffffffc0207d00 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201c12:	863e                	mv	a2,a5
ffffffffc0201c14:	00001517          	auipc	a0,0x1
ffffffffc0201c18:	68450513          	addi	a0,a0,1668 # ffffffffc0203298 <etext+0xa8e>
}
ffffffffc0201c1c:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201c1e:	d2cfe06f          	j	ffffffffc020014a <cprintf>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201c22:	86ae                	mv	a3,a1
ffffffffc0201c24:	00001617          	auipc	a2,0x1
ffffffffc0201c28:	55460613          	addi	a2,a2,1364 # ffffffffc0203178 <etext+0x96e>
ffffffffc0201c2c:	08900593          	li	a1,137
ffffffffc0201c30:	00001517          	auipc	a0,0x1
ffffffffc0201c34:	50850513          	addi	a0,a0,1288 # ffffffffc0203138 <etext+0x92e>
ffffffffc0201c38:	d94fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0201c3c <kmalloc>:
    }
    return s;
}

void *kmalloc(size_t size) {
    if (size == 0 || size > KMEMSIZE - HEADER_SIZE) { return NULL; }
ffffffffc0201c3c:	07e007b7          	lui	a5,0x7e00
ffffffffc0201c40:	fff50713          	addi	a4,a0,-1
ffffffffc0201c44:	fbf78793          	addi	a5,a5,-65 # 7dfffbf <kern_entry-0xffffffffb8400041>
ffffffffc0201c48:	20e7eb63          	bltu	a5,a4,ffffffffc0201e5e <kmalloc+0x222>
    if (!initialized) {
ffffffffc0201c4c:	00006697          	auipc	a3,0x6
ffffffffc0201c50:	0dc68693          	addi	a3,a3,220 # ffffffffc0207d28 <initialized>
ffffffffc0201c54:	429c                	lw	a5,0(a3)
void *kmalloc(size_t size) {
ffffffffc0201c56:	7179                	addi	sp,sp,-48
ffffffffc0201c58:	f406                	sd	ra,40(sp)
ffffffffc0201c5a:	f022                	sd	s0,32(sp)
    if (!initialized) {
ffffffffc0201c5c:	e385                	bnez	a5,ffffffffc0201c7c <kmalloc+0x40>
ffffffffc0201c5e:	00006797          	auipc	a5,0x6
ffffffffc0201c62:	ffa78793          	addi	a5,a5,-6 # ffffffffc0207c58 <partial>
ffffffffc0201c66:	00006717          	auipc	a4,0x6
ffffffffc0201c6a:	07270713          	addi	a4,a4,114 # ffffffffc0207cd8 <is_panic>
ffffffffc0201c6e:	e79c                	sd	a5,8(a5)
ffffffffc0201c70:	e39c                	sd	a5,0(a5)
        for (unsigned i = 0; i < CACHE_COUNT; ++i) { list_init(&partial[i]); }
ffffffffc0201c72:	07c1                	addi	a5,a5,16
ffffffffc0201c74:	fee79de3          	bne	a5,a4,ffffffffc0201c6e <kmalloc+0x32>
        initialized = 1;
ffffffffc0201c78:	4785                	li	a5,1
ffffffffc0201c7a:	c29c                	sw	a5,0(a3)
    init_caches();
    if (size > 2048) {
ffffffffc0201c7c:	6785                	lui	a5,0x1
ffffffffc0201c7e:	80078793          	addi	a5,a5,-2048 # 800 <kern_entry-0xffffffffc01ff800>
ffffffffc0201c82:	06a7ea63          	bltu	a5,a0,ffffffffc0201cf6 <kmalloc+0xba>
ffffffffc0201c86:	ec26                	sd	s1,24(sp)
ffffffffc0201c88:	e84a                	sd	s2,16(sp)
ffffffffc0201c8a:	e44e                	sd	s3,8(sp)
    while (((size_t)16 << i) < size) { ++i; }
ffffffffc0201c8c:	47c1                	li	a5,16
    unsigned i = 0;
ffffffffc0201c8e:	4701                	li	a4,0
    while (((size_t)16 << i) < size) { ++i; }
ffffffffc0201c90:	46c1                	li	a3,16
ffffffffc0201c92:	1aa7ff63          	bgeu	a5,a0,ffffffffc0201e50 <kmalloc+0x214>
ffffffffc0201c96:	0017079b          	addiw	a5,a4,1
ffffffffc0201c9a:	00f694b3          	sll	s1,a3,a5
ffffffffc0201c9e:	0007871b          	sext.w	a4,a5
ffffffffc0201ca2:	fea4eae3          	bltu	s1,a0,ffffffffc0201c96 <kmalloc+0x5a>
        s->used = 1;
        return (char *)s + HEADER_SIZE;
    }
    unsigned index = cache_index(size);
    struct slab *s;
    if (list_empty(&partial[index])) {
ffffffffc0201ca6:	02079693          	slli	a3,a5,0x20
ffffffffc0201caa:	01c6d793          	srli	a5,a3,0x1c
ffffffffc0201cae:	00006917          	auipc	s2,0x6
ffffffffc0201cb2:	faa90913          	addi	s2,s2,-86 # ffffffffc0207c58 <partial>
ffffffffc0201cb6:	97ca                	add	a5,a5,s2
    return list->next == list;
ffffffffc0201cb8:	02071413          	slli	s0,a4,0x20
ffffffffc0201cbc:	9001                	srli	s0,s0,0x20
ffffffffc0201cbe:	00441713          	slli	a4,s0,0x4
ffffffffc0201cc2:	974a                	add	a4,a4,s2
ffffffffc0201cc4:	00873983          	ld	s3,8(a4)
        s = new_slab(1, (size_t)16 << index);
        if (s == NULL) { return NULL; }
        list_add(&partial[index], &s->link);
    } else {
        s = to_struct(list_next(&partial[index]), struct slab, link);
ffffffffc0201cc8:	ff898693          	addi	a3,s3,-8
    if (list_empty(&partial[index])) {
ffffffffc0201ccc:	0cf98d63          	beq	s3,a5,ffffffffc0201da6 <kmalloc+0x16a>
    }
    void *obj = s->free;
ffffffffc0201cd0:	6e88                	ld	a0,24(a3)
    assert(obj != NULL && s->used < s->capacity);
ffffffffc0201cd2:	18050863          	beqz	a0,ffffffffc0201e62 <kmalloc+0x226>
ffffffffc0201cd6:	769c                	ld	a5,40(a3)
ffffffffc0201cd8:	7a98                	ld	a4,48(a3)
ffffffffc0201cda:	18e7f463          	bgeu	a5,a4,ffffffffc0201e62 <kmalloc+0x226>
    s->free = *(void **)obj;
ffffffffc0201cde:	6118                	ld	a4,0(a0)
    ++s->used;
ffffffffc0201ce0:	0785                	addi	a5,a5,1
ffffffffc0201ce2:	f69c                	sd	a5,40(a3)
    s->free = *(void **)obj;
ffffffffc0201ce4:	ee98                	sd	a4,24(a3)
    if (s->free == NULL) { list_del_init(&s->link); }
ffffffffc0201ce6:	c34d                	beqz	a4,ffffffffc0201d88 <kmalloc+0x14c>
    return obj;
}
ffffffffc0201ce8:	70a2                	ld	ra,40(sp)
ffffffffc0201cea:	7402                	ld	s0,32(sp)
ffffffffc0201cec:	64e2                	ld	s1,24(sp)
ffffffffc0201cee:	6942                	ld	s2,16(sp)
ffffffffc0201cf0:	69a2                	ld	s3,8(sp)
ffffffffc0201cf2:	6145                	addi	sp,sp,48
ffffffffc0201cf4:	8082                	ret
        size_t npages = ROUNDUP(size + HEADER_SIZE, PGSIZE) / PGSIZE;
ffffffffc0201cf6:	6785                	lui	a5,0x1
ffffffffc0201cf8:	03f78793          	addi	a5,a5,63 # 103f <kern_entry-0xffffffffc01fefc1>
ffffffffc0201cfc:	953e                	add	a0,a0,a5
ffffffffc0201cfe:	00c55413          	srli	s0,a0,0xc
    struct Page *p = alloc_pages(npages);
ffffffffc0201d02:	8522                	mv	a0,s0
ffffffffc0201d04:	e05ff0ef          	jal	ffffffffc0201b08 <alloc_pages>
    if (p == NULL) { return NULL; }
ffffffffc0201d08:	c93d                	beqz	a0,ffffffffc0201d7e <kmalloc+0x142>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201d0a:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0201d0e:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac4fa1>
ffffffffc0201d12:	07b2                	slli	a5,a5,0xc
ffffffffc0201d14:	ccd78793          	addi	a5,a5,-819
ffffffffc0201d18:	07b2                	slli	a5,a5,0xc
ffffffffc0201d1a:	00006717          	auipc	a4,0x6
ffffffffc0201d1e:	00673703          	ld	a4,6(a4) # ffffffffc0207d20 <pages>
ffffffffc0201d22:	ccd78793          	addi	a5,a5,-819
ffffffffc0201d26:	8d19                	sub	a0,a0,a4
ffffffffc0201d28:	07b2                	slli	a5,a5,0xc
ffffffffc0201d2a:	ccd78793          	addi	a5,a5,-819
ffffffffc0201d2e:	850d                	srai	a0,a0,0x3
ffffffffc0201d30:	02f50533          	mul	a0,a0,a5
ffffffffc0201d34:	00002717          	auipc	a4,0x2
ffffffffc0201d38:	b5473703          	ld	a4,-1196(a4) # ffffffffc0203888 <nbase>
}
ffffffffc0201d3c:	70a2                	ld	ra,40(sp)
    s->capacity = unit == 0 ? 1 : (PGSIZE - HEADER_SIZE) / unit;
ffffffffc0201d3e:	4785                	li	a5,1
    s->magic = SLAB_MAGIC;
ffffffffc0201d40:	00002697          	auipc	a3,0x2
ffffffffc0201d44:	b506b683          	ld	a3,-1200(a3) # ffffffffc0203890 <nbase+0x8>
ffffffffc0201d48:	953a                	add	a0,a0,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d4a:	0532                	slli	a0,a0,0xc
    struct slab *s = (struct slab *)(page2pa(p) + va_pa_offset);
ffffffffc0201d4c:	00006717          	auipc	a4,0x6
ffffffffc0201d50:	fc473703          	ld	a4,-60(a4) # ffffffffc0207d10 <va_pa_offset>
ffffffffc0201d54:	953a                	add	a0,a0,a4
    s->npages = npages;
ffffffffc0201d56:	fd00                	sd	s0,56(a0)
}
ffffffffc0201d58:	7402                	ld	s0,32(sp)
    list_init(&s->link);
ffffffffc0201d5a:	00850713          	addi	a4,a0,8
    s->magic = SLAB_MAGIC;
ffffffffc0201d5e:	e114                	sd	a3,0(a0)
    s->free = NULL;
ffffffffc0201d60:	00053c23          	sd	zero,24(a0)
    s->unit = unit;
ffffffffc0201d64:	02053023          	sd	zero,32(a0)
    s->capacity = unit == 0 ? 1 : (PGSIZE - HEADER_SIZE) / unit;
ffffffffc0201d68:	f91c                	sd	a5,48(a0)
    elm->prev = elm->next = elm;
ffffffffc0201d6a:	e918                	sd	a4,16(a0)
ffffffffc0201d6c:	e518                	sd	a4,8(a0)
        s->used = 1;
ffffffffc0201d6e:	f51c                	sd	a5,40(a0)
        return (char *)s + HEADER_SIZE;
ffffffffc0201d70:	04050513          	addi	a0,a0,64
}
ffffffffc0201d74:	6145                	addi	sp,sp,48
ffffffffc0201d76:	8082                	ret
ffffffffc0201d78:	64e2                	ld	s1,24(sp)
ffffffffc0201d7a:	6942                	ld	s2,16(sp)
ffffffffc0201d7c:	69a2                	ld	s3,8(sp)
ffffffffc0201d7e:	70a2                	ld	ra,40(sp)
ffffffffc0201d80:	7402                	ld	s0,32(sp)
    if (size == 0 || size > KMEMSIZE - HEADER_SIZE) { return NULL; }
ffffffffc0201d82:	4501                	li	a0,0
}
ffffffffc0201d84:	6145                	addi	sp,sp,48
ffffffffc0201d86:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0201d88:	6690                	ld	a2,8(a3)
ffffffffc0201d8a:	6a98                	ld	a4,16(a3)
ffffffffc0201d8c:	70a2                	ld	ra,40(sp)
ffffffffc0201d8e:	7402                	ld	s0,32(sp)
    prev->next = next;
ffffffffc0201d90:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc0201d92:	e310                	sd	a2,0(a4)
    if (s->free == NULL) { list_del_init(&s->link); }
ffffffffc0201d94:	00868793          	addi	a5,a3,8
    elm->prev = elm->next = elm;
ffffffffc0201d98:	ea9c                	sd	a5,16(a3)
ffffffffc0201d9a:	e69c                	sd	a5,8(a3)
ffffffffc0201d9c:	64e2                	ld	s1,24(sp)
ffffffffc0201d9e:	6942                	ld	s2,16(sp)
ffffffffc0201da0:	69a2                	ld	s3,8(sp)
}
ffffffffc0201da2:	6145                	addi	sp,sp,48
ffffffffc0201da4:	8082                	ret
    struct Page *p = alloc_pages(npages);
ffffffffc0201da6:	4505                	li	a0,1
ffffffffc0201da8:	d61ff0ef          	jal	ffffffffc0201b08 <alloc_pages>
    if (p == NULL) { return NULL; }
ffffffffc0201dac:	d571                	beqz	a0,ffffffffc0201d78 <kmalloc+0x13c>
    s->capacity = unit == 0 ? 1 : (PGSIZE - HEADER_SIZE) / unit;
ffffffffc0201dae:	6705                	lui	a4,0x1
ffffffffc0201db0:	fc070713          	addi	a4,a4,-64 # fc0 <kern_entry-0xffffffffc01ff040>
ffffffffc0201db4:	02975633          	divu	a2,a4,s1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201db8:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0201dbc:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac4fa1>
ffffffffc0201dc0:	07b2                	slli	a5,a5,0xc
ffffffffc0201dc2:	ccd78793          	addi	a5,a5,-819
ffffffffc0201dc6:	07b2                	slli	a5,a5,0xc
ffffffffc0201dc8:	00006697          	auipc	a3,0x6
ffffffffc0201dcc:	f586b683          	ld	a3,-168(a3) # ffffffffc0207d20 <pages>
ffffffffc0201dd0:	ccd78793          	addi	a5,a5,-819
ffffffffc0201dd4:	40d506b3          	sub	a3,a0,a3
ffffffffc0201dd8:	07b2                	slli	a5,a5,0xc
ffffffffc0201dda:	ccd78793          	addi	a5,a5,-819
ffffffffc0201dde:	868d                	srai	a3,a3,0x3
ffffffffc0201de0:	02f686b3          	mul	a3,a3,a5
ffffffffc0201de4:	00002797          	auipc	a5,0x2
ffffffffc0201de8:	aa47b783          	ld	a5,-1372(a5) # ffffffffc0203888 <nbase>
ffffffffc0201dec:	96be                	add	a3,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201dee:	06b2                	slli	a3,a3,0xc
    struct slab *s = (struct slab *)(page2pa(p) + va_pa_offset);
ffffffffc0201df0:	00006797          	auipc	a5,0x6
ffffffffc0201df4:	f207b783          	ld	a5,-224(a5) # ffffffffc0207d10 <va_pa_offset>
ffffffffc0201df8:	96be                	add	a3,a3,a5
    s->magic = SLAB_MAGIC;
ffffffffc0201dfa:	00002797          	auipc	a5,0x2
ffffffffc0201dfe:	a967b783          	ld	a5,-1386(a5) # ffffffffc0203890 <nbase+0x8>
    list_init(&s->link);
ffffffffc0201e02:	00868593          	addi	a1,a3,8
    s->magic = SLAB_MAGIC;
ffffffffc0201e06:	e29c                	sd	a5,0(a3)
    s->npages = npages;
ffffffffc0201e08:	4785                	li	a5,1
    s->free = NULL;
ffffffffc0201e0a:	0006bc23          	sd	zero,24(a3)
    s->unit = unit;
ffffffffc0201e0e:	f284                	sd	s1,32(a3)
    s->used = 0;
ffffffffc0201e10:	0206b423          	sd	zero,40(a3)
    s->npages = npages;
ffffffffc0201e14:	fe9c                	sd	a5,56(a3)
    s->capacity = unit == 0 ? 1 : (PGSIZE - HEADER_SIZE) / unit;
ffffffffc0201e16:	fa90                	sd	a2,48(a3)
ffffffffc0201e18:	ea8c                	sd	a1,16(a3)
ffffffffc0201e1a:	e68c                	sd	a1,8(a3)
        for (size_t i = s->capacity; i > 0; --i) {
ffffffffc0201e1c:	02976063          	bltu	a4,s1,ffffffffc0201e3c <kmalloc+0x200>
ffffffffc0201e20:	167d                	addi	a2,a2,-1
ffffffffc0201e22:	029607b3          	mul	a5,a2,s1
ffffffffc0201e26:	4701                	li	a4,0
ffffffffc0201e28:	04078793          	addi	a5,a5,64
ffffffffc0201e2c:	97b6                	add	a5,a5,a3
ffffffffc0201e2e:	a011                	j	ffffffffc0201e32 <kmalloc+0x1f6>
ffffffffc0201e30:	167d                	addi	a2,a2,-1
            *(void **)obj = s->free;
ffffffffc0201e32:	e398                	sd	a4,0(a5)
            void *obj = (char *)s + HEADER_SIZE + (i - 1) * unit;
ffffffffc0201e34:	873e                	mv	a4,a5
        for (size_t i = s->capacity; i > 0; --i) {
ffffffffc0201e36:	8f85                	sub	a5,a5,s1
ffffffffc0201e38:	fe65                	bnez	a2,ffffffffc0201e30 <kmalloc+0x1f4>
ffffffffc0201e3a:	ee98                	sd	a4,24(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201e3c:	00441713          	slli	a4,s0,0x4
ffffffffc0201e40:	974a                	add	a4,a4,s2
ffffffffc0201e42:	671c                	ld	a5,8(a4)
    prev->next = next->prev = elm;
ffffffffc0201e44:	e38c                	sd	a1,0(a5)
ffffffffc0201e46:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0201e48:	ea9c                	sd	a5,16(a3)
    elm->prev = prev;
ffffffffc0201e4a:	0136b423          	sd	s3,8(a3)
}
ffffffffc0201e4e:	b549                	j	ffffffffc0201cd0 <kmalloc+0x94>
    while (((size_t)16 << i) < size) { ++i; }
ffffffffc0201e50:	00006917          	auipc	s2,0x6
ffffffffc0201e54:	e0890913          	addi	s2,s2,-504 # ffffffffc0207c58 <partial>
ffffffffc0201e58:	87ca                	mv	a5,s2
ffffffffc0201e5a:	44c1                	li	s1,16
ffffffffc0201e5c:	bdb1                	j	ffffffffc0201cb8 <kmalloc+0x7c>
    if (size == 0 || size > KMEMSIZE - HEADER_SIZE) { return NULL; }
ffffffffc0201e5e:	4501                	li	a0,0
}
ffffffffc0201e60:	8082                	ret
    assert(obj != NULL && s->used < s->capacity);
ffffffffc0201e62:	00001697          	auipc	a3,0x1
ffffffffc0201e66:	47668693          	addi	a3,a3,1142 # ffffffffc02032d8 <etext+0xace>
ffffffffc0201e6a:	00001617          	auipc	a2,0x1
ffffffffc0201e6e:	bf660613          	addi	a2,a2,-1034 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201e72:	04900593          	li	a1,73
ffffffffc0201e76:	00001517          	auipc	a0,0x1
ffffffffc0201e7a:	48a50513          	addi	a0,a0,1162 # ffffffffc0203300 <etext+0xaf6>
ffffffffc0201e7e:	b4efe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0201e82 <kfree>:

void kfree(void *ptr) {
    if (ptr == NULL) { return; }
ffffffffc0201e82:	12050c63          	beqz	a0,ffffffffc0201fba <kfree+0x138>
    struct slab *s = (struct slab *)ROUNDDOWN((uintptr_t)ptr, PGSIZE);
    assert(s->magic == SLAB_MAGIC && s->used > 0);
ffffffffc0201e86:	014d37b7          	lui	a5,0x14d3
ffffffffc0201e8a:	15578793          	addi	a5,a5,341 # 14d3155 <kern_entry-0xffffffffbed2ceab>
ffffffffc0201e8e:	07b2                	slli	a5,a5,0xc
ffffffffc0201e90:	09378793          	addi	a5,a5,147
    struct slab *s = (struct slab *)ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0201e94:	76fd                	lui	a3,0xfffff
ffffffffc0201e96:	8ee9                	and	a3,a3,a0
    assert(s->magic == SLAB_MAGIC && s->used > 0);
ffffffffc0201e98:	07b2                	slli	a5,a5,0xc
ffffffffc0201e9a:	10578793          	addi	a5,a5,261
ffffffffc0201e9e:	6298                	ld	a4,0(a3)
void kfree(void *ptr) {
ffffffffc0201ea0:	1141                	addi	sp,sp,-16
    assert(s->magic == SLAB_MAGIC && s->used > 0);
ffffffffc0201ea2:	07ba                	slli	a5,a5,0xe
void kfree(void *ptr) {
ffffffffc0201ea4:	e406                	sd	ra,8(sp)
    assert(s->magic == SLAB_MAGIC && s->used > 0);
ffffffffc0201ea6:	23278793          	addi	a5,a5,562
ffffffffc0201eaa:	14f71063          	bne	a4,a5,ffffffffc0201fea <kfree+0x168>
ffffffffc0201eae:	7698                	ld	a4,40(a3)
ffffffffc0201eb0:	12070d63          	beqz	a4,ffffffffc0201fea <kfree+0x168>
    if (s->unit == 0) {
ffffffffc0201eb4:	729c                	ld	a5,32(a3)
ffffffffc0201eb6:	c7a9                	beqz	a5,ffffffffc0201f00 <kfree+0x7e>
        assert(ptr == (void *)((char *)s + HEADER_SIZE));
    } else {
        uintptr_t offset = (uintptr_t)ptr - (uintptr_t)s;
ffffffffc0201eb8:	40d50633          	sub	a2,a0,a3
        assert(offset >= HEADER_SIZE);
ffffffffc0201ebc:	03f00593          	li	a1,63
ffffffffc0201ec0:	16c5fd63          	bgeu	a1,a2,ffffffffc020203a <kfree+0x1b8>
        assert((offset - HEADER_SIZE) % s->unit == 0);
ffffffffc0201ec4:	fc060613          	addi	a2,a2,-64
ffffffffc0201ec8:	02f675b3          	remu	a1,a2,a5
ffffffffc0201ecc:	18059763          	bnez	a1,ffffffffc020205a <kfree+0x1d8>
        assert((offset - HEADER_SIZE) / s->unit < s->capacity);
ffffffffc0201ed0:	02f65633          	divu	a2,a2,a5
ffffffffc0201ed4:	7a8c                	ld	a1,48(a3)
ffffffffc0201ed6:	1ab67263          	bgeu	a2,a1,ffffffffc020207a <kfree+0x1f8>
        for (void *p = s->free; p != NULL; p = *(void **)p) {
ffffffffc0201eda:	6e90                	ld	a2,24(a3)
ffffffffc0201edc:	c659                	beqz	a2,ffffffffc0201f6a <kfree+0xe8>
            assert(p != ptr); // detect double-free while the slab is live
ffffffffc0201ede:	0ec50663          	beq	a0,a2,ffffffffc0201fca <kfree+0x148>
        for (void *p = s->free; p != NULL; p = *(void **)p) {
ffffffffc0201ee2:	87b2                	mv	a5,a2
ffffffffc0201ee4:	a019                	j	ffffffffc0201eea <kfree+0x68>
            assert(p != ptr); // detect double-free while the slab is live
ffffffffc0201ee6:	0ef50263          	beq	a0,a5,ffffffffc0201fca <kfree+0x148>
        for (void *p = s->free; p != NULL; p = *(void **)p) {
ffffffffc0201eea:	639c                	ld	a5,0(a5)
ffffffffc0201eec:	ffed                	bnez	a5,ffffffffc0201ee6 <kfree+0x64>
        }
        if (s->free == NULL) {
            list_add(&partial[cache_index(s->unit)], &s->link);
        }
        *(void **)ptr = s->free;
ffffffffc0201eee:	e110                	sd	a2,0(a0)
        s->free = ptr;
ffffffffc0201ef0:	ee88                	sd	a0,24(a3)
    }
    if (--s->used == 0) {
ffffffffc0201ef2:	fff70793          	addi	a5,a4,-1
ffffffffc0201ef6:	f69c                	sd	a5,40(a3)
ffffffffc0201ef8:	cf81                	beqz	a5,ffffffffc0201f10 <kfree+0x8e>
        size_t npages = s->npages;
        list_del_init(&s->link);
        s->magic = 0;
        free_pages(pa2page(PADDR(s)), npages);
    }
}
ffffffffc0201efa:	60a2                	ld	ra,8(sp)
ffffffffc0201efc:	0141                	addi	sp,sp,16
ffffffffc0201efe:	8082                	ret
        assert(ptr == (void *)((char *)s + HEADER_SIZE));
ffffffffc0201f00:	04068793          	addi	a5,a3,64 # fffffffffffff040 <end+0x3fdf7314>
ffffffffc0201f04:	18f51b63          	bne	a0,a5,ffffffffc020209a <kfree+0x218>
    if (--s->used == 0) {
ffffffffc0201f08:	fff70793          	addi	a5,a4,-1
ffffffffc0201f0c:	f69c                	sd	a5,40(a3)
ffffffffc0201f0e:	f7f5                	bnez	a5,ffffffffc0201efa <kfree+0x78>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201f10:	6690                	ld	a2,8(a3)
ffffffffc0201f12:	6a98                	ld	a4,16(a3)
        size_t npages = s->npages;
ffffffffc0201f14:	7e8c                	ld	a1,56(a3)
        list_del_init(&s->link);
ffffffffc0201f16:	00868793          	addi	a5,a3,8
    prev->next = next;
ffffffffc0201f1a:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc0201f1c:	e310                	sd	a2,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0201f1e:	ea9c                	sd	a5,16(a3)
ffffffffc0201f20:	e69c                	sd	a5,8(a3)
        s->magic = 0;
ffffffffc0201f22:	0006b023          	sd	zero,0(a3)
        free_pages(pa2page(PADDR(s)), npages);
ffffffffc0201f26:	c02007b7          	lui	a5,0xc0200
ffffffffc0201f2a:	0ef6e063          	bltu	a3,a5,ffffffffc020200a <kfree+0x188>
ffffffffc0201f2e:	00006797          	auipc	a5,0x6
ffffffffc0201f32:	de27b783          	ld	a5,-542(a5) # ffffffffc0207d10 <va_pa_offset>
ffffffffc0201f36:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0201f3a:	83b1                	srli	a5,a5,0xc
ffffffffc0201f3c:	00006717          	auipc	a4,0x6
ffffffffc0201f40:	ddc73703          	ld	a4,-548(a4) # ffffffffc0207d18 <npage>
ffffffffc0201f44:	0ce7ff63          	bgeu	a5,a4,ffffffffc0202022 <kfree+0x1a0>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f48:	00002717          	auipc	a4,0x2
ffffffffc0201f4c:	94073703          	ld	a4,-1728(a4) # ffffffffc0203888 <nbase>
ffffffffc0201f50:	8f99                	sub	a5,a5,a4
ffffffffc0201f52:	00279513          	slli	a0,a5,0x2
}
ffffffffc0201f56:	60a2                	ld	ra,8(sp)
ffffffffc0201f58:	97aa                	add	a5,a5,a0
ffffffffc0201f5a:	078e                	slli	a5,a5,0x3
        free_pages(pa2page(PADDR(s)), npages);
ffffffffc0201f5c:	00006517          	auipc	a0,0x6
ffffffffc0201f60:	dc453503          	ld	a0,-572(a0) # ffffffffc0207d20 <pages>
ffffffffc0201f64:	953e                	add	a0,a0,a5
}
ffffffffc0201f66:	0141                	addi	sp,sp,16
        free_pages(pa2page(PADDR(s)), npages);
ffffffffc0201f68:	b675                	j	ffffffffc0201b14 <free_pages>
    while (((size_t)16 << i) < size) { ++i; }
ffffffffc0201f6a:	4641                	li	a2,16
ffffffffc0201f6c:	04f67863          	bgeu	a2,a5,ffffffffc0201fbc <kfree+0x13a>
    unsigned i = 0;
ffffffffc0201f70:	4581                	li	a1,0
    while (((size_t)16 << i) < size) { ++i; }
ffffffffc0201f72:	48c1                	li	a7,16
ffffffffc0201f74:	0015861b          	addiw	a2,a1,1
ffffffffc0201f78:	00c89833          	sll	a6,a7,a2
ffffffffc0201f7c:	0006059b          	sext.w	a1,a2
ffffffffc0201f80:	fef86ae3          	bltu	a6,a5,ffffffffc0201f74 <kfree+0xf2>
            list_add(&partial[cache_index(s->unit)], &s->link);
ffffffffc0201f84:	02061813          	slli	a6,a2,0x20
ffffffffc0201f88:	01c85793          	srli	a5,a6,0x1c
ffffffffc0201f8c:	00006617          	auipc	a2,0x6
ffffffffc0201f90:	ccc60613          	addi	a2,a2,-820 # ffffffffc0207c58 <partial>
ffffffffc0201f94:	97b2                	add	a5,a5,a2
    __list_add(elm, listelm, listelm->next);
ffffffffc0201f96:	02059813          	slli	a6,a1,0x20
ffffffffc0201f9a:	01c85593          	srli	a1,a6,0x1c
ffffffffc0201f9e:	962e                	add	a2,a2,a1
ffffffffc0201fa0:	660c                	ld	a1,8(a2)
ffffffffc0201fa2:	00868813          	addi	a6,a3,8
    prev->next = next->prev = elm;
ffffffffc0201fa6:	0105b023          	sd	a6,0(a1)
ffffffffc0201faa:	01063423          	sd	a6,8(a2)
        *(void **)ptr = s->free;
ffffffffc0201fae:	6e90                	ld	a2,24(a3)
    elm->next = next;
ffffffffc0201fb0:	ea8c                	sd	a1,16(a3)
    elm->prev = prev;
ffffffffc0201fb2:	e69c                	sd	a5,8(a3)
ffffffffc0201fb4:	e110                	sd	a2,0(a0)
        s->free = ptr;
ffffffffc0201fb6:	ee88                	sd	a0,24(a3)
ffffffffc0201fb8:	bf2d                	j	ffffffffc0201ef2 <kfree+0x70>
ffffffffc0201fba:	8082                	ret
    while (((size_t)16 << i) < size) { ++i; }
ffffffffc0201fbc:	00006617          	auipc	a2,0x6
ffffffffc0201fc0:	c9c60613          	addi	a2,a2,-868 # ffffffffc0207c58 <partial>
ffffffffc0201fc4:	87b2                	mv	a5,a2
    unsigned i = 0;
ffffffffc0201fc6:	4581                	li	a1,0
ffffffffc0201fc8:	b7f9                	j	ffffffffc0201f96 <kfree+0x114>
            assert(p != ptr); // detect double-free while the slab is live
ffffffffc0201fca:	00001697          	auipc	a3,0x1
ffffffffc0201fce:	40e68693          	addi	a3,a3,1038 # ffffffffc02033d8 <etext+0xbce>
ffffffffc0201fd2:	00001617          	auipc	a2,0x1
ffffffffc0201fd6:	a8e60613          	addi	a2,a2,-1394 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201fda:	05c00593          	li	a1,92
ffffffffc0201fde:	00001517          	auipc	a0,0x1
ffffffffc0201fe2:	32250513          	addi	a0,a0,802 # ffffffffc0203300 <etext+0xaf6>
ffffffffc0201fe6:	9e6fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(s->magic == SLAB_MAGIC && s->used > 0);
ffffffffc0201fea:	00001697          	auipc	a3,0x1
ffffffffc0201fee:	32668693          	addi	a3,a3,806 # ffffffffc0203310 <etext+0xb06>
ffffffffc0201ff2:	00001617          	auipc	a2,0x1
ffffffffc0201ff6:	a6e60613          	addi	a2,a2,-1426 # ffffffffc0202a60 <etext+0x256>
ffffffffc0201ffa:	05300593          	li	a1,83
ffffffffc0201ffe:	00001517          	auipc	a0,0x1
ffffffffc0202002:	30250513          	addi	a0,a0,770 # ffffffffc0203300 <etext+0xaf6>
ffffffffc0202006:	9c6fe0ef          	jal	ffffffffc02001cc <__panic>
        free_pages(pa2page(PADDR(s)), npages);
ffffffffc020200a:	00001617          	auipc	a2,0x1
ffffffffc020200e:	16e60613          	addi	a2,a2,366 # ffffffffc0203178 <etext+0x96e>
ffffffffc0202012:	06800593          	li	a1,104
ffffffffc0202016:	00001517          	auipc	a0,0x1
ffffffffc020201a:	2ea50513          	addi	a0,a0,746 # ffffffffc0203300 <etext+0xaf6>
ffffffffc020201e:	9aefe0ef          	jal	ffffffffc02001cc <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202022:	00001617          	auipc	a2,0x1
ffffffffc0202026:	20e60613          	addi	a2,a2,526 # ffffffffc0203230 <etext+0xa26>
ffffffffc020202a:	06a00593          	li	a1,106
ffffffffc020202e:	00001517          	auipc	a0,0x1
ffffffffc0202032:	22250513          	addi	a0,a0,546 # ffffffffc0203250 <etext+0xa46>
ffffffffc0202036:	996fe0ef          	jal	ffffffffc02001cc <__panic>
        assert(offset >= HEADER_SIZE);
ffffffffc020203a:	00001697          	auipc	a3,0x1
ffffffffc020203e:	32e68693          	addi	a3,a3,814 # ffffffffc0203368 <etext+0xb5e>
ffffffffc0202042:	00001617          	auipc	a2,0x1
ffffffffc0202046:	a1e60613          	addi	a2,a2,-1506 # ffffffffc0202a60 <etext+0x256>
ffffffffc020204a:	05800593          	li	a1,88
ffffffffc020204e:	00001517          	auipc	a0,0x1
ffffffffc0202052:	2b250513          	addi	a0,a0,690 # ffffffffc0203300 <etext+0xaf6>
ffffffffc0202056:	976fe0ef          	jal	ffffffffc02001cc <__panic>
        assert((offset - HEADER_SIZE) % s->unit == 0);
ffffffffc020205a:	00001697          	auipc	a3,0x1
ffffffffc020205e:	32668693          	addi	a3,a3,806 # ffffffffc0203380 <etext+0xb76>
ffffffffc0202062:	00001617          	auipc	a2,0x1
ffffffffc0202066:	9fe60613          	addi	a2,a2,-1538 # ffffffffc0202a60 <etext+0x256>
ffffffffc020206a:	05900593          	li	a1,89
ffffffffc020206e:	00001517          	auipc	a0,0x1
ffffffffc0202072:	29250513          	addi	a0,a0,658 # ffffffffc0203300 <etext+0xaf6>
ffffffffc0202076:	956fe0ef          	jal	ffffffffc02001cc <__panic>
        assert((offset - HEADER_SIZE) / s->unit < s->capacity);
ffffffffc020207a:	00001697          	auipc	a3,0x1
ffffffffc020207e:	32e68693          	addi	a3,a3,814 # ffffffffc02033a8 <etext+0xb9e>
ffffffffc0202082:	00001617          	auipc	a2,0x1
ffffffffc0202086:	9de60613          	addi	a2,a2,-1570 # ffffffffc0202a60 <etext+0x256>
ffffffffc020208a:	05a00593          	li	a1,90
ffffffffc020208e:	00001517          	auipc	a0,0x1
ffffffffc0202092:	27250513          	addi	a0,a0,626 # ffffffffc0203300 <etext+0xaf6>
ffffffffc0202096:	936fe0ef          	jal	ffffffffc02001cc <__panic>
        assert(ptr == (void *)((char *)s + HEADER_SIZE));
ffffffffc020209a:	00001697          	auipc	a3,0x1
ffffffffc020209e:	29e68693          	addi	a3,a3,670 # ffffffffc0203338 <etext+0xb2e>
ffffffffc02020a2:	00001617          	auipc	a2,0x1
ffffffffc02020a6:	9be60613          	addi	a2,a2,-1602 # ffffffffc0202a60 <etext+0x256>
ffffffffc02020aa:	05500593          	li	a1,85
ffffffffc02020ae:	00001517          	auipc	a0,0x1
ffffffffc02020b2:	25250513          	addi	a0,a0,594 # ffffffffc0203300 <etext+0xaf6>
ffffffffc02020b6:	916fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02020ba <slub_check>:
static void verify_bytes(void *ptr, size_t n, unsigned char value) {
    assert(((uintptr_t)ptr & 15) == 0);
    for (size_t j = 0; j < n; ++j) { assert(((unsigned char *)ptr)[j] == value); }
}

void slub_check(void) {
ffffffffc02020ba:	7139                	addi	sp,sp,-64
ffffffffc02020bc:	f822                	sd	s0,48(sp)
ffffffffc02020be:	f426                	sd	s1,40(sp)
ffffffffc02020c0:	f04a                	sd	s2,32(sp)
ffffffffc02020c2:	ec4e                	sd	s3,24(sp)
ffffffffc02020c4:	e852                	sd	s4,16(sp)
ffffffffc02020c6:	e05a                	sd	s6,0(sp)
ffffffffc02020c8:	fc06                	sd	ra,56(sp)
ffffffffc02020ca:	e456                	sd	s5,8(sp)
ffffffffc02020cc:	00005417          	auipc	s0,0x5
ffffffffc02020d0:	18c40413          	addi	s0,s0,396 # ffffffffc0207258 <objects.0>
        1, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 129,
        255, 256, 257, 511, 512, 513, 1023, 1024, 1025,
        2047, 2048, 2049, 4032, 4033, 4096, 8193
    };
    static void *objects[320];
    size_t before = nr_free_pages();
ffffffffc02020d4:	a4dff0ef          	jal	ffffffffc0201b20 <nr_free_pages>
ffffffffc02020d8:	84aa                	mv	s1,a0
    assert(kmalloc(0) == NULL && kmalloc(~(size_t)0) == NULL);
    kfree(NULL);
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); ++i) {
ffffffffc02020da:	00001a17          	auipc	s4,0x1
ffffffffc02020de:	536a0a13          	addi	s4,s4,1334 # ffffffffc0203610 <sizes.1>
    size_t before = nr_free_pages();
ffffffffc02020e2:	89a2                	mv	s3,s0
ffffffffc02020e4:	4905                	li	s2,1
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); ++i) {
ffffffffc02020e6:	4b79                	li	s6,30
        objects[i] = kmalloc(sizes[i]);
ffffffffc02020e8:	000a3a83          	ld	s5,0(s4)
ffffffffc02020ec:	8556                	mv	a0,s5
ffffffffc02020ee:	b4fff0ef          	jal	ffffffffc0201c3c <kmalloc>
ffffffffc02020f2:	00a9b023          	sd	a0,0(s3)
        assert(objects[i] != NULL);
ffffffffc02020f6:	24050563          	beqz	a0,ffffffffc0202340 <slub_check+0x286>
        memset(objects[i], (int)(i + 1), sizes[i]);
ffffffffc02020fa:	0ff97593          	zext.b	a1,s2
ffffffffc02020fe:	8656                	mv	a2,s5
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); ++i) {
ffffffffc0202100:	0905                	addi	s2,s2,1
        memset(objects[i], (int)(i + 1), sizes[i]);
ffffffffc0202102:	6f6000ef          	jal	ffffffffc02027f8 <memset>
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); ++i) {
ffffffffc0202106:	0a21                	addi	s4,s4,8
ffffffffc0202108:	09a1                	addi	s3,s3,8
ffffffffc020210a:	fd691fe3          	bne	s2,s6,ffffffffc02020e8 <slub_check+0x2e>
ffffffffc020210e:	00005a17          	auipc	s4,0x5
ffffffffc0202112:	22aa0a13          	addi	s4,s4,554 # ffffffffc0207338 <objects.0+0xe0>
ffffffffc0202116:	00001997          	auipc	s3,0x1
ffffffffc020211a:	5da98993          	addi	s3,s3,1498 # ffffffffc02036f0 <sizes.1+0xe0>
ffffffffc020211e:	4975                	li	s2,29
    }
    for (size_t i = sizeof(sizes) / sizeof(sizes[0]); i > 0; --i) {
        verify_bytes(objects[i - 1], sizes[i - 1], i);
ffffffffc0202120:	000a3503          	ld	a0,0(s4)
ffffffffc0202124:	0009b703          	ld	a4,0(s3)
    assert(((uintptr_t)ptr & 15) == 0);
ffffffffc0202128:	00f57693          	andi	a3,a0,15
ffffffffc020212c:	87aa                	mv	a5,a0
ffffffffc020212e:	1e069963          	bnez	a3,ffffffffc0202320 <slub_check+0x266>
    for (size_t j = 0; j < n; ++j) { assert(((unsigned char *)ptr)[j] == value); }
ffffffffc0202132:	00a70633          	add	a2,a4,a0
ffffffffc0202136:	0ff97693          	zext.b	a3,s2
ffffffffc020213a:	cb01                	beqz	a4,ffffffffc020214a <slub_check+0x90>
ffffffffc020213c:	0007c703          	lbu	a4,0(a5)
ffffffffc0202140:	12d71063          	bne	a4,a3,ffffffffc0202260 <slub_check+0x1a6>
ffffffffc0202144:	0785                	addi	a5,a5,1
ffffffffc0202146:	fec79be3          	bne	a5,a2,ffffffffc020213c <slub_check+0x82>
    for (size_t i = sizeof(sizes) / sizeof(sizes[0]); i > 0; --i) {
ffffffffc020214a:	197d                	addi	s2,s2,-1
        kfree(objects[i - 1]);
ffffffffc020214c:	d37ff0ef          	jal	ffffffffc0201e82 <kfree>
    for (size_t i = sizeof(sizes) / sizeof(sizes[0]); i > 0; --i) {
ffffffffc0202150:	1a61                	addi	s4,s4,-8
ffffffffc0202152:	19e1                	addi	s3,s3,-8
ffffffffc0202154:	fc0916e3          	bnez	s2,ffffffffc0202120 <slub_check+0x66>
    }
    assert(nr_free_pages() == before);
ffffffffc0202158:	9c9ff0ef          	jal	ffffffffc0201b20 <nr_free_pages>
ffffffffc020215c:	00005997          	auipc	s3,0x5
ffffffffc0202160:	0fc98993          	addi	s3,s3,252 # ffffffffc0207258 <objects.0>

    // Multiple slabs of one class, preserve live objects across partial reuse.
    for (unsigned i = 0; i < 320; ++i) {
ffffffffc0202164:	14000a13          	li	s4,320
    assert(nr_free_pages() == before);
ffffffffc0202168:	14951c63          	bne	a0,s1,ffffffffc02022c0 <slub_check+0x206>
        objects[i] = kmalloc(32);
ffffffffc020216c:	02000513          	li	a0,32
ffffffffc0202170:	acdff0ef          	jal	ffffffffc0201c3c <kmalloc>
ffffffffc0202174:	00a9b023          	sd	a0,0(s3)
        assert(objects[i] != NULL);
ffffffffc0202178:	18050463          	beqz	a0,ffffffffc0202300 <slub_check+0x246>
        memset(objects[i], i & 255, 32);
ffffffffc020217c:	0ff97593          	zext.b	a1,s2
ffffffffc0202180:	02000613          	li	a2,32
    for (unsigned i = 0; i < 320; ++i) {
ffffffffc0202184:	2905                	addiw	s2,s2,1
        memset(objects[i], i & 255, 32);
ffffffffc0202186:	672000ef          	jal	ffffffffc02027f8 <memset>
    for (unsigned i = 0; i < 320; ++i) {
ffffffffc020218a:	09a1                	addi	s3,s3,8
ffffffffc020218c:	ff4910e3          	bne	s2,s4,ffffffffc020216c <slub_check+0xb2>
ffffffffc0202190:	00006997          	auipc	s3,0x6
ffffffffc0202194:	ac898993          	addi	s3,s3,-1336 # ffffffffc0207c58 <partial>
ffffffffc0202198:	00005917          	auipc	s2,0x5
ffffffffc020219c:	0c090913          	addi	s2,s2,192 # ffffffffc0207258 <objects.0>
    }
    for (unsigned i = 0; i < 320; i += 2) { kfree(objects[i]); }
ffffffffc02021a0:	00093503          	ld	a0,0(s2)
ffffffffc02021a4:	0941                	addi	s2,s2,16
ffffffffc02021a6:	cddff0ef          	jal	ffffffffc0201e82 <kfree>
ffffffffc02021aa:	ff391be3          	bne	s2,s3,ffffffffc02021a0 <slub_check+0xe6>
ffffffffc02021ae:	00005997          	auipc	s3,0x5
ffffffffc02021b2:	0aa98993          	addi	s3,s3,170 # ffffffffc0207258 <objects.0>
    for (unsigned i = 0; i < 320; i += 2) {
ffffffffc02021b6:	4901                	li	s2,0
ffffffffc02021b8:	14000a13          	li	s4,320
        objects[i] = kmalloc(32);
ffffffffc02021bc:	02000513          	li	a0,32
ffffffffc02021c0:	a7dff0ef          	jal	ffffffffc0201c3c <kmalloc>
ffffffffc02021c4:	00a9b023          	sd	a0,0(s3)
        assert(objects[i] != NULL);
ffffffffc02021c8:	10050c63          	beqz	a0,ffffffffc02022e0 <slub_check+0x226>
        memset(objects[i], i & 255, 32);
ffffffffc02021cc:	0ff97593          	zext.b	a1,s2
ffffffffc02021d0:	02000613          	li	a2,32
    for (unsigned i = 0; i < 320; i += 2) {
ffffffffc02021d4:	2909                	addiw	s2,s2,2
        memset(objects[i], i & 255, 32);
ffffffffc02021d6:	622000ef          	jal	ffffffffc02027f8 <memset>
    for (unsigned i = 0; i < 320; i += 2) {
ffffffffc02021da:	09c1                	addi	s3,s3,16
ffffffffc02021dc:	ff4910e3          	bne	s2,s4,ffffffffc02021bc <slub_check+0x102>
    }
    for (unsigned i = 0; i < 320; ++i) {
ffffffffc02021e0:	4901                	li	s2,0
ffffffffc02021e2:	14000993          	li	s3,320
        verify_bytes(objects[i], 32, i & 255);
ffffffffc02021e6:	6008                	ld	a0,0(s0)
    assert(((uintptr_t)ptr & 15) == 0);
ffffffffc02021e8:	00f57713          	andi	a4,a0,15
ffffffffc02021ec:	87aa                	mv	a5,a0
ffffffffc02021ee:	12071963          	bnez	a4,ffffffffc0202320 <slub_check+0x266>
ffffffffc02021f2:	02050613          	addi	a2,a0,32
ffffffffc02021f6:	0ff97693          	zext.b	a3,s2
    for (size_t j = 0; j < n; ++j) { assert(((unsigned char *)ptr)[j] == value); }
ffffffffc02021fa:	0007c703          	lbu	a4,0(a5)
ffffffffc02021fe:	06d71163          	bne	a4,a3,ffffffffc0202260 <slub_check+0x1a6>
ffffffffc0202202:	0785                	addi	a5,a5,1
ffffffffc0202204:	fec79be3          	bne	a5,a2,ffffffffc02021fa <slub_check+0x140>
    for (unsigned i = 0; i < 320; ++i) {
ffffffffc0202208:	2905                	addiw	s2,s2,1
        kfree(objects[i]);
ffffffffc020220a:	c79ff0ef          	jal	ffffffffc0201e82 <kfree>
    for (unsigned i = 0; i < 320; ++i) {
ffffffffc020220e:	0421                	addi	s0,s0,8
ffffffffc0202210:	fd391be3          	bne	s2,s3,ffffffffc02021e6 <slub_check+0x12c>
    }
    assert(nr_free_pages() == before);
ffffffffc0202214:	90dff0ef          	jal	ffffffffc0201b20 <nr_free_pages>
ffffffffc0202218:	00006797          	auipc	a5,0x6
ffffffffc020221c:	a4078793          	addi	a5,a5,-1472 # ffffffffc0207c58 <partial>
ffffffffc0202220:	00006697          	auipc	a3,0x6
ffffffffc0202224:	ab868693          	addi	a3,a3,-1352 # ffffffffc0207cd8 <is_panic>
ffffffffc0202228:	04951c63          	bne	a0,s1,ffffffffc0202280 <slub_check+0x1c6>
    for (unsigned i = 0; i < CACHE_COUNT; ++i) { assert(list_empty(&partial[i])); }
ffffffffc020222c:	6798                	ld	a4,8(a5)
ffffffffc020222e:	06f71963          	bne	a4,a5,ffffffffc02022a0 <slub_check+0x1e6>
ffffffffc0202232:	07c1                	addi	a5,a5,16
ffffffffc0202234:	fef69ce3          	bne	a3,a5,ffffffffc020222c <slub_check+0x172>
    cprintf("[SLUB] %s: size boundaries, alignment, data, reuse, reclaim: PASS\n",
            pmm_manager->name);
}
ffffffffc0202238:	7442                	ld	s0,48(sp)
            pmm_manager->name);
ffffffffc020223a:	00006797          	auipc	a5,0x6
ffffffffc020223e:	abe7b783          	ld	a5,-1346(a5) # ffffffffc0207cf8 <pmm_manager>
}
ffffffffc0202242:	70e2                	ld	ra,56(sp)
ffffffffc0202244:	74a2                	ld	s1,40(sp)
ffffffffc0202246:	7902                	ld	s2,32(sp)
ffffffffc0202248:	69e2                	ld	s3,24(sp)
ffffffffc020224a:	6a42                	ld	s4,16(sp)
ffffffffc020224c:	6aa2                	ld	s5,8(sp)
ffffffffc020224e:	6b02                	ld	s6,0(sp)
    cprintf("[SLUB] %s: size boundaries, alignment, data, reuse, reclaim: PASS\n",
ffffffffc0202250:	638c                	ld	a1,0(a5)
ffffffffc0202252:	00001517          	auipc	a0,0x1
ffffffffc0202256:	22e50513          	addi	a0,a0,558 # ffffffffc0203480 <etext+0xc76>
}
ffffffffc020225a:	6121                	addi	sp,sp,64
    cprintf("[SLUB] %s: size boundaries, alignment, data, reuse, reclaim: PASS\n",
ffffffffc020225c:	eeffd06f          	j	ffffffffc020014a <cprintf>
    for (size_t j = 0; j < n; ++j) { assert(((unsigned char *)ptr)[j] == value); }
ffffffffc0202260:	00001697          	auipc	a3,0x1
ffffffffc0202264:	1c068693          	addi	a3,a3,448 # ffffffffc0203420 <etext+0xc16>
ffffffffc0202268:	00000617          	auipc	a2,0x0
ffffffffc020226c:	7f860613          	addi	a2,a2,2040 # ffffffffc0202a60 <etext+0x256>
ffffffffc0202270:	06e00593          	li	a1,110
ffffffffc0202274:	00001517          	auipc	a0,0x1
ffffffffc0202278:	08c50513          	addi	a0,a0,140 # ffffffffc0203300 <etext+0xaf6>
ffffffffc020227c:	f51fd0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == before);
ffffffffc0202280:	00001697          	auipc	a3,0x1
ffffffffc0202284:	1c868693          	addi	a3,a3,456 # ffffffffc0203448 <etext+0xc3e>
ffffffffc0202288:	00000617          	auipc	a2,0x0
ffffffffc020228c:	7d860613          	addi	a2,a2,2008 # ffffffffc0202a60 <etext+0x256>
ffffffffc0202290:	09600593          	li	a1,150
ffffffffc0202294:	00001517          	auipc	a0,0x1
ffffffffc0202298:	06c50513          	addi	a0,a0,108 # ffffffffc0203300 <etext+0xaf6>
ffffffffc020229c:	f31fd0ef          	jal	ffffffffc02001cc <__panic>
    for (unsigned i = 0; i < CACHE_COUNT; ++i) { assert(list_empty(&partial[i])); }
ffffffffc02022a0:	00001697          	auipc	a3,0x1
ffffffffc02022a4:	1c868693          	addi	a3,a3,456 # ffffffffc0203468 <etext+0xc5e>
ffffffffc02022a8:	00000617          	auipc	a2,0x0
ffffffffc02022ac:	7b860613          	addi	a2,a2,1976 # ffffffffc0202a60 <etext+0x256>
ffffffffc02022b0:	09700593          	li	a1,151
ffffffffc02022b4:	00001517          	auipc	a0,0x1
ffffffffc02022b8:	04c50513          	addi	a0,a0,76 # ffffffffc0203300 <etext+0xaf6>
ffffffffc02022bc:	f11fd0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == before);
ffffffffc02022c0:	00001697          	auipc	a3,0x1
ffffffffc02022c4:	18868693          	addi	a3,a3,392 # ffffffffc0203448 <etext+0xc3e>
ffffffffc02022c8:	00000617          	auipc	a2,0x0
ffffffffc02022cc:	79860613          	addi	a2,a2,1944 # ffffffffc0202a60 <etext+0x256>
ffffffffc02022d0:	08400593          	li	a1,132
ffffffffc02022d4:	00001517          	auipc	a0,0x1
ffffffffc02022d8:	02c50513          	addi	a0,a0,44 # ffffffffc0203300 <etext+0xaf6>
ffffffffc02022dc:	ef1fd0ef          	jal	ffffffffc02001cc <__panic>
        assert(objects[i] != NULL);
ffffffffc02022e0:	00001697          	auipc	a3,0x1
ffffffffc02022e4:	10868693          	addi	a3,a3,264 # ffffffffc02033e8 <etext+0xbde>
ffffffffc02022e8:	00000617          	auipc	a2,0x0
ffffffffc02022ec:	77860613          	addi	a2,a2,1912 # ffffffffc0202a60 <etext+0x256>
ffffffffc02022f0:	08f00593          	li	a1,143
ffffffffc02022f4:	00001517          	auipc	a0,0x1
ffffffffc02022f8:	00c50513          	addi	a0,a0,12 # ffffffffc0203300 <etext+0xaf6>
ffffffffc02022fc:	ed1fd0ef          	jal	ffffffffc02001cc <__panic>
        assert(objects[i] != NULL);
ffffffffc0202300:	00001697          	auipc	a3,0x1
ffffffffc0202304:	0e868693          	addi	a3,a3,232 # ffffffffc02033e8 <etext+0xbde>
ffffffffc0202308:	00000617          	auipc	a2,0x0
ffffffffc020230c:	75860613          	addi	a2,a2,1880 # ffffffffc0202a60 <etext+0x256>
ffffffffc0202310:	08900593          	li	a1,137
ffffffffc0202314:	00001517          	auipc	a0,0x1
ffffffffc0202318:	fec50513          	addi	a0,a0,-20 # ffffffffc0203300 <etext+0xaf6>
ffffffffc020231c:	eb1fd0ef          	jal	ffffffffc02001cc <__panic>
    assert(((uintptr_t)ptr & 15) == 0);
ffffffffc0202320:	00001697          	auipc	a3,0x1
ffffffffc0202324:	0e068693          	addi	a3,a3,224 # ffffffffc0203400 <etext+0xbf6>
ffffffffc0202328:	00000617          	auipc	a2,0x0
ffffffffc020232c:	73860613          	addi	a2,a2,1848 # ffffffffc0202a60 <etext+0x256>
ffffffffc0202330:	06d00593          	li	a1,109
ffffffffc0202334:	00001517          	auipc	a0,0x1
ffffffffc0202338:	fcc50513          	addi	a0,a0,-52 # ffffffffc0203300 <etext+0xaf6>
ffffffffc020233c:	e91fd0ef          	jal	ffffffffc02001cc <__panic>
        assert(objects[i] != NULL);
ffffffffc0202340:	00001697          	auipc	a3,0x1
ffffffffc0202344:	0a868693          	addi	a3,a3,168 # ffffffffc02033e8 <etext+0xbde>
ffffffffc0202348:	00000617          	auipc	a2,0x0
ffffffffc020234c:	71860613          	addi	a2,a2,1816 # ffffffffc0202a60 <etext+0x256>
ffffffffc0202350:	07d00593          	li	a1,125
ffffffffc0202354:	00001517          	auipc	a0,0x1
ffffffffc0202358:	fac50513          	addi	a0,a0,-84 # ffffffffc0203300 <etext+0xaf6>
ffffffffc020235c:	e71fd0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0202360 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0202360:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202364:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0202366:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020236a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020236c:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202370:	f022                	sd	s0,32(sp)
ffffffffc0202372:	ec26                	sd	s1,24(sp)
ffffffffc0202374:	e84a                	sd	s2,16(sp)
ffffffffc0202376:	f406                	sd	ra,40(sp)
ffffffffc0202378:	84aa                	mv	s1,a0
ffffffffc020237a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020237c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0202380:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0202382:	05067063          	bgeu	a2,a6,ffffffffc02023c2 <printnum+0x62>
ffffffffc0202386:	e44e                	sd	s3,8(sp)
ffffffffc0202388:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020238a:	4785                	li	a5,1
ffffffffc020238c:	00e7d763          	bge	a5,a4,ffffffffc020239a <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0202390:	85ca                	mv	a1,s2
ffffffffc0202392:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0202394:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0202396:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0202398:	fc65                	bnez	s0,ffffffffc0202390 <printnum+0x30>
ffffffffc020239a:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020239c:	1a02                	slli	s4,s4,0x20
ffffffffc020239e:	020a5a13          	srli	s4,s4,0x20
ffffffffc02023a2:	00001797          	auipc	a5,0x1
ffffffffc02023a6:	12678793          	addi	a5,a5,294 # ffffffffc02034c8 <etext+0xcbe>
ffffffffc02023aa:	97d2                	add	a5,a5,s4
}
ffffffffc02023ac:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02023ae:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02023b2:	70a2                	ld	ra,40(sp)
ffffffffc02023b4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02023b6:	85ca                	mv	a1,s2
ffffffffc02023b8:	87a6                	mv	a5,s1
}
ffffffffc02023ba:	6942                	ld	s2,16(sp)
ffffffffc02023bc:	64e2                	ld	s1,24(sp)
ffffffffc02023be:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02023c0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02023c2:	03065633          	divu	a2,a2,a6
ffffffffc02023c6:	8722                	mv	a4,s0
ffffffffc02023c8:	f99ff0ef          	jal	ffffffffc0202360 <printnum>
ffffffffc02023cc:	bfc1                	j	ffffffffc020239c <printnum+0x3c>

ffffffffc02023ce <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02023ce:	7119                	addi	sp,sp,-128
ffffffffc02023d0:	f4a6                	sd	s1,104(sp)
ffffffffc02023d2:	f0ca                	sd	s2,96(sp)
ffffffffc02023d4:	ecce                	sd	s3,88(sp)
ffffffffc02023d6:	e8d2                	sd	s4,80(sp)
ffffffffc02023d8:	e4d6                	sd	s5,72(sp)
ffffffffc02023da:	e0da                	sd	s6,64(sp)
ffffffffc02023dc:	f862                	sd	s8,48(sp)
ffffffffc02023de:	fc86                	sd	ra,120(sp)
ffffffffc02023e0:	f8a2                	sd	s0,112(sp)
ffffffffc02023e2:	fc5e                	sd	s7,56(sp)
ffffffffc02023e4:	f466                	sd	s9,40(sp)
ffffffffc02023e6:	f06a                	sd	s10,32(sp)
ffffffffc02023e8:	ec6e                	sd	s11,24(sp)
ffffffffc02023ea:	892a                	mv	s2,a0
ffffffffc02023ec:	84ae                	mv	s1,a1
ffffffffc02023ee:	8c32                	mv	s8,a2
ffffffffc02023f0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02023f2:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02023f6:	05500b13          	li	s6,85
ffffffffc02023fa:	00001a97          	auipc	s5,0x1
ffffffffc02023fe:	2fea8a93          	addi	s5,s5,766 # ffffffffc02036f8 <sizes.1+0xe8>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202402:	000c4503          	lbu	a0,0(s8)
ffffffffc0202406:	001c0413          	addi	s0,s8,1
ffffffffc020240a:	01350a63          	beq	a0,s3,ffffffffc020241e <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc020240e:	cd0d                	beqz	a0,ffffffffc0202448 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0202410:	85a6                	mv	a1,s1
ffffffffc0202412:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202414:	00044503          	lbu	a0,0(s0)
ffffffffc0202418:	0405                	addi	s0,s0,1
ffffffffc020241a:	ff351ae3          	bne	a0,s3,ffffffffc020240e <vprintfmt+0x40>
        char padc = ' ';
ffffffffc020241e:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0202422:	4b81                	li	s7,0
ffffffffc0202424:	4601                	li	a2,0
        width = precision = -1;
ffffffffc0202426:	5d7d                	li	s10,-1
ffffffffc0202428:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020242a:	00044683          	lbu	a3,0(s0)
ffffffffc020242e:	00140c13          	addi	s8,s0,1
ffffffffc0202432:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0202436:	0ff5f593          	zext.b	a1,a1
ffffffffc020243a:	02bb6663          	bltu	s6,a1,ffffffffc0202466 <vprintfmt+0x98>
ffffffffc020243e:	058a                	slli	a1,a1,0x2
ffffffffc0202440:	95d6                	add	a1,a1,s5
ffffffffc0202442:	4198                	lw	a4,0(a1)
ffffffffc0202444:	9756                	add	a4,a4,s5
ffffffffc0202446:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0202448:	70e6                	ld	ra,120(sp)
ffffffffc020244a:	7446                	ld	s0,112(sp)
ffffffffc020244c:	74a6                	ld	s1,104(sp)
ffffffffc020244e:	7906                	ld	s2,96(sp)
ffffffffc0202450:	69e6                	ld	s3,88(sp)
ffffffffc0202452:	6a46                	ld	s4,80(sp)
ffffffffc0202454:	6aa6                	ld	s5,72(sp)
ffffffffc0202456:	6b06                	ld	s6,64(sp)
ffffffffc0202458:	7be2                	ld	s7,56(sp)
ffffffffc020245a:	7c42                	ld	s8,48(sp)
ffffffffc020245c:	7ca2                	ld	s9,40(sp)
ffffffffc020245e:	7d02                	ld	s10,32(sp)
ffffffffc0202460:	6de2                	ld	s11,24(sp)
ffffffffc0202462:	6109                	addi	sp,sp,128
ffffffffc0202464:	8082                	ret
            putch('%', putdat);
ffffffffc0202466:	85a6                	mv	a1,s1
ffffffffc0202468:	02500513          	li	a0,37
ffffffffc020246c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020246e:	fff44703          	lbu	a4,-1(s0)
ffffffffc0202472:	02500793          	li	a5,37
ffffffffc0202476:	8c22                	mv	s8,s0
ffffffffc0202478:	f8f705e3          	beq	a4,a5,ffffffffc0202402 <vprintfmt+0x34>
ffffffffc020247c:	02500713          	li	a4,37
ffffffffc0202480:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0202484:	1c7d                	addi	s8,s8,-1
ffffffffc0202486:	fee79de3          	bne	a5,a4,ffffffffc0202480 <vprintfmt+0xb2>
ffffffffc020248a:	bfa5                	j	ffffffffc0202402 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc020248c:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0202490:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0202492:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0202496:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc020249a:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020249e:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc02024a0:	02b76563          	bltu	a4,a1,ffffffffc02024ca <vprintfmt+0xfc>
ffffffffc02024a4:	4525                	li	a0,9
                ch = *fmt;
ffffffffc02024a6:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02024aa:	002d171b          	slliw	a4,s10,0x2
ffffffffc02024ae:	01a7073b          	addw	a4,a4,s10
ffffffffc02024b2:	0017171b          	slliw	a4,a4,0x1
ffffffffc02024b6:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc02024b8:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02024bc:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02024be:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc02024c2:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc02024c6:	feb570e3          	bgeu	a0,a1,ffffffffc02024a6 <vprintfmt+0xd8>
            if (width < 0)
ffffffffc02024ca:	f60cd0e3          	bgez	s9,ffffffffc020242a <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02024ce:	8cea                	mv	s9,s10
ffffffffc02024d0:	5d7d                	li	s10,-1
ffffffffc02024d2:	bfa1                	j	ffffffffc020242a <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02024d4:	8db6                	mv	s11,a3
ffffffffc02024d6:	8462                	mv	s0,s8
ffffffffc02024d8:	bf89                	j	ffffffffc020242a <vprintfmt+0x5c>
ffffffffc02024da:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc02024dc:	4b85                	li	s7,1
            goto reswitch;
ffffffffc02024de:	b7b1                	j	ffffffffc020242a <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02024e0:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02024e2:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc02024e6:	00c7c463          	blt	a5,a2,ffffffffc02024ee <vprintfmt+0x120>
    else if (lflag) {
ffffffffc02024ea:	1a060163          	beqz	a2,ffffffffc020268c <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc02024ee:	000a3603          	ld	a2,0(s4)
ffffffffc02024f2:	46c1                	li	a3,16
ffffffffc02024f4:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02024f6:	000d879b          	sext.w	a5,s11
ffffffffc02024fa:	8766                	mv	a4,s9
ffffffffc02024fc:	85a6                	mv	a1,s1
ffffffffc02024fe:	854a                	mv	a0,s2
ffffffffc0202500:	e61ff0ef          	jal	ffffffffc0202360 <printnum>
            break;
ffffffffc0202504:	bdfd                	j	ffffffffc0202402 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0202506:	000a2503          	lw	a0,0(s4)
ffffffffc020250a:	85a6                	mv	a1,s1
ffffffffc020250c:	0a21                	addi	s4,s4,8
ffffffffc020250e:	9902                	jalr	s2
            break;
ffffffffc0202510:	bdcd                	j	ffffffffc0202402 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0202512:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0202514:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0202518:	00c7c463          	blt	a5,a2,ffffffffc0202520 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc020251c:	16060363          	beqz	a2,ffffffffc0202682 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0202520:	000a3603          	ld	a2,0(s4)
ffffffffc0202524:	46a9                	li	a3,10
ffffffffc0202526:	8a3a                	mv	s4,a4
ffffffffc0202528:	b7f9                	j	ffffffffc02024f6 <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc020252a:	85a6                	mv	a1,s1
ffffffffc020252c:	03000513          	li	a0,48
ffffffffc0202530:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0202532:	85a6                	mv	a1,s1
ffffffffc0202534:	07800513          	li	a0,120
ffffffffc0202538:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020253a:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020253e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202540:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0202542:	bf55                	j	ffffffffc02024f6 <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0202544:	85a6                	mv	a1,s1
ffffffffc0202546:	02500513          	li	a0,37
ffffffffc020254a:	9902                	jalr	s2
            break;
ffffffffc020254c:	bd5d                	j	ffffffffc0202402 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc020254e:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202552:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0202554:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0202556:	bf95                	j	ffffffffc02024ca <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0202558:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc020255a:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc020255e:	00c7c463          	blt	a5,a2,ffffffffc0202566 <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0202562:	10060b63          	beqz	a2,ffffffffc0202678 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0202566:	000a3603          	ld	a2,0(s4)
ffffffffc020256a:	46a1                	li	a3,8
ffffffffc020256c:	8a3a                	mv	s4,a4
ffffffffc020256e:	b761                	j	ffffffffc02024f6 <vprintfmt+0x128>
            if (width < 0)
ffffffffc0202570:	fffcc793          	not	a5,s9
ffffffffc0202574:	97fd                	srai	a5,a5,0x3f
ffffffffc0202576:	00fcf7b3          	and	a5,s9,a5
ffffffffc020257a:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020257e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0202580:	b56d                	j	ffffffffc020242a <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202582:	000a3403          	ld	s0,0(s4)
ffffffffc0202586:	008a0793          	addi	a5,s4,8
ffffffffc020258a:	e43e                	sd	a5,8(sp)
ffffffffc020258c:	12040063          	beqz	s0,ffffffffc02026ac <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0202590:	0d905963          	blez	s9,ffffffffc0202662 <vprintfmt+0x294>
ffffffffc0202594:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202598:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc020259c:	12fd9763          	bne	s11,a5,ffffffffc02026ca <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02025a0:	00044783          	lbu	a5,0(s0)
ffffffffc02025a4:	0007851b          	sext.w	a0,a5
ffffffffc02025a8:	cb9d                	beqz	a5,ffffffffc02025de <vprintfmt+0x210>
ffffffffc02025aa:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02025ac:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02025b0:	000d4563          	bltz	s10,ffffffffc02025ba <vprintfmt+0x1ec>
ffffffffc02025b4:	3d7d                	addiw	s10,s10,-1
ffffffffc02025b6:	028d0263          	beq	s10,s0,ffffffffc02025da <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc02025ba:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02025bc:	0c0b8d63          	beqz	s7,ffffffffc0202696 <vprintfmt+0x2c8>
ffffffffc02025c0:	3781                	addiw	a5,a5,-32
ffffffffc02025c2:	0cfdfa63          	bgeu	s11,a5,ffffffffc0202696 <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc02025c6:	03f00513          	li	a0,63
ffffffffc02025ca:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02025cc:	000a4783          	lbu	a5,0(s4)
ffffffffc02025d0:	3cfd                	addiw	s9,s9,-1
ffffffffc02025d2:	0a05                	addi	s4,s4,1
ffffffffc02025d4:	0007851b          	sext.w	a0,a5
ffffffffc02025d8:	ffe1                	bnez	a5,ffffffffc02025b0 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc02025da:	01905963          	blez	s9,ffffffffc02025ec <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc02025de:	85a6                	mv	a1,s1
ffffffffc02025e0:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02025e4:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc02025e6:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02025e8:	fe0c9be3          	bnez	s9,ffffffffc02025de <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02025ec:	6a22                	ld	s4,8(sp)
ffffffffc02025ee:	bd11                	j	ffffffffc0202402 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02025f0:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02025f2:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02025f6:	00c7c363          	blt	a5,a2,ffffffffc02025fc <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc02025fa:	ce25                	beqz	a2,ffffffffc0202672 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc02025fc:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0202600:	08044d63          	bltz	s0,ffffffffc020269a <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0202604:	8622                	mv	a2,s0
ffffffffc0202606:	8a5e                	mv	s4,s7
ffffffffc0202608:	46a9                	li	a3,10
ffffffffc020260a:	b5f5                	j	ffffffffc02024f6 <vprintfmt+0x128>
            if (err < 0) {
ffffffffc020260c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202610:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0202612:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0202616:	8fb9                	xor	a5,a5,a4
ffffffffc0202618:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020261c:	02d64663          	blt	a2,a3,ffffffffc0202648 <vprintfmt+0x27a>
ffffffffc0202620:	00369713          	slli	a4,a3,0x3
ffffffffc0202624:	00001797          	auipc	a5,0x1
ffffffffc0202628:	22c78793          	addi	a5,a5,556 # ffffffffc0203850 <error_string>
ffffffffc020262c:	97ba                	add	a5,a5,a4
ffffffffc020262e:	639c                	ld	a5,0(a5)
ffffffffc0202630:	cf81                	beqz	a5,ffffffffc0202648 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0202632:	86be                	mv	a3,a5
ffffffffc0202634:	00001617          	auipc	a2,0x1
ffffffffc0202638:	ec460613          	addi	a2,a2,-316 # ffffffffc02034f8 <etext+0xcee>
ffffffffc020263c:	85a6                	mv	a1,s1
ffffffffc020263e:	854a                	mv	a0,s2
ffffffffc0202640:	0e8000ef          	jal	ffffffffc0202728 <printfmt>
            err = va_arg(ap, int);
ffffffffc0202644:	0a21                	addi	s4,s4,8
ffffffffc0202646:	bb75                	j	ffffffffc0202402 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0202648:	00001617          	auipc	a2,0x1
ffffffffc020264c:	ea060613          	addi	a2,a2,-352 # ffffffffc02034e8 <etext+0xcde>
ffffffffc0202650:	85a6                	mv	a1,s1
ffffffffc0202652:	854a                	mv	a0,s2
ffffffffc0202654:	0d4000ef          	jal	ffffffffc0202728 <printfmt>
            err = va_arg(ap, int);
ffffffffc0202658:	0a21                	addi	s4,s4,8
ffffffffc020265a:	b365                	j	ffffffffc0202402 <vprintfmt+0x34>
            lflag ++;
ffffffffc020265c:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020265e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0202660:	b3e9                	j	ffffffffc020242a <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202662:	00044783          	lbu	a5,0(s0)
ffffffffc0202666:	0007851b          	sext.w	a0,a5
ffffffffc020266a:	d3c9                	beqz	a5,ffffffffc02025ec <vprintfmt+0x21e>
ffffffffc020266c:	00140a13          	addi	s4,s0,1
ffffffffc0202670:	bf2d                	j	ffffffffc02025aa <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0202672:	000a2403          	lw	s0,0(s4)
ffffffffc0202676:	b769                	j	ffffffffc0202600 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc0202678:	000a6603          	lwu	a2,0(s4)
ffffffffc020267c:	46a1                	li	a3,8
ffffffffc020267e:	8a3a                	mv	s4,a4
ffffffffc0202680:	bd9d                	j	ffffffffc02024f6 <vprintfmt+0x128>
ffffffffc0202682:	000a6603          	lwu	a2,0(s4)
ffffffffc0202686:	46a9                	li	a3,10
ffffffffc0202688:	8a3a                	mv	s4,a4
ffffffffc020268a:	b5b5                	j	ffffffffc02024f6 <vprintfmt+0x128>
ffffffffc020268c:	000a6603          	lwu	a2,0(s4)
ffffffffc0202690:	46c1                	li	a3,16
ffffffffc0202692:	8a3a                	mv	s4,a4
ffffffffc0202694:	b58d                	j	ffffffffc02024f6 <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc0202696:	9902                	jalr	s2
ffffffffc0202698:	bf15                	j	ffffffffc02025cc <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc020269a:	85a6                	mv	a1,s1
ffffffffc020269c:	02d00513          	li	a0,45
ffffffffc02026a0:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02026a2:	40800633          	neg	a2,s0
ffffffffc02026a6:	8a5e                	mv	s4,s7
ffffffffc02026a8:	46a9                	li	a3,10
ffffffffc02026aa:	b5b1                	j	ffffffffc02024f6 <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc02026ac:	01905663          	blez	s9,ffffffffc02026b8 <vprintfmt+0x2ea>
ffffffffc02026b0:	02d00793          	li	a5,45
ffffffffc02026b4:	04fd9263          	bne	s11,a5,ffffffffc02026f8 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02026b8:	02800793          	li	a5,40
ffffffffc02026bc:	00001a17          	auipc	s4,0x1
ffffffffc02026c0:	e25a0a13          	addi	s4,s4,-475 # ffffffffc02034e1 <etext+0xcd7>
ffffffffc02026c4:	02800513          	li	a0,40
ffffffffc02026c8:	b5cd                	j	ffffffffc02025aa <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02026ca:	85ea                	mv	a1,s10
ffffffffc02026cc:	8522                	mv	a0,s0
ffffffffc02026ce:	0ae000ef          	jal	ffffffffc020277c <strnlen>
ffffffffc02026d2:	40ac8cbb          	subw	s9,s9,a0
ffffffffc02026d6:	01905963          	blez	s9,ffffffffc02026e8 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc02026da:	2d81                	sext.w	s11,s11
ffffffffc02026dc:	85a6                	mv	a1,s1
ffffffffc02026de:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02026e0:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc02026e2:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02026e4:	fe0c9ce3          	bnez	s9,ffffffffc02026dc <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02026e8:	00044783          	lbu	a5,0(s0)
ffffffffc02026ec:	0007851b          	sext.w	a0,a5
ffffffffc02026f0:	ea079de3          	bnez	a5,ffffffffc02025aa <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02026f4:	6a22                	ld	s4,8(sp)
ffffffffc02026f6:	b331                	j	ffffffffc0202402 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02026f8:	85ea                	mv	a1,s10
ffffffffc02026fa:	00001517          	auipc	a0,0x1
ffffffffc02026fe:	de650513          	addi	a0,a0,-538 # ffffffffc02034e0 <etext+0xcd6>
ffffffffc0202702:	07a000ef          	jal	ffffffffc020277c <strnlen>
ffffffffc0202706:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc020270a:	00001417          	auipc	s0,0x1
ffffffffc020270e:	dd640413          	addi	s0,s0,-554 # ffffffffc02034e0 <etext+0xcd6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202712:	00001a17          	auipc	s4,0x1
ffffffffc0202716:	dcfa0a13          	addi	s4,s4,-561 # ffffffffc02034e1 <etext+0xcd7>
ffffffffc020271a:	02800793          	li	a5,40
ffffffffc020271e:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202722:	fb904ce3          	bgtz	s9,ffffffffc02026da <vprintfmt+0x30c>
ffffffffc0202726:	b551                	j	ffffffffc02025aa <vprintfmt+0x1dc>

ffffffffc0202728 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202728:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020272a:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020272e:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0202730:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202732:	ec06                	sd	ra,24(sp)
ffffffffc0202734:	f83a                	sd	a4,48(sp)
ffffffffc0202736:	fc3e                	sd	a5,56(sp)
ffffffffc0202738:	e0c2                	sd	a6,64(sp)
ffffffffc020273a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020273c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020273e:	c91ff0ef          	jal	ffffffffc02023ce <vprintfmt>
}
ffffffffc0202742:	60e2                	ld	ra,24(sp)
ffffffffc0202744:	6161                	addi	sp,sp,80
ffffffffc0202746:	8082                	ret

ffffffffc0202748 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0202748:	4781                	li	a5,0
ffffffffc020274a:	00005717          	auipc	a4,0x5
ffffffffc020274e:	8c673703          	ld	a4,-1850(a4) # ffffffffc0207010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0202752:	88ba                	mv	a7,a4
ffffffffc0202754:	852a                	mv	a0,a0
ffffffffc0202756:	85be                	mv	a1,a5
ffffffffc0202758:	863e                	mv	a2,a5
ffffffffc020275a:	00000073          	ecall
ffffffffc020275e:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0202760:	8082                	ret

ffffffffc0202762 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0202762:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0202766:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0202768:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020276a:	cb81                	beqz	a5,ffffffffc020277a <strlen+0x18>
        cnt ++;
ffffffffc020276c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020276e:	00a707b3          	add	a5,a4,a0
ffffffffc0202772:	0007c783          	lbu	a5,0(a5)
ffffffffc0202776:	fbfd                	bnez	a5,ffffffffc020276c <strlen+0xa>
ffffffffc0202778:	8082                	ret
    }
    return cnt;
}
ffffffffc020277a:	8082                	ret

ffffffffc020277c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020277c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020277e:	e589                	bnez	a1,ffffffffc0202788 <strnlen+0xc>
ffffffffc0202780:	a811                	j	ffffffffc0202794 <strnlen+0x18>
        cnt ++;
ffffffffc0202782:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202784:	00f58863          	beq	a1,a5,ffffffffc0202794 <strnlen+0x18>
ffffffffc0202788:	00f50733          	add	a4,a0,a5
ffffffffc020278c:	00074703          	lbu	a4,0(a4)
ffffffffc0202790:	fb6d                	bnez	a4,ffffffffc0202782 <strnlen+0x6>
ffffffffc0202792:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0202794:	852e                	mv	a0,a1
ffffffffc0202796:	8082                	ret

ffffffffc0202798 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202798:	00054783          	lbu	a5,0(a0)
ffffffffc020279c:	e791                	bnez	a5,ffffffffc02027a8 <strcmp+0x10>
ffffffffc020279e:	a02d                	j	ffffffffc02027c8 <strcmp+0x30>
ffffffffc02027a0:	00054783          	lbu	a5,0(a0)
ffffffffc02027a4:	cf89                	beqz	a5,ffffffffc02027be <strcmp+0x26>
ffffffffc02027a6:	85b6                	mv	a1,a3
ffffffffc02027a8:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02027ac:	0505                	addi	a0,a0,1
ffffffffc02027ae:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02027b2:	fef707e3          	beq	a4,a5,ffffffffc02027a0 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02027b6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02027ba:	9d19                	subw	a0,a0,a4
ffffffffc02027bc:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02027be:	0015c703          	lbu	a4,1(a1)
ffffffffc02027c2:	4501                	li	a0,0
}
ffffffffc02027c4:	9d19                	subw	a0,a0,a4
ffffffffc02027c6:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02027c8:	0005c703          	lbu	a4,0(a1)
ffffffffc02027cc:	4501                	li	a0,0
ffffffffc02027ce:	b7f5                	j	ffffffffc02027ba <strcmp+0x22>

ffffffffc02027d0 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02027d0:	ce01                	beqz	a2,ffffffffc02027e8 <strncmp+0x18>
ffffffffc02027d2:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02027d6:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02027d8:	cb91                	beqz	a5,ffffffffc02027ec <strncmp+0x1c>
ffffffffc02027da:	0005c703          	lbu	a4,0(a1)
ffffffffc02027de:	00f71763          	bne	a4,a5,ffffffffc02027ec <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc02027e2:	0505                	addi	a0,a0,1
ffffffffc02027e4:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02027e6:	f675                	bnez	a2,ffffffffc02027d2 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02027e8:	4501                	li	a0,0
ffffffffc02027ea:	8082                	ret
ffffffffc02027ec:	00054503          	lbu	a0,0(a0)
ffffffffc02027f0:	0005c783          	lbu	a5,0(a1)
ffffffffc02027f4:	9d1d                	subw	a0,a0,a5
}
ffffffffc02027f6:	8082                	ret

ffffffffc02027f8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02027f8:	ca01                	beqz	a2,ffffffffc0202808 <memset+0x10>
ffffffffc02027fa:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02027fc:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02027fe:	0785                	addi	a5,a5,1
ffffffffc0202800:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0202804:	fef61de3          	bne	a2,a5,ffffffffc02027fe <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0202808:	8082                	ret

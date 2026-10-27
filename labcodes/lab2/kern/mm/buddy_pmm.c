// lab2 Buddy System 2411156
#include <buddy_pmm.h>
#include <stdio.h>

#define MAX_ORDER 18
#define ALLOC_HEAD (1UL << 2)
static list_entry_t areas[MAX_ORDER + 1];
static size_t free_count;

static size_t block_size(unsigned order) { return (size_t)1 << order; }

static void buddy_init(void) {
    for (unsigned i = 0; i <= MAX_ORDER; ++i) {
        list_init(&areas[i]);
    }
    free_count = 0;
}

static void put_block(struct Page *p, unsigned order) {
    p->property = block_size(order);
    SetPageProperty(p);
    list_add(&areas[order], &p->page_link);
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    for (size_t i = 0; i < n; ++i) {
        assert(PageReserved(base + i));
        base[i].flags = base[i].property = 0;
        base[i].ref = 0;
    }
    free_count += n;
    while (n != 0) {
        unsigned order = MAX_ORDER;
        while (block_size(order) > n ||
               (page2ppn(base) & (block_size(order) - 1)) != 0) {
            --order;
        }
        put_block(base, order);
        base += block_size(order);
        n -= block_size(order);
    }
}

static struct Page *buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > free_count || n > block_size(MAX_ORDER)) {
        return NULL;
    }
    unsigned want = 0, found;
    while (block_size(want) < n) { ++want; }
    for (found = want; found <= MAX_ORDER; ++found) {
        if (!list_empty(&areas[found])) { break; }
    }
    if (found > MAX_ORDER) { return NULL; }
    struct Page *p = le2page(list_next(&areas[found]), page_link);
    list_del(&p->page_link);
    ClearPageProperty(p);
    while (found > want) {
        --found;
        put_block(p + block_size(found), found);
    }
    p->property = block_size(want);
    p->flags |= ALLOC_HEAD;
    free_count -= block_size(want);
    return p;
}

static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0 && n <= block_size(MAX_ORDER));
    unsigned order = 0;
    while (block_size(order) < n) { ++order; }
    assert((base->flags & ALLOC_HEAD) && !PageProperty(base));
    assert(base->property == block_size(order));
    free_count += block_size(order);
    base->flags &= ~ALLOC_HEAD;
    base->property = 0;
    while (order < MAX_ORDER) {
        ppn_t other = page2ppn(base) ^ block_size(order);
        if (other < nbase || other >= npage || block_size(order) > npage - other) {
            break;
        }
        struct Page *partner = pages + other - nbase;
        if (!PageProperty(partner) || partner->property != block_size(order)) {
            break;
        }
        list_del(&partner->page_link);
        ClearPageProperty(partner);
        partner->property = 0;
        if (partner < base) { base = partner; }
        ++order;
    }
    put_block(base, order);
}

static size_t buddy_nr_free_pages(void) { return free_count; }

static void check_lists(void) {
    size_t total = 0;
    for (unsigned order = 0; order <= MAX_ORDER; ++order) {
        list_entry_t *le = &areas[order];
        while ((le = list_next(le)) != &areas[order]) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p) && !(p->flags & ALLOC_HEAD));
            assert(p->property == block_size(order));
            assert((page2ppn(p) & (block_size(order) - 1)) == 0);
            total += p->property;
        }
    }
    assert(total == free_count);
}

static void buddy_check(void) {
    size_t before = free_count;
    struct Page *a = buddy_alloc_pages(1);
    struct Page *b = buddy_alloc_pages(3);
    struct Page *c = buddy_alloc_pages(5);
    assert(a && b && c);
    assert(free_count == before - 13);
    assert(a + 1 <= b || b + 4 <= a);
    assert(a + 1 <= c || c + 8 <= a);
    assert(b + 4 <= c || c + 8 <= b);
    size_t held = free_count;
    assert(buddy_alloc_pages(~(size_t)0) == NULL && free_count == held);
    buddy_free_pages(b, 3);
    buddy_free_pages(a, 1);
    buddy_free_pages(c, 5);
    assert(free_count == before);
    check_lists();

    // Reserve a real, aligned arena, then temporarily isolate the allocator.
    struct Page *arena = buddy_alloc_pages(64);
    assert(arena != NULL);
    list_entry_t saved[MAX_ORDER + 1];
    for (unsigned i = 0; i <= MAX_ORDER; ++i) { saved[i] = areas[i]; }
    size_t saved_count = free_count;
    buddy_init();
    for (unsigned i = 0; i < 64; ++i) {
        arena[i].flags = 0;
        SetPageReserved(arena + i);
    }
    // Adjacent pages at PPN+1 and PPN+2 are not a buddy pair.
    buddy_init_memmap(arena + 1, 2);
    assert(buddy_alloc_pages(2) == NULL && free_count == 2);
    check_lists();

    buddy_init();
    for (unsigned i = 0; i < 64; ++i) { SetPageReserved(arena + i); }
    buddy_init_memmap(arena + 1, 31);
    static struct Page *single[31];
    for (unsigned i = 0; i < 31; ++i) {
        single[i] = buddy_alloc_pages(1);
        assert(single[i] >= arena + 1 && single[i] < arena + 32);
        for (unsigned j = 0; j < i; ++j) { assert(single[i] != single[j]); }
    }
    assert(free_count == 0 && buddy_alloc_pages(1) == NULL);
    for (unsigned i = 31; i > 0; --i) { buddy_free_pages(single[i - 1], 1); }
    assert(free_count == 31 && buddy_alloc_pages(32) == NULL);
    a = buddy_alloc_pages(16);
    assert(a == arena + 16);
    buddy_free_pages(a, 16);
    check_lists();
    for (unsigned i = 0; i <= MAX_ORDER; ++i) { areas[i] = saved[i]; }
    free_count = saved_count;
    for (unsigned i = 0; i < 64; ++i) {
        arena[i].flags = arena[i].property = 0;
        arena[i].ref = 0;
    }
    arena->flags = ALLOC_HEAD;
    arena->property = 64;
    buddy_free_pages(arena, 64);
    assert(free_count == before);
    check_lists();
    cprintf("[Buddy] rounding, splitting, merging, exhaustion, irregular range: PASS\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};

// lab2 simplified SLUB 2411156: single-core, no per-CPU caches.
#include <slub.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>

#define CACHE_COUNT 8
#define SLAB_MAGIC 0x534c55424c414232UL
struct slab {
    uintptr_t magic;
    list_entry_t link;
    void *free;
    size_t unit, used, capacity, npages;
};
#define HEADER_SIZE ROUNDUP(sizeof(struct slab), 16)
static list_entry_t partial[CACHE_COUNT];
static bool initialized;

static void init_caches(void) {
    if (!initialized) {
        for (unsigned i = 0; i < CACHE_COUNT; ++i) { list_init(&partial[i]); }
        initialized = 1;
    }
}

static unsigned cache_index(size_t size) {
    unsigned i = 0;
    while (((size_t)16 << i) < size) { ++i; }
    return i;
}

static struct slab *new_slab(size_t npages, size_t unit) {
    struct Page *p = alloc_pages(npages);
    if (p == NULL) { return NULL; }
    struct slab *s = (struct slab *)(page2pa(p) + va_pa_offset);
    s->magic = SLAB_MAGIC;
    s->free = NULL;
    s->unit = unit;
    s->used = 0;
    s->npages = npages;
    s->capacity = unit == 0 ? 1 : (PGSIZE - HEADER_SIZE) / unit;
    list_init(&s->link);
    if (unit != 0) {
        for (size_t i = s->capacity; i > 0; --i) {
            void *obj = (char *)s + HEADER_SIZE + (i - 1) * unit;
            *(void **)obj = s->free;
            s->free = obj;
        }
    }
    return s;
}

void *kmalloc(size_t size) {
    if (size == 0 || size > KMEMSIZE - HEADER_SIZE) { return NULL; }
    init_caches();
    if (size > 2048) {
        size_t npages = ROUNDUP(size + HEADER_SIZE, PGSIZE) / PGSIZE;
        struct slab *s = new_slab(npages, 0);
        if (s == NULL) { return NULL; }
        s->used = 1;
        return (char *)s + HEADER_SIZE;
    }
    unsigned index = cache_index(size);
    struct slab *s;
    if (list_empty(&partial[index])) {
        s = new_slab(1, (size_t)16 << index);
        if (s == NULL) { return NULL; }
        list_add(&partial[index], &s->link);
    } else {
        s = to_struct(list_next(&partial[index]), struct slab, link);
    }
    void *obj = s->free;
    assert(obj != NULL && s->used < s->capacity);
    s->free = *(void **)obj;
    ++s->used;
    if (s->free == NULL) { list_del_init(&s->link); }
    return obj;
}

void kfree(void *ptr) {
    if (ptr == NULL) { return; }
    struct slab *s = (struct slab *)ROUNDDOWN((uintptr_t)ptr, PGSIZE);
    assert(s->magic == SLAB_MAGIC && s->used > 0);
    if (s->unit == 0) {
        assert(ptr == (void *)((char *)s + HEADER_SIZE));
    } else {
        uintptr_t offset = (uintptr_t)ptr - (uintptr_t)s;
        assert(offset >= HEADER_SIZE);
        assert((offset - HEADER_SIZE) % s->unit == 0);
        assert((offset - HEADER_SIZE) / s->unit < s->capacity);
        for (void *p = s->free; p != NULL; p = *(void **)p) {
            assert(p != ptr); // detect double-free while the slab is live
        }
        if (s->free == NULL) {
            list_add(&partial[cache_index(s->unit)], &s->link);
        }
        *(void **)ptr = s->free;
        s->free = ptr;
    }
    if (--s->used == 0) {
        size_t npages = s->npages;
        list_del_init(&s->link);
        s->magic = 0;
        free_pages(pa2page(PADDR(s)), npages);
    }
}

static void verify_bytes(void *ptr, size_t n, unsigned char value) {
    assert(((uintptr_t)ptr & 15) == 0);
    for (size_t j = 0; j < n; ++j) { assert(((unsigned char *)ptr)[j] == value); }
}

void slub_check(void) {
    static const size_t sizes[] = {
        1, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 129,
        255, 256, 257, 511, 512, 513, 1023, 1024, 1025,
        2047, 2048, 2049, 4032, 4033, 4096, 8193
    };
    static void *objects[320];
    size_t before = nr_free_pages();
    assert(kmalloc(0) == NULL && kmalloc(~(size_t)0) == NULL);
    kfree(NULL);
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); ++i) {
        objects[i] = kmalloc(sizes[i]);
        assert(objects[i] != NULL);
        memset(objects[i], (int)(i + 1), sizes[i]);
    }
    for (size_t i = sizeof(sizes) / sizeof(sizes[0]); i > 0; --i) {
        verify_bytes(objects[i - 1], sizes[i - 1], i);
        kfree(objects[i - 1]);
    }
    assert(nr_free_pages() == before);

    // Multiple slabs of one class, preserve live objects across partial reuse.
    for (unsigned i = 0; i < 320; ++i) {
        objects[i] = kmalloc(32);
        assert(objects[i] != NULL);
        memset(objects[i], i & 255, 32);
    }
    for (unsigned i = 0; i < 320; i += 2) { kfree(objects[i]); }
    for (unsigned i = 0; i < 320; i += 2) {
        objects[i] = kmalloc(32);
        assert(objects[i] != NULL);
        memset(objects[i], i & 255, 32);
    }
    for (unsigned i = 0; i < 320; ++i) {
        verify_bytes(objects[i], 32, i & 255);
        kfree(objects[i]);
    }
    assert(nr_free_pages() == before);
    for (unsigned i = 0; i < CACHE_COUNT; ++i) { assert(list_empty(&partial[i])); }
    cprintf("[SLUB] %s: size boundaries, alignment, data, reuse, reclaim: PASS\n",
            pmm_manager->name);
}

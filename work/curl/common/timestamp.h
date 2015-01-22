/************************************************
 *       Filename: vs_timestamp.h
 *    Description: 
 *        Created:
 *         Author: dengwei
 ************************************************/
#ifndef _TIMESTAMP_H
#define _TIMESTAMP_H

int get_cpukhz(void);

#if __WORDSIZE == 64
#define rdtscll(val) \
do { \
    register unsigned long __lo, __hi; \
    asm volatile ("rdtsc" : "=a" (__lo), "=d"(__hi)); \
    (val) = (__lo) | ((__hi) << 32); \
} while (0)
#elif __WORDSIZE == 32
#define rdtscll(val) \
do { \
    register unsigned long __lo, __hi; \
    asm volatile ("rdtsc" : "=a" (__lo), "=d"(__hi)); \
    (val) = (__lo); \
} while (0)
#endif

#define get_cputick(time) rdtscll(time)

#define cputick()         \
({                        \
    unsigned long __tick; \
    rdtscll(__tick);      \
    __tick;               \
 })

unsigned long cputick2ms(unsigned long diff_track);
unsigned long cputick2ns(unsigned long diff_track);
int get_cpu_num(void);

#define CHECKTIME_DEBUG

#ifdef CHECKTIME_DEBUG
#define TS_INIT() get_cpukhz()     // alias

#define TS_DECLARE(MNAME)    \
    unsigned long MNAME##_time_begin = 0, MNAME##_time_end = 0

#define TS_BEGIN(MNAME) \
    get_cputick(MNAME##_time_begin)

#define TS_END(MNAME) \
    get_cputick(MNAME##_time_end)

#define TS_DIFF(MNAME)    \
    ((unsigned long)(MNAME##_time_end - MNAME##_time_begin))

#define TS_NSDIFF_TICK(ticks)    \
    ((unsigned long)(cputick2ns(ticks)))

#define TS_NSDIFF(MNAME)    \
    ((unsigned long)(cputick2ns(TS_DIFF(MNAME))))

#define TS_MSDIFF_TICK(ticks)    \
    ((unsigned long)(cputick2ms(ticks)))

#define TS_MSDIFF(MNAME)    \
    ((unsigned long)(cputick2ms(TS_DIFF(MNAME))))

#define TS_PRINT(MNAME)                                                                            \
do {                                                                                               \
    unsigned long MNAME##_cputicks = TS_DIFF(MNAME);                                          \
    CMLIB_DBG(TICKS, "%s time: tick(%lu)-ns(%lu)-ms(%lu)\n", #MNAME,                            \
            MNAME##_cputicks, TS_NSDIFF_TICK(MNAME##_cputicks), TS_MSDIFF_TICK(MNAME##_cputicks)); \
} while (0)

#define TS_PRINT_FILE(__stream, MNAME)                                                                            \
do {                                                                                               \
    unsigned long MNAME##_cputicks = TS_DIFF(MNAME);                                          \
    fprintf(__stream, "%s time: tick(%lu)-ns(%lu)-ms(%lu)\n", #MNAME,                            \
            MNAME##_cputicks, TS_NSDIFF_TICK(MNAME##_cputicks), TS_MSDIFF_TICK(MNAME##_cputicks)); \
} while (0)

#else

#define TS_INIT()           1
#define TS_DECLARE(MNAME)   EMPTY_STATE
#define TS_BEGIN(MNAME)     EMPTY_STATE
#define TS_END(MNAME)       EMPTY_STATE
#define TS_DIFF(MNAME)      0
#define TS_NSDIFF(MNAME)    0
#define TS_MSDIFF(MNAME)    0
#define TS_NSDIFF_TICK(ticks)    0
#define TS_MSDIFF_TICK(ticks)    0
#define TS_PRINT(MNAME)     EMPTY_STATE

#endif
#endif    // _TIMESTAMP_H


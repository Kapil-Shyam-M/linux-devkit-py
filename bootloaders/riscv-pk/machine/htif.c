#include "htif.h"
#include "atomic.h"
#include "mtrap.h"
#include "fdt.h"
#include <string.h>

extern uint64_t __htif_base;
volatile uint64_t tohost __attribute__((section(".htif")));
volatile uint64_t fromhost __attribute__((section(".htif")));
volatile int htif_console_buf;
static spinlock_t htif_lock = SPINLOCK_INIT;
uintptr_t htif;

#define TOHOST(base_int)	(uint64_t *)(base_int + TOHOST_OFFSET)
#define FROMHOST(base_int)	(uint64_t *)(base_int + FROMHOST_OFFSET)

#define TOHOST_OFFSET		((uintptr_t)tohost - (uintptr_t)__htif_base)
#define FROMHOST_OFFSET		((uintptr_t)fromhost - (uintptr_t)__htif_base)

static void __check_fromhost()
{
  uint64_t fh = fromhost;
  if (!fh)
    return;
  fromhost = 0;

  // this should be from the console
  assert(FROMHOST_DEV(fh) == 1);
  switch (FROMHOST_CMD(fh)) {
    case 0:
      htif_console_buf = 1 + (uint8_t)FROMHOST_DATA(fh);
      break;
    case 1:
      break;
    default:
      assert(0);
  }
}

static void __set_tohost(uintptr_t dev, uintptr_t cmd, uintptr_t data)
{
  while (tohost)
    __check_fromhost();
  tohost = TOHOST_CMD(dev, cmd, data);
}

int htif_console_getchar()
{
  spinlock_lock(&htif_lock);
    __check_fromhost();
    int ch = htif_console_buf;
    if (ch >= 0) {
      htif_console_buf = -1;
      __set_tohost(1, 0, 0);
    }
  spinlock_unlock(&htif_lock);

  return ch - 1;
}

static void do_tohost_fromhost(uintptr_t dev, uintptr_t cmd, uintptr_t data)
{
  spinlock_lock(&htif_lock);
    __set_tohost(dev, cmd, data);

    while (1) {
      uint64_t fh = fromhost;
      if (fh) {
        if (FROMHOST_DEV(fh) == dev && FROMHOST_CMD(fh) == cmd) {
          fromhost = 0;
          break;
        }
        __check_fromhost();
      }
    }
  spinlock_unlock(&htif_lock);
}

void htif_syscall(uintptr_t arg)
{
  do_tohost_fromhost(0, 0, arg);
}

void htif_console_putchar(uint8_t ch)
{


  /* register char a0 asm("a0") = ch; 
   asm volatile ("li t1, 0x11200" "\n\t" //The base address of UART config registers
                 "uart_status: lb t2, 40(t1)" "\n\t"
                 "andi t2, t2, 0x20" "\n\t"
                 "beqz t2, uart_status" "\n\t"
                 "sb a0, 0(t1)"  "\n\t"
                 :
                 :
                 :"x0","a0","t1","t2", "cc", "memory");
*/
  spinlock_lock(&htif_lock);
 __set_tohost(1, 1, ch);
  spinlock_unlock(&htif_lock);
/*  register char a0 asm("a0") = ch;
  asm volatile ("li t1, 0x11300" "\n\t"    //The base address of UART config registers
                "sb a0, 0(t1)"  "\n\t"
                :
                :
                :"a0","t1","cc","memory");
*/
}

void htif_poweroff()
{
  while (1) {
    fromhost = 0;
    tohost = 1;
  }
}

struct htif_scan
{
  int compat;
};

static void htif_open(const struct fdt_scan_node *node, void *extra)
{
  struct htif_scan *scan = (struct htif_scan *)extra;
  memset(scan, 0, sizeof(*scan));
}

static void htif_prop(const struct fdt_scan_prop *prop, void *extra)
{
  struct htif_scan *scan = (struct htif_scan *)extra;
  if (!strcmp(prop->name, "compatible") && !strcmp((const char*)prop->value, "ucb,htif0")) {
    scan->compat = 1;
  }
}

static void htif_done(const struct fdt_scan_node *node, void *extra)
{
  struct htif_scan *scan = (struct htif_scan *)extra;
  if (!scan->compat) return;

  htif = 1;
}

void query_htif(uintptr_t fdt)
{
  struct fdt_cb cb;
  struct htif_scan scan;

  memset(&cb, 0, sizeof(cb));
  cb.open = htif_open;
  cb.prop = htif_prop;
  cb.done = htif_done;
  cb.extra = &scan;

  fdt_scan(fdt, &cb);
/* asm  ("li t1, 0x11200" "\n\t" //The base address of UART config registers
                 "li t2, 0x83" "\n\t"    //Access divisor registers
                 "sb t2, 24(t1)" "\n\t"  //Writing to UART_ADDR_LINE_CTRL
                 "li t2, 0x0"    "\n\t"  //The upper bits of uart div
                 "sb x0, 8(t1)" "\n\t"   //Storing upper bits of uart div
                 "li t2, 0x82" "\n\t"    //The lower bits of uart div
                 "sb t2, 0(t1)" "\n\t"     
                 "li t2, 0x3" "\n\t"
                 "sb t2, 24(t1)" "\n\t"
                 "li t2, 0x6" "\n\t"
                 "sb t2, 16(t1)" "\n\t"
                 "sb x0, 8(t1)" "\n\n"
                 :
                 :
                 :"x0","t1","t2", "cc", "memory");
*/}

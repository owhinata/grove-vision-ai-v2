/**
 * @file main.c
 * @brief Simple UART Hello World for Grove Vision AI V2
 */

#include "WE2_device.h"
#include "board.h"
#include "xprintf.h"
#include "hx_drv_scu.h"
#include "hx_drv_uart.h"
#include "console_io.h"

/* UART configuration */
#define CONSOLE_UART_ID     USE_DW_UART_0
#define CONSOLE_BAUD_RATE   UART_BAUDRATE_921600

int main(void)
{
    /* Board initialization */
    board_init();

    /* Configure UART pins (PB0=RX, PB1=TX) */
    hx_drv_scu_set_PB0_pinmux(SCU_PB0_PINMUX_UART0_RX_1, 1);
    hx_drv_scu_set_PB1_pinmux(SCU_PB1_PINMUX_UART0_TX_1, 1);

    /* Initialize UART */
    hx_drv_uart_init(CONSOLE_UART_ID, HX_UART0_BASE);

    /* Setup console for xprintf */
    xprintf_setup();

    /* Print Hello World */
    xprintf("\n");
    xprintf("================================\n");
    xprintf("  Grove Vision AI V2\n");
    xprintf("  UART Hello World\n");
    xprintf("================================\n");
    xprintf("\n");

    /* Main loop */
    while (1) {
        xprintf("Hello World!\n");

        /* Simple delay */
        for (volatile int i = 0; i < 1000000; i++) {
            __NOP();
        }
    }

    return 0;
}

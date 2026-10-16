#pragma once
#include <stdbool.h>
#include <stdint.h>

// DDC/CI (VESA MCCS) over Apple Silicon's IOAVService. Calls block for ~50-100 ms.
typedef const void *DDCDisplayRef;

DDCDisplayRef ddc_open_external_display(void);
void ddc_close(DDCDisplayRef display);
bool ddc_get_vcp(DDCDisplayRef display, uint8_t code, uint16_t *current, uint16_t *maximum);
bool ddc_set_vcp(DDCDisplayRef display, uint8_t code, uint16_t value);

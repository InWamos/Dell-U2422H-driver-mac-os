#include "ddc.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <string.h>
#include <unistd.h>

// Private IOKit exports, the same ones Dell's DDPM and m1ddc use.
typedef CFTypeRef IOAVServiceRef;
extern IOAVServiceRef IOAVServiceCreateWithService(CFAllocatorRef, io_service_t);
extern IOReturn IOAVServiceReadI2C(IOAVServiceRef, uint32_t chip, uint32_t offset, void *buf, uint32_t len);
extern IOReturn IOAVServiceWriteI2C(IOAVServiceRef, uint32_t chip, uint32_t dataAddr, void *buf, uint32_t len);

enum { DDC_CHIP = 0x37, DDC_HOST = 0x51, DDC_DISPLAY = 0x6E, DDC_RETRIES = 4 };

DDCDisplayRef ddc_open_external_display(void) {
    io_iterator_t iterator;
    if (IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("DCPAVServiceProxy"), &iterator) != KERN_SUCCESS)
        return NULL;
    IOAVServiceRef found = NULL;
    io_service_t service;
    while (!found && (service = IOIteratorNext(iterator))) {
        CFStringRef location = IORegistryEntryCreateCFProperty(service, CFSTR("Location"), kCFAllocatorDefault, 0);
        if (location && CFStringCompare(location, CFSTR("External"), 0) == kCFCompareEqualTo)
            found = IOAVServiceCreateWithService(kCFAllocatorDefault, service);
        if (location) CFRelease(location);
        IOObjectRelease(service);
    }
    IOObjectRelease(iterator);
    return found;
}

void ddc_close(DDCDisplayRef display) {
    if (display) CFRelease(display);
}

static bool send_packet(DDCDisplayRef display, const uint8_t *payload, int length) {
    uint8_t packet[8];
    packet[0] = 0x80 | length;
    memcpy(packet + 1, payload, length);
    uint8_t checksum = DDC_DISPLAY ^ DDC_HOST;
    for (int i = 0; i <= length; i++) checksum ^= packet[i];
    packet[length + 1] = checksum;
    // The first write after idle is sometimes dropped; every command here is idempotent.
    bool sent = false;
    for (int i = 0; i < 2; i++) sent |= IOAVServiceWriteI2C(display, DDC_CHIP, DDC_HOST, packet, length + 2) == kIOReturnSuccess;
    return sent;
}

bool ddc_get_vcp(DDCDisplayRef display, uint8_t code, uint16_t *current, uint16_t *maximum) {
    const uint8_t request[] = {0x01, code};
    uint8_t reply[11];
    for (int attempt = 0; attempt < DDC_RETRIES; attempt++) {
        send_packet(display, request, sizeof request);
        usleep(50000);
        memset(reply, 0, sizeof reply);
        if (IOAVServiceReadI2C(display, DDC_CHIP, DDC_HOST, reply, sizeof reply) != kIOReturnSuccess) continue;
        if (reply[2] != 0x02 || reply[4] != code) continue;
        if (reply[3] != 0) return false;
        *maximum = (reply[6] << 8) | reply[7];
        *current = (reply[8] << 8) | reply[9];
        return true;
    }
    return false;
}

bool ddc_set_vcp(DDCDisplayRef display, uint8_t code, uint16_t value) {
    const uint8_t request[] = {0x03, code, value >> 8, value & 0xFF};
    bool sent = send_packet(display, request, sizeof request);
    usleep(50000);
    return sent;
}

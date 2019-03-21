#pragma once

#ifdef __cplusplus
extern "C"
{
#endif
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "freertos/semphr.h"
#include "freertos/event_groups.h"
#include "esp_log.h"
#include "mbedtls/aes.h"

#define E2EE_BIT BIT1

    EventGroupHandle_t e2ee_event_group;

    mbedtls_aes_context aes_ctx;
    void
    endToEndEnc();

    void
    AESEncrypt();

    void
    AESDecrypt();

#ifdef __cplusplus
}
#endif

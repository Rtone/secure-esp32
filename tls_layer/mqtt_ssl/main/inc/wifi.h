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

#define CONNECTED_BIT BIT0

    EventGroupHandle_t wifi_event_group;

    void
    register_wifi();

    TaskHandle_t wifiHandle;

    void
    initialiseWifiTask();

#ifdef __cplusplus
}
#endif

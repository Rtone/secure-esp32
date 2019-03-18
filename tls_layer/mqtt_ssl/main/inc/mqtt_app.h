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

    TaskHandle_t MqttHandle;

    void
    mqtt_app_start();

#ifdef __cplusplus
}
#endif

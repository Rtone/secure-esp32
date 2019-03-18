#pragma once
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "freertos/semphr.h"
#include "freertos/event_groups.h"
#ifdef __cplusplus
extern "C"
{
#endif

    esp_err_t taskWifi(void);
    esp_err_t taskHttpsRequests(void);

#ifdef __cplusplus
}
#endif

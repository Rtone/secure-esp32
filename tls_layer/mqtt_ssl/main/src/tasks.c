#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "freertos/semphr.h"
#include "freertos/event_groups.h"
#include "esp_log.h"
#include "wifi.h"
#include "mqtt_app.h"

esp_err_t taskWifi(void)
{
    BaseType_t retTaskWifi;
    wifiHandle = NULL;

    retTaskWifi = xTaskCreate(initialiseWifiTask,
                              "Init_Module_WIFI",
                              8192,
                              NULL,
                              5,
                              &wifiHandle);

    configASSERT(wifiHandle);

    if (retTaskWifi == pdPASS)
    {
        ESP_LOGI("Task", "Module Wifi create");
        // vTaskDelete(wifiHandle);
        return ESP_OK;
    }
    else
    {
        ESP_LOGI("Task", "Module Wifi failed");
        return ESP_FAIL;
    }
}

esp_err_t mqttTaskStart(void)
{
    BaseType_t retTaskMqttClient;
    MqttHandle = NULL;

    retTaskMqttClient = xTaskCreate(mqtt_app_start,
                                    "Mqtt_client_task",
                                    8192,
                                    NULL,
                                    5,
                                    &MqttHandle);

    configASSERT(MqttHandle);

    if (retTaskMqttClient == pdPASS)
    {
        ESP_LOGI("Task", "Https Req task created");
        // vTaskDelete(wifiHandle);
        return ESP_OK;
    }
    else
    {
        ESP_LOGI("Task", "Https Req task failed");
        return ESP_FAIL;
    }
}
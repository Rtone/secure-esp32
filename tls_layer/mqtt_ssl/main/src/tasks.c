#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "freertos/semphr.h"
#include "freertos/event_groups.h"
#include "esp_log.h"
#include "wifi.h"
#include "e2ee.h"
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
        ESP_LOGI("Task", "Mqtt app task created");
        // vTaskDelete(wifiHandle);
        return ESP_OK;
    }
    else
    {
        ESP_LOGI("Task", "Mqtt app task failed");
        return ESP_FAIL;
    }
}

esp_err_t taskEndToEndEnc(void)
{
    BaseType_t retTaskEndToEndEnc;
    // wifiHandle = NULL;

    retTaskEndToEndEnc = xTaskCreate(endToEndEnc,
                                     "End_to_End_Encryption",
                                     8192,
                                     NULL,
                                     5,
                                     NULL);

    if (retTaskEndToEndEnc == pdPASS)
    {
        ESP_LOGI("Task", "End2End Enc task created");
        // vTaskDelete(wifiHandle);
        return ESP_OK;
    }
    else
    {
        ESP_LOGI("Task", "End2End Enc task failed");
        return ESP_FAIL;
    }
}
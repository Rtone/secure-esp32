#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include "esp_wifi.h"
#include "esp_system.h"
#include "nvs_flash.h"
#include "esp_event_loop.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include "freertos/queue.h"
#include "freertos/event_groups.h"

#include "lwip/sockets.h"
#include "lwip/dns.h"
#include "lwip/netdb.h"

#include "esp_log.h"
#include "mqtt_client.h"
#include "mbedtls/aes.h"

#include "wifi.h"
#include "e2ee.h"
#include "mqtt_app.h"

static const char *TAG = "MQTTS_APP_TASK";

#if CONFIG_BROKER_CERTIFICATE_OVERRIDDEN == 1
static const uint8_t ca_cert_pem_start[] = "-----BEGIN CERTIFICATE-----\n" CONFIG_BROKER_CERTIFICATE_OVERRIDE "\n-----END CERTIFICATE-----";
#else
extern const uint8_t ca_cert_pem_start[] asm("_binary_ca_cert_pem_start");
#endif
extern const uint8_t ca_cert_pem_end[] asm("_binary_ca_cert_pem_end");

static void _MqttPublish(esp_mqtt_client_handle_t client)
{
    char buffer[1024];
    static int msg_id;
    memset(buffer, 0, 1024);
    char msgID1[] = "FOR";
    char msgID2[] = "FORBETTER";
    char msgID3[] = "FORBETTERSECURITY";
    char msgID4[] = "FORBETTERSECURITYIMPLEMENTATION";

    char msgID5[] = "WITHLOVERIDAIDIL";
    char msgID6[] = "(AKA.) RIDILX";

    printf("La taille du message sizeof %d\n", sizeof(msgID1));

    AESEncrypt(msgID1, sizeof(msgID1), buffer);
    msg_id = esp_mqtt_client_publish(client, "/topic/qos0", buffer, ((sizeof(msgID1) / 16) + 1) * 16, 0, 0);
    ESP_LOGI(TAG, "sent publish successful, msg_id=%d", msg_id);

    AESEncrypt(msgID2, sizeof(msgID2), buffer);
    msg_id = esp_mqtt_client_publish(client, "/topic/qos0", buffer, ((sizeof(msgID2) / 16) + 1) * 16, 0, 0);
    ESP_LOGI(TAG, "sent publish successful, msg_id=%d", msg_id);

    AESEncrypt(msgID3, sizeof(msgID3), buffer);
    msg_id = esp_mqtt_client_publish(client, "/topic/qos0", buffer, ((sizeof(msgID3) / 16) + 1) * 16, 0, 0);
    ESP_LOGI(TAG, "sent publish successful, msg_id=%d", msg_id);

    AESEncrypt(msgID4, sizeof(msgID4), buffer);
    msg_id = esp_mqtt_client_publish(client, "/topic/qos0", buffer, ((sizeof(msgID4) / 16) + 1) * 16, 0, 0);
    ESP_LOGI(TAG, "sent publish successful, msg_id=%d", msg_id);

    AESEncrypt(msgID5, sizeof(msgID5), buffer);
    msg_id = esp_mqtt_client_publish(client, "/topic/qos0", buffer, ((sizeof(msgID5) / 16) + 1) * 16, 0, 0);
    ESP_LOGI(TAG, "sent publish successful, msg_id=%d", msg_id);

    AESEncrypt(msgID6, sizeof(msgID6), buffer);
    msg_id = esp_mqtt_client_publish(client, "/topic/qos0", buffer, ((sizeof(msgID6) / 16) + 1) * 16, 0, 0);
    ESP_LOGI(TAG, "sent publish successful, msg_id=%d", msg_id);
}

static esp_err_t mqtt_event_handler(esp_mqtt_event_handle_t event)
{
    esp_mqtt_client_handle_t client = event->client;
    int msg_id;

    // your_context_t *context = event->context;
    configASSERT(MqttHandle != NULL);

    switch (event->event_id)
    {
    case MQTT_EVENT_CONNECTED:
        ESP_LOGI(TAG, "MQTT_EVENT_CONNECTED");

        msg_id = esp_mqtt_client_subscribe(client, "/topic/qos0", 0);
        ESP_LOGI(TAG, "sent subscribe successful, msg_id=%d", msg_id);

        msg_id = esp_mqtt_client_subscribe(client, "/topic/qos1", 1);
        ESP_LOGI(TAG, "sent subscribe successful, msg_id=%d", msg_id);

        // msg_id = esp_mqtt_client_unsubscribe(client, "/topic/qos1");
        // ESP_LOGI(TAG, "sent unsubscribe successful, msg_id=%d", msg_id);
        break;

    case MQTT_EVENT_DISCONNECTED:
        ESP_LOGI(TAG, "MQTT_EVENT_DISCONNECTED");
        break;

    case MQTT_EVENT_SUBSCRIBED:
        ESP_LOGI(TAG, "MQTT_EVENT_SUBSCRIBED, msg_id=%d", event->msg_id);
        _MqttPublish(client);
        break;

    case MQTT_EVENT_UNSUBSCRIBED:
        ESP_LOGI(TAG, "MQTT_EVENT_UNSUBSCRIBED, msg_id=%d", event->msg_id);
        break;

    case MQTT_EVENT_PUBLISHED:
        ESP_LOGI(TAG, "MQTT_EVENT_PUBLISHED, msg_id=%d", event->msg_id);
        break;

    case MQTT_EVENT_DATA:
        ESP_LOGI(TAG, "MQTT_EVENT_DATA");
        printf("TOPIC=%.*s\r\n", event->topic_len, event->topic);
        printf("DATA=\e[31m%.*s\e[0m\r\n", event->data_len, event->data);
        AESDecrypt(event->data, event->data_len);
        break;

    case MQTT_EVENT_ERROR:
        ESP_LOGI(TAG, "MQTT_EVENT_ERROR");
        break;

    default:
        ESP_LOGI(TAG, "Other event id:%d", event->event_id);
        break;
    }
    return ESP_OK;
}

void mqtt_app_start(void)
{
    const esp_mqtt_client_config_t mqtt_cfg = {
        .uri = BROKER_URI,
        .username = BROKER_USERNAME,
        .password = BROKER_PASSWORD,
        .event_handle = mqtt_event_handler,
        .cert_pem = (const char *)ca_cert_pem_start,
    };

    ESP_LOGI(TAG, "[APP] Free memory: %d bytes", esp_get_free_heap_size());

    xEventGroupWaitBits(wifi_event_group, CONNECTED_BIT,
                        false, true, portMAX_DELAY);

    xEventGroupWaitBits(e2ee_event_group, E2EE_BIT,
                        false, true, portMAX_DELAY);

    esp_mqtt_client_handle_t client = esp_mqtt_client_init(&mqtt_cfg);
    esp_mqtt_client_start(client);
    while (1)
    {
        vTaskDelay(1000 / portTICK_RATE_MS);
    }
}

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include "freertos/queue.h"
#include "freertos/event_groups.h"

#include "e2ee.h"

static void _initAES128()
{
    mbedtls_aes_init(&aes_ctx);
    static const unsigned char key[16] = {
        0xAE, 0x68, 0x52, 0xF8, 0x12, 0x10, 0x67, 0xCC,
        0x4B, 0xF7, 0xA5, 0x76, 0x55, 0x77, 0xF3, 0xF3};

    mbedtls_aes_init(&aes_ctx);
    // memset(key, 0, 16);
    // memcpy(key, "f75b2a4dfdca8e32b309f891f2081d6d", 16);

    mbedtls_aes_setkey_enc(&aes_ctx, key, 128);
    mbedtls_aes_setkey_dec(&aes_ctx, key, 128);
}

static void _initAES256()
{
    mbedtls_aes_init(&aes_ctx);
    static const unsigned char key[32] = {
        0x2B, 0x7E, 0x15, 0x16, 0x28, 0xAE, 0xD2, 0xA6,
        0xAB, 0xF7, 0x15, 0x88, 0x09, 0xCF, 0x4F, 0x3C,
        0x8E, 0x73, 0xB0, 0xF7, 0xDA, 0x0E, 0x64, 0x52,
        0xC8, 0x10, 0xF3, 0x2B, 0x80, 0x90, 0x79, 0xE5};

    mbedtls_aes_init(&aes_ctx);
    // memset(key, 0, 32);
    // memcpy(key, "f75b2a4dfdca8e32b309f891f2081d6d", 32);

    mbedtls_aes_setkey_enc(&aes_ctx, key, 256);
    mbedtls_aes_setkey_dec(&aes_ctx, key, 256);
}

void AESEncrypt(uint8_t *input_data, uint32_t input_length, char buffer[32])
{
    unsigned char input[16];
    unsigned char output[16];
    char cipher_text[input_length];

    memset(cipher_text, 0, 32);
    memset(output, 0, 16);
    memset(buffer, 0, 32);

    if (input_length <= 16)
    {
        memset(input, 0, 16);
        memcpy(input, input_data, 16);

        mbedtls_aes_crypt_ecb(&aes_ctx, MBEDTLS_AES_ENCRYPT, input, output);
        printf("EncryptedDATA=%.*s\r\n", 16, output);

        for (int i = 0; i < 16; i++)
        {
            cipher_text[i] = output[i];
            buffer[i] = cipher_text[i];
        }
    }
    else
    {
        for (int offset = 0; offset < input_length; offset += 16)
        {
            for (int i = 0; i < 16; i++)
            {
                if ((offset + i) < input_length)
                {
                    input[i] = input_data[i + offset];
                }
                else
                {
                    input[i] = 0x0b;
                }
            }
            mbedtls_aes_crypt_ecb(&aes_ctx, MBEDTLS_AES_ENCRYPT, input, output);
            printf("EncryptedDATA=%.*s\r\n", 16, output);

            for (int j = 0; j < 16; j++)
            {
                // if ((offset + j) < input_length)
                // {
                cipher_text[j + offset] = output[j];
                buffer[j + offset] = output[j];
                // }
            }
        }
        printf("All Cipher Text %.*s\r\n", input_length, cipher_text);
        AESDecrypt(cipher_text, 32);
    }
}

void AESDecrypt(uint8_t *input_data, uint32_t input_length)
{
    unsigned char input[16];
    unsigned char output[16];
    unsigned char plain_text[input_length];

    if (input_length <= 16)
    {
        memset(input, 0, 16);
        memcpy(input, input_data, 16);

        mbedtls_aes_crypt_ecb(&aes_ctx, MBEDTLS_AES_DECRYPT, input, output);
        printf("DecryptedDATA=%.*s\r\n", 16, output);

        for (int i = 0; i < 16; i++)
        {
            plain_text[i] = output[i];
        }
    }
    else
    {
        for (int offset = 0; offset < input_length; offset += 16)
        {
            for (int i = 0; i < 16; i++)
            {
                if ((offset + i) < input_length)
                {
                    input[i] = input_data[i + offset];
                }
                else
                {
                    input[i] = 0x0b;
                }
            }

            mbedtls_aes_crypt_ecb(&aes_ctx, MBEDTLS_AES_DECRYPT, input, output);
            printf("DecryptedDATA=%.*s\r\n", 16, output);

            for (int j = 0; j < 16; j++)
            {
                if ((offset + j) < input_length)
                {
                    plain_text[j + offset] = output[j];
                }
            }
        }

        printf("All Plain text %.*s\n", input_length, plain_text);
    }
}

void endToEndEnc(void)
{
    /*********************************************************************
     * AES Task
    *********************************************************************/

    _initAES256();

    e2ee_event_group = xEventGroupCreate();
    xEventGroupSetBits(e2ee_event_group, E2EE_BIT);
    while (1)
    {
        vTaskDelay(1000 / portTICK_RATE_MS);
    }
}

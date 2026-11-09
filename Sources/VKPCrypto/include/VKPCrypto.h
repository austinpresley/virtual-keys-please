#ifndef VKP_CRYPTO_H
#define VKP_CRYPTO_H
#include <stddef.h>
#include <stdint.h>
int vkp_aes_cbc(int encrypt, const uint8_t *key, const uint8_t *iv,
                const uint8_t *input, size_t input_length,
                uint8_t *output, size_t output_capacity, size_t *output_length);
#endif

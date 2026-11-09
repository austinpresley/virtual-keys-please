#include "VKPCrypto.h"
#include <CommonCrypto/CommonCryptor.h>

int vkp_aes_cbc(int encrypt, const uint8_t *key, const uint8_t *iv,
                const uint8_t *input, size_t input_length,
                uint8_t *output, size_t output_capacity, size_t *output_length) {
    return CCCrypt(encrypt ? kCCEncrypt : kCCDecrypt, kCCAlgorithmAES, 0,
                   key, kCCKeySizeAES256, iv, input, input_length,
                   output, output_capacity, output_length);
}

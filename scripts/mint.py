import binascii
import random

import sha3

masks = [2**250-1]
challenge_number_hex = '755cb93585b067b0af76ca7c4e0769436b02d66ab66fa3a38cbfdf403bda49c9'

def mine():
    challenge_number = binascii.unhexlify(challenge_number_hex)

    while True:
        nonce = random.getrandbits(256)
        raw = challenge_number + nonce.to_bytes(32, 'big')

        hash_value = sha3.keccak_256(raw)
        digest_number = int.from_bytes(hash_value.digest(), 'big')

        for m in masks:
            if m | digest_number == m:
                return nonce, hash_value.hexdigest()

if __name__ == '__main__':
    print(mine())

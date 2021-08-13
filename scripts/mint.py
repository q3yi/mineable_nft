import binascii
import random

import sha3

from collections import namedtuple

Mask = namedtuple("Mask", "id pattern challenge_number")

masks = [
    Mask(1, 2**240-1, "5687febf410591227276fb47b859d185cc30cbfd06811a2cd9cfd17d041af1af")
]

def mine():

    while True:
        nonce = random.getrandbits(256)

        for m in masks:
            challenge_number = binascii.unhexlify(m.challenge_number)
            raw = challenge_number + nonce.to_bytes(32, 'big')

            hash_value = sha3.keccak_256(raw)
            digest_number = int.from_bytes(hash_value.digest(), 'big')

            if m.pattern | digest_number == m.pattern:
                return m.id, nonce, hash_value.hexdigest()

if __name__ == '__main__':
    print(mine())

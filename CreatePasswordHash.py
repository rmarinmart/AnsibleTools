#!/usr/bin/env python3
from passlib.hash import sha512_crypt #sudo apt install python3-passlib
import getpass
import sys

def generar_hash(password: str) -> str:
    # rounds define el coste computacional (por defecto 29000, puedes ajustarlo)
    return sha512_crypt.hash(password, rounds=5000)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Si la contraseña se pasa como argumento
        password = sys.argv[1]
    else:
        # Si no, la pedimos de forma segura
        password = getpass.getpass("Introduce la contraseña: ")

    print(generar_hash(password))

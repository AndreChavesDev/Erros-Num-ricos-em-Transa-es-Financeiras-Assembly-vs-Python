"""
python_float.py
Simula N transacoes de R$ 0.10 usando float nativo do Python.
Demonstra que o erro IEEE 754 existe em alto nivel tambem,
mas fica escondido pela abstracao da linguagem.
"""

N = 1_000_000
valor_transacao = 0.1   # float nativo = IEEE 754 double (mesmo que Assembly)

print("=== PYTHON FLOAT (ponto flutuante IEEE 754) ===")
print(f"Transacoes     : {N:,}")
print(f"Valor esperado : R$ {N * 0.1:,.2f}")

# Simula exatamente o mesmo loop do Assembly
total = 0.0
for _ in range(N):
    total += valor_transacao

print(f"Resultado real : R$ {total:,.10f}")
print(f"Resultado visto: R$ {total:,.2f}  <- Python ARREDONDA na exibicao!")
print(f"Diferenca      : {total - (N * 0.1):.20f}")
print()

# Mostra a raiz do problema
print("--- Por que 0.1 nao existe em binario? ---")
import struct
bits = struct.pack('d', 0.1)
hex_repr = bits[::-1].hex()
print(f"0.1 em hex (IEEE 754): {hex_repr}")
print(f"0.1 real armazenado  : {0.1:.55f}")
print(f"0.1 que queremos     : 0.1000000000000000000000000000000000000000000000000000000")
print()
print("ERRO: Python float e Assembly float erram do mesmo jeito.")
print("A diferenca: Python esconde o erro ao exibir; Assembly expoe os bits.")
print()

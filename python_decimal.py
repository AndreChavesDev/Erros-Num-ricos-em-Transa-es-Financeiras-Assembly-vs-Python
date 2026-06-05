"""
python_decimal.py
Simula N transacoes de R$ 0.10 usando o tipo Decimal do Python.
Esta e a abordagem correta para sistemas financeiros em alto nivel.
Equivalente ao inteiro escalado do Assembly em termos de precisao.
"""

from decimal import Decimal, getcontext

getcontext().prec = 28              # precisao de 28 digitos significativos

N = 1_000_000
valor_transacao = Decimal("0.1")   # string -> Decimal exato, NAO float!

print("=== PYTHON DECIMAL (precisao arbitraria) ===")
print(f"Transacoes     : {N:,}")
print(f"Valor esperado : R$ 100000.00")

# Simula o mesmo loop
total = Decimal("0")
for _ in range(N):
    total += valor_transacao

print(f"Resultado real : R$ {total:,.2f}")
print(f"Diferenca      : {total - Decimal('100000.00')}")
print()
print("SEM ERRO: Decimal usa representacao de base 10, nao binario.")
print("Equivalente em filosofia ao inteiro escalado do Assembly.")
print()

# Mostra a diferenca entre Decimal("0.1") e float(0.1)
print("--- Comparacao de representacoes ---")
print(f"float(0.1)         : {float(0.1):.55f}")
print(f"Decimal('0.1')     : {Decimal('0.1')}")
print(f"Decimal(0.1)       : {Decimal(0.1)}")  # ERRADO! passa float antes
print()
print("ATENCAO: Decimal(0.1) ainda erra! O float contamina antes de virar Decimal.")
print("Sempre use Decimal('0.1') com string para garantir precisao.")
print()

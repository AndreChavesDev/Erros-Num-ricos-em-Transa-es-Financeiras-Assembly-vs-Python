#!/bin/bash
# ============================================================
# compilar.sh
# Compila os programas Assembly, executa todos os experimentos
# e salva os resultados em resultados.txt
#
# Uso:
#   chmod +x compilar.sh
#   ./compilar.sh
# ============================================================

set -e

echo ""
echo "=============================================="
echo "  Erros Numericos: Assembly vs Python"
echo "=============================================="
echo ""

# ----------------------------------------------------------
# Verificar dependencias
# ----------------------------------------------------------
echo "[1/6] Verificando dependencias..."

if ! command -v nasm &> /dev/null; then
    echo "ERRO: nasm nao encontrado. Instale com: sudo apt install nasm"
    exit 1
fi

if ! command -v ld &> /dev/null; then
    echo "ERRO: ld nao encontrado. Instale com: sudo apt install binutils"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "ERRO: python3 nao encontrado. Instale com: sudo apt install python3"
    exit 1
fi

echo "    OK: nasm, ld, python3 disponiveis."
echo ""

# ----------------------------------------------------------
# Compilar Assembly
# ----------------------------------------------------------
echo "[2/6] Compilando asm_float.asm..."
nasm -f elf64 asm_float.asm -o asm_float.o
ld asm_float.o -o asm_float
echo "    OK: asm_float compilado."

echo "[3/6] Compilando asm_inteiro.asm..."
nasm -f elf64 asm_inteiro.asm -o asm_inteiro.o
ld asm_inteiro.o -o asm_inteiro
echo "    OK: asm_inteiro compilado."

echo "[4/6] Compilando comparacao.asm..."
nasm -f elf64 comparacao.asm -o comparacao.o
ld comparacao.o -o comparacao
echo "    OK: comparacao compilado."
echo ""

# ----------------------------------------------------------
# Executar todos e salvar resultados
# ----------------------------------------------------------
echo "[5/6] Executando experimentos..."
echo ""

OUTPUT="resultados.txt"

{
echo "============================================================"
echo "  ERROS NUMERICOS EM TRANSACOES FINANCEIRAS"
echo "  Assembly vs Python - Comparacao Didatica"
echo "  Cenario: 1.000.000 transacoes de R\$ 0,10"
echo "  Resultado esperado: R\$ 100.000,00"
echo "============================================================"
echo ""

echo "------------------------------------------------------------"
echo "  EXPERIMENTO 1: ASM FLOAT (erro isolado)"
echo "------------------------------------------------------------"
./asm_float

echo "------------------------------------------------------------"
echo "  EXPERIMENTO 2: ASM INTEIRO ESCALADO (solucao isolada)"
echo "------------------------------------------------------------"
./asm_inteiro

echo "------------------------------------------------------------"
echo "  EXPERIMENTO 3: PYTHON FLOAT (erro em alto nivel)"
echo "------------------------------------------------------------"
python3 python_float.py

echo "------------------------------------------------------------"
echo "  EXPERIMENTO 4: PYTHON DECIMAL (solucao em alto nivel)"
echo "------------------------------------------------------------"
python3 python_decimal.py

echo "------------------------------------------------------------"
echo "  EXPERIMENTO 5: COMPARACAO.ASM (deteccao e correcao)"
echo "------------------------------------------------------------"
./comparacao

echo ""
echo "============================================================"
echo "  RESUMO FINAL"
echo "============================================================"
echo ""
echo "| Implementacao    | Resultado       | Correto? |"
echo "|------------------|-----------------|----------|"
echo "| ASM float        | diverge         | NAO      |"
echo "| ASM inteiro      | R\$ 100000.00   | SIM      |"
echo "| Python float     | diverge         | NAO      |"
echo "| Python Decimal   | R\$ 100000.00   | SIM      |"
echo "| comparacao.asm   | detecta+corrige | SIM      |"
echo ""
echo "O erro nao e da linguagem: e do padrao IEEE 754."
echo "A solucao (inteiro escalado / Decimal) funciona em ambas."
echo "Em Assembly, voce ve ONDE e POR QUE o erro ocorre nos bits."
echo "Em Python, o erro existe mas fica escondido pela abstracao."
echo "============================================================"

} | tee "$OUTPUT"

echo ""
echo "[6/6] Resultados salvos em: $OUTPUT"
echo ""

# ----------------------------------------------------------
# Limpar arquivos objeto intermediarios
# ----------------------------------------------------------
rm -f asm_float.o asm_inteiro.o comparacao.o
echo "Arquivos .o intermediarios removidos."
echo ""
echo "Executaveis gerados: ./asm_float  ./asm_inteiro  ./comparacao"
echo "Para rodar individualmente:"
echo "  ./asm_float"
echo "  ./asm_inteiro"
echo "  ./comparacao"
echo "  python3 python_float.py"
echo "  python3 python_decimal.py"
echo ""

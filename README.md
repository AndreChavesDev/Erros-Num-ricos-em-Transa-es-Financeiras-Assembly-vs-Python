# Erros Numéricos em Transações Financeiras
### Assembly vs Python — Uma Comparação Didática

---

## A Ideia

Todo sistema financeiro que processa transações em larga escala enfrenta um problema silencioso: **o número `0.1` não existe em binário**.

Assim como `1/3` não tem representação exata em decimal (0.333...), o valor `0.1` não pode ser representado com exatidão no padrão IEEE 754 — que é o padrão de ponto flutuante usado por praticamente todo hardware e linguagem de programação moderno.

O valor real armazenado quando você escreve `0.1` é:

```
0.1000000000000000055511151231257827021181583404541015625
```

Esse erro é pequeno. Mas em um sistema que processa **1 milhão de transações de R$ 0,10**, o acúmulo desse erro pode fazer centavos aparecerem ou desaparecerem — dinheiro real, em produção.

Este projeto demonstra esse fenômeno em cinco experimentos:

1. **`asm_float.asm`** — Assembly com ponto flutuante: o erro exposto nos bits do registrador XMM, sem nenhuma abstração no caminho.
2. **`asm_inteiro.asm`** — Assembly com inteiro escalado: a solução correta em baixo nível.
3. **`python_float.py`** — Python com `float`: o mesmo erro existe, mas fica escondido pelo arredondamento automático na exibição.
4. **`python_decimal.py`** — Python com `Decimal`: a solução correta em alto nível.
5. **`comparacao.asm`** — O arquivo central do projeto: detecta o erro em tempo de execução, identifica a causa, aplica a correção com inteiro escalado e confirma o resultado — tudo dentro do mesmo fluxo.

O ponto central da comparação: **o erro não é da linguagem, é do padrão IEEE 754**. Assembly e Python erram da mesma forma. A diferença é que em Assembly você consegue ver exatamente onde e por que o erro ocorre — e a solução (inteiro escalado) também fica mais explícita.

---

## Casos Reais

Este não é um problema acadêmico. Alguns exemplos históricos:

- **Vancouver Stock Exchange (1982):** o índice da bolsa era recalculado 3.000 vezes por dia com truncamento de ponto flutuante. Em 22 meses, o índice marcava 524 — quando deveria estar em 1.098.
- **Patriot Missile (1991):** acúmulo de erro em ponto flutuante em contagem de tempo causou falha no rastreamento de um míssil. 28 soldados mortos.
- **Sistemas bancários modernos:** bancos sérios proíbem `float` para valores monetários. Usam `DECIMAL` em SQL, `BigDecimal` em Java, `decimal` em Python — ou armazenam tudo em centavos como inteiro.

---

## Estrutura do Projeto

```
projeto_erros_numericos/
│
├── asm_float.asm        # Assembly: soma 1M x R$0,10 com float (IEEE 754) — expõe o erro
├── asm_inteiro.asm      # Assembly: soma 1M x R$0,10 com inteiro escalado — solução
├── python_float.py      # Python: mesmo erro em alto nível
├── python_decimal.py    # Python: solução correta com Decimal
│
├── comparacao.asm       # Fluxo completo: detecta o erro e aplica a correção
│
├── compilar.sh          # Compila e executa tudo com um comando
├── resultados.txt       # Gerado automaticamente ao rodar compilar.sh
├── .gitignore
└── README.md
```

---

## O Arquivo Principal: `comparacao.asm`

Este é o coração do projeto. Ao contrário dos outros arquivos que isolam um único experimento, o `comparacao.asm` executa o fluxo completo que um sistema real precisaria implementar:

```
[ ETAPA 1 ] Calcula 1.000.000 x R$0,10 com ponto flutuante (IEEE 754)
[ ETAPA 2 ] Compara o resultado com o valor esperado e detecta a divergência
[ ETAPA 3 ] Explica a causa: 0.1 = 0x3FB999999999999A — inexato em binário
[ ETAPA 4 ] Reexecuta o cálculo com inteiro escalado (10 centavos por transação)
[ ETAPA 5 ] Confirma que o resultado agora é exato
```

Em Assembly você controla cada etapa desse processo em nível de hardware — comparações com flags de CPU, aritmética de inteiros sem intermediários, e acesso direto aos bits do registrador XMM.

---

## Pré-requisitos

Este projeto roda no **Linux x86-64**. Se você usa **Windows**, o caminho recomendado é via WSL2:

```powershell
# No PowerShell como administrador
wsl --install
```

Após instalar o WSL2 (Ubuntu), abra o terminal Ubuntu e instale as dependências:

```bash
sudo apt update
sudo apt install nasm binutils python3
```

---

## Como Executar

**1. Clone o repositório**

```bash
git clone https://github.com/seu-usuario/projeto_erros_numericos.git
cd projeto_erros_numericos
```

**2. Dê permissão de execução ao script**

```bash
chmod +x compilar.sh
```

**3. Compile e execute tudo**

```bash
./compilar.sh
```

O script vai:
- Verificar se `nasm`, `ld` e `python3` estão instalados
- Compilar os três programas Assembly (`asm_float`, `asm_inteiro`, `comparacao`)
- Executar os cinco experimentos em sequência
- Salvar todos os resultados em `resultados.txt`
- Remover os arquivos `.o` intermediários

**4. Para executar individualmente**

```bash
./asm_float                  # Assembly com float (erro)
./asm_inteiro                # Assembly com inteiro escalado (solução)
./comparacao                 # Detecção e correção no mesmo fluxo
python3 python_float.py      # Python com float (erro)
python3 python_decimal.py    # Python com Decimal (solução)
```

---

## Resultados Esperados

```
============================================================
  DETECCAO E CORRECAO DE ERRO NUMERICO
  Cenario: 1.000.000 transacoes de R$ 0,10
  Valor esperado: R$ 100.000,00
============================================================

[ ETAPA 1 ] Calculando com ponto flutuante (IEEE 754)...
  Resultado obtido : R$ 100000.000001
  Valor esperado   : R$ 100000.00

[ ETAPA 2 ] Verificando divergencia...
  Delta (diferenca): R$ 0.000001
  STATUS: ERRO DETECTADO - resultado diverge do esperado!

[ ETAPA 3 ] Causa do erro:
  0.1 em IEEE 754 = 0x3FB999999999999A
  Valor real armazenado: 0.1000000000000000055511...
  A cada soma, o excesso de ~5.5e-18 se acumula.
  Em 1.000.000 operacoes, o erro acumulado se torna visivel.

[ ETAPA 4 ] Aplicando correcao: inteiro escalado...
  Estrategia: representar R$ 0,10 como 10 centavos (inteiro).
  Inteiros sao exatos em binario. Sem ponto flutuante no calculo.
  Resultado obtido : R$ 100000.00

[ ETAPA 5 ] Confirmacao:
  STATUS: CORRIGIDO - resultado exato apos aplicar inteiro escalado.
```

### Tabela resumo

| Implementação     | Resultado         | Correto? | Por quê                                    |
|-------------------|-------------------|----------|--------------------------------------------|
| ASM float         | diverge           | ❌        | IEEE 754 — 0.1 inexato em binário          |
| ASM inteiro       | R$ 100.000,00     | ✅        | Inteiros são exatos; sem ponto flutuante   |
| Python float      | diverge (oculto)  | ❌        | Mesmo IEEE 754; Python arredonda exibição  |
| Python Decimal    | R$ 100.000,00     | ✅        | Base 10 interna; sem representação binária |
| comparacao.asm    | detecta + corrige | ✅        | Fluxo completo em Assembly                 |

---

## O Que Cada Arquivo Ensina

**`asm_float.asm`**
Mostra os bits exatos do valor `0.1` no registrador XMM. O loop de soma acumula o erro progressivamente. A flag de overflow não acende porque não há overflow — o erro é de *representação*, não de magnitude.

**`asm_inteiro.asm`**
Demonstra a solução usada em sistemas críticos: trabalhar com centavos como inteiro (`10`) e dividir por `100` apenas na hora de exibir. Nenhum ponto flutuante entra no cálculo.

**`comparacao.asm`**
O arquivo central do projeto. Executa o cálculo com float, compara com o valor esperado usando `ucomisd` (instrução SSE2 de comparação de doubles), detecta a divergência, explica a causa e reexecuta com inteiro escalado. Usa `cmp` para confirmar que o resultado inteiro bate exatamente com o esperado.

**`python_float.py`**
Mostra que Python sofre do mesmo problema. A diferença: Python arredonda automaticamente ao usar `{:.2f}`, dando a ilusão de resultado correto. O erro real só aparece com mais casas decimais.

**`python_decimal.py`**
Demonstra a solução correta em alto nível. Também alerta sobre a armadilha de `Decimal(0.1)` (passa float antes, contamina o resultado) versus `Decimal("0.1")` (string, correto).

---

## Conceitos Abordados

- Representação IEEE 754 de ponto flutuante
- Registradores XMM e instruções SSE2 (`movsd`, `addsd`, `ucomisd`, `cvttsd2si`)
- Acúmulo de erro em operações de ponto flutuante
- Técnica de inteiro escalado para aritmética financeira
- Detecção de divergência numérica em tempo de execução
- Diferença entre erros de *representação* e erros de *overflow*
- Flags de CPU e comparação de ponto flutuante em Assembly

---

## Linguagens e Ferramentas

- **Assembly:** NASM, x86-64, Linux (syscalls diretas)
- **Python:** 3.x, módulo `decimal` da biblioteca padrão
- **Linker:** GNU `ld` (binutils)
- **Ambiente:** Linux x86-64 / WSL2 no Windows

---

## Licença

MIT — livre para uso educacional e acadêmico.

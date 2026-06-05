; ============================================================
; comparacao.asm
; Fluxo completo: detecta o erro de ponto flutuante e aplica
; a correcao com inteiro escalado dentro do mesmo programa.
;
; Narrativa:
;   1. Calcula 1.000.000 x R$ 0,10 com float (IEEE 754)
;   2. Compara com o valor esperado (R$ 100.000,00)
;   3. Detecta a divergencia e exibe o delta
;   4. Reexecuta o mesmo calculo com inteiro escalado
;   5. Confirma que o resultado e exato
;
; Compilar:
;   nasm -f elf64 comparacao.asm -o comparacao.o
;   ld comparacao.o -o comparacao
; ============================================================

section .data

    n_transacoes        dq 1000000
    valor_float         dq 0.1              ; IEEE 754 - inexato
    centavos_unit       dq 10               ; 10 centavos - exato
    esperado_centavos   dq 10000000         ; 100000.00 em centavos

    ; Constantes de comparacao
    tolerancia          dq 0.000001            ; tolerancia: R$ 0,001

    ; --- Cabecalho ---
    str_cabecalho   db "============================================================", 10
                    db "  DETECCAO E CORRECAO DE ERRO NUMERICO", 10
                    db "  Cenario: 1.000.000 transacoes de R$ 0,10", 10
                    db "  Valor esperado: R$ 100.000,00", 10
                    db "============================================================", 10, 0

    ; --- Etapa 1 ---
    str_etapa1      db 10, "[ ETAPA 1 ] Calculando com ponto flutuante (IEEE 754)...", 10, 0
    str_res_float   db "  Resultado obtido : R$ ", 0
    str_esperado    db "  Valor esperado   : R$ 100000.00", 10, 0

    ; --- Etapa 2 ---
    str_etapa2      db 10, "[ ETAPA 2 ] Verificando divergencia...", 10, 0
    str_delta       db "  Delta (diferenca): R$ ", 0
    str_erro_sim    db "  STATUS: ERRO DETECTADO - resultado diverge do esperado!", 10, 0
    str_erro_nao    db "  STATUS: sem divergencia detectada.", 10, 0

    ; --- Etapa 3 ---
    str_etapa3      db 10, "[ ETAPA 3 ] Causa do erro:", 10
                    db "  0.1 em IEEE 754 = 0x3FB999999999999A", 10
                    db "  Valor real armazenado: 0.1000000000000000055511...", 10
                    db "  A cada soma, o excesso de ~5.5e-18 se acumula.", 10
                    db "  Em 1.000.000 operacoes, o erro acumulado se torna visivel.", 10, 0

    ; --- Etapa 4 ---
    str_etapa4      db 10, "[ ETAPA 4 ] Aplicando correcao: inteiro escalado...", 10
                    db "  Estrategia: representar R$ 0,10 como 10 centavos (inteiro).", 10
                    db "  Inteiros sao exatos em binario. Sem ponto flutuante no calculo.", 10, 0
    str_res_int     db "  Resultado obtido : R$ ", 0

    ; --- Etapa 5 ---
    str_etapa5      db 10, "[ ETAPA 5 ] Confirmacao:", 10, 0
    str_ok          db "  STATUS: CORRIGIDO - resultado exato apos aplicar inteiro escalado.", 10, 0
    str_conclusao   db 10, "============================================================", 10
                    db "  CONCLUSAO", 10
                    db "  Float (IEEE 754) : acumula erro em operacoes repetidas.", 10
                    db "  Inteiro escalado : exato. Usado em sistemas bancarios reais.", 10
                    db "  Em Assembly voce ve e controla cada etapa desse processo.", 10
                    db "============================================================", 10, 0

    newline         db 10, 0
    buf1            db 32 dup(0)
    buf2            db 32 dup(0)
    buf_delta       db 32 dup(0)

section .bss
    res_float       resq 1
    res_centavos    resq 1

section .text
    global _start

; ============================================================
; print_str: imprime string terminada em zero
; rdi = ponteiro
; ============================================================
print_str:
    push rdi
    xor rcx, rcx
.len:
    mov al, [rdi + rcx]
    test al, al
    jz .fim
    inc rcx
    jmp .len
.fim:
    mov rdx, rcx
    mov rsi, rdi
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdi
    ret

; ============================================================
; double_to_str: converte xmm0 (double) para string com 6 casas
; xmm0 = valor, rdi = buffer destino
; ============================================================
double_to_str:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r15, rdi

    ; parte inteira
    cvttsd2si rbx, xmm0
    movsd xmm2, xmm0
    cvtsi2sd xmm3, rbx
    subsd xmm2, xmm3                ; xmm2 = fracao

    ; fracao * 1000000
    mov rax, 1000000
    cvtsi2sd xmm4, rax
    mulsd xmm2, xmm4
    cvttsd2si r12, xmm2

    ; converter parte inteira
    mov rax, rbx
    lea rsi, [r15 + 22]
    mov byte [rsi], 0
    dec rsi
    mov r13, 10
.li:
    xor rdx, rdx
    div r13
    add dl, '0'
    mov [rsi], dl
    dec rsi
    test rax, rax
    jnz .li
    inc rsi

    mov rdi, r15
.ci:
    mov al, [rsi]
    test al, al
    jz .di
    mov [rdi], al
    inc rdi
    inc rsi
    jmp .ci
.di:
    mov byte [rdi], '.'
    inc rdi

    ; 6 casas decimais
    mov rax, r12
    lea rsi, [rdi + 7]
    mov byte [rsi], 0
    dec rsi
    mov r14, 6
.lf:
    xor rdx, rdx
    div r13
    add dl, '0'
    mov [rsi], dl
    dec rsi
    dec r14
    jnz .lf
    inc rsi

    mov rcx, 6
.cf:
    mov al, [rsi]
    mov [rdi], al
    inc rdi
    inc rsi
    loop .cf
    mov byte [rdi], 0

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================
; centavos_to_str: converte rax (centavos) para string "R.CC"
; rax = centavos, rdi = buffer destino
; ============================================================
centavos_to_str:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r14

    mov r14, rdi

    mov rbx, 100
    xor rdx, rdx
    div rbx
    mov r12, rdx                    ; centavos restantes

    ; reais -> string
    lea rsi, [r14 + 22]
    mov byte [rsi], 0
    dec rsi
    mov rbx, 10
.lr:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    dec rsi
    test rax, rax
    jnz .lr
    inc rsi

    mov rdi, r14
.cr:
    mov al, [rsi]
    test al, al
    jz .dr
    mov [rdi], al
    inc rdi
    inc rsi
    jmp .cr
.dr:
    mov byte [rdi], '.'
    inc rdi

    ; centavos (2 digitos)
    mov rax, r12
    xor rdx, rdx
    div rbx
    add al, '0'
    add dl, '0'
    mov [rdi], al
    inc rdi
    mov [rdi], dl
    inc rdi
    mov byte [rdi], 0

    pop r14
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================
; _start
; ============================================================
_start:

    ; --- Cabecalho ---
    mov rdi, str_cabecalho
    call print_str

    ; --------------------------------------------------------
    ; ETAPA 1: calculo com float
    ; --------------------------------------------------------
    mov rdi, str_etapa1
    call print_str

    movsd xmm0, [valor_float]
    xorpd xmm1, xmm1
    mov rcx, [n_transacoes]
.loop_float:
    addsd xmm1, xmm0
    dec rcx
    jnz .loop_float

    movsd [res_float], xmm1

    mov rdi, str_res_float
    call print_str

    movsd xmm0, [res_float]
    mov rdi, buf1
    call double_to_str
    mov rdi, buf1
    call print_str
    mov rdi, newline
    call print_str

    mov rdi, str_esperado
    call print_str

    ; --------------------------------------------------------
    ; ETAPA 2: detectar divergencia
    ; --------------------------------------------------------
    mov rdi, str_etapa2
    call print_str

    ; Calcula |resultado - esperado|
    movsd xmm0, [res_float]
    mov rax, [esperado_centavos]    ; 10000000 centavos
    cvtsi2sd xmm2, rax
    mov rax, 100
    cvtsi2sd xmm3, rax
    divsd xmm2, xmm3               ; xmm2 = 100000.0 (esperado em reais)
    subsd xmm0, xmm2               ; xmm0 = resultado - esperado

    ; valor absoluto
    mov rax, 0x7FFFFFFFFFFFFFFF
    movq xmm3, rax
    andpd xmm0, xmm3               ; |delta|

    movsd xmm4, xmm0               ; salva delta

    ; compara com tolerancia
    movsd xmm5, [tolerancia]
    ucomisd xmm0, xmm5
    jb .sem_erro

    ; --- com erro ---
    mov rdi, str_delta
    call print_str
    movsd xmm0, xmm4
    mov rdi, buf_delta
    call double_to_str
    mov rdi, buf_delta
    call print_str
    mov rdi, newline
    call print_str

    mov rdi, str_erro_sim
    call print_str
    jmp .etapa3

.sem_erro:
    mov rdi, str_erro_nao
    call print_str

    ; --------------------------------------------------------
    ; ETAPA 3: causa do erro
    ; --------------------------------------------------------
.etapa3:
    mov rdi, str_etapa3
    call print_str

    ; --------------------------------------------------------
    ; ETAPA 4: correcao com inteiro escalado
    ; --------------------------------------------------------
    mov rdi, str_etapa4
    call print_str

    xor rax, rax
    mov rcx, [n_transacoes]
    mov rbx, [centavos_unit]
.loop_int:
    add rax, rbx
    dec rcx
    jnz .loop_int

    mov [res_centavos], rax

    mov rdi, str_res_int
    call print_str

    mov rax, [res_centavos]
    mov rdi, buf2
    call centavos_to_str
    mov rdi, buf2
    call print_str
    mov rdi, newline
    call print_str

    ; --------------------------------------------------------
    ; ETAPA 5: confirmacao
    ; --------------------------------------------------------
    mov rdi, str_etapa5
    call print_str

    mov rax, [res_centavos]
    cmp rax, [esperado_centavos]
    jne .resultado_errado

    mov rdi, str_ok
    call print_str
    jmp .conclusao

.resultado_errado:
    mov rdi, str_erro_sim
    call print_str

    ; --------------------------------------------------------
    ; Conclusao
    ; --------------------------------------------------------
.conclusao:
    mov rdi, str_conclusao
    call print_str

    mov rax, 60
    xor rdi, rdi
    syscall

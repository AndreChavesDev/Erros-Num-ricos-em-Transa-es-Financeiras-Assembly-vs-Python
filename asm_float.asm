; ============================================================
; asm_float.asm
; Simula N transacoes de R$ 0.10 usando ponto flutuante (SSE2)
; Demonstra o erro de representacao IEEE 754
;
; Compilar:
;   nasm -f elf64 asm_float.asm -o asm_float.o
;   ld asm_float.o -o asm_float
; ============================================================

section .data
    valor_transacao dq 0.1          ; R$ 0.10 em double (IEEE 754 - inexato!)
    n_transacoes    dq 1000000      ; 1 milhao de transacoes

    ; Strings de saida
    titulo      db "=== ASM FLOAT (ponto flutuante IEEE 754) ===", 10, 0
    label_n     db "Transacoes     : 1.000.000", 10, 0
    label_esp   db "Valor esperado : R$ 100000.00", 10, 0
    label_res   db "Resultado real : R$ ", 0
    label_err   db "ERRO detectado : o acumulo de imprecisao em 0.1 (IEEE 754)", 10, 0
    label_bits  db "Bits de 0.1    : 3FB999999999999A (hex) - nao e exato em binario!", 10, 0
    newline     db 10, 0

    ; Buffer para conversao do resultado
    buf         db 32 dup(0)

section .bss
    result      resq 1              ; armazena resultado final

section .text
    global _start

; -------------------------------------------------------
; Converte double em string decimal (6 casas)
; xmm0 = valor, rdi = buffer destino
; -------------------------------------------------------
double_to_str:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    ; Extrair parte inteira
    cvttsd2si rax, xmm0             ; parte inteira em rax
    movsd xmm1, xmm0
    cvtsi2sd xmm2, rax
    subsd xmm1, xmm2                ; xmm1 = parte fracionaria

    ; Multiplicar fracao por 1000000 para pegar 6 casas
    mov rax, 1000000
    cvtsi2sd xmm3, rax
    mulsd xmm1, xmm3
    cvttsd2si r12, xmm1             ; r12 = parte fracionaria * 1000000

    ; Converter parte inteira para string
    cvttsd2si rbx, xmm0
    mov rax, rbx
    mov r13, rdi                    ; salva ponteiro inicio
    mov r14, rdi

    ; Digits da parte inteira
    lea rsi, [rdi + 20]
    mov byte [rsi], 0
    dec rsi
    mov rcx, 10
.loop_int:
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rsi], dl
    dec rsi
    test rax, rax
    jnz .loop_int
    inc rsi

    ; Copiar para buffer destino
.copy_int:
    mov al, [rsi]
    test al, al
    jz .done_int
    mov [rdi], al
    inc rdi
    inc rsi
    jmp .copy_int
.done_int:
    ; Adicionar ponto decimal
    mov byte [rdi], '.'
    inc rdi

    ; Converter 6 casas decimais
    mov rax, r12
    lea rsi, [rdi + 7]
    mov byte [rsi], 0
    dec rsi
    mov rcx, 10
    mov r8, 6
.loop_frac:
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rsi], dl
    dec rsi
    dec r8
    test r8, r8
    jnz .loop_frac
    inc rsi

    ; Copiar 6 casas
    mov rcx, 6
.copy_frac:
    mov al, [rsi]
    mov [rdi], al
    inc rdi
    inc rsi
    loop .copy_frac

    mov byte [rdi], 0

    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; -------------------------------------------------------
; Imprime string terminada em zero
; rdi = ponteiro para string
; -------------------------------------------------------
print_str:
    push rdi
    xor rcx, rcx
.len_loop:
    mov al, [rdi + rcx]
    test al, al
    jz .done_len
    inc rcx
    jmp .len_loop
.done_len:
    mov rdx, rcx
    mov rsi, rdi
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdi
    ret

; -------------------------------------------------------
; Ponto de entrada principal
; -------------------------------------------------------
_start:
    ; Imprimir titulo
    mov rdi, titulo
    call print_str

    mov rdi, label_bits
    call print_str

    mov rdi, label_n
    call print_str

    mov rdi, label_esp
    call print_str

    ; === LOOP DE ACUMULACAO ===
    ; Carrega 0.1 em xmm0 (ja inexato aqui!)
    movsd xmm0, [valor_transacao]

    ; xmm1 = acumulador zerado
    xorpd xmm1, xmm1

    ; rcx = contador de transacoes
    mov rcx, [n_transacoes]

.loop_soma:
    addsd xmm1, xmm0               ; acumula 0.1 + 0.1 + ...
    dec rcx
    jnz .loop_soma

    ; Salva resultado
    movsd [result], xmm1

    ; Imprime label do resultado
    mov rdi, label_res
    call print_str

    ; Converte e imprime o resultado
    movsd xmm0, [result]
    mov rdi, buf
    call double_to_str
    mov rdi, buf
    call print_str

    mov rdi, newline
    call print_str

    ; Imprime aviso do erro
    mov rdi, label_err
    call print_str

    mov rdi, newline
    call print_str

    ; Sair
    mov rax, 60
    xor rdi, rdi
    syscall

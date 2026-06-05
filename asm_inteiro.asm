; ============================================================
; asm_inteiro.asm
; Simula N transacoes de R$ 0.10 usando inteiro escalado
; R$ 0.10 = 10 centavos (inteiro) -> sem erro de representacao
;
; Compilar:
;   nasm -f elf64 asm_inteiro.asm -o asm_inteiro.o
;   ld asm_inteiro.o -o asm_inteiro
; ============================================================

section .data
    ; R$ 0.10 representado como 10 centavos (inteiro exato)
    centavos_por_transacao  dq 10       ; 10 centavos
    n_transacoes            dq 1000000  ; 1 milhao de transacoes

    titulo      db "=== ASM INTEIRO ESCALADO (centavos) ===", 10, 0
    label_n     db "Transacoes     : 1.000.000", 10, 0
    label_esp   db "Valor esperado : R$ 100000.00", 10, 0
    label_res   db "Resultado real : R$ ", 0
    label_ok    db "SEM ERRO: inteiros sao exatos. 10 centavos * 1.000.000 = 10.000.000 centavos", 10, 0
    label_conv  db "Conversao      : 10.000.000 centavos / 100 = R$ 100000.00 (exato)", 10, 0
    newline     db 10, 0

    buf         db 32 dup(0)

section .bss
    result_centavos resq 1

section .text
    global _start

; -------------------------------------------------------
; Converte inteiro (centavos) em string "REAIS.CENTAVOS"
; rax = valor em centavos, rdi = buffer destino
; -------------------------------------------------------
centavos_to_str:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov r14, rdi                    ; salva ponteiro de destino

    ; Separar reais e centavos
    ; rax ja contem o total em centavos
    mov rbx, 100
    xor rdx, rdx
    div rbx                         ; rax = reais, rdx = centavos (0-99)
    mov r12, rdx                    ; r12 = centavos
    ; rax = reais

    ; Converter parte dos reais para string (via buffer temporario)
    lea rsi, [r14 + 25]             ; fim do buffer temporario
    mov byte [rsi], 0
    dec rsi
    mov r13, 10
.loop_reais:
    xor rdx, rdx
    div r13
    add dl, '0'
    mov [rsi], dl
    dec rsi
    test rax, rax
    jnz .loop_reais
    inc rsi                         ; rsi aponta para primeiro digito

    mov rdi, r14
.copy_reais:
    mov al, [rsi]
    test al, al
    jz .done_reais
    mov [rdi], al
    inc rdi
    inc rsi
    jmp .copy_reais
.done_reais:
    ; Ponto decimal
    mov byte [rdi], '.'
    inc rdi

    ; Centavos (sempre 2 digitos)
    mov rax, r12
    xor rdx, rdx
    mov rbx, 10
    div rbx                         ; rax = dezena, rdx = unidade
    add al, '0'
    add dl, '0'
    mov [rdi], al
    inc rdi
    mov [rdi], dl
    inc rdi
    mov byte [rdi], 0

    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; -------------------------------------------------------
; Imprime string terminada em zero
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
    mov rdi, titulo
    call print_str

    mov rdi, label_n
    call print_str

    mov rdi, label_esp
    call print_str

    ; === LOOP DE ACUMULACAO COM INTEIROS ===
    mov rax, 0                      ; acumulador em centavos
    mov rcx, [n_transacoes]
    mov rbx, [centavos_por_transacao]

.loop_soma:
    add rax, rbx                    ; soma 10 centavos por vez (exato!)
    dec rcx
    jnz .loop_soma

    ; rax agora contem 10.000.000 centavos = R$ 100.000,00 exatos
    mov [result_centavos], rax      ; salva antes de qualquer call

    ; Imprimir resultado
    mov rdi, label_res
    call print_str

    mov rax, [result_centavos]      ; restaura para a conversao
    mov rdi, buf
    call centavos_to_str
    mov rdi, buf
    call print_str

    mov rdi, newline
    call print_str

    mov rdi, label_ok
    call print_str

    mov rdi, label_conv
    call print_str

    mov rdi, newline
    call print_str

    mov rax, 60
    xor rdi, rdi
    syscall

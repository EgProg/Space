.MODEL SMALL
.STACK 400h
.DATA
    EOFLine  EQU  '$'  ; Константа для обозначения конца строки
    INPUT_HEADER DB 50h,0 ; Заголовок для ввода строки, содержащий максимальную длину строки
    INPUT_BUFFER DB 80 DUP('*'), 0AH, 0DH, EOFLine ; Буфер для ввода строки
    OUTPUT_BUFFER DB 80 DUP(' '), 0AH, 0DH, EOFLine ; Буфер для вывода строки

    INPUT_ENTER_HEADER db 0A0h, 0 ; Заголовок для ввода строки, содержащий предельную и фактическую длины строки
    INPUT_ENTER_BUFFER db 160 DUP(EOFLINE), EOFLine ; Буфер для ввода строки

    ticks DW 0  ; Счетчик тиков для отсчета времени

    GREETING DB 'ENTER INPUT STRING', 0DH, 0AH, EOFLine ; Приветственное сообщение
    WAITING DB 'WAITING FOR YOUR STRING', 0DH, 0AH, EOFLine ; Сообщение ожидания
    TOO_LATE DB 'TOO LATE 6 SECONDS PAST', 0DH, 0AH, EOFLine ; Сообщение спустя 6 сек

    SYS_4B_IP DW 0 ; Сохраненный IP для обработчика прерывания 4Bh
    SYS_4B_CS DW 0 ; Сохраненный CS для обработчика прерывания 4Bh

    SYS_1C_IP DW 0 ; Сохраненный IP для обработчика прерывания 1Ch
    SYS_1C_CS DW 0 ; Сохраненный CS для обработчика прерывания 1Ch

.CODE
    MAIN PROC FAR
        push ds         ; Сохранение DS в стеке
        xor ax, ax      ; Очистка AX
        push ax         ; Сохранение AX в стеке
        mov ax, @data   ; Загрузка сегмента данных в AX
        mov ds, ax      ; Установка DS на сегмент данных
        mov es, ax      ; Установка ES на сегмент данных

        ; Вывод приветственного сообщения
        lea dx, GREETING
        call StringPrint

        ; Вывод сообщения ожидания
        lea dx, WAITING
        call StringPrint

        ; Чтение входной строки
        lea dx, INPUT_HEADER
        call StringRead

        ; Вывод введенной строки
        lea dx, INPUT_BUFFER
        call StringPrint

        ; Сохранение оригинального обработчика прерывания 4Bh
        mov ah, 35h     ; Функция DOS для получения обработчика прерывания
        mov al, 4Bh     ; Номер прерывания 4Bh
        int 21h         ; Вызов DOS
        mov SYS_4B_CS, es ; Сохранение сегмента обработчика
        mov SYS_4B_IP, bx ; Сохранение смещения обработчика

        ; Установка нового обработчика прерывания 4Bh
        push ds         ; Сохранение DS в стеке
        lea dx, CustomExecInterruptHandler ; Загрузка смещения нового обработчика
        mov ax, SEG CustomExecInterruptHandler ; Загрузка сегмента нового обработчика
        mov ds, ax      ; Установка DS на сегмент нового обработчика
        mov ah, 25h     ; Функция DOS для установки обработчика прерывания
        mov al, 4Bh     ; Номер прерывания 4Bh
        int 21h         ; Вызов DOS
        pop ds          ; Восстановление DS из стека

        ; Сохранение оригинального обработчика прерывания 1Ch
        mov ah, 35h     ; Функция DOS для получения обработчика прерывания
        mov al, 1Ch     ; Номер прерывания 1Ch
        int 21h         ; Вызов DOS
        mov SYS_1C_CS, es ; Сохранение сегмента обработчика
        mov SYS_1C_IP, bx ; Сохранение смещения обработчика

        ; Установка нового обработчика прерывания 1Ch
        push ds         ; Сохранение DS в стеке
        lea dx, CustomTimerInterruptHandler ; Загрузка смещения нового обработчика
        mov ax, SEG CustomTimerInterruptHandler ; Загрузка сегмента нового обработчика
        mov ds, ax      ; Установка DS на сегмент нового обработчика
        mov ah, 25h     ; Функция DOS для установки обработчика прерывания
        mov al, 1Ch     ; Номер прерывания 1Ch
        int 21h         ; Вызов DOS
        pop ds          ; Восстановление DS из стека
        
        ; Чтение входной строки
        lea dx, INPUT_ENTER_HEADER
        call StringRead

        ; Вызов прерывания 4Bh
        int 4Bh

        call RecoverInteruptions ; Восстановление оригинальных обработчиков прерываний
        ret
    MAIN ENDP

    StringRead PROC
        ; Чтение строки от пользователя
        mov  ah, 0ah    ; Функция DOS для чтения строки
        push dx         ; Сохранение DX в стеке
        int  21h        ; Вызов DOS
        pop  bp         ; Восстановление BP из стека
        xor  bx, bx     ; Очистка BX
        mov  bl, ds:[bp+1] ; Загрузка длины введенной строки в BL
        add  bx, bp     ; Вычисление адреса конца строки
        add  bx, 2      ; Добавление смещения для записи символов конца строки
        mov  word ptr [bx + 1], 240ah ; Запись 24h ('$') и 0Ah (новая строка) в конец строки
        ret
    StringRead ENDP

    StringPrint PROC
        ; Вывод строки на экран
        mov ah, 09h     ; Функция DOS для вывода строки
        int 21h         ; Вызов DOS
        ret
    StringPrint ENDP

    CustomExecInterruptHandler PROC FAR
    ;обработчик прерываний
        push ax         ; Сохранение AX в стеке
        push bx         ; Сохранение BX в стеке
        push cx         ; Сохранение CX в стеке
        push dx         ; Сохранение DX в стеке
        push si         ; Сохранение SI в стеке
        push di         ; Сохранение DI в стеке

        ; Преобразование шестнадцатеричной строки в десятичные цифры
        mov ax, ds      ; Загрузка сегмента данных в AX
        mov es, ax      ; Установка ES на сегмент данных
        lea si, INPUT_BUFFER ; Загрузка адреса буфера ввода в SI
        lea di, OUTPUT_BUFFER ; Загрузка адреса буфера вывода в DI
        call HexStringToDecimalDigits ; Вызов процедуры преобразования

        ; Вывод результата
        lea dx, OUTPUT_BUFFER ; Загрузка адреса буфера вывода в DX
        call StringPrint ; Вызов процедуры вывода строки

        pop di          ; Восстановление DI из стека
        pop si          ; Восстановление SI из стека
        pop dx          ; Восстановление DX из стека
        pop cx          ; Восстановление CX из стека
        pop bx          ; Восстановление BX из стека
        pop ax          ; Восстановление AX из стека
        iret            ; Возврат из прерывания
    CustomExecInterruptHandler ENDP

    ; Восстановление прерываний
    RecoverInteruptions PROC
        ; Восстановление обработчика прерывания 4Bh
        push ds         ; Сохранение DS в стеке
        mov dx, SYS_4B_IP ; Загрузка смещения оригинального обработчика
        mov ax, SYS_4B_CS ; Загрузка сегмента оригинального обработчика
        mov ds, ax      ; Установка DS на сегмент оригинального обработчика
        mov ah, 25h     ; Функция DOS для установки обработчика прерывания
        mov al, 4Bh     ; Номер прерывания 4Bh
        int 21h         ; Вызов DOS
        pop ds          ; Восстановление DS из стека

        ; Восстановление обработчика прерывания 1Ch
        push ds         ; Сохранение DS в стеке
        mov dx, SYS_1C_IP ; Загрузка смещения оригинального обработчика
        mov ax, SYS_1C_CS ; Загрузка сегмента оригинального обработчика
        mov ds, ax      ; Установка DS на сегмент оригинального обработчика
        mov ah, 25h     ; Функция DOS для установки обработчика прерывания
        mov al, 1Ch     ; Номер прерывания 1Ch
        int 21h         ; Вызов DOS
        pop ds          ; Восстановление DS из стека
        ret
    RecoverInteruptions ENDP

    CustomTimerInterruptHandler PROC
        inc ticks       ; Увеличение счетчика тиков
        cmp ticks, 110  ; Сравнение счетчика с 110 (примерно 6 секунд)
        jne skip        ; Если не равно, пропустить вывод сообщения
        mov dx, OFFSET TOO_LATE ; Загрузка адреса сообщения в DX
        call StringPrint ; Вызов процедуры вывода строки
        call RecoverInteruptions ; Восстановление оригинальных обработчиков прерываний
    skip:
        iret            ; Возврат из прерывания
    CustomTimerInterruptHandler ENDP










    HexStringToDecimalDigits PROC
        push ax         ; Сохранение AX в стеке
        push bx         ; Сохранение BX в стеке
        push cx         ; Сохранение CX в стеке
        push dx         ; Сохранение DX в стеке
        push si         ; Сохранение SI в стеке
        push di         ; Сохранение DI в стеке

        cld             ; Очистка флага направления (DF = 0)
        mov cx, 80      ; Установка счетчика на максимальную длину строки
        rep movsb       ; Копирование строки из INPUT_BUFFER в OUTPUT_BUFFER

        ; Преобразование шестнадцатеричных символов в десятичные цифры
        lea si, INPUT_BUFFER ; Загрузка адреса буфера ввода в SI
        lea di, OUTPUT_BUFFER ; Загрузка адреса буфера вывода в DI
        mov cx, 80      ; Установка счетчика на максимальную длину строки
        xor ax, ax      ; Очистка AX
        mov bx, 0       ; Флаг для отслеживания первого символа

    convert_loop:
        lodsb           ; Загрузка символа из строки в AL
        cmp al, '0'     ; Проверка, является ли символ цифрой
        jb non_digit    ; Если меньше '0', перейти к non_digit
        cmp al, '9'     ; Проверка, является ли символ цифрой
        jbe digit       ; Если меньше или равно '9', перейти к digit
        cmp al, 'A'     ; Проверка, является ли символ буквой
        jb non_digit    ; Если меньше 'A', перейти к non_digit
        cmp al, 'F'     ; Проверка, является ли символ буквой
        jbe letter      ; Если меньше или равно 'F', перейти к letter
        cmp al, 'a'     ; Проверка, является ли символ буквой
        jb non_digit    ; Если меньше 'a', перейти к non_digit
        cmp al, 'f'     ; Проверка, является ли символ буквой
        jbe letter      ; Если меньше или равно 'f', перейти к letter
        jmp non_digit   ; Перейти к non_digit

    digit:
        sub al, '0'     ; Преобразование символа в цифру
        jmp store_digit ; Перейти к store_digit

    letter:
        cmp al, 'a'     ; Проверка, является ли символ строчной буквой
        jb upper_letter ; Если меньше 'a', перейти к upper_letter
        sub al, 'a' - 10 ; Преобразование строчной буквы в цифру
        jmp store_digit ; Перейти к store_digit

    upper_letter:
        sub al, 'A' - 10 ; Преобразование заглавной буквы в цифру

    store_digit:
        push cx         ; Сохранение CX в стеке
        ; Инициализация счетчика цифр
        mov cx, 0       ; Очистка счетчика цифр
        mov bx, 10      ; Основание 10

    store_digits:
        xor dx, dx      ; Очистка DX для деления
        div bx          ; Деление AX на 10
        add dl, '0'     ; Преобразование остатка в символ
        push dx         ; Сохранение символа в стеке
        inc cx          ; Увеличение счетчика цифр
        cmp ax, 0       ; Проверка, остались ли цифры для обработки
        jnz store_digits ; Если не равно 0, продолжить цикл

    write_digits:
        pop ax          ; Извлечение символа из стека
        stosb           ; Запись символа в OUTPUT_BUFFER
        loop write_digits ; Цикл по всем символам

        mov al, ' '     ; Добавление пробела между числами
        stosb           ; Запись пробела в OUTPUT_BUFFER

        pop cx          ; Восстановление CX из стека
        jmp continue    ; Перейти к continue

    non_digit:
        ; Игнорирование символа, не являющегося шестнадцатеричной цифрой
        jmp continue    ; Перейти к continue

    continue:
        loop convert_loop ; Цикл по всем символам строки

    end_convert:
        mov al, 0AH     ; Запись символа новой строки
        stosb           ; Запись символа в OUTPUT_BUFFER
        mov al, 0DH     ; Запись символа возврата каретки
        stosb           ; Запись символа в OUTPUT_BUFFER
        mov al, EOFLine ; Запись символа конца строки
        stosb           ; Запись символа в OUTPUT_BUFFER

        pop di          ; Восстановление DI из стека
        pop si          ; Восстановление SI из стека
        pop dx          ; Восстановление DX из стека
        pop cx          ; Восстановление CX из стека
        pop bx          ; Восстановление BX из стека
        pop ax          ; Восстановление AX из стека
        ret
    HexStringToDecimalDigits ENDP

END MAIN
; ======================================================;
; RTC.SYS Driver for ESXDOS                             ;
; Supports RTC chips:                                   ;
;   - DS1285, MC146818, BQ3285, KR512VI1, etc           ;
;                                                       ;
; Compatible with the GLUK RTC standard                 ;
;                                                       ;
; Developer : Aleksandr Hrytsevskyi (Alex Zor)          ;
; Location  : Kryvyi Rih, Ukraine                       ;
; Date      : 10.05.2026                                ;
; ======================================================;

                        output_bin "RTC.SYS", 0, endrtc+1 ;

                        org $0                          ;

                        push af                         ;

                        ld c, $F7                       ;

rtc_detect:             ld b, $EF                       ; RTC on
                        ld a, $80                       ;
                        out (c), a                      ;

                        ld b, $DF                       ; register B
                        ld a, $0B                       ; bit 2: 0-BCD, 1-BIN
                        out (c), a                      ; bit 1: 0-12h, 1-24h
                        ld b, $BF                       ;
                        in a, (c)                       ; read data
                        cp $FF                          ; Exit if RTC not present
                        jr nz, read_time                ;
                        ld b, $EF                       ; RTC off
                        ld a, $00                       ;
                        out (c), a                      ;
                        ld de, $0000                    ;
                        ld bc, $0497                    ; ZX Spectrum birthday
                        pop af                          ;
                        ret                             ;

read_time:              ld l, a                         ; store RTC reg B
                        ld b, $DF                       ; seconds
                        xor a                           ;
                        out (c), a                      ;
                        ld b, $BF                       ;
                        in a, (c)                       ;
                        ld h, $01                       ; return label
                        jr convert                      ;
ret_1:                  srl a                           ; *2
                        and $1F                         ; bits 0-4
                        ld e, a                         ;

                        ld b, $DF                       ; minutes
                        ld a, $02                       ;
                        out (c), a                      ;
                        ld b, $BF                       ;
                        in a, (c)                       ;
                        ld h, $02                       ; return label
                        jr convert                      ;
ret_2:                  ld d, a                         ;
                        xor a                           ;
                        rr d                            ;
                        rra                             ;
                        rr d                            ;
                        rra                             ;
                        rr d                            ;
                        rra                             ;
                        or e                            ;
                        ld e, a                         ;

                        ld b, $DF                       ; hours
                        ld a, $04                       ;
                        out (c), a                      ;
                        ld b, $BF                       ;
                        in a, (c)                       ;
                        and $7F                         ;
                        ld h, $04                       ; return label
                        jr convert                      ;
ret_3:                  bit 1, l                        ; 12 or 24 hour format
                        jr nz, format24                 ;
                        cp $0C                          ;
                        jr nz, not12h                   ;
                        xor a                           ; 12 -> 0
not12h:                 push af                         ;
                        ld b, $BF                       ;
                        in a, (c)                       ;
                        ld b, 0                         ;
                        bit 7, a                        ;
                        jr z, time_am                   ;
                        ld b, $0C                       ; +12 when PM
time_am:                pop af                          ;
                        add a, b                        ;
format24:               rlca                            ;
                        rlca                            ;
                        rlca                            ;
                        or d                            ;
                        ld d, a                         ;
                        jr read_date                    ;

;---------------- BCD to BIN ---------------------------
convert:                bit 2, l                        ; BIN or BCD
                        jr nz, notbcd                   ; return if not BCD
                        push af                         ; convert BCD to BIN
                        srl a                           ;
                        srl a                           ;
                        srl a                           ;
                        srl a                           ;
                        add a, a                        ; * 2
                        ld b, a                         ; store *2
                        add a, a                        ; * 4
                        add a, a                        ; * 8
                        add a, b                        ; *2 + *8 = *10
                        ld b, a                         ;
                        pop af                          ;
                        and $0F                         ;
                        add a, b                        ;
notbcd:                 bit 0, h                        ;
                        jr nz, ret_1                    ;
                        bit 1, h                        ;
                        jr nz, ret_2                    ;
                        bit 2, h                        ;
                        jr nz, ret_3                    ;
                        bit 3, h                        ;
                        jr nz, ret_4                    ;
                        bit 4, h                        ;
                        jr nz, ret_5                    ;
                        bit 5, h                        ;
                        jr nz, ret_6                    ;
;-------------------------------------------------------

read_date:              push de                         ;

                        ld b, $DF                       ; day
                        ld a, $07                       ;
                        out (c), a                      ;
                        ld b, $BF                       ;
                        in a, (c)                       ;
                        ld h, $08                       ; return label
                        jr convert                      ;
ret_4:                  and $1F                         ;
                        ld e, a                         ;

                        ld b, $DF                       ; month
                        ld a, $08                       ;
                        out (c), a                      ;
                        ld b, $BF                       ;
                        in a, (c)                       ;
                        ld h, $10                       ; return label
                        jr convert                      ;
ret_5:                  ld d, a                         ;
                        xor a                           ;
                        rr d                            ;
                        rra                             ;
                        rr d                            ;
                        rra                             ;
                        rr d                            ;
                        rra                             ;
                        or e                            ;
                        ld e, a                         ;

                        ld b, $DF                       ; year
                        ld a, $09                       ;
                        out (c), a                      ;
                        ld b, $BF                       ;
                        in a, (c)                       ;
                        ld h, $20                       ; return label
                        jr convert                      ;
ret_6:                  ld l, $14                       ;
                        add a, l                        ;
                        sla a                           ;
                        or d                            ;
                        ld d, a                         ;

                        ld b, $EF                       ; RTC off
                        xor a                           ;
                        out (c), a                      ;

                        ld b, d                         ; BC - date
                        ld c, e                         ;
                        pop de                          ; DE - time
                        pop af                          ;

endrtc:                 ret                             ;




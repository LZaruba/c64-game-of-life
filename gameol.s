; Game of Life

.include "c64.inc"
.include "cbm_kernal.inc"

SCREEN_MEM = $0400
LIVE_SYMBOL = $51
DEAD_SYMBOL = $20
LIVE_BIT = 128 ; 0b10000000
NEIGHBOUR_MASK = 127 ; 0b01111111
ROUND_NUMBER_PONITER = $07C0
Y_PLAY_SIZE = YSIZE - 1
X_PLAY_SIZE = XSIZE

.zeropage
roundNumber: ; roundNumber is in decimal mode
    .res 4
screenPointer:
    .res 2
screenPointerTopLeftNeighbour:
    .res 2
dataPointer:
    .res 2
firstColumn:
    .res 1
lastColumn:
    .res 1
cellNeighboursCount:
    .res 1
speed:
    .res 1
stringPointer:
    .res 2

.segment "CODE"
    jsr $e544 ; clear screen

    ; clear round number
    lda #0
    sta speed

    sta roundNumber
    sta roundNumber+1
    sta roundNumber+2
    sta roundNumber+3

    ; initialize the game
    lda #LIVE_SYMBOL 
    sta SCREEN_MEM+(40*21)+39
    sta SCREEN_MEM+(40*21)+38
    sta SCREEN_MEM+(40*21)+37
    sta SCREEN_MEM+(40*23)+1
    sta SCREEN_MEM+(40*23)+2
    sta SCREEN_MEM+(40*23)+3
    sta SCREEN_MEM+(40*22)+1
    sta SCREEN_MEM+(40*22)+2
    sta SCREEN_MEM+(40*22)+3

cycle:
    jsr printRoundNumber
    jsr waitForNextRound

    ; increment round counter
    sed             ; Set Decimal Mode for BCD arithmetic
    clc
    lda roundNumber
    adc #$01        ; BCD value
    sta roundNumber

    lda roundNumber+1
    adc #$00        ; BCD value
    sta roundNumber+1

    lda roundNumber+2
    adc #$00        ; BCD value
    sta roundNumber+2

    lda roundNumber+3
    adc #$00        ; BCD value
    sta roundNumber+3
    cld             ; Clear Decimal Mode

    jsr clearData

    ; reset screen pointer
    lda #<SCREEN_MEM
    sta screenPointer
    lda #>SCREEN_MEM
    sta screenPointer+1

    ; reset data pointer
    lda #<data
    sta dataPointer
    lda #>data
    sta dataPointer+1

    sec               ; Set carry flag
    lda screenPointer
    sbc #41 ; one line above and one column to the left
    sta screenPointerTopLeftNeighbour
    lda screenPointer+1
    sbc #0  ; subtracting 0 and carry
    sta screenPointerTopLeftNeighbour+1

; X - line counter
; Y - column counter
    ldx #0
@lineloop:
    ldy #0

@columnloop:
    lda #0
    sta firstColumn
    sta lastColumn
    lda #1
    cpy #0
    bne @checkLastColumn
    sta firstColumn
@checkLastColumn:
    cpy #X_PLAY_SIZE-1
    bne @continue
    sta lastColumn

@continue:
    jsr countNeighbors
    
    clc                 ; Clear carry flag
    lda screenPointer
    adc #1
    sta screenPointer
    lda screenPointer+1
    adc #0
    sta screenPointer+1

    clc                 ; Clear carry flag
    lda screenPointerTopLeftNeighbour
    adc #1
    sta screenPointerTopLeftNeighbour
    lda screenPointerTopLeftNeighbour+1
    adc #0
    sta screenPointerTopLeftNeighbour+1

    clc                 ; Clear carry flag
    lda dataPointer
    adc #1
    sta dataPointer
    lda dataPointer+1
    adc #0
    sta dataPointer+1

    iny
    cpy #X_PLAY_SIZE
    bne @columnloop

    inx
    cpx #Y_PLAY_SIZE
    bne @lineloop

; store the data back to the screen
    ; reset screen pointer
    lda #<SCREEN_MEM
    sta screenPointer
    lda #>SCREEN_MEM
    sta screenPointer+1

    ; reset data pointer
    lda #<data
    sta dataPointer
    lda #>data
    sta dataPointer+1

; X - line counter
; Y - column counter
    ldx #0
@storeToScreenLineLoop:
    ldy #0
@storeToScreenColumnLoop:
    tya
    pha

    ldy #0

    lda (dataPointer), y
    cmp #1
    beq @live
    lda #DEAD_SYMBOL
    jmp @store

@live:
    lda #LIVE_SYMBOL

@store:
    sta (screenPointer), y

    pla
    tay

    clc                 ; Clear carry flag
    lda screenPointer
    adc #1
    sta screenPointer
    lda screenPointer+1
    adc #0
    sta screenPointer+1

    clc                 ; Clear carry flag
    lda dataPointer
    adc #1
    sta dataPointer
    lda dataPointer+1
    adc #0
    sta dataPointer+1

    iny
    cpy #X_PLAY_SIZE
    bne @storeToScreenColumnLoop

    inx
    cpx #Y_PLAY_SIZE
    bne @storeToScreenLineLoop

    jmp cycle

; ========= waitForNextRound =========
waitForNextRound:
    lda speed
    cmp #0
    beq waitForSpace

    jsr SCNKEY
    jsr GETIN
    cmp #$20 ; space bar
    beq @setSpeedZero
    cmp #$91 ; UP key
    beq @speedUp
    cmp #$11 ; DOWN key
    beq @speedDown

    jmp @delayLoop

@speedUp:
    lda speed
    cmp #1
    beq @delayLoop
    dec speed
    jmp @delayLoop

@speedDown:
    lda speed
    cmp #9
    beq @delayLoop
    inc speed
    jmp @delayLoop

@setSpeedZero:
    lda #$00
    sta speed
    
@delayLoop:
    sec
    sbc #1
    ; simple delay loop
    ldx #$1f
@innerDelayLoop:
    dex 
    cpx #0
    bne @innerDelayLoop
    cmp #0
    bne @delayLoop

    rts ; return after delay

waitForSpace:
    jsr SCNKEY
    jsr GETIN
    cmp #$52 ; R key
    beq @setRunMode
    cmp #$20 ; space bar
    bne waitForNextRound

    rts ; return after space

@setRunMode:
    lda #5
    sta speed
    jmp waitForNextRound

    rts ; return after R

; ========= waitForNextRound END =========

countNeighbors:
    ; stores y on stack
    tya
    pha

    ; reset cell neighbours count
    lda #0
    sta cellNeighboursCount

    ldy #0

    lda (screenPointer), y
    cmp #LIVE_SYMBOL
    bne @skipLiveSymbol

    ; mark live bit
    lda #LIVE_BIT
    sta cellNeighboursCount

; for calculations, 40 constant equals one line, but it is counted from left top neighbour, meaning +40 -> left next to me

@skipLiveSymbol:
    cpx #0
    beq @checkRightNeighbour ; first line, no need to check top neighbours
@checkTopRightNeighbour:
    lda lastColumn
    cmp #1
    beq @checkTopNeighbour
    ; check top right neighbour
    ldy #2 ; -41 + 2 = top right
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkTopNeighbour
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkTopNeighbour:
    ; check top neigbour
    ldy #1 ; -41 + 1 = top
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkTopLeftNeighbour
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkTopLeftNeighbour:
    lda firstColumn
    cmp #1
    beq @checkRightNeighbour
    ; check top left neighbour
    ldy #0 ; -41 + 0 = top left
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkRightNeighbour
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkRightNeighbour:
    lda lastColumn
    cmp #1
    beq @checkLeftNeighbour
    ; check right neighbour
    ldy #42; -41 + 42 = right
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkLeftNeighbour
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkLeftNeighbour:
    lda firstColumn
    cmp #1
    beq @checkBottomNeighbour
    ; check left neighbour
    ldy #40 ; -41 + 40 = left
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkBottomNeighbour
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkBottomNeighbour:
    cpx #Y_PLAY_SIZE-1
    beq @end ; last line, no need to check bottom neighbours
    ; check bottom neighbour
    ldy #81 ; -41 + 81 = bottom
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkBottomRightNeighbour
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkBottomRightNeighbour:
    lda lastColumn
    cmp #1
    beq @checkBottomLeftNeighbour
    ; check bottom right neighbour
    ldy #82 ; -41 + 82 = bottom right
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkBottomLeftNeighbour
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkBottomLeftNeighbour:
    lda firstColumn
    cmp #1
    beq @end
    ; check bottom left neighbour
    ldy #80 ; -41 + 80 = bottom left
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @end
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@end:
    jsr applyRules
    ; restore y
    pla
    tay
    rts

applyRules:
    lda cellNeighboursCount
    and #LIVE_BIT
    bne @liveCell

    lda cellNeighboursCount
    and #NEIGHBOUR_MASK
    cmp #3 ; dead cell with 3 live neighbours
    beq @makeAlive
    jmp @makeDead

@liveCell:
    lda cellNeighboursCount
    and #NEIGHBOUR_MASK
    cmp #2 ; live cell with 2 or 3 live neighbours
    bcc @makeDead
    beq @makeAlive

    cmp #3
    beq @makeAlive
    jmp @makeDead

@makeAlive:
    lda #1
    jmp @storeAndReturn

@makeDead:
    lda #0

@storeAndReturn:
    ldy #0
    sta (dataPointer), y
    rts

; Clears the data array setting it to 0
; Modifies A, X
clearData:
    ldx #$ff
    lda #0

@loop:
    sta data,x
    sta data+$0100,x
    sta data+$0200,x
    sta data+$0300,x

    dex
    bne @loop

    rts

; Print 8 decimal digits at ROUND_NUMBER_PONITER
; Each byte holds 2 BCD digits (0-9), so we extract nibbles to get individual digits
; appends speed to the output
printRoundNumber:
    ; Preserve registers
    txa
    pha
    tya
    pha
    ldx #0

    ; byte 3 - high nibble (BCD digit)
    lda roundNumber+3
    and #$F0
    lsr
    lsr
    lsr
    lsr
    jsr digitToAscii
    sta ROUND_NUMBER_PONITER, x
    inx

    ; byte 3 - low nibble (BCD digit)
    lda roundNumber+3
    and #$0F
    jsr digitToAscii
    sta ROUND_NUMBER_PONITER, x
    inx

    ; byte 2 - high nibble (BCD digit)
    lda roundNumber+2
    and #$F0
    lsr
    lsr
    lsr
    lsr
    jsr digitToAscii
    sta ROUND_NUMBER_PONITER, x
    inx

    ; byte 2 - low nibble (BCD digit)
    lda roundNumber+2
    and #$0F
    jsr digitToAscii
    sta ROUND_NUMBER_PONITER, x
    inx

    ; byte 1 - high nibble (BCD digit)
    lda roundNumber+1
    and #$F0
    lsr
    lsr
    lsr
    lsr
    jsr digitToAscii
    sta ROUND_NUMBER_PONITER, x
    inx

    ; byte 1 - low nibble (BCD digit)
    lda roundNumber+1
    and #$0F
    jsr digitToAscii
    sta ROUND_NUMBER_PONITER, x
    inx

    ; byte 0 - high nibble (BCD digit)
    lda roundNumber
    and #$F0
    lsr
    lsr
    lsr
    lsr
    jsr digitToAscii
    sta ROUND_NUMBER_PONITER, x
    inx

    ; byte 0 - low nibble (BCD digit)
    lda roundNumber
    and #$0F
    jsr digitToAscii
    sta ROUND_NUMBER_PONITER, x
    inx

    inx ; skip one byte for space

    lda speed
    cmp #0
    beq @printSpeedManual

    lda #<runLabel1
    sta stringPointer
    lda #>runLabel1
    sta stringPointer+1
    jsr printString

    lda #10 ; complement speed
    sec
    sbc speed
    clc
    adc #48 ; '0' character code
    sta ROUND_NUMBER_PONITER, x
    inx

    lda #<runLabel2
    sta stringPointer
    lda #>runLabel2
    sta stringPointer+1
    jsr printString

    jmp @finishPrint

@printSpeedManual:
    lda #<manualLabel
    sta stringPointer
    lda #>manualLabel
    sta stringPointer+1
    jsr printString

@finishPrint:

    ; restore registers
    pla
    tay
    pla
    tax
    rts

; ========= printString =========
; use stringPointer to point to null-terminated string
; modifies X, incrementing by the lenghth of the string, starts printing at ROUND_NUMBER_PONITER + X
printString:
    ldy #0
@printLoop:
    lda (stringPointer), y
    cmp #0
    beq @end
    sta ROUND_NUMBER_PONITER, x
    inx
    iny
    jmp @printLoop
    
@end:
    rts

; ========= printString END =========

; Convert BCD digit (0-9) to ASCII
digitToAscii:
    and #$0F    ; Ensure value is 0-9 (mask to nibble)
    clc
    adc #$30    ; 0 -> '0', 1 -> '1', ..., 9 -> '9'
    rts

.segment "DATA"
data:
    .res 1024
manualLabel:
    ; .asciiz "M, SPACE FOR STEP, R FOR RUN   "
    ; in screen code
    .byte $0D,$2C,$20,$13,$10,$01,$03,$05,$20,$06,$0F,$12,$20,$13,$14,$05,$10,$2C,$20,$12,$20,$06,$0F,$12,$20,$12,$15,$0E,$20,$20,$20,$00
runLabel1:
    ; .asciiz "S:"
    ; in screen code
    .byte $13,$3A,$00
runLabel2:
    ;.asciiz ", UP/DOWN SPEED, SPACE TO M."
    ; in screen code
    .byte $2C,$20,$15,$10,$2F,$04,$0F,$17,$0E,$20,$13,$10,$05,$05,$04,$2C,$20,$13,$10,$01,$03,$05,$20,$14,$0F,$20,$0D,$2E,$00

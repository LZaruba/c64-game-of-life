; Game of Life

.include "c64.inc"
.include "cbm_kernal.inc"

SCREEN_MEM = $0400
LIVE_SYMBOL = 1
DEAD_SYMBOL = $20
LIVE_BIT = 128 ; 0b10000000
NEIGHBOUR_MASK = 127 ; 0b01111111

.zeropage
roundNumber:
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

; Print round number variables
workingNumber:
    .res 4, 0           ; 4-byte working space for conversion
bcdAccumulator:
    .res 5, 0           ; 5 bytes for 10 BCD digits (max 32-bit = 4,294,967,295)
bcdTemp:
    .byte 0             ; Temporary for BCD adjustment (zeropage for speed)
buffer:
    .res 10, 0          ; Buffer to store ASCII digits (up to 10 digits)
bufferIndex:
    .byte 0             ; Index for buffer
roundNumberScreenPointer:
    .word $07C0         ; Pointer to the start of the last row

.segment "CODE"
    jsr $e544 ; clear screen

    ; clear round number
    lda #0
    sta roundNumber
    sta roundNumber+1
    sta roundNumber+2
    sta roundNumber+3

    ; initialize the game
    lda #LIVE_SYMBOL 
    sta SCREEN_MEM+(40*1)+1
    sta SCREEN_MEM+(40*1)+2
    sta SCREEN_MEM+(40*1)+3
    sta SCREEN_MEM+(40*2)+1
    sta SCREEN_MEM+(40*2)+2
    sta SCREEN_MEM+(40*2)+3
    sta SCREEN_MEM+(40*3)+1
    sta SCREEN_MEM+(40*3)+2
    sta SCREEN_MEM+(40*3)+3

cycle:
    ; increment round counter
    clc
    lda roundNumber
    adc #1
    sta roundNumber

    lda roundNumber+1
    adc #0
    sta roundNumber+1

    lda roundNumber+2
    adc #0
    sta roundNumber+2

    lda roundNumber+3
    adc #0
    sta roundNumber+3

    jsr printRoundNumber

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
    cpy #XSIZE-1
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
    cpy #XSIZE
    bne @columnloop

    inx
    cpx #YSIZE
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
    cpy #XSIZE
    bne @storeToScreenColumnLoop

    inx
    cpx #YSIZE
    bne @storeToScreenLineLoop

    jsr waitforspace
    jmp cycle

waitforspace:
    jsr SCNKEY
    jsr GETIN
    cmp #$20 ; space bar
    bne waitforspace
    
    rts

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
    ldy #0
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
    ldy #0
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
    ldy #0
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkRightNeighbour:
    lda lastColumn
    cmp #1
    beq @checkLeftNeighbour
    ; check right neighbour
    ldy #41; -41 + 41 = right
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkLeftNeighbour
    ldy #0
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkLeftNeighbour:
    lda firstColumn
    cmp #1
    beq @checkBottomNeighbour
    ; check left neighbour
    ldy #39 ; -41 + 39 = left
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkBottomNeighbour
    ldy #0
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkBottomNeighbour:
    cpx #YSIZE-1
    beq @end ; last line, no need to check bottom neighbours
    ; check bottom neighbour
    ldy #82 ; -41 + 82 = bottom
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkBottomRightNeighbour
    ldy #0
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkBottomRightNeighbour:
    lda lastColumn
    cmp #1
    beq @checkBottomLeftNeighbour
    ; check bottom right neighbour
    ldy #83 ; -41 + 83 = bottom right
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkBottomLeftNeighbour
    ldy #0
    lda cellNeighboursCount
    clc
    adc #1
    sta cellNeighboursCount

@checkBottomLeftNeighbour:
    lda firstColumn
    cmp #1
    beq @end
    ; check bottom left neighbour
    ldy #81 ; -41 + 81 = bottom left
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @end
    ldy #0
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

printRoundNumber:
    ; Preserve registers
    txa
    pha
    tya
    pha
    
    ; Clear buffer index first (defensive)
    lda #0
    sta bufferIndex
    
    ; Copy the 32-bit number to a working space
    ldx #3
copyNumber:
    lda roundNumber, x
    sta workingNumber, x
    dex
    bpl copyNumber

    ; Clear BCD accumulator (5 bytes)
    lda #0
    sta bcdAccumulator
    sta bcdAccumulator+1
    sta bcdAccumulator+2
    sta bcdAccumulator+3
    sta bcdAccumulator+4

    ; Double Dabble algorithm: loop 32 times (once per bit)
    ; Process bits from MSB to LSB
    ldx #32              ; 32 bits to process
dabbleLoop:
    ; Shift BCD accumulator left (5 bytes)
    clc
    rol bcdAccumulator
    rol bcdAccumulator+1
    rol bcdAccumulator+2
    rol bcdAccumulator+3
    rol bcdAccumulator+4

    ; Shift workingNumber left (4 bytes), MSB goes into carry
    ; Rotate left starting from MSB byte to get MSB into carry
    clc                  ; Clear carry - we want MSB bit, not a 1
    lda workingNumber+3
    rol                  ; Rotate left: bit 7 -> carry, carry (0) -> bit 0
    sta workingNumber+3
    lda workingNumber+2
    rol                  ; Continue rotation chain
    sta workingNumber+2
    lda workingNumber+1
    rol
    sta workingNumber+1
    lda workingNumber
    rol
    sta workingNumber
    ; Now carry has the MSB bit from the 32-bit number
    ; Bring it into BCD accumulator's LSB
    rol bcdAccumulator    ; Bring carry into BCD LSB

    ; Check each BCD digit (nibble), if >= 5, add 3
    ; Check bcdAccumulator (byte 0)
    lda bcdAccumulator
    jsr adjustBCDByte
    sta bcdAccumulator

    ; Check bcdAccumulator+1 (byte 1)
    lda bcdAccumulator+1
    jsr adjustBCDByte
    sta bcdAccumulator+1

    ; Check bcdAccumulator+2 (byte 2)
    lda bcdAccumulator+2
    jsr adjustBCDByte
    sta bcdAccumulator+2

    ; Check bcdAccumulator+3 (byte 3)
    lda bcdAccumulator+3
    jsr adjustBCDByte
    sta bcdAccumulator+3

    ; Check bcdAccumulator+4 (byte 4)
    lda bcdAccumulator+4
    jsr adjustBCDByte
    sta bcdAccumulator+4

    dex
    bne dabbleLoop

    ; Convert BCD digits to ASCII
    lda #0
    sta bufferIndex       ; Clear buffer index

    ; Traverse BCD accumulator from MSB to LSB (byte 4 down to 0)
    ldx #4                ; Start with byte 4 (MSB)
bcdToAsciiLoop:
    lda bcdAccumulator, x
    ; Process upper nibble
    pha                   ; Save byte
    lsr                   ; Shift upper nibble to lower
    lsr
    lsr
    lsr
    jsr convertNibbleToAscii
    pla                   ; Restore byte
    ; Process lower nibble
    and #$0F              ; Mask lower nibble
    jsr convertNibbleToAscii

    dex
    bpl bcdToAsciiLoop

    ; If no digits were stored, we need to print "0"
    lda bufferIndex
    bne printBuffer
    lda #$30              ; ASCII '0'
    sta buffer
    inc bufferIndex

printBuffer:
    ; Screen memory address for the last row: $07C0
    lda #$C0
    sta roundNumberScreenPointer
    lda #$07
    sta roundNumberScreenPointer+1

    ; Print digits in order (they're already stored correctly)
    ldx #0
printLoop:
    lda buffer, x
    ldy #0
    sta (roundNumberScreenPointer), y
    inc roundNumberScreenPointer
    bne skip
    inc roundNumberScreenPointer+1
skip:
    inx
    cpx bufferIndex
    bne printLoop
    
    ; Restore registers
    pla
    tay
    pla
    tax
    rts

; Helper routine: Adjust BCD byte (check both nibbles, add 3 if >= 5)
; Input: A = byte with two BCD nibbles
; Output: A = adjusted byte
; Modifies: bcdTemp (zeropage temporary)
adjustBCDByte:
    sta bcdTemp           ; Save original byte
    and #$F0              ; Get upper nibble
    lsr                   ; Shift to lower position for comparison
    lsr
    lsr
    lsr
    cmp #5
    bcc @checkLower       ; If upper nibble < 5, check lower nibble
    ; Add 3 to upper nibble
    lda bcdTemp           ; Get original byte
    clc
    adc #$30              ; Add 3 to upper nibble ($30 = 3 << 4)
    sta bcdTemp           ; Save modified byte
@checkLower:
    lda bcdTemp           ; Get byte (original or modified)
    and #$0F              ; Get lower nibble
    cmp #5
    bcc @done             ; If lower nibble < 5, done
    ; Add 3 to lower nibble
    lda bcdTemp           ; Get byte
    clc
    adc #$03              ; Add 3 to lower nibble
    rts
@done:
    lda bcdTemp           ; Return byte (original or modified)
    rts

; Helper routine: Convert BCD nibble to ASCII and store in buffer
; Input: A = BCD nibble (0-9)
; Modifies: bufferIndex, buffer
convertNibbleToAscii:
    ; Skip leading zeros unless we've already started storing digits
    cmp #0
    bne @notZero
    ldy bufferIndex
    bne @notZero          ; If bufferIndex > 0, we've started, so include this zero
    rts                   ; Skip leading zero
@notZero:
    clc
    adc #$30              ; Convert to ASCII ('0' = $30)
    ldy bufferIndex
    sta buffer, y
    inc bufferIndex
    rts

.segment "DATA"
data:
    .res 1024

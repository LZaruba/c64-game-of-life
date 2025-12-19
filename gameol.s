; Game of Life

.include "c64.inc"
.include "cbm_kernal.inc"

SCREEN_MEM = $0400
LIVE_SYMBOL = $51
DEAD_SYMBOL = $20
LIVE_BIT = 128 ; 0b10000000
NEIGHBOUR_MASK = 127 ; 0b01111111
ROUND_NUMBER_PONITER = $07C0
INIT_GAME_LABEL_POINTER = $0400 + 10 * 40 ; line 10 start
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
tmp:
    .res 2
liveCellsCount:
    .res 2
sound:
    .res 1

; screen editor zero page variables
columnPointer:
    .res 1
rowPointer:
    .res 1
cursorPointer:
    .res 2

.segment "CODE"

start:
    jsr initRandom
    jsr sidInit

    jsr $e544 ; clear screen

    ; clear round number
    lda #0
    sta speed

    sta roundNumber
    sta roundNumber+1
    sta roundNumber+2
    sta roundNumber+3

    lda #1
    sta sound

initializeGame:

    ldx #0
@printLoop1:
    lda initGameLabel1, x
    cmp #0
    beq @printLoop1Done
    sta INIT_GAME_LABEL_POINTER - 80, x
    inx
    jmp @printLoop1

@printLoop1Done:

    ldx #0
@printLoop2:
    lda initGameLabel2, x
    cmp #0
    beq @printLoop2Done
    sta INIT_GAME_LABEL_POINTER + 160, x
    inx
    jmp @printLoop2

@printLoop2Done:

ldx #0
@printLoop3:
    lda initGameLabel3, x
    cmp #0
    beq @printLoop3Done
    sta INIT_GAME_LABEL_POINTER + 240, x
    inx
    jmp @printLoop3

@printLoop3Done:

    ldx #0
@printLoop4:
    lda initGameLabel4, x
    cmp #0
    beq @keyLoop
    sta INIT_GAME_LABEL_POINTER + 360, x
    inx
    jmp @printLoop4

@jumpToScreenEditor:
    jmp screenEditor_start

; read the key
@keyLoop:
    jsr SCNKEY
    jsr GETIN
    jsr handleColorChanges
    cmp #$45 ; 'E' key for editor
    beq @jumpToScreenEditor
    cmp #$31 ; '1' key
    bcc @keyLoop
    cmp #$40 ; one key after '9'
    bcs @keyLoop

    ; convert ASCII to number 1-9
    sec
    sbc #$30
    pha ; protecting A against clear screen

    jsr $e544 ; clear screen

    pla
    tay

@fillOuterLoop:
    ldx #20 ; total number of cells * 1..9
@fillInnerLoop:
    txa
    pha
    jsr random_line
    tax
    lda screenRowLo, x
    sta tmp
    lda screenRowHi, x
    sta tmp+1
    pla
    tax

    jsr random_column
    clc
    adc tmp
    sta tmp
    lda tmp+1
    adc #0
    sta tmp+1

    tya
    pha
    ldy #0
    lda #LIVE_SYMBOL
    sta (tmp), y
    pla
    tay

    dex
    bne @fillInnerLoop
    dey
    bne @fillOuterLoop

start_game:
    jsr start_song ; start jingle

cycle:
    jsr printRoundNumber
    jsr waitForNextRound

    lda #0
    sta liveCellsCount
    sta liveCellsCount+1

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

    lda liveCellsCount
    ora liveCellsCount+1
    beq endGame ; game ends, no more living cells

    lda sound
    beq @skipBlip
    jsr roundBlip

@skipBlip:
    jmp cycle

endGame:
    jsr $e544 ; clear screen
    ldx #0
@printLoop1:
    lda gameOverLabel1, x
    cmp #0
    beq @print1Done
    sta INIT_GAME_LABEL_POINTER - 80, x
    inx
    jmp @printLoop1

@print1Done:
    ldx #0
@printLoop2:
    lda gameOverLabel2, x
    cmp #0
    beq @print2Done
    sta INIT_GAME_LABEL_POINTER, x
    inx
    jmp @printLoop2

@print2Done:    

    ldx #0
@printLoop3:
    lda gameOverLabel3, x
    cmp #0
    beq @print3Done
    sta INIT_GAME_LABEL_POINTER + 160, x
    inx
    jmp @printLoop3

@print3Done:    
    jsr endgame_song

@waitForSpace:
    jsr SCNKEY
    jsr GETIN
    cmp #$20 ; SPACE key
    bne @waitForSpace
    ; restart the game
    jmp start

; ========= waitForNextRound =========

waitForSpace:
    jsr SCNKEY
    jsr GETIN

    jsr handleColorChanges
    cmp #$52 ; R key
    beq @setRunMode
    cmp #$4d ; M key
    beq @toggleSound
    cmp #$51 ; Q key
    bne @skipRestart
    ; restart the game
    jmp start

@toggleSound:
    lda sound
    eor #1
    sta sound
    jmp waitForSpace

@skipRestart:
    cmp #$20 ; space bar
    bne waitForNextRound

    rts ; return after space
    

@setRunMode:
    lda #2
    sta speed
    jmp waitForNextRound

    rts ; return after R

waitForNextRound:
    lda speed
    cmp #0
    beq waitForSpace

@readKeys:
    jsr SCNKEY
    jsr GETIN

    jsr handleColorChanges

    cmp #$20 ; space bar
    beq @setSpeedZero
    cmp #$57 ; UP key
    beq @speedUp
    cmp #$53 ; DOWN key
    beq @speedDown
    cmp #$4d ; M key
    beq @toggleSound
    cmp #$51 ; Q key
    bne @preDelayLoop

    jmp start ; restart the game

@toggleSound:
    lda sound
    eor #1
    sta sound
    jmp @readKeys

@speedUp:
    lda speed
    cmp #1
    beq @preDelayLoop
    dec speed
    jsr printRoundNumber
    jmp @speedUpdateDone

@speedDown:
    lda speed
    cmp #9
    beq @preDelayLoop
    inc speed
    jsr printRoundNumber
    jmp @speedUpdateDone

@setSpeedZero:
    lda #$00
    sta speed

@speedUpdateDone:
    jsr printRoundNumber
    jmp waitForNextRound
    
@preDelayLoop:
    lda speed
@delayLoop:
    ldy #$7f

    sec ; go through A down to 0 and skip if 1
    sbc #1
    cmp #0
    bne @outerDelayLoop
    rts
@outerDelayLoop:
    ldx #$ff
@innerDelayLoop:
    dex 
    bne @innerDelayLoop
    dey
    bne @outerDelayLoop
    cmp #0
    bne @delayLoop

    rts ; return after delay

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
    clc
    lda liveCellsCount
    adc #1
    sta liveCellsCount
    lda liveCellsCount+1
    adc #0
    sta liveCellsCount+1

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

    ; space
    lda #$20
    sta ROUND_NUMBER_PONITER, x
    inx

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

initRandom:
    lda #$ff  ; maximum frequency value
    sta $d40e ; voice 3 frequency low byte
    sta $d40f ; voice 3 frequency high byte
    lda #$80  ; noise waveform, gate bit off
    sta $d412 ; voice 3 control register
    rts

; Returns random column index in A (0 to X_PLAY_SIZE-1)
random_column:
    lda $D41B ; sid chip noise
    cmp #X_PLAY_SIZE
    bcs random_column
    rts

random_line:
    lda $D41B ; sid chip noise
    cmp #Y_PLAY_SIZE
    bcs random_line
    rts

sidInit:
    lda #$0F          ; volume 0..15
    sta SID_Amp
    rts

; ------------------------------------------------------------
; End-of-round blip (self-contained, no lingering)
; Uses voice 1 only
; Clobbers: A, X, Y
; ------------------------------------------------------------
roundBlip:
    ; Ensure voice 1 starts silent
    lda #$00
    sta SID_Ctl1

    ; Pulse width ~50% ($0800)
    lda #$00
    sta SID_PB1Lo
    lda #$08
    sta SID_PB1Hi

    ; Envelope: quick hit, NO sustain so it can't hang
    lda #$02          ; A=0, D=2
    sta SID_AD1
    lda #$08          ; S=0, R=8  (key: sustain = 0)
    sta SID_SUR1

    ; Frequency
    lda #$C0
    sta SID_S1Lo
    lda #$18
    sta SID_S1Hi

    ; Gate on + pulse waveform
    lda #%01000001    ; $41 = pulse + gate
    sta SID_Ctl1

    ; Short audible delay
    ldx #$20
@d1:
    ldy #$FF
@d2:
    dey
    bne @d2
    dex
    bne @d1

    ; Gate off
    lda #%01000000    ; pulse, gate=0
    sta SID_Ctl1

    ; Small release time to settle
    ldy #$20
@r:
    dey
    bne @r

    ; Hard kill (guaranteed silence)
    lda #$00
    sta SID_Ctl1
    rts

; -----------------------------------------
; End-game song (very short, blocking)
; Clobbers: A, X, Y
; -----------------------------------------
endgame_song:
    ; volume (lower nibble). This also clears any filter bits.
    lda #$0F
    sta SID_Amp

    ; envelope: snappy, no sustain (prevents hanging)
    lda #$02          ; A=0, D=2
    sta SID_AD1
    lda #$08          ; S=0, R=8
    sta SID_SUR1

    ldx #0
@next:
    ; read duration first (3rd byte) -> terminator if 0
    ldy endgame_data+2,x
    beq @done

    ; load freq
    lda endgame_data,x
    sta SID_S1Lo
    lda endgame_data+1,x
    sta SID_S1Hi

    ; gate on + triangle
    lda #%00010001    ; $11 = TRI + GATE
    sta SID_Ctl1

@wait:
    jsr wait_frame
    dey
    bne @wait

    ; gate off (keep waveform bit)
    lda #%00010000    ; $10 = TRI, gate=0
    sta SID_Ctl1

    ; small gap (2 frames)
    ldy #2
@gap:
    jsr wait_frame
    dey
    bne @gap

    ; next note (advance by 3 bytes)
    txa
    clc
    adc #3
    tax
    jmp @next

@done:
    lda #$00
    sta SID_Ctl1       ; hard kill
    rts


; Wait ~1 frame using raster (PAL/NTSC OK)
wait_frame:
@wait_not0:
    lda $D012
    bne @wait_not0          ; wait until low raster becomes 0
@wait_leave0:
    lda $D012
    beq @wait_leave0        ; ensure we don't return twice in same frame
    rts

; ===================== SCREEN EDITOR

screenEditor_start:
    jsr $e544 ; clear screen

    ldx #0
@printLoop:
    lda editorStatusBar, x
    cmp #0
    beq @printLoopDone
    sta $0400 + 24*40, x
    inx
    jmp @printLoop

@printLoopDone:

    lda #0
    sta columnPointer
    sta rowPointer
    jsr screenEditor_updateCursorPointer
    jsr screenEditor_highlightCharacter

screenEditor_mainLoop:
    jsr GETIN

    cmp #$57 ; W key - UP
    beq @handleUp
    cmp #$91 ; arrow UP
    beq @handleUp
    cmp #$53 ; S key - DOWN
    beq @handleDown
    cmp #$11 ; arrow DOWN
    beq @handleDown    
    cmp #$41 ; A key - LEFT
    beq @handleLeft
    cmp #$9D ; arrow LEFT
    beq @handleLeft
    cmp #$44 ; D key - RIGHT
    beq @handleRight
    cmp #$1D ; arrow RIGHT
    beq @handleRight
    cmp #$20 ; Space key - TOGGLE CELL
    beq @handleToggle
    cmp #$0D ; Return key - DONE
    beq @handleDone
    cmp #$51 ; Q key - EXIT
    beq @handleExit

    jsr handleColorChanges
    jmp screenEditor_mainLoop

@handleExit:
    jmp start

@handleDone:
    jsr screenEditor_highlightCharacter
    jmp start_game ; exit editor to the main loop

@handleUp:
    lda rowPointer
    beq screenEditor_mainLoop
    dec rowPointer
    jmp @moveCursor

@handleDown:
    lda rowPointer
    cmp #Y_PLAY_SIZE - 1
    beq screenEditor_mainLoop
    inc rowPointer
    jmp @moveCursor

@handleLeft:
    lda columnPointer
    beq screenEditor_mainLoop
    dec columnPointer
    jmp @moveCursor

@handleRight:
    lda columnPointer
    cmp #X_PLAY_SIZE - 1
    beq screenEditor_mainLoop
    inc columnPointer
    jmp @moveCursor

@handleToggle:
    ldy #0
    lda (cursorPointer), y
    cmp #$d1
    beq @clearCell
    lda #$d1
    sta (cursorPointer), y
    jmp screenEditor_mainLoop

@clearCell:
    lda #$a0
    sta (cursorPointer), y
    jmp screenEditor_mainLoop

@moveCursor:
    jsr screenEditor_highlightCharacter
    jsr screenEditor_updateCursorPointer
    jsr screenEditor_highlightCharacter
    jmp screenEditor_mainLoop

; screenEditor_mainLoop END

; updates cursorPointer based on rowPointer and columnPointer
; Modifies A, X
screenEditor_updateCursorPointer:
    ; Calculate screen address
    ; get beginning of row
    lda rowPointer
    tax
    lda screenRowLo, x
    sta cursorPointer
    lda screenRowHi, x
    sta cursorPointer + 1

    ; add column offset
    lda columnPointer
    clc
    adc cursorPointer
    sta cursorPointer
    lda cursorPointer + 1
    adc #0
    sta cursorPointer + 1

    rts

; updateCursorPointer END

; toggles the character with 128 at current cursor position
; Modifies A, Y
screenEditor_highlightCharacter:
    ldy #0
    lda (cursorPointer), y
    clc
    adc #128
    sta (cursorPointer), y

    rts

; highlightCharacter END

; ===================== SCREEN EDITOR END

; -----------------------------------------
; Start-game jingle (cheerful, short)
; Clobbers: A, X, Y
; -----------------------------------------
start_song:
    ; Volume setup
    lda #$0F
    sta SID_Amp

    ; Envelope: quick attack/decay, short release
    lda #$04          ; A=4, D=0
    sta SID_AD1
    lda #$08          ; S=0, R=8
    sta SID_SUR1

    ldx #0
@next:
    ldy start_data+2,x
    beq @done

    lda start_data,x
    sta SID_S1Lo
    lda start_data+1,x
    sta SID_S1Hi

    lda #%00010001    ; TRI + Gate
    sta SID_Ctl1

@wait:
    jsr wait_frame
    dey
    bne @wait

    lda #%00010000    ; TRI, Gate off
    sta SID_Ctl1

    ldy #2            ; small gap
@gap:
    jsr wait_frame
    dey
    bne @gap

    txa
    clc
    adc #3
    tax
    jmp @next

@done:
    lda #0
    sta SID_Ctl1
    rts

; handling of color changes based on the key pressed
; Expects A to have the key code
; Modifies A, Y
handleColorChanges:
    cmp #$85 ; fn 1
    beq @rotateForeground
    cmp #$86 ; fn 3
    beq @rotateBackground
    cmp #$87 ; fn 5
    beq @rotateBorder
    rts

@rotateForeground:
    lda $d800
    clc
    adc #1
    ora #$f0
    cmp $d021
    bne @skipEqualsBackground
    clc
    adc #1

@skipEqualsBackground:
    and #$0f
    ldy #$00

@colorLoop: 
    sta $d800, y
    sta $d900, y
    sta $da00, y
    sta $db00, y
    dey
    bne @colorLoop
    rts

@rotateBackground:
    lda $D021
    clc
    adc #1
    and #$0f
    cmp $d800
    bne @skipEqualsForeground
    clc
    adc #1
    and #$0f

@skipEqualsForeground:
    sta $d021
    rts

@rotateBorder:
    lda $d020
    clc
    adc #1
    and #$0f
    sta $d020
    rts

; handleColorChanges END

.segment "DATA"
data:
    .res 1024
manualLabel:
    ; .asciiz "MAN SPACE=STEP R=RUN Q=RESTART   "
    ; in screen code
    .byte $0D,$01,$0E,$20
    .byte $13,$10,$01,$03,$05,$3D,$13,$14,$05,$10,$20
    .byte $12,$3D,$12,$15,$0E,$20
    .byte $11,$3D,$12,$05,$13,$14,$01,$12,$14
    .byte $20,$20,$20,$00
runLabel1:
    ; .asciiz "AUT"
    ; in screen code
    .byte $01,$15,$14,$00
runLabel2:
    ;.asciiz " W/S SPACE=MANUAL Q=RESTART"
    ; in screen code
    .byte $20
    .byte $17,$2F,$13,$20
    .byte $13,$10,$01,$03,$05,$3D,$0D,$01,$0E,$15,$01,$0C,$20
    .byte $11,$3D,$12,$05,$13,$14,$01,$12,$14,$00

initGameLabel1:
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $03,$0F,$0E,$17,$01,$19,$27,$13
    .byte $20
    .byte $07,$01,$0D,$05
    .byte $20
    .byte $0F,$06
    .byte $20
    .byte $0C,$09,$06,$05
    .byte $00

initGameLabel2:
    ; "PRESS 1-9 TO CHOOSE STARTING DENSITY" centered
    .byte $20,$20
    .byte $10,$12,$05,$13,$13
    .byte $20
    .byte $31,$2D,$39
    .byte $20
    .byte $14,$0F
    .byte $20
    .byte $03,$08,$0F,$0F,$13,$05
    .byte $20
    .byte $13,$14,$01,$12,$14,$09,$0E,$07
    .byte $20
    .byte $04,$05,$0E,$13,$09,$14,$19
    .byte $00

initGameLabel3:
    ; "PRESS E FOR GAME EDITOR" centered
    .byte $20,$20,$20,$20,$20,$20,$20,$20
    .byte $10,$12,$05,$13,$13
    .byte $20
    .byte $05
    .byte $20
    .byte $06,$0F,$12
    .byte $20
    .byte $07,$01,$0D,$05
    .byte $20
    .byte $05,$04,$09,$14,$0F,$12
    .byte $00

initGameLabel4:
    ; "F1/F3/F5 TO CHANGE COLORS" centered
    .byte $20,$20,$20,$20,$20,$20,$20
    .byte $06,$31,$2F,$06,$33,$2F,$06,$35
    .byte $20
    .byte $14,$0F
    .byte $20
    .byte $03,$08,$01,$0E,$07,$05
    .byte $20
    .byte $03,$0F,$0C,$0F,$12,$13
    .byte $00

gameOverLabel1:
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $07,$01,$0D,$05
    .byte $20
    .byte $0F,$16,$05,$12
    .byte $00 

gameOverLabel2:
    .byte $20,$20,$20,$20,$20
    .byte $19,$0F,$15,$12
    .byte $20
    .byte $10,$0F,$10,$15,$0C,$01,$14,$09,$0F,$0E
    .byte $20
    .byte $04,$09,$04,$0E,$27,$14
    .byte $20
    .byte $13,$15,$12,$16,$09,$16,$05
    .byte $00

gameOverLabel3:
    .byte $20,$20,$20,$20,$20,$20,$20,$20
    .byte $10,$12,$05,$13,$13
    .byte $20
    .byte $13,$10,$01,$03,$05
    .byte $20
    .byte $14,$0F
    .byte $20
    .byte $03,$0F,$0E,$14,$09,$0E,$15,$05
    .byte $00

editorStatusBar:
    ; "MOVE=ASWD SELECT=SPACE START=RETURN"
    .byte $0D,$0F,$16,$05,$3D,$01,$13,$17,$04,$20
    .byte $13,$05,$0C,$05,$03,$14,$3D,$13,$10,$01,$03,$05,$20
    .byte $13,$14,$01,$12,$14,$3D,$12,$05,$14,$15,$12,$0E,$00
    
; screen addressing for 25 rows of 40 columns
; each entry is the address of the start of the row in screen memory
screenRowLo:
    .byte <($0400 +  0*40),<($0400 +  1*40),<($0400 +  2*40),<($0400 +  3*40)
    .byte <($0400 +  4*40),<($0400 +  5*40),<($0400 +  6*40),<($0400 +  7*40)
    .byte <($0400 +  8*40),<($0400 +  9*40),<($0400 + 10*40),<($0400 + 11*40)
    .byte <($0400 + 12*40),<($0400 + 13*40),<($0400 + 14*40),<($0400 + 15*40)
    .byte <($0400 + 16*40),<($0400 + 17*40),<($0400 + 18*40),<($0400 + 19*40)
    .byte <($0400 + 20*40),<($0400 + 21*40),<($0400 + 22*40),<($0400 + 23*40)
    .byte <($0400 + 24*40),<($0400 + 25*40)

screenRowHi:
    .byte >($0400 +  0*40),>($0400 +  1*40),>($0400 +  2*40),>($0400 +  3*40)
    .byte >($0400 +  4*40),>($0400 +  5*40),>($0400 +  6*40),>($0400 +  7*40)
    .byte >($0400 +  8*40),>($0400 +  9*40),>($0400 + 10*40),>($0400 + 11*40)
    .byte >($0400 + 12*40),>($0400 + 13*40),>($0400 + 14*40),>($0400 + 15*40)
    .byte >($0400 + 16*40),>($0400 + 17*40),>($0400 + 18*40),>($0400 + 19*40)
    .byte >($0400 + 20*40),>($0400 + 21*40),>($0400 + 22*40),>($0400 + 23*40)
    .byte >($0400 + 24*40),>($0400 + 25*40)

; -----------------------------------------
; Data: freqLo, freqHi, durationFrames
; (Frequencies are SID values; tweak to taste)
; -----------------------------------------
endgame_data:
    .byte $00,$18,10   ; note 1
    .byte $40,$1C,10   ; note 2
    .byte $80,$20,10   ; note 3
    .byte $00,$16,18   ; resolve
    .byte $00,$00,0    ; terminator

; -----------------------------------------
; Data: freqLo, freqHi, durationFrames
; (Ascending C major: C4–E4–G4–C5)
; -----------------------------------------
start_data:
    .byte $00,$10,8    ; C4
    .byte $A0,$12,8    ; E4
    .byte $20,$15,8    ; G4
    .byte $00,$18,12   ; C5
    .byte $00,$00,0    ; terminator

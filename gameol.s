; Game of Life

.include "c64.inc"
.include "cbm_kernal.inc"

SCREEN_MEM = $0400
LIVE_SYMBOL = 1
DEAD_SYMBOL = $20
LIVE_BIT = 128 ; 0b10000000

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

    jmp wozmon

countNeighbors:
    ; stores y on stack
    tya
    pha

    ldy #0

    lda (screenPointer), y
    cmp #LIVE_SYMBOL
    bne @skipLiveSymbol

    ; mark live bit
    lda #LIVE_BIT
    ora (dataPointer), y
    sta (dataPointer), y


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
    lda (dataPointer), y
    clc
    adc #1
    sta (dataPointer), y

@checkTopNeighbour:
    ; check top neigbour
    ldy #1 ; -41 + 1 = top
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkTopLeftNeighbour
    ldy #0
    lda (dataPointer), y
    clc
    adc #1
    sta (dataPointer), y

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
    lda (dataPointer), y
    clc
    adc #1
    sta (dataPointer), y

@checkRightNeighbour:
    lda lastColumn
    cmp #1
    beq @checkLeftNeighbour
    ; check right neighbour
    ldy #42; -41 + 42 = right
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkLeftNeighbour
    ldy #0
    lda (dataPointer), y
    clc
    adc #1
    sta (dataPointer), y

@checkLeftNeighbour:
    lda firstColumn
    cmp #1
    beq @checkBottomNeighbour
    ; check left neighbour
    ldy #40 ; -41 + 40 = left
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkBottomNeighbour
    ldy #0
    lda (dataPointer), y
    clc
    adc #1
    sta (dataPointer), y

@checkBottomNeighbour:
    cpx #YSIZE-1
    beq @end ; last line, no need to check bottom neighbours
    ; check bottom neighbour
    ldy #81 ; -41 + 81 = bottom
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkBottomRightNeighbour
    ldy #0
    lda (dataPointer), y
    clc
    adc #1
    sta (dataPointer), y

@checkBottomRightNeighbour:
    lda lastColumn
    cmp #1
    beq @checkBottomLeftNeighbour
    ; check bottom right neighbour
    ldy #82 ; -41 + 82 = bottom right
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @checkBottomLeftNeighbour
    ldy #0
    lda (dataPointer), y
    clc
    adc #1
    sta (dataPointer), y

@checkBottomLeftNeighbour:
    lda firstColumn
    cmp #1
    beq @end
    ; check bottom left neighbour
    ldy #80 ; -41 + 80 = bottom left
    lda (screenPointerTopLeftNeighbour), y
    cmp #LIVE_SYMBOL
    bne @end
    ldy #0
    lda (dataPointer), y
    clc
    adc #1
    sta (dataPointer), y

@end:
    ; restore y
    pla
    tay
    rts
    
processNeighbors:
    jsr $e544 ; clear screen

    ldx #$ff
@evalCycle:
    
    lda #LIVE_BIT
    and data, x
    beq @dead

    lda #LIVE_SYMBOL
    jmp @store

@dead:
    lda #DEAD_SYMBOL

@store:
    sta SCREEN_MEM, x

    dex
    bne @evalCycle

    jmp wozmon
waitforspace:
    jsr SCNKEY
    jsr GETIN
    cmp #$20 ; space bar
    bne waitforspace
    
    jmp cycle

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

.segment "DATA"
data:
    .res 1024

wozmon:
; wozmon.asm
;
; Originally from Apple-1 Operation Manual, Steve Wozniak, 1976
; Revised 2024 May 8 for Commodore 64/VIC/128 by David R. Van Wagner davevw.com
; * Using C64 KERNAL (instead of MC6520 and KBD/CRT)
; * extra processing for expected mark parity, software caps lock, and revised newline/carriage return processing
; * revised to expect terminal line edit mode instead of echo off character processing
; * revised to acme syntax
; * different zero page usage
; * changed l/h to wl/wh because vice didn't like that symbol
; * reverse toggle instead of spaces only on vic-20 (like HESMON) because too few columns

; zero page usage - tape stuff on vic-20, 64, 128.  Needs to change for PET, TED, Plus/4, 16, etc.
xaml=$a3
xamh=$a4
stl=$a5
sth=$a6
wl=$a7
wh=$a8
ysav=$a9
mode=$aa

in=$200 ; same as Commodore uses, should be fine to copy from/to this, will probably use slightly less

;** C64, etc. support added by David R. Van Wagner davevw.com ***************************************
; Commodore KENRAL
; CHROUT=$FFD2
; CHRIN=$FFCF
;** C64 etc. support added by David R. Van Wagner davevw.com ***************************************

; * = $1400
START:
	cld
	cli
	jmp escape
	
;** C64, etc. support added by David R. Van Wagner davevw.com ***************************************
KBD_IN:
	sty $22
	jsr CHRIN ; note: full screen editor
	ldy $22
	rts
;** C64, etc. support added by David R. Van Wagner davevw.com ***************************************

notcr:
	cmp #$DF ; underscore or Commodore back arrow (rub out?)
	beq backspace
	cmp #$83
	beq escape
	iny
	bpl nextchar
escape:
	lda #$DC ; backslash
	jsr echo
getline:
	lda #13
	jsr echo
	ldy #1
backspace:
	dey
	bmi getline
nextchar:
	jsr KBD_IN
	ora #$80
	sta in, y
	;jsr echo - needed only if terminal echo off, line editing off
	cmp #$8D
	bne notcr
	ldy #$ff
	lda #$00
	tax
setstor:
	asl
setmode:
	sta mode
blskip:
	iny
nextitem:
	lda in, y
	cmp #$8D
	beq getline
	cmp #$AE ; period
	bcc blskip
	beq setmode
	cmp #$BA ; colon
	beq setstor
	cmp #$D2 ; R
	beq run
	stx wl
	stx wh
	sty ysav
nexthex:
	lda in, y
	eor #$B0
	cmp #$0A
	bcc dig
	adc #$88
	cmp #$FA
	bcc nothex
dig:
	asl
	asl
	asl
	asl
	ldx #4
hexshift:
	asl
	rol wl
	rol wh
	dex
	bne hexshift
	iny
	bne nexthex
nothex:
	cpy ysav
	beq escape
	bit mode
	bvc notstor
	lda wl
	sta (stl, x)
	inc stl
	bne nextitem
	inc sth
tonextitem:
	jmp nextitem
run:
	jmp (xaml)
notstor:
	bmi xamnext
	ldx #2
setadr:
	lda wl-1,x
	sta stl-1,x
	sta xaml-1,x
	dex
	bne setadr
nxtprnt:
	bne prdata
	lda #13
	jsr echo
	lda xamh
	jsr prbyte
	lda xaml
	jsr prbyte
	lda #$BA ; colon
	jsr echo
prdata:
	lda #32
	jsr echo
	lda (xaml,x)
	jsr prbyte
xamnext:
	stx mode
	lda xaml
	cmp wl
	lda xamh
	sbc wh
	bcs tonextitem
	inc xaml
	bne mod8chk
	inc xamh
mod8chk:
	lda xaml
	and #7
	bpl nxtprnt ; should always branch
prbyte:
	pha
	lsr
	lsr
	lsr
	lsr
	jsr prhex
	pla
prhex:
	and #$0F
	ora #$B0
	cmp #$BA
	bcc echo
	adc #6
echo:
;** C64, etc. support added by David R. Van Wagner davevw.com ***************************************
	and #$7f ; strip mark bit
	cmp #32	; space?
	bne notspace
	lda $FF80 ; Commodore ROM version
	cmp #$16  ; VIC?
	bne notvic
	lda 199
	eor #18	; invert reverse state
	sta 199
	rts
notvic:
    lda #32
notspace:
	jmp CHROUT
;** C64, etc. support added by David R. Van Wagner davevw.com ***************************************
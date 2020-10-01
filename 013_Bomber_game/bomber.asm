    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files with VCS register memory mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare the variables starting from memory address $80
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80

JetXPos         byte         ; player0 x-position
JetYPos         byte         ; player0 y-position
BomberXPos      byte         ; player1 x-position (enemy)
BomberYPos      byte         ; player1 y-position (enemy)
JetSpritePtr    word         ; pointer to player0 sprite lookup table
JetColorPtr     word         ; pointer to player0 color lookup table
BomberSpritePtr word         ; pointer to player1 sprite lookup table
BomberColorPtr  word         ; pointer to player1 color lookup table
JetAnimOffset   byte         ; player0 frame offset for sprite animation

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JET_HEIGHT = 9               ; player0 sprite height (# rows in lookup table)
BOMBER_HEIGHT = 9            ; player1 sprite height (# rows in lookup table)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code at memory address $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START              ; call macro to reset memory and registers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize RAM variables and TIA registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #10
    sta JetYPos              ; JetYPos = 10
    lda #0
    sta JetXPos              ; JetXPos = 0
    lda #83
    sta BomberYPos           ; BomberYPos = 83
    lda #54
    sta BomberXPos           ; BomberXPos = 54

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize pointers to the correct lookup table addresses (little endian arquitecture)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #<JetSprite          
    sta JetSpritePtr         ; lo-byte pointer for jet sprite lookup table
    lda #>JetSprite
    sta JetSpritePtr+1       ; hi-byte pointer for jet sprite lookup table

    lda #<JetColor
    sta JetColorPtr          ; lo-byte pointer for jet color lookup table
    lda #>JetColor
    sta JetColorPtr+1        ; hi-byte pointer for jet color lookup table

    lda #<BomberSprite
    sta BomberSpritePtr      ; lo-byte pointer for enemy sprite lookup table
    lda #>BomberSprite
    sta BomberSpritePtr+1    ; hi-byte pointer for enemy sprite lookup table

    lda #<BomberColor
    sta BomberColorPtr       ; lo-byte pointer for enemy color lookup table
    lda #>BomberColor
    sta BomberColorPtr+1     ; hi-byte pointer for enemy color lookup table

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start the main display loop and frame rendering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations and tasks performed in the pre-VBlank
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda JetXPos
    ldy #0
    jsr SetObjectXPos        ; set player0 horizontal position <jump subroutine>

    lda BomberXPos
    ldy #1
    jsr SetObjectXPos        ; set player1 horizontal position <jump subroutine>

    sta WSYNC
    sta HMOVE                ; apply the horizontal offsets previously set

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display VSYNC and VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK               ; turn on VBLANK
    sta VSYNC                ; turn on VSYNC
    REPEAT 3
        sta WSYNC            ; display 3 recommended lines of VSYNC
    REPEND
    lda #0

    sta VSYNC                ; turn off VSYNC
    REPEAT 37
        sta WSYNC            ; display the 37 recommended lines of VBLANK
    REPEND
    sta VBLANK               ; turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display the 96 visible scanlines of our main game <because 2-line kernel>
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameVisibleLine:
    lda #$84
    sta COLUBK               ; set background/river color to blue
    lda #$C2
    sta COLUPF               ; set playfield/grass color to green
    lda #%00000001
    sta CTRLPF               ; enable playfield reflection
    lda #$F0
    sta PF0                  ; setting PF0 bit pattern
    lda #$FC
    sta PF1                  ; setting PF1 bit pattern
    lda #0
    sta PF2                  ; setting PF2 bit pattern

    ldx #96                  ; X counts the number of remaining scanlines
.GameLineLoop:               ; inside GameVisibleLine label
.AreWeInsideJetSprite:       ; check if should render sprite player0
    txa                      ; transfer X to A
    sec                      ; make sure carry flag is set
    sbc JetYPos              ; subtract sprite Y coordinate
    cmp JET_HEIGHT           ; are we inside the sprite height bounds?
    bcc .DrawSpriteP0        ; if result < SpriteHeight, call subroutine
    lda #0                   ; else, set lookup index to 0
.DrawSpriteP0:
    clc                      ; clears carry flag before addition
    adc JetAnimOffset        ; jumps to correct sprite frame in memory
    tay                      ; load Y so we can work with pointer
    lda (JetSpritePtr),Y     ; load player bitmap slice of data
    sta WSYNC                ; wait for next scanline
    sta GRP0                 ; set graphics for player 0
    lda (JetColorPtr),Y      ; load player color from lookup table
    sta COLUP0               ; set color for player 0 slice

.AreWeInsideBomberSprite:    ; check if should render sprite player1
    txa                      ; transfer X to A
    sec                      ; make sure carry flag is set
    sbc BomberYPos           ; subtract sprite Y coordinate
    cmp BOMBER_HEIGHT        ; are we inside the sprite height bounds?
    bcc .DrawSpriteP1        ; if result < SpriteHeight, call subroutine
    lda #0                   ; else, set index to 0
.DrawSpriteP1:
    tay
    lda #%0000101
    sta NUSIZ1               ; stretch player1 sprite
    lda (BomberSpritePtr),Y  ; load player bitmap slice of data
    sta WSYNC                ; wait for next scanline
    sta GRP1                 ; set graphics for player 0
    lda (BomberColorPtr),Y   ; load player color from lookup table
    sta COLUP1               ; set color for player 0 slice

    dex                      ; X--
    bne .GameLineLoop        ; repeat next main game scanline until finished

    lda #0
    sta JetAnimOffset        ; reset jet animation frame to zero each frame

    sta WSYNC                ; wait for final scanline

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display Overscan
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK               ; turn on VBLANK again
    REPEAT 30
        sta WSYNC            ; display 30 recommended lines of VBlank Overscan
    REPEND
    lda #0
    sta VBLANK               ; turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Process joystick input for player0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckP0Up:
    lda #%00010000           ; player0 joystick up
    bit SWCHA
    bne CheckP0Down          ; if bit pattern doesnt match, bypass Up block
    inc JetYPos
    lda #0
    sta JetAnimOffset        ; reset sprite animation to first frame

CheckP0Down:
    lda #%00100000           ; player0 joystick down
    bit SWCHA
    bne CheckP0Left          ; if bit pattern doesnt match, bypass Down block
    dec JetYPos
    lda #0
    sta JetAnimOffset        ; reset sprite animation to first frame

CheckP0Left:
    lda #%01000000           ; player0 joystick left
    bit SWCHA
    bne CheckP0Right         ; if bit pattern doesnt match, bypass Left block
    dec JetXPos
    lda JET_HEIGHT           ; 9
    sta JetAnimOffset        ; set animation offset to the second frame

CheckP0Right:
    lda #%10000000           ; player0 joystick right
    bit SWCHA
    bne EndInputCheck        ; if bit pattern doesnt match, bypass Right block
    inc JetXPos
    lda JET_HEIGHT           ; 9
    sta JetAnimOffset        ; set animation offset to the second frame

EndInputCheck:               ; fallback when no input was performed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop back to start a brand new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame           ; continue to display the next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to handle object horizontal position with fine offset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; A is the target x-coordinate position in pixels of our object
;; Y is the object type (0:player0, 1:player1, 2:missile0, 3:missile1, 4:ball)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetObjectXPos subroutine
    sta WSYNC                ; start a fresh new scanline
    sec                      ; make sure carry-flag is set before subtraction
.Div15Loop                 
    sbc #15                  ; subtract 15 from accumulator
    bcs .Div15Loop           ; loop until carry-flag is clear
    eor #7                   ; handle offset range from -8 to 7
    asl
    asl
    asl
    asl                      ; four shift lefts to get only the top 4 bits
    sta HMP0,Y               ; store the fine offset to the correct HMxx
    sta RESP0,Y              ; fix object position in 15-step increment
    rts                      ; return to the memory address that called the subroutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare ROM lookup tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JetSprite:
    .byte #%00000000         ;
    .byte #%00010100         ;   # #
    .byte #%01111111         ; #######
    .byte #%00111110         ;  #####
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #

JetSpriteTurn:
    .byte #%00000000         ;
    .byte #%00001000         ;    #
    .byte #%00111110         ;  #####
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #

BomberSprite:
    .byte #%00000000         ;
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00101010         ;  # # #
    .byte #%00111110         ;  #####
    .byte #%01111111         ; #######
    .byte #%00101010         ;  # # #
    .byte #%00001000         ;    #
    .byte #%00011100         ;   ###

JetColor:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$BA
    .byte #$0E
    .byte #$08

JetColorTurn:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$0E
    .byte #$0E
    .byte #$08

BomberColor:
    .byte #$00
    .byte #$32
    .byte #$32
    .byte #$0E
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size with exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC                ; move to position $FFFC
    word Reset               ; write 2 bytes with the program reset address
    word Reset               ; write 2 bytes with the interruption vector
    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files with register mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start an uninitialized segment at $80 for var declaration.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables ; define variable names
    org $80         ; we usually start our segment in this location memory 
P0Height .byte      ; defines one byte for player 0 height
P1Height .byte      ; defines one byte for player 1 height

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code segment starting at $F000.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START    ; macro to clean memory and TIA

    ldx #$80       ; blue background color
    stx COLUBK

    lda #%1111     ; white playfield color
    sta COLUPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize P0Height and P1Height with the value 10.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #10        ; A = 10
    sta P0Height   ; P0Height = A
    sta P1Height   ; P1Height = A

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; We set the TIA registers for the colors of P0 and P1.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #$48       ; player 0 color light red
    sta COLUP0

    lda #$C6       ; player 1 color light green
    sta COLUP1

    ldy #%00000010 ; CTRLPF D1 set to 1 means (score)
    sty CTRLPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by configuring VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:
    lda #2
    sta VBLANK     ; turn VBLANK on
    sta VSYNC      ; turn VSYNC on

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 3
        sta WSYNC  ; first three VSYNC scanlines
    REPEND

    lda #0
    sta VSYNC      ; turn VSYNC off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the 37 recommended lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 37
        sta WSYNC
    REPEND

    lda #0
    sta VBLANK     ; turn VBLANK off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the 192 visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VisibleScanlines:

    ; Draw 10 empty scanlines at the top of the frame
    REPEAT 10
        sta WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Displays 10 scanlines for the scoreboard number.
;; Pulls data from an array of bytes defined at NumberBitmap.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldy #0
ScoreboardLoop:
    lda NumberBitmap,Y
    sta PF1                 ; Score in the middle
    sta WSYNC
    iny
    cpy #10                 ; y == 10 (?)
    bne ScoreboardLoop      ; loop if y != 10

    lda #0
    sta PF1        ; disable playfield

    ; Draw 50 empty scanlines between scoreboard and and player
    REPEAT 50
        sta WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Displays 10 scanlines for the Player 0 graphics.
;; Pulls data from an array of bytes defined at PlayerBitmap.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldy #0
Player0Loop:
    lda PlayerBitmap,Y
    sta GRP0
    sta WSYNC
    iny
    cpy P0Height
    bne Player0Loop

    lda #0
    sta GRP0       ; disable player 0 graphics

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Displays 10 scanlines for the player 1 graphics.
;; Pulls data from an array of bytes defined at PlayerBitmap.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldy #0
Player1Loop:
    lda PlayerBitmap,Y
    sta GRP1
    sta WSYNC
    iny
    cpy P1Height
    bne Player1Loop

    lda #0
    sta GRP1       ; disable player 1 graphics

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the remaining 102 scanlines (192-90), since we already
;; used 10+10+50+10+10=90 scanlines in the current frame.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 102
        sta WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK overscan lines to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 30
        sta WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Defines an array of bytes to draw the scoreboard number.
;; We add these bytes in the last ROM addresses.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFE8
PlayerBitmap:
    .byte #%01111110   ;  ######
    .byte #%11111111   ; ########
    .byte #%10011001   ; #  ##  #
    .byte #%11111111   ; ########
    .byte #%11111111   ; ########
    .byte #%11111111   ; ########
    .byte #%10111101   ; # #### #
    .byte #%11000011   ; ##    ##
    .byte #%11111111   ; ########
    .byte #%01111110   ;  ######

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Defines an array of bytes to draw the scoreboard number.
;; We add these bytes in the final ROM addresses.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFF2
NumberBitmap:
    .byte #%00001110   ; ########
    .byte #%00001110   ; ########
    .byte #%00000010   ;      ###
    .byte #%00000010   ;      ###
    .byte #%00001110   ; ########
    .byte #%00001110   ; ########
    .byte #%00001000   ; ###
    .byte #%00001000   ; ###
    .byte #%00001110   ; ########
    .byte #%00001110   ; ########

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    .word Reset
    .word Reset
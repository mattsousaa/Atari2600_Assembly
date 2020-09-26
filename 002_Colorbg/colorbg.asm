;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Initial configuration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    processor 6502

    include "vcs.h"
    include "macro.h"

    seg code
    org $F000       ; defines the origin of the ROM at $F000

START:
    CLEAN_START     ; Macro to safely clear the memory (clear the screen with 0 - black)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set background luminosity color to yellow
; Visit https://en.wikipedia.org/wiki/List_of_video_game_console_palettes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #$1E        ; Load color into A ($1E is NTSC yellow)
    sta COLUBK      ; Store A to memory address $09 (TIA COLUBK)

    jmp START       ; Repeat from START

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM size to exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC      ; Defines origin to $FFFC
    .word START    ; Reset vector at $FFFC (where program starts)
    .word START    ; Interrupt vector at $FFFE (unused by the VCS)
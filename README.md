# Learn Assembly Language by Making Games for the Atari 2600
Activities carried out during the [Assembly course for Atari 2600](https://courses.pikuma.com/courses/atari2600) with the 6052 processor. First of all, thank you Gustavo Pezzi for taking my fear out of the Assembly language during the course and making me understand such important concepts of computer architecture. It was certainly one of the best courses I ever took to understand concepts learned during Computer Engineering faculty here in Brazil. My professors at the university always made me afraid to program in Assembly. During the course, I understood that the language is not as complicated as I thought. Thanks again, Gusttavo. The concepts passed on in the course helped me a lot to connect concepts in embedded systems.

## Preparation of the environment

First, choose an IDE of your choice. During the course, I used [VSCode](https://code.visualstudio.com/). Gustavo, in turn, used [Vim](https://vim.fandom.com/wiki/Use_Vim_like_an_IDE). After that, download the DASM assembler for 8-bit architectures available in the references link. On Linux, for example, rename the **dasm.Linux.x86** file and copy it to the path:

```
$ sudo cp dasm /usr/local/bin
```

This command allows you to use the DASM assembler from anywhere via the terminal. Through this brief presentation, it will be possible to compile all the programs through the Makefiles existing in each of the folders. After that, download the **Stella emulator** to run the programs. The emulator can be downloaded using the references below. After that, run the installation command:

```
$ sudo dpkg -i stella_6.2.1-1_amd64.deb
```

The example above was an installation for the Ubuntu 20.04 system. For installation on other systems, refer to the emulator reference manual. If you don't prefer to run the codes on the machine, you can also run them in online IDEs like [Javatari](https://javatari.org/) or [8bitworkshop](https://8bitworkshop.com/v3.6.0/?file=examples%2Fhello.a&platform=vcs).

## Final project

After several lessons of Assembly language for 6502, it is proposed to carry out a final project. The project can be consulted in the archive [bomber.asm](https://github.com/mattsousaa/Atari2600_Assembly6502/blob/master/013_Bomber_game/bomber.asm). In this project, a bomber game focused on the logic of language is carried out. Below is a gif of the final project. As can be seen, the **jet** is able to move in all possible directions and also launches shots. The **bomber** appears in random positions defined in the code. It is not possible to predict its position immediately. The top left on the top is the **score** that the player makes when shooting the **bomber** and on the right is the **execution time** (simulated). A **game over** situation is simulated when the **jet** hits the **bomber** and fills the **screen in red**. After that, the **scoreboard** is restarted.

![Alt Text](https://github.com/mattsousaa/Atari2600_Assembly6502/blob/master/013_Bomber_game/stella.gif)

Also remembering that sounds can be enabled in the game. The sounds made imitate the airplane's turbine. Uncomment the code blocks below:

* **1st Code snippet:**
   ```assembly
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Calculations and tasks performed in the VBlank
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
         lda JetXPos
         ldy #0
         jsr SetObjectXPos        ; set player0 horizontal position <jump subroutine>

         lda BomberXPos
         ldy #1
         jsr SetObjectXPos        ; set player1 horizontal position <jump subroutine>

         lda MissileXPos
         ldy #2
         jsr SetObjectXPos        ; set missile horizontal position <jump subroutine>

         jsr CalculateDigitOffset ; calculate scoreboard digits lookup table offset

         jsr GenerateJetSound     ; configure and enable our jet engine audio 

         sta WSYNC
         sta HMOVE                ; apply the horizontal offsets previously set

         lda #0
         sta VBLANK               ; turn off VBLANK
    
    ```
* **2st Code snippet:**
    ```assembly
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Generate audio for the jet engine sound based on the jet y-position
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; The frequency/pitch will be modified based on the jet current y-position.
    ;; Normally, the TIA audio frequency goes from 0 (highest) to 31 (lowest).
    ;; We subtract 31 - (JetYPos/8) to achieve the desired final pitch value.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    GenerateJetSound subroutine
        lda #3
        sta AUDV0                ; set the audio volume register

        lda #8                   ; white noise (explosions)
        sta AUDC0                ; set the audio control register to white noise

        lda JetYPos              ; loads the accumulator with the jet y-position
        lsr
        lsr
        lsr                      ; divide the accumulator by 8 (using right-shifts)
        sta Temp                 ; save the Y/8 value in a temp variable
        lda #31
        sec
        sbc Temp                 ; subtract 31-(Y/8)
        sta AUDF0                ; set the audio frequency/pitch register

        rts
    
    ```
    
## References
### Websites
* [Pikuma: 6502 Assembly Language for the Atari 2600](https://courses.pikuma.com/courses/atari2600)
* [DASM: 8-bit macro assembler](https://dasm-assembler.github.io/)
* [Instructions and Opcodes for 6502](http://www.6502.org/tutorials/6502opcodes.html)
* [Stella: A multi-plataform Atari 2600 VCS emulator](https://stella-emu.github.io/)
* [Javatari: The online Atari 2600 emulator](https://javatari.org/)
* [8-bit code IDE in your browser](https://8bitworkshop.com/v3.6.0/?file=examples%2Fhello.a&platform=vcs)
* [Editor for atari 2600 graphics](https://alienbill.com/2600/playerpalnext.html)
* [Asymetric Playfield TIA timing](https://www.randomterrain.com/atari-2600-lets-make-a-game-spiceware-03.html) 
* [Gopher 2600 VCS Emulator](https://github.com/JetSetIlly/Gopher2600)
* [AtariAge forum](https://atariage.com/forums/)

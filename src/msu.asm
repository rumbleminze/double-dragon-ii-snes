.segment "PRGB2"

; Audio Tracks for Double Dragon II
; NES value - track
; 01 - music (title, loops)
; 02 - music (level 2, loops)
; 03 - music (level 1, loops)
; 04 - music (level 5, loops)
; 05 - music (level 8, loops)
; 06 - music (level 7, loops)
; 07 - music (level 6, loops)
; 08 - music (Stage Boss, loops)
; 09 - music (level 5 boss (tractor), loops)
; 0a - music (stage end, doesn't loop, probably needs a timer)
; 0b - music (ending?  wasn't seen but same as 13)
; 0c - music (final boss part 1, loops)
; 0d - music (Shadow Fight, loops)
; 0e - music (level load cutscene, loops?)
; 0f - music (level 3, loops)

; 10 - music (level 4, loops)
; 11 - music (final boss part 2, loops)
; 12 - music (death, doesn't loop)
; 13 - music (ending part 1, loops?)
; 14 - music (credits, loops?)

; 15+ SFX

; 4C - Punch
; 4D - Kick
; 1C - Spinning Jump Kick
; 1D - Jump
; 1E - Flying knee

.DEFINE NUM_TRACKS        $14

; Read Flags
.DEFINE MSU_STATUS      $2000
.DEFINE MSU_READ        $2001
.DEFINE MSU_ID          $2002   ; 2002 - 2007

; Write flags
.DEFINE MSU_SEEK        $2000
.DEFINE MSU_TRACK       $2004   ; 2004 - 2005
.DEFINE MSU_VOLUME      $2006
.DEFINE MSU_CONTROL     $2007

; game specific flags, needs to be updated
.DEFINE NSF_STOP        #$00
.DEFINE NSF_PAUSE       #$FD ; 
.DEFINE NSF_RESUME      #$FF ; 
.DEFINE NSF_MUTE        #$00

; this duplicates the logic that we normally execute when
; 0 is set as the song to play.  We
double_dragon_2_mute_nsf_copy:
  LDA #$8D
  STA $07F0
  LDA #$40
  STA $07F2
  LDA #$60
  STA $07F3

  LDA MSU_PLAYING
  ORA $07FE
  STA $07FE

  RTL


play_track_hijack:
    STA $07FF
    bne :+
    ; 00 is no sound, and the game takes care of stopping
    ; so we can return.  We'll also return 00 if we're going to play
    ; msu-1
      rtl
  :
    PHA
    jsl msu_check
    BEQ :+
    ; non-0 value returned from MSU-check, we're not playing MSU
    ; either it's not a music track or we don't have it.
    ; return the original value
    PLA
    rtl

:   
;   00 returned from msu_check, mute nsf and return the mute value
    PLA
    LDA NSF_MUTE
    STA $07FF

    rtl


wait_a_frame:
  LDA RDNMI
: LDA RDNMI
  BPL :-
  rts


check_for_all_tracks_present:
  PHB
  LDA #$B2
  PHA
  PLB
  LDA MSU_ID		; load first byte of msu-1 identification string
  CMP #$53		    ; is it "M" present from "MSU-1" string?
  BEQ :+
  PLB
  RTL ; no MSU exit early

: STZ MSU_VOLUME
  LDY #NUM_TRACKS
  INY
: 
  jsr wait_a_frame
  STZ MSU_CONTROL

  DEY
  BMI :+
  
  LDA #$00
  STA TRACKS_AVAILABLE, Y
  STA TRACKS_ENABLED, Y

  TYA
  STA MSU_TRACK
  STZ MSU_TRACK + 1 

  msu_status_check:
    LDA MSU_STATUS
    AND #$40
    BNE msu_status_check
  ; LDA #$FF
  ; :		; check msu ready status (required for sd2snes hardware compatibility)
  ;   bit MSU_STATUS
  ;   bvs :-

  LDA MSU_STATUS ; load track STAtus
  AND #$08		; isolate PCM track present byte
        		; is PCM track present after attempting to play using STA $2004?
  
  BNE :-
  LDA #$01
  STA TRACKS_AVAILABLE, Y  
  STA TRACKS_ENABLED, Y
  BRA :-
: 
  LDA #$01
  STA MSU_SELECTED
  PLB
  RTL

;org $E2F5F5
; stop_nsf:
;   LDX #$00		; native code
;   LDY #$00		; native code
;   PHA
;   LDA CURRENT_NSF		; load currently playing msu-1 track
;   CMP #$5B		; is it the Title Screen?
;   BNE skip_mute
;   STZ MSU_CONTROL		; mute msu-1 (from title screen)
; skip_mute:
;   PLA
;   RTL

; Checks for MSU track for audio track in Accumulator
msu_check:
  PHB
  PHK
  PLB
  PHY
  PHX
  PHA  

  LDA MSU_SELECTED
  BEQ fall_through


  LDA MSU_ID		; load first byte of msu-1 identification string
  CMP #$53		    ; is it "M" present from "MSU-1" string?
  BNE fall_through  ; No MSU-1 support, fall back to NSF
  
  ; check if we have a track for this value

  PLA
  PHA
      ; CMP NSF_STOP
      ; BEQ stop_msu

      CMP NSF_PAUSE
      BEQ pause_msu

      CMP NSF_RESUME
      BEQ resume_msu
  TAY
  LDA msu_track_lookup, Y
  CMP #$FF
  BEQ fall_through
  
  TAY
  LDA TRACKS_ENABLED, Y
  BEQ fall_back_to_nsf

  PLA
  CMP CURRENT_NSF
  BEQ already_playing
  STA CURRENT_NSF		; store current nsf track-id for later retrieval
  PHA

  TYA

  ; non-FF value means we have an MSU track
  BRA msu_available

fall_back_to_nsf:
  bra stop_msu

stop_msu:
; is msu playing?  if not, just exit
    LDA MSU_PLAYING
    BEQ fall_through
    STZ MSU_CONTROL
    STZ MSU_CURR_CTRL    
    STZ MSU_PLAYING
    BRA fall_through

pause_msu:
    LDA MSU_PLAYING
    BEQ fall_through
    STZ MSU_CONTROL
    STZ MSU_CURR_CTRL
    BRA fall_through

resume_msu:
    LDA MSU_PLAYING
    BEQ fall_through
    LDA MSU_TRACK_IDX
    TAY
    LDA TRACKS_ENABLED, y
    beq fall_through
    LDA msu_track_loops, Y
    STA MSU_CONTROL
    STA MSU_CURR_CTRL

  ; fall through to default
fall_through:
  PLA
  PLX
  PLY
  PLB
  RTL

already_playing:
  PLX
  PLY
  PLB
  LDA NSF_MUTE ; set nsf music to mute since we are playing msu  
  rtl

pause_msu_only:
  PHB
  PHK
  PLB
  PHY
  PHX
  PHA  

  LDA MSU_SELECTED
  BEQ fall_through


  LDA MSU_ID		; load first byte of msu-1 identification string
  CMP #$53		    ; is it "M" present from "MSU-1" string?
  BNE fall_through  ; No MSU-1 support, fall back to NSF
  BRA pause_msu


resume_msu_only:
  PHB
  PHK
  PLB
  PHY
  PHX
  PHA  

  LDA MSU_SELECTED
  BEQ fall_through

  LDA MSU_ID		; load first byte of msu-1 identification string
  CMP #$53		    ; is it "M" present from "MSU-1" string?
  BNE fall_through  ; No MSU-1 support, fall back to NSF
  BRA resume_msu

stop_msu_only:
  PHB
  PHK
  PLB
  PHY
  PHX
  PHA  

  LDA MSU_SELECTED
  BEQ fall_through

  LDA MSU_ID		; load first byte of msu-1 identification string
  CMP #$53		    ; is it "M" present from "MSU-1" string?
  BNE fall_through  ; No MSU-1 support, fall back to NSF
  BRA stop_msu

  ; if msu is present, process msu routine
msu_available:
  TAY
  PLA
  PHY                   ; push the MSU-1 track 
  PHA                   ; repush the NSF track

  LDA #$00		        ; clear disable/enable nsf music flag
  STA MSU_PLAYING		; clear disable/enable nsf music flag

  PLA
  STA CURRENT_NSF		; store current nsf track-id for later retrieval

  LDA #$01
  STA MSU_TRIGGER
  LDA #$02          ; use #$02 for convience so we can ORA with it for "song playing" in DD2 sound engine		       
  STA MSU_PLAYING		; set mute NSF flag (writing 02 in RAM location)

  pla
  STA MSU_TRACK_IDX		; store current re-mapped nsf track-id for later retrieval
  STA MSU_TRACK		    ; store current valid NSF track-ID
  stz MSU_TRACK + 1	    ; must zero out high byte or current msu-1 track will not play !!!

  ; jsl msu_nmi_check
  PLX
  PLY
  PLB
  LDA NSF_MUTE ; set nsf music to mute since we are playing msu  

  RTL

:
  LDA MSU_CURR_VOLUME
  STA MSU_VOLUME
  RTL

msu_nmi_check:

  jsr decrement_timer_if_needed
  
  LDA MSU_TRIGGER
  BEQ :-
  LDA MSU_STATUS
  AND #$40
  BNE :-
  LDA MSU_STATUS

  PHB
  PHK
  PLB
  STZ MSU_TRIGGER

  LDA MSU_TRACK_IDX ; pull the current MSU-1 Track
  TAY
  LDA msu_track_loops, Y
  STA MSU_CONTROL		; write current loop value
  STA MSU_CURR_CTRL
  LDA msu_track_volume, Y
  STA MSU_VOLUME		; write max volume value
  STA MSU_CURR_VOLUME
  
  jsr set_timer_if_needed
  PLB
  RTL


check_if_msu_is_available:
  STZ MSU_AVAILABLE
  LDA MSU_ID
  CMP #$53
  BNE :+
    LDA #$01
    STA MSU_AVAILABLE
  : 
  rtl

  
set_timer_if_needed:  
  PHB
  PHK
  PLB
  LDA $00
  PHA
  LDA $01
  PHA

  LDA MSU_TRACK_IDX
  ASL a
  TAY

  LDA track_timers, Y
  STA $00
  INY 
  LDA track_timers, y
  STA $01
  
  LDY #$01
  ; the high bit of the timer is always != 0
  LDA ($00),Y
  BEQ :+

    STA MSU_TIMER_HB
    DEY
    LDA ($00),Y
    STA MSU_TIMER_LB
    STZ MSU_TIMER_INDX
    INC MSU_TIMER_ON
    
  :

  PLA
  STA $01
  PLA
  STA $00
  PLB
  rts

decrement_timer_if_needed:
  LDA MSU_TIMER_ON
  BEQ :++

  setAXY16
  DEC MSU_TIMER_LB
  setAXY8

  BNE :++

  PHB
  PHK
  PLB

  LDA $00
  PHA
  LDA $01
  PHA

  STZ MSU_TIMER_ON
  LDA $07FE
  AND #$BD
  STA $07FE

  ; LDA #$01
  ; STA $E0
  ; INC MSU_TIMER_INDX

  LDA MSU_TRACK_IDX
  ASL
  TAY
  LDA track_timers, Y
  STA $00
  INY 
  LDA track_timers, y
  STA $01

  LDA MSU_TIMER_INDX
  ASL
  INC A
  TAY
  LDA ($00),Y
  beq :+

    STA MSU_TIMER_HB
    DEY
    LDA ($00),Y
    STA MSU_TIMER_LB
    INC MSU_TIMER_ON
  :
  
  PLA
  STA $01
  PLA
  STA $00
  PLB
: 
  rts
; this 0x100 byte lookup table maps the NSF track to the MSU-1 track
; MSU Index - NES value - track
; 00        - 01        - music (title, loops)
; 01        - 0E        - music (level load cutscene, loops)
; 02        - 03        - music (level 1, loops)
; 03        - 08        - music (Stage Boss, loops)
; 04        - 0A        - music (stage end, doesn't loop, probably needs a timer)
; 05        - 02        - music (level 2, loops)
; 06        - 0F        - music (level 3, loops)
; 07        - 10        - music (level 4, loops)
; 08        - 04        - music (level 5, loops)
; 09        - 09        - music (level 5 boss (tractor), loops)
; 0A        - 07        - music (level 6, loops)
; 0B        - 06        - music (level 7, loops)
; 0C        - 05        - music (level 8, loops)
; 0d        - 0D        - music (Shadow Fight, loops)
; 0e        - 0C        - music (final boss part 1, loops)
; 0f        - 11        - music (final boss part 2, loops)
;
; 10        - 13        - music (ending part 1, loops?)
; 11        - 14        - music (credits, loops?)
; 12        - 12        - music (death, doesn't loop)

; 00        - 0B        - music (ending?  wasn't seen but same as 13)

; unused but marked as supported so it shuts off MSU when played


msu_track_lookup:
.byte $FF, $00, $05, $02, $08, $0C, $0B, $0A, $03, $09, $04, $FF, $0E, $0D, $01, $06
.byte $07, $0F, $12, $10, $11, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

; this 0x100 byte lookup table maps the NSF track to the if it loops ($03) or no ($01)
msu_track_loops:
.byte $03, $03, $03, $03, $01, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
.byte $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

; this 0x100 byte lookup table maps the NSF track to the MSU-1 volume ($FF is max, $4F is half)
msu_track_volume:
.byte $b5, $b5, $b6, $d5, $d4, $b5, $b5, $b5, $b6, $b6, $b5, $b5, $b5, $eb, $c1, $bc
.byte $B5, $B5, $B8, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F
.byte $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F, $4F


msu_track_e0_delay_options:
.word $0100, $068B, $0f4a

track_timers:
.addr no_timer            ; 
.addr no_timer            ; 
.addr no_timer            ; 
.addr no_timer            ; 
.addr end_of_level_timer  ; 04 - Level Clear
.addr no_timer            ; 
.addr no_timer            ; 
.addr no_timer            ; 
.addr no_timer            ; 
.addr no_timer            ; 
.addr no_timer            ; 
.addr no_timer            ; 
.addr no_timer            ; 
.addr no_timer            ; 
.addr no_timer            ; 
.addr no_timer            ; 

.addr no_timer            ; 
.addr no_timer            ; 
.addr game_over_timer     ; 

no_timer:
.word $0000               ; 
end_of_level_timer:
.word $014A, $0000        ; End of Level         - 0D
game_over_timer:
.word $0100, $0000
; sets up a black window on the left column of the screen
setup_hide_left_8_pixel_window:
    LDA #$11
    STA TMW

    ; Window 1 Left
    LDA #$00
    STA WH0

    LDA #$08
    STA WH1

    LDA #%10101010
    STA WBGLOG

    LDA #%00001010
    STA WOBJLOG

    LDA #$02
    STA W12SEL
    STA WOBJSEL
    
    jslb disable_hide_left_8_pixel_window, $a0
    rts

enable_hide_left_8_pixel_window:
    LDA #$11
    STA TMW

    RTL

disable_hide_left_8_pixel_window:
    LDA #$00
    STA TMW
    RTL
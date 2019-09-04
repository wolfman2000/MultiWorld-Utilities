SpiralWarp:
{

    pha : lda $040c : cmp.b #$ff : beq .abort ; abort if not in dungeon
    cmp #$06 : bcs .abort ; abort if not supported yet -- todo: this needs to be altered/removed as more dungeons are implemented
    lda $0e : cmp #$5e : beq .gtg ; abort if not spiral - intended room is in A!
    cmp #$5f : beq .gtg
    .abort pla : sta $a0 : bra .end

    .gtg
    pla
    phb : phk : plb : phx : phy ; push stuff
    jsr LookupSpiralOffset
    rep #$30 : and #$00FF : asl #2 : tax
    lda SpiralTable, x : sta $00
    lda SpiralTable+2, x : sta $02
    sep #$30
    lda $00 : sta $a0
    ; shift quadrant if necessary
    lda $01 : and #$01 : !sub $a9
    beq .skipXQuad
    sta $06 : !add $a9 : sta $a9
    ldy #$00 : jsr ShiftQuadSimple

    .skipXQuad
    lda $01 : and #$02 : lsr : sta $06 : lda $aa : lsr : !sub $06
    beq .skipYQuad
    sta $06 : asl : !add $aa : sta $aa
    ldy #$01 : jsr ShiftQuadSimple

    .skipYQuad
    ; shift lower coordinates
    lda $02 : sta $22
    lda $03 : sta $20

    ldy #$00 : jsr SetCamera ; todo: figure out camera jazz
    ldy #$01 : jsr SetCamera

    ply : plx : plb ; pull the stuff we pushed

    .end
    ; this is the code we are hijacking
    ; lda $a0 - we overwrote this behavior
    lda $063d, x
    rtl
}

;Sets the offset in A
LookupSpiralOffset:
{
    ;where link currently is in $a2: quad in a8 & #$03
    ;count doors
    stz $00 : ldx #$00 : stz $01

    .loop
    lda $047e, x : cmp $00 : bcc .continue
    sta $00
    .continue inx #2
    cpx #$08 : bcc .loop

    lda $00 : lsr
    cmp #$01 : beq .done

    ; look up the quad
    lda $a8 : and #$03 : beq .quad0
    cmp #$01 : beq .quad1
    cmp #$02 : beq .quad2
    cmp #$03 : beq .quad3
    .quad0
    inc $01 : lda $22 : cmp #$98 : bcc .done ;gt ent and hc stairwell
    inc $01 : bra .done
    .quad1
    lda $22 : cmp #$78 : bcc .done ;swamp/pod dual stairs
    inc $01 : bra .done
    .quad2    ;ice room
    lda #$03 : sta $01
    lda $22 : cmp #$78 : bcc .done
    inc $01 : bra .done
    .quad3 lda #$02 : sta $01 ; always 2

    .done
    lda $a2 : tax : lda SpiralOffset,x
    !add $01 ;add a thing (0 in .easy)
    rts
}

ShiftQuadSimple:
{
	lda CoordIndex,y : tax
	lda $21,x : !add $06 : sta $21,x ; coordinate update
	lda CamQuadIndex,y : tax
	lda $0601,x : !add $06 : sta $0601,x
	lda $0605,x : !add $06 : sta $0605,x ; high bytes of these guys
	rts
}

SetCamera:
{
    stz $04 : sty $05
    lda $01 : and #$10 : !add $05 : cmp #$10 : beq .done ; zeroHzCam check (10+0 = 10)
    lda $01 : and #$20 : !add $05 : cmp #$21 : beq .done ; zeroVtCam check (20+1 = 21)

    tyx : lda $a9,x : bne .nonZeroHalf
    lda CamQuadIndex,y : tax : lda $607,x : pha
    lda CameraIndex,y : tax : pla : cmp $e3, x : bne .noQuadAdj
    dec $e3,x

    .noQuadAdj
    lda CoordIndex,y : tax
    lda $20,x : cmp #$79 : bcc .adjust
    !sub #$78 : sta $04 : bra .adjust

    .nonZeroHalf ;meaning either right half or bottom half
    lda CoordIndex,y : tax
    lda $20,x : cmp #$78 : bcs .setQuad
    !add #$78 : sta $04 : bra .adjust

    .setQuad
    lda CamQuadIndex,y : tax : lda $0607, x : pha
    lda CameraIndex,y : tax : pla : sta $e3, x : bra .done

    .adjust
    lda CameraIndex,y : tax
    .done lda $04 : sta $e2,x
    rts
}
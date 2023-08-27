//-----------Segments------------
	.disk [filename="game.d64", name="GAME DISK"]
	{
		[name="----------------", type="rel"				 ],
		[name="GAME", 			  type="prg", segments="Code"],
		[name="----------------", type="rel"				 ],
	}

	.segmentdef Code [start=$0810]
	.segmentdef Buffer [start=$8000]
	.segmentdef Variables [start=$8600]

	.segment Code

	.const charmem = $0400
	.const buffer  = $8000
	
	.const plrx = $8400
	.const plry = $8401
	.const oplrx = $8402
	.const oplry = $8403

	.label ZP = $fb
	.label ARG1 = $fd
	.label ARG2 = $fe
	.label SCNKEY  = $ff9f
	.label GETIN   = $ffe4

//------------Program------------
	*=$8600
screenRowLUTLo:
	.for (var ue = buffer; ue < buffer + $400; ue += 40) {
		.byte <ue
	}
screenRowLUTHi:
	.for (var ue = buffer; ue < buffer + $400; ue += 40) {
		.byte >ue
	}

	*=$0810
	BasicUpstart2(main)
main:
	// Clear buffer
	jsr clearBuffer

	// Disable keyboard stuff
	mov #1 : $0289
	mov #127 : $028a

	// Set background and foreground
	mov #0 : $d020
	mov #0 : $d021

	// Set Interrupt Handling
	sei
	lda #<irq1
	sta $0314
	lda #>irq1
	sta $0315
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda #$81
	sta $d01a
	lda #$1b
	sta $d011
	lda #$80
	sta $d012
	lda $dc0d
	lda $dd0d
	asl $d019
	cli

	// Set player defaults
	mov #3 : plrx
	mov #3 : plry
	mov plrx : oplrx
	mov plry : oplry

	// Draw Line
	mov #13 : ARG1
	lda #$A0
	ldx #0
	ldy #0
	jsr drawHLine
	mov #13 : ARG1
	lda #$A0
	ldx #0
	ldy #0
	jsr drawVLine
	mov #13 : ARG1
	lda #$A0
	ldx #12
	ldy #0
	jsr drawHLine
	mov #13 : ARG1
	lda #$A0
	ldx #0
	ldy #12
	jsr drawVLine

	// Main loop
loop:
	// Check Keypress
	jsr SCNKEY
	jsr GETIN

	// Is Right
down:
	cmp #$53
	bne up
	mov plry : oplry
	mov plrx : oplrx
	inc plry
up:
	cmp #$57
	bne left
	mov plry : oplry
	mov plrx : oplrx
	dec plry
left:
	cmp #$41
	bne right
	mov plry : oplry
	mov plrx : oplrx
	dec plrx
right:
	cmp #$44
	bne loop_end
	mov plry : oplry
	mov plrx : oplrx
	inc plrx

loop_end:
	// drawChar(5, 5, '@')
	lda #'@'
	ldy plrx
	ldx plry
	jsr drawChar

	lda #' '
	ldy oplrx
	ldx oplry
	jsr drawChar
	jmp loop

//-----------Interrupt-----------
irq1:
	// Acknowledge interrupt
	asl $d019

	// Draw buffer to screen
	jsr drawBuffer

	// End Interrupt
	jmp $ea81

//--------Pseudo Commands--------
.pseudocommand mov src:tar {
	lda src
	sta tar
}

//----------Subroutines----------
.macro drawRect(px, py, width, height) {
	lda #'o'
	.for(var x=0; x<width; x++){
		.for(var y=0; y<height; y++) {
			sta buffer + (((y+py) * 40) + (px+x))
		}
	}
}

// Draws horizontal line
// A - Character
// X - Y position
// Y - X position
// ARG1 - Length
drawHLine: {
loop:
	jsr drawChar
	iny
	dec ARG1
	bne loop
	rts
}

// Draws horizontal line
// A - Character
// X - Y position
// Y - X position
// ARG1 - Length
drawVLine: {
loop:
	jsr drawChar
	inx
	dec ARG1
	bne loop
	rts
}

// Draws a character at a set position on screen
// A - Character to draw
// X - Y position to draw at
// Y - X position to draw at
drawChar: {
	pha
	lda screenRowLUTLo,x
	sta ZP
	lda screenRowLUTHi,x
	sta ZP+1
	pla
	sta (ZP),y
	rts
}

// Draw contents of buffer to screen
drawBuffer: {
	ldx #0

loop:
	mov buffer,x : charmem, x
	mov buffer+$100,x : charmem+$100, x
	mov buffer+$200,x : charmem+$200, x
	mov buffer+$300,x : charmem+$300, x
	inx
	bne loop

	rts
}

// Clear contents of buffer
clearBuffer: {
	ldx #0
	lda #' '

loop:
	sta buffer, x
	sta buffer+$100, x
	sta buffer+$200, x
	sta buffer+$300, x
	inx
	bne loop

	rts
}

//------------Buffer-------------
	.segment Buffer
table:	.fill $3c0, 0

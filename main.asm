//-----------Segments------------
	.disk [filename="game.d64", name="GAME DISK"]					// Create disk (d64) image
	{
		[name="----------------", type="rel"				 ],		// For styling
		[name="GAME", 			  type="prg", segments="Code"],		// Add Code segment
		[name="----------------", type="rel"				 ],		// For styling
	}

	.segmentdef Code [start=$0810]									// Define Code segment
	.segmentdef Buffer [start=$8000]								// Define Buffer segment
	.segmentdef Variables [start=$9000]								// Define Variables segment

	.segment Code													// Start code segment

	// Memory Locations
	.const charmem = $0400											// Character memory
	.const colmem = $d800											// Colour memory
	.const buffer  = $8000											// Character buffer
	
	// Player variables
	.const plrx = $9000												// Player X position
	.const plry = $9001												// Player Y position
	.const oplrx = $9002											// Player old X position
	.const oplry = $9003											// Player old Y position

	// More memory locations
	.label AP = $f9													// Argument pointer
	.label ZP = $fb													// Zero Page pointer
	.label ARG1 = $fd												// Subroutine argument 1
	.label ARG2 = $fe												// Subroutine argument 2
	.label SCNKEY  = $ff9f											// ScanKey kernel subroutine
	.label GETIN   = $ffe4											// GetIn kernel subroutine

//------------Program------------
	*=$9600
name:	.text "name"
hp:   	.text "hp"
p1n:  	.text "nyx"
p1hp: 	.text "10"

	*=$9400
screenRowLUTLo:
	.for (var ue = buffer; ue < buffer + $400; ue += 40) {
		.byte <ue
	}
screenRowLUTHi:
	.for (var ue = buffer; ue < buffer + $400; ue += 40) {
		.byte >ue
	}
colourRowLUTLo:
	.for (var ue = colmem; ue < colmem + $400; ue += 40) {
		.byte <ue
	}
colourRowLUTHi:
	.for (var ue = colmem; ue < colmem + $400; ue += 40) {
		.byte >ue
	}

	*=$0810
	BasicUpstart2(main)
main:
	// Clear buffer
	jsr clearBuffer
	jsr clearColBuffer

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

	// Draw borders
	mov #40 : ARG1
	lda #$e6
	ldx #0
	ldy #0
	jsr drawHLine
	mov #40 : ARG1
	lda #$09
	ldx #0
	ldy #0
	jsr colourHLine

	mov #24 : ARG1
	lda #$e6
	ldx #0
	ldy #0
	jsr drawVLine
	mov #24 : ARG1
	lda #$09
	ldx #0
	ldy #0
	jsr colourVLine

	mov #24 : ARG1
	lda #$e6
	ldx #0
	ldy #39
	jsr drawVLine
	mov #24 : ARG1
	lda #$09
	ldx #0
	ldy #39
	jsr colourVLine

	mov #40 : ARG1
	lda #$e6
	ldx #12
	ldy #0
	jsr drawHLine
	mov #40 : ARG1
	lda #$09
	ldx #12
	ldy #0
	jsr colourHLine

	mov #13 : ARG1
	lda #$e6
	ldx #0
	ldy #12
	jsr drawVLine
	mov #13 : ARG1
	lda #$09
	ldx #0
	ldy #12
	jsr colourVLine

	mov #40 : ARG1
	lda #$e6
	ldx #23
	ldy #0
	jsr drawHLine
	mov #40 : ARG1
	lda #$09
	ldx #23
	ldy #0
	jsr colourHLine

	mov #26 : ARG1
	lda #$0e
	ldx #1
	ldy #13
	jsr colourHLine

	mov #10 : ARG1
	lda #$0d
	ldx #2
	ldy #21
	jsr colourVLine
	mov #10 : ARG1
	lda #$0d
	ldx #2
	ldy #22
	jsr colourVLine
	mov #10 : ARG1
	lda #$0d
	ldx #2
	ldy #23
	jsr colourVLine

	//Draw text
	mov #3 : ARG1
	ldx #1
	ldy #16
	mov #<name : AP
	mov #>name : AP+1
	jsr drawText

	mov #1 : ARG1
	ldx #1
	ldy #22
	mov #<hp : AP
	mov #>hp : AP+1
	jsr drawText

	mov #2 : ARG1
	ldx #2
	ldy #15
	mov #<p1n : AP
	mov #>p1n : AP+1
	jsr drawText

	mov #1 : ARG1
	ldx #2
	ldy #22
	mov #<p1hp : AP
	mov #>p1hp : AP+1
	jsr drawText

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
	lda #05
	jsr colourChar

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
// Move to memory address
// src - Source address
// tar - Target address
.pseudocommand mov src:tar {
	lda src
	sta tar
}

//----------Subroutines----------
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

// Colours horizontal line
// A - Colour
// X - Y position
// Y - X position
// ARG1 - Length
colourHLine: {
loop:
	jsr colourChar
	iny
	dec ARG1
	bne loop
	rts
}

// Colours horizontal line
// A - Colour
// X - Y position
// Y - X position
// ARG1 - Length
colourVLine: {
loop:
	jsr colourChar
	inx
	dec ARG1
	bne loop
	rts
}

// Writes text
// ARG1 - Length of text
// X - Y position of text
// Y - X position of text
// AP - Lo Byte of text
// AP+1 - Hi Byte of text
drawText: {
	sty ARG2
	ldy ARG1
loop:
	lda (AP),y
	ldy ARG2
	jsr drawChar
	dey
	dec ARG1
	sty ARG2
	ldy ARG1
	cpy #$ff
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

// Sets a colour at a set position on screen
// A - Colour to draw
// X - Y position to draw at
// Y - X position to draw at
colourChar: {
	pha
	lda colourRowLUTLo,x
	sta ZP
	lda colourRowLUTHi,x
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

// Clear contents of colour buffer, sets to white
clearColBuffer: {
	ldx #0
	lda #$01

loop:
	sta colmem, x
	sta colmem+$100, x
	sta colmem+$200, x
	sta colmem+$300, x
	inx
	bne loop

	rts
}


//------------Buffer-------------
	.segment Buffer
table:		.fill $3c0, 0

		; entangler (256-byte demo for Sinclair ZX Spectrum + AY-3-8912)
		; (c) 2023, Milos Bazelides a.k.a. baze/3SC

SquareBank	equ	#7E
SinusBank	equ	#7F

StartAddr	equ	#F100 - CodeSize
		org	StartAddr

		; Initialize AY.

		ld	hl,AyInitRegs
		ld	a,3
		call	AyOutputRegs

		out	(254),a

		; Zero the remaining area of color palette.

ZeroMemory	ld	(hl),a
		inc	l
		jr	nz,ZeroMemory

		; Draw bitmap pattern used for rudimentary dithering.

		ld	h,#58
DrawBitmap	dec	hl
		ld	(hl),%11000011
		cp	h
		jr	nz,DrawBitmap

		; Generate X^2 lookup table.

		ld	de,SquareBank * 256
		ld	b,d
		ld	c,e
GenSquare	ld	(de),a
		inc	e
		ld	(bc),a
		dec	c
		inc	h
		add	a,h
		inc	h
		jr	nz,GenSquare

		; Generate "sinus" -8..8 approximated by parabola.

		inc	d
		ld	l,h
		ld	bc,64
GenSinus	add	hl,bc
		dec	bc
		ld	a,h
		res	7,e
		ld	(de),a
		neg
		set	7,e
		ld	(de),a
		inc	e
		jr	nz,GenSinus

		; Generate heightmap at #8000..#BFFF.

		inc	d
GenHeightmap	ld	h,SquareBank
		ld	a,d
		sub	160			; Map Y to -32..31.
		ld	l,a
		ld	a,(hl)
		ld	l,e
		add	a,(hl)			; Calculate X * X + Y * Y.
		inc	h
		ld	l,a
		ldi				; Store sin(X * X + Y * Y).
		bit	6,d
		jr	z,GenHeightmap

		; Synchronize with beam.

MainLoop	halt

		; Load FRAMES.

		ld	de,(#5C78)

		; Advance music position.

		ld	a,e
		rra
		rra
		rra
		ld	h,MusicPattern / 256
		or	h
		ld	l,a

		; Allow at most two tone generator ticks to be played.

		ld	a,e
		and	%110
		ld	a,(hl)
		jr	z,DoNotMute
		xor	a			; Just play ultrasonic frequency.
DoNotMute	rr	d
		jr	c,SetToneFreq
		rla
SetToneFreq	ld	l,AyToneFreq + 1
		ld	(hl),a

		; Set the envelope period.

SetEnvelope	dec	l
		ld	a,e
		and	%110000
		ld	a,2
		jr	z,AyOutput
		inc	a
AyOutput	call	AyOutputRegs

		; Change palette every two patterns.

		ld	hl,ColorPalette2
		or	e
		jr	nz,KeepColors

		ld	d,h
		ld	b,9
ChangeColors	ld	a,(de)
		xor	(hl)
		ld	(de),a
		inc	e
		inc	l
		djnz	ChangeColors

KeepColors	ld	de,#5800
		exx

		; Update animation phases X1, Y1 and X2, Y2 on stack.

		ld	bc,#0203
		pop	hl
		add	hl,bc
		ex	de,hl
		pop	hl
		add	hl,bc
		inc	h
		inc	l
		push	hl
		push	de

		; Update heightmap positions (oscillating movement).

UpdateLoop	push	bc
		ld	b,SinusBank
		ld	c,l
		ld	a,(bc)
		add	a,16
		ld	l,a
		ld	c,h
		ld	a,(bc)
		add	a,160 - 12
		ld	h,a
		ex	de,hl
		pop	bc
		djnz	UpdateLoop

		; Subtract heightmaps and render colors from predefined palette.

		ld	c,24
RenderLoop1	ld	b,32
		ld	a,e
		sub	b
		ld	e,a
		ld	a,l
		sub	b
		ld	l,a
RenderLoop2	ld	a,(de)
		sub	(hl)
		exx
		ld	l,a
		ld	a,(hl)
		ld	(de),a			; LDI is tempting but it can change H.
		inc	de
		exx
		inc	e
		inc	l
		djnz	RenderLoop2
		inc	d
		inc	h
		dec	c
		jr	nz,RenderLoop1

		jr	MainLoop

AyOutputRegs	ld	bc,#C1FD
		outi
		outi
		dec	a
		jr	nz,AyOutputRegs
		ret

AyToneFreq	db	4, 0			; Tone frequency.
		db	11, #A8			; Envelope frequency.
		db	11, #70			; Alternate envelope frequency.

MusicPattern	db	#2A, #2D, #3F, #38, #38, #38, 0, 0, #38, #3F, #3F, #2D, #2D, 0, #2D, #2A

CodeSize	equ	$ - StartAddr

		; The palette is aligned to 256 bytes.

ColorPalette1	db	%01000001		; Color 1.
		db	%01001001		; Color 2.
		db	%00001101		; Color 3.
		db	%00001101		; Color 3.
		db	%00101101		; Color 4.
		db	%00101101		; Color 4.
		db	%00101110		; Color 5.
		db	%00101110		; Color 5.
		db	%00101110		; Color 5.
		db	%00110110		; Color 6.
		db	%00110110		; Color 6.
		db	%00110111		; Color 7.
		db	%00110111		; Color 7.
		db	%00111111		; Color 8.
		db	%00111111		; Color 8.
		db	%00111111		; Color 8.
		db	%00111111		; Color 8.

ColorPalette2	db	%00000010 ^ %01000001
		db	%00010010 ^ %01001001
		db	%00010011 ^ %00001101
		db	%00010011 ^ %00001101
		db	%00011011 ^ %00101101
		db	%00011011 ^ %00101101
		db	%00011110 ^ %00101110
		db	%00011110 ^ %00101110
		db	%00011110 ^ %00101110

AyInitRegs	db	7, %00111011		; Enable channel C tone generator.
		db	10, 16			; Enable channel C envelope.
		db	13, 12			; Set envelope shape to /|/|/|/|.

		export	StartAddr

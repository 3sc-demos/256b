
		; dissolver (256-byte demo for Sinclair ZX Spectrum with AY-3-8912)
		; (c) 2024, Milos Bazelides a.k.a. baze/3SC

StartAddr	equ	#F000 - CodeSize
		org	StartAddr

EntryPoint	ld	iyl,a			; Reset frame counter.

		; Initialize AY registers.

		REPT	4
		ld	bc,#C1FD
		outd
		outd
		ENDR

		; Clear screen and set border color.

ClearColor	dec	hl
		ld	(hl),a
		cp	(hl)
		jr	z,ClearColor

		out	(254),a

		; Generate lookup table used for frame buffer dithering.

		ld	hl,Rasters
		ld	d,h
		ld	b,h
GenRasters1	ld	e,Rasters % 256
		ld	c,h
GenRasters2	ld	a,(de)
		inc	e
		xor	(hl)
		and	h			; Assumes H = #F0.
		xor	(hl)
		ld	(bc),a
		inc	c
		jr	nz,GenRasters2
		inc	l
		inc	b
		jr	nz,GenRasters1

		; Determine background color.

MainLoop	ld	a,iyh
		rra
		sbc	a,a
		and	%00011011
		xor	%01001101
		ld	c,a

		; Render effects using pseudo-random (X, Y) coordinates in HL.

		ld	d,#F0
RenderLoop	exx
		add	hl,hl			; HL' = #2758 is used as seed.
		sbc	a,a
		and	#2D
		xor	l
		ld	l,a
		ex	af,af'
		ld	a,h
		exx

		; Constrain (X, Y) values to %00XXXXXX and %10YYYYYY.

		ld	e,a
		and	63
		ld	l,a
		ex	af,af'
		rra
		scf
		rra
		ld	h,a

		; Calculate a function of (HL), H, L or IYL.

Effect		add	a,iyl
		or	d

		; Distribute the value to neighboring pixels.

		inc	l
		res	6,l
		ld	(hl),a
		inc	h
		res	6,h
		ld	(hl),a

		; Initialize background color at random attribute address.

		ld	hl,#6880
		add	hl,de
		ld	(hl),c
		inc	h
		ld	(hl),c

		djnz	RenderLoop

		; Update AY music (D-A / F-A power chord combined with A / D tone tick).

		ld	de,#4080

		ld	hl,BassFreq
		ld	c,iyl
		ld	a,c
		rla
		sbc	a,a
		add	a,l			; A = 5 or 6, assumes L = 6.
		ld	(hl),a
		ld	l,b
		ld	(hl),b			; Mute tone tick (ultrasonic frequency), assumes B = 0.

		ld	a,c
		sub	h			; Assumes H = #F0 (-16).
		and	%11101
		jr	nz,Update

		ld	a,c
		add	a,32
		ld	a,e
		rra
		ld	(hl),a			; A = #80 or #C0, assumes E = #80.
		inc	l
		ld	a,(hl)
		xor	2			; Swap channels A and B to produce echo.
		ld	(hl),a

		; Update effect from script and set AY register values.

Update		ld	a,iyh
		rla
		or	h

		ld	l,AyRegs % 256
		REPT	5
		ld	bc,#C1FD
		outd
		outd
		ENDR

		ld	l,a
		ld	sp,hl
		pop	hl
		ld	(Effect),hl

		; Dither frame buffer to screen (DE is already initialized).

		ld	ix,#BF00
DitherLoop	ld	sp,ix
		ld	b,e
		ld	c,d			; Make sure LDIs don't change B.

		REPT	31
		pop	hl
		ldi
		ENDR
		pop	hl
		ld	a,(hl)
		ld	(de),a

		inc	d
		inc	d
		ld	a,d
		and	7
		jr	nz,NextLine1
		ld	b,a			; Sneakily initialize B for the next frame.
		inc	e
		jr	z,NextLine2
		ld	a,d
		sub	8
		ld	d,a
		db	#3E			; Dummy LD A,nn that "swallows" LD E,B :)
NextLine1	ld	e,b

NextLine2	dec	ixh
		jp	m,DitherLoop

		; Increment frame counter and do the next frame.

		inc	iy
		jp	MainLoop

		; The sequence is offset to account for the default value of IYH.

Script		ld	a,(hl)			; Effect 5.
		nop
		sub	l			; Effect 6.
		rra
		ld	a,(hl)			; Effect 7.
		nop
		ld	a,(hl)			; Effect 8.
		sub	l
		add	a,iyl			; Effect 1.
		rra				; Effect 2.
		xor	l
		rra				; Effect 3.
		adc	a,(hl)
		sub	l			; Effect 4.
		nop

CodeSize	equ	$ - EntryPoint

		; AY register values located at #F000.

		db	#00, 0			; Channel A fine tone frequency.
		db	#10, 8			; Enable envelope in channel A.
		db	#10, 9			; Enable envelope in channel B.
BassFreq	db	#00, 5			; Channel C coarse tone frequency.
		db	#10, 10			; Enable envelope in channel C.

AyRegs		equ	$ - 1

		; Raster definitions used for rudimentary dithering.

RASTER0		equ	%0000'0000
RASTER1		equ	%0100'0100
RASTER2		equ	%0101'0101
RASTER3		equ	%0111'0111
RASTER4		equ	%1111'1111

Rasters		db	RASTER4
		db	RASTER3
		db	RASTER3
		db	RASTER2
		db	RASTER2
		db	RASTER1
		db	RASTER1
		db	RASTER0
		db	RASTER0
		db	RASTER1
		db	RASTER1
		db	RASTER2
		db	RASTER2
		db	RASTER3
		db	RASTER3
		db	RASTER4

RawSize		equ	$ - EntryPoint

		export	StartAddr
		export	RawSize

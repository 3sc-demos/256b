
		; quadpusher (256-byte demo for Sinclair ZX Spectrum 128)
		; (c) 2021, Milos Bazelides a.k.a. baze/3SC

FarLayerBank	equ	#BE
NearLayerBank	equ	#BF

StartAddr	equ	#8200 - CodeSize
		org	StartAddr

EntryPoint	di

		; Reset the frame counter (decompressor leaves BC = 0).

		push	bc
		pop	iy

		; Let IX point to our filler routines.

		ld	ixh,BackFiller / 256

		; Initialize AY (we exploit its partial port decoding, HL is already set).

		ld	bc,#C1FD
		outd
		outd
		ld	bc,#C1FD
		outd
		outd
		ld	bc,#C1FD
		outd
		outd
		ld	bc,#C1FD
		outd
		outd
		ld	bc,#C1FD
		outd
		outd

ToneFreq	equ	$ + 1

		; Initialize attributes in both video RAMs (page 6 is collateral damage).

		ld	hl,#0546
		ld	de,#0243
		ld	a,#55
AttrInit	out	(253),a
		ld	sp,#DB00
		ld	b,96
AttrLoop	push	de
		push	hl
		push	hl
		push	de
		djnz	AttrLoop
		inc	a
		bit	3,a
		jr	z,AttrInit

		; Generate display lists for both layers.

		ld	d,FarLayerBank
GenFarLayer	ld	a,16
		and	e
		rla
		ld	(de),a
		inc	e
		djnz	GenFarLayer

		inc	d
GenNearLayer	ld	a,32
		and	e
		rla
		ld	(de),a
		inc	e
		djnz	GenNearLayer

		; Set the border color to black.

		out	(254),a

		; Enter the main loop and wait for vertical sync.

MainLoop	ld	h,a
		ld	l,a
		ld	sp,hl
		push	hl

		ei
		halt

		; Initialize "sprites".

		pop	af
		ex	af,af'
		ld	bc,%1010111100000000
		ld	de,%0000000011110101

		ld	a,iyl
		and	%00011100
		jr	nz,SwapVram
		dec	a
		ld	b,a
		ld	e,a

		; Swap frame buffers.

SwapVram	ld	a,#5D
		xor	%1010
		ld	(SwapVram + 1),a
		out	(253),a

		; Advance "script".

		ld	a,iyh
		or	a
		jr	z,IntroScreen
		ld	hl,%0111111001111110
		dec	a
IntroScreen	exx
		ld	h,a
		jr	z,SkipCamera

		; Feed back camera position as acceleration.

		ld	a,(CameraPos + 1)
		add	a,a
		ld	l,a
		sbc	a,a
		ld	h,a
CameraVel	ld	de,1
		add	hl,de
		ld	(CameraVel + 1),hl
CameraPos	ld	de,1
		add	hl,de
		ld	(CameraPos + 1),hl

		; Determine the near layer offset.

SkipCamera	ld	d,NearLayerBank
		ld	e,h

		; Update the power chord (slightly downtuned D-A or F-A in just intonation).

		ld	a,iyl
		rla
		sbc	a,a
		add	a,6
		ld	hl,ToneFreq
		ld	(hl),a
		inc	l
		ld	bc,#C1FD
		outd
		outd

		; Determine the far layer offset.

		ld	b,FarLayerBank
		ld	c,e
		srl	c

		; Blend layers and render scan lines (jump to one of four possible fillers).

		ld	hl,#C01F
RenderLoop	ld	sp,hl
		inc	sp
		ld	a,(bc)
		inc	c
		ex	de,hl
		or	(hl)
		ex	de,hl
		inc	e
		ld	ixl,a
		ex	af,af'
		exx
		jp	(ix)

RenderRet	ex	af,af'
		exx
		inc	h
		ld	a,h
		and	7
		jr	nz,RenderLoop
		ld	a,l
		add	a,32
		ld	l,a
		ld	a,h
		jr	c,RenderNext
		sub	8
		ld	h,a
RenderNext	sub	#D8
		jr	nz,RenderLoop

		; Increment the frame counter and render the next frame.

		inc	iy
		jp	MainLoop

CodeSize	equ	$ - EntryPoint

		; Background filler (aligned to 256-byte boudary).

BackFiller	push	af
		push	af
		push	af
		push	af
		push	af
		push	af
		push	af
		push	af
		push	af
		push	af
		push	af
		push	af
		push	af
		push	af
		push	af
		push	af
		jp	RenderRet

		; Dummy, easily packable values.

		push	de
		push	bc
		push	de
		push	bc
		push	de
		push	bc
		push	de
		push	bc
		push	de
		push	bc
		push	de
		push	bc
		push	de

		; Far layer filler (at bank offset 32).

FarFiller	push	bc
		push	de
		push	bc
		push	de
		push	bc
		push	de
		push	bc
		push	de
		push	bc
		push	de
		push	bc
		push	de
		push	bc
		push	de
		push	bc
		push	de
		jp	RenderRet

		; Dummy, easily packable values.

		push	af
		push	af
		push	hl
		push	hl
		push	af
		push	af
		push	hl
		push	hl
		push	af
		push	af
		push	hl
		push	hl
		push	af

		; Near layer filler (at bank offset 64).

NearFiller	push	af
		push	hl
		push	hl
		push	af
		push	af
		push	hl
		push	hl
		push	af
		push	af
		push	hl
		push	hl
		push	af
		push	af
		push	hl
		push	hl
		push	af
		jp	RenderRet

		; Dummy, easily packable values.

		push	de
		push	bc
		push	hl
		push	hl
		push	de
		push	bc
		push	hl
		push	hl
		push	de
		push	bc
		push	hl
		push	hl
		push	de

		; Near plus far layer filler (at bank offset 96).

BlendFiller	push	bc
		push	hl
		push	hl
		push	de
		push	bc
		push	hl
		push	hl
		push	de
		push	bc
		push	hl
		push	hl
		push	de
		push	bc
		push	hl
		push	hl
		push	de
		jp	RenderRet

RawSize		equ	$ - EntryPoint

		export	StartAddr
		export	RawSize

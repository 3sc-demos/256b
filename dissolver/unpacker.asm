
		; dissolver (256-byte demo for Sinclair ZX Spectrum with AY-3-8912)
		; (c) 2024, Milos Bazelides a.k.a. baze/3SC

		include	"dissolver.inc"

Payload		db	#02, 4			; Channel C fine tone frequency (slightly downtuned to produce flange).
		db	#38, 7			; Enable tone generators.
		db	#10, 11			; Envelope period.
		db	#0E, 13			; Envelope shape /\/\/\/\.

		; Compressed code.

		incbin	"dissolver.lzs"

PayloadSize	equ	$ - Payload

		; Entry point called from BASIC.

		org	StartAddr - (EntryPoint - UnpackAddr)

UnpackAddr	di
		xor	a

		; 23-byte LZS decompressor from Bzpack (github.com/mbaze/bzpack).

		ld	de,EntryPoint + RawSize - 1
		push	bc
		ld	b,a
MainLoop1	pop	hl
		dec	hl
MainLoop2	ld	c,(hl)
		dec	hl
		srl	c
		jr	c,CopyBytes
		push	hl
		ld	l,(hl)
		ld	h,b
		add	hl,de
CopyBytes	lddr
		jr	nc,MainLoop1
EntryPoint	jr	MainLoop2

LoadAddr	equ	UnpackAddr - PayloadSize

		export	LoadAddr
		export	UnpackAddr

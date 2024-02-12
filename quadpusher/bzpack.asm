
		; quadpusher (256-byte demo for Sinclair ZX Spectrum 128)
		; (c) 2021, Milos Bazelides a.k.a. baze/3SC

		include	"imports.inc"

		; Initial AY register values.

Payload		db	2, 4			; Add a bit of flange effect.
		db	%00111011, 7		; Enable channel C tone generator.
		db	16, 10			; Enable envelope in channel C.
		db	32, 11			; Envelope frequency.
		db	12, 13			; Envelope shape /|/|/|/|.

		; Compressed code.

		incbin	"quadpusher.lzs"

PayloadSize	equ	$ - Payload

		org	StartAddr - (EntryPoint - Unpacker)

		; Use the smallest decompressor from Bzpack (github.com/mbaze/bzpack).

Unpacker	ld	hl,$ - 1
		ld	de,EntryPoint + RawSize - 1
		ld	b,0
MainLoop	ld	c,(hl)
		dec	hl
		srl	c
		jr	c,CopyBytes
		push	hl
		ld	l,(hl)
		ld	h,b
		add	hl,de
CopyBytes	lddr
EntryPoint	jr	c,MainLoop
		pop	hl
		dec	hl
		jr	MainLoop

LoadAddr	equ	Unpacker - PayloadSize

		export	LoadAddr
		export	Unpacker

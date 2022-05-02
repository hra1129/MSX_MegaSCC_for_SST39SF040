; -----------------------------------------------------------------------------
;   WRTSST
;   SST Flash ROM Writer
;
;   Copyright (C)2022 Takayuki Hara (HRA!)
;
;    �ȉ��ɒ�߂�����ɏ]���A�{�\�t�g�E�F�A����ъ֘A�����̃t�@�C���i�ȉ��u�\�t�g�E�F�A�v�j
;  �̕������擾���邷�ׂĂ̐l�ɑ΂��A�\�t�g�E�F�A�𖳐����Ɉ������Ƃ𖳏��ŋ����܂��B
;  ����ɂ́A�\�t�g�E�F�A�̕������g�p�A���ʁA�ύX�A�����A�f�ځA�Еz�A�T�u���C�Z���X�A
;  �����/�܂��͔̔����錠���A����у\�t�g�E�F�A��񋟂��鑊��ɓ������Ƃ������錠����
;  �������Ɋ܂܂�܂��B
;    ��L�̒��쌠�\������і{�����\�����A�\�t�g�E�F�A�̂��ׂĂ̕����܂��͏d�v�ȕ����ɋL��
;  ������̂Ƃ��܂��B
;    �\�t�g�E�F�A�́u����̂܂܁v�ŁA�����ł��邩�Öقł��邩���킸�A����̕ۏ؂��Ȃ�
;  �񋟂���܂��B�����ł����ۏ؂Ƃ́A���i���A����̖ړI�ւ̓K�����A����ь�����N�Q�ɂ���
;  �̕ۏ؂��܂݂܂����A����Ɍ��肳�����̂ł͂���܂���B ��҂܂��͒��쌠�҂́A�_��s�ׁA
;  �s�@�s�ׁA�܂��͂���ȊO�ł��낤�ƁA�\�t�g�E�F�A�ɋN���܂��͊֘A���A���邢�̓\�t�g�E�F�A
;  �̎g�p�܂��͂��̑��̈����ɂ���Đ������؂̐����A���Q�A���̑��̋`���ɂ��ĉ���̐ӔC��
;  ����Ȃ����̂Ƃ��܂��B
;
;  Permission is hereby granted, free of charge, to any person obtaining a copy of this 
; software and associated documentation files (the "Software"), to deal in the Software 
; without restriction, including without limitation the rights to use, copy, modify, merge, 
; publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
; to whom the Software is furnished to do so, subject to the following conditions:
;  The above copyright notice and this permission notice shall be included in all copies or 
; substantial portions of the Software.
;  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
; INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
; PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
; FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
; SOFTWARE.
; -----------------------------------------------------------------------------
; History
; May/2nd/2022  t.hara  First release
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
;	MSX Defines
; -----------------------------------------------------------------------------
RAMAD0		:= 0xF341
RAMAD1		:= 0xF342
RAMAD2		:= 0xF343
RAMAD3		:= 0xF344
ENASLT		:= 0x0024		; A: SLOT#, H[7:6]: PAGE#
BDOS		:= 0x0005
_DIRIO		:= 0x06
_STROUT		:= 0x09
_TERM0		:= 0x00

; -----------------------------------------------------------------------------
;	MegaSCC Defines
; -----------------------------------------------------------------------------
BANK0_SEL	:= 0x5000
BANK1_SEL	:= 0x7000
BANK2_SEL	:= 0x9000
BANK3_SEL	:= 0xB000

; -----------------------------------------------------------------------------
;	SST Flash ROM Defines
; -----------------------------------------------------------------------------
CMD_2AAA	:= 0x0AAA | 0x4000
CMD_5555	:= 0x0555 | 0x6000

; -----------------------------------------------------------------------------
;	Entry Point
; -----------------------------------------------------------------------------
			org		0x100
entry_point::
			; Change to SLOT#1 on Page1 and Page2
			ld		a, 0x01
			ld		h, 0x40
			call	ENASLT				; di
			ld		a, 0x01
			ld		h, 0x80
			call	ENASLT				; di
			; Change BANK0 to BANK#1
			ld		a, 1
			ld		[BANK0_SEL], a
			; Change BANK1 to BANK#6
			ld		a, 6
			ld		[BANK1_SEL], a
			; Change BANK2 to BANK#0
			ld		a, 0
			ld		[BANK2_SEL], a
			; EXECUTE: Software ID Entry and Read
			ld		hl, 0x8000
			ld		a, 0xAA
			ld		[CMD_5555], a
			ld		a, 0x55
			ld		[CMD_2AAA], a
			ld		a, 0x90
			ld		[CMD_5555], a
			ld		c, [hl]				; 0xBF
			inc		hl
			ld		b, [hl]				; Device ID
			ld		[save_device_id], bc
			; Restore SLOT
			ld		a, [RAMAD1]
			ld		h, 0x40
			call	ENASLT				; di
			ld		a, [RAMAD2]
			ld		h, 0x80
			call	ENASLT				; di
			ei
			; Display informations
			ld		de, title_message
			ld		c, _STROUT
			call	bdos

			ld		a, [save_device_id + 0]
			call	puthex
			ld		e, '-'
			ld		c, _DIRIO
			call	bdos
			ld		a, [save_device_id + 1]
			call	puthex

			ld		de, completed_message
			ld		c, _STROUT
			call	bdos

			ld		b, 0				; Error code: 0
			ld		c, _TERM
			jp		bdos

; -----------------------------------------------------------------------------
;  puthex
;  input:
;     A .... Target number
;  output:
;     none
;  break:
;     all
;  comment:
;     Displays text using BDOS; must be called with BDOS available.
; -----------------------------------------------------------------------------
			scope	puthex
puthex::
			push	af
			rrca
			rrca
			rrca
			rrca
			call	puthex_c
			pop		af
			jp		puthex_c
			endscope

; -----------------------------------------------------------------------------
;  puthex_c
;  input:
;     A[3:0] .... Target number
;  output:
;     none
;  break:
;     all
;  comment:
;     Displays text using BDOS; must be called with BDOS available.
; -----------------------------------------------------------------------------
			scope	puthex_c
puthex_c::
			and		a, 0x0F
			ld		hl, hex_characters
			ld		d, 0
			ld		e, a
			add		hl, de
			ld		e, [hl]
			ld		c, _DIRIO
			jp		bdos
			endscope

save_device_id:
			dw		0
title_message:
			ds		"SST Checker v0.00\r\n"
			ds		"Copyright (C)2022 HRA!\r\n"
			ds		"Device ID: $"
hex_characters:
			ds		"0123456789ABCDEF"
completed_message:
			ds		"\r\nCompleted.\r\n$"

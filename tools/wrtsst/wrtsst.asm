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
_TERM0		:= 0x00
_DIRIO		:= 0x06
_STROUT		:= 0x09
_FOPEN		:= 0x0F
_FCLOSE		:= 0x10
_SETDTA		:= 0x1A
_RDBLK		:= 0x27

; -----------------------------------------------------------------------------
;	Entry Point
; -----------------------------------------------------------------------------
			org		0x100
entry_point::
			; Display informations
			ld		de, title_message
			call	puts

			call	command_line_options

			call	display_target_slot
			call	puts_crlf

			ld		de, completed_message
			call	puts

			ld		c, _TERM0
			jp		bdos

title_message:
			ds		"WRTSST [SST FlashROM Writer] v0.00\r\n"
			ds		"Copyright (C)2022 HRA!\r\n"
			db		0
completed_message:
			ds		"\r\nCompleted.\r\n"
			db		0

; -----------------------------------------------------------------------------
; command_line_options
; input:
;    none
; output:
;    none
; break:
;    all
; comment:
;    After parsing command line options, reflect them in internal variables.
; -----------------------------------------------------------------------------
			scope	command_line_options
command_line_options::
			ld		hl, 0x0080
			ld		a, [hl]				; Length of command line parameter.
			or		a, a
			jp		z, usage
			ld		b, a
			inc		hl
l1:
			ld		a, [hl]
			inc		hl
			cp		a, '/'
			jr		z, option
			cp		a, ' '
			jr		nz, file_name
l2:
			djnz	l1
			; If no file name is specified, it ends up displaying the usage.
			ld		a, [fcb_fname]
			cp		a, ' '
			jp		z, usage
			ret

option:
			ld		a, [hl]
			inc		hl
			dec		b
			jp		z, usage
			cp		a, 'S'
			jp		z, option_s
			jp		usage
option_s:
			ld		a, [hl]
			inc		hl
			dec		b
			jp		z, usage
			; The slot number is 0 to 3. If it is out of range, the system displays the usage and exits.
			sub		a, '0'
			cp		a, 4
			jp		nc, usage
			ld		[target_slot], a
			; Check expansion slot designations.
			ld		a, [hl]
			cp		a, '-'
			jp		nz, l1
			inc		hl
			dec		b
			jp		z, usage
			ld		a, [hl]
			inc		hl
			dec		b
			jp		z, usage
			; The expantion slot number is 0 to 3. If it is out of range, the system displays the usage and exits.
			sub		a, '0'
			cp		a, 4
			jp		nc, usage
			rlca
			rlca
			ld		c, a
			ld		a, [target_slot]
			or		a, c
			or		a, 0x80
			jp		l1

file_name:
			; If a file name has already been specified, the system displays usage and exits.
			ld		c, a
			ld		a, [fcb_fname]
			cp		a, ' '
			jp		nz, usage
			ld		a, c

			ld		c, 8
			ld		de, fcb_fname
fl1:
			ld		[de], a
			inc		de
			dec		b
			ret		z
			ld		a, [hl]
			inc		hl
			cp		a, '.'
			jp		z, file_ext
			cp		a, ' '
			jp		z, l1
			dec		c
			jr		nz, fl1
file_ext:
			dec		b
			ret		z
			ld		c, 3
			ld		de, fcb_fext
fl2:
			ld		a, [hl]
			cp		a, ' '
			jp		z, l1
			ld		[de], a
			inc		de
			inc		hl
			dec		b
			ret		z
			dec		c
			jp		z, l1
			jr		fl2
			endscope

; -----------------------------------------------------------------------------
; display usage
; input:
;    none
; output:
;    none
; break:
;    all
; comment:
;    Does not return processing and returns to DOS.
; -----------------------------------------------------------------------------
			scope		usage
usage::
			ld			de, usage_message
			call		puts
			ld			c, _TERM0
			jp			BDOS

usage_message:
			ds			"Usage> WRTSST [/Sx][/Sx-y] file_name.rom\r\n"
			ds			"  /Sx ........ Rewrite in SLOT#x.\r\n"
			ds			"  /Sx-y ...... Rewrite in SLOT#x-y.\r\n"
			ds			"  /S omitted . Auto detect.\r\n"
			db			0
			endscope

; -----------------------------------------------------------------------------
; display target slot
; input:
;    none
; output:
;    none
; break:
;    all
; comment:
;    none
; -----------------------------------------------------------------------------
			scope		display_target_slot
display_target_slot::
			ld			de, slot_message
			call		puts

			ld			a, [target_slot]
			and			a, 3
			call		puthex_c

			ld			a, [target_slot]
			rlca
			ret			nc
			rra
			rra
			rra
			and			a, 3
			jp			puthex_c
slot_message:
			ds			"SLOT#"
			db			0
			endscope

; -----------------------------------------------------------------------------
;  WORK AREA
; -----------------------------------------------------------------------------
target_slot::
			db		0xFF				; 0xFF: auto, 0bE000DDCC: slot number
fcb::
fcb_dr::
			db		0					; 0: Default Drive, 1: A, 2: B, ... 8: H
fcb_fname::
			ds		"        "
fcb_fext::
			ds		"   "
fcb_ex::
			db		0
fcb_s1::
			db		0
fcb_s2::
			db		0
fcb_rc::
			db		0
fcb_filsiz::
			dw		0, 0
fcb_date::
			dw		0
fcb_time::
			dw		0
fcb_devid::
			db		0
fcb_dirloc::
			db		0
fcb_strcls::
			dw		0
fcb_clrcls::
			dw		0
fcb_clsoff::
			dw		0
fcb_cr::
			db		0
fcb_rn::
			dw		0, 0

			include	"stdio.asm"
			include	"flashrom.asm"
			include	"scc.asm"

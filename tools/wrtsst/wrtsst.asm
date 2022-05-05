; -----------------------------------------------------------------------------
;   WRTSST
;   SST Flash ROM Writer
;
;   Copyright (C)2022 Takayuki Hara (HRA!)
;
;    以下に定める条件に従い、本ソフトウェアおよび関連文書のファイル（以下「ソフトウェア」）
;  の複製を取得するすべての人に対し、ソフトウェアを無制限に扱うことを無償で許可します。
;  これには、ソフトウェアの複製を使用、複写、変更、結合、掲載、頒布、サブライセンス、
;  および/または販売する権利、およびソフトウェアを提供する相手に同じことを許可する権利も
;  無制限に含まれます。
;    上記の著作権表示および本許諾表示を、ソフトウェアのすべての複製または重要な部分に記載
;  するものとします。
;    ソフトウェアは「現状のまま」で、明示であるか暗黙であるかを問わず、何らの保証もなく
;  提供されます。ここでいう保証とは、商品性、特定の目的への適合性、および権利非侵害について
;  の保証も含みますが、それに限定されるものではありません。 作者または著作権者は、契約行為、
;  不法行為、またはそれ以外であろうと、ソフトウェアに起因または関連し、あるいはソフトウェア
;  の使用またはその他の扱いによって生じる一切の請求、損害、その他の義務について何らの責任も
;  負わないものとします。
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
EXPTBL		:= 0xFCC1
JIFFY		:= 0xFC9E

; -----------------------------------------------------------------------------
;	Entry Point
; -----------------------------------------------------------------------------
			org		0x100
entry_point::
			; Display informations
			ld		de, title_message
			call	puts

			call	command_line_options
			ld		a, [fcb_fname]
			cp		a, ' '
			jp		z, usage

			call	display_target_fname
			call	puts_crlf

			call	file_open

			call	check_target_slot
			jp		nz, not_detected

			call	display_target_slot
			call	puts_crlf

			ld		de, erase_message
			call	puts
			call	flash_chip_erase

			ld		de, completed_message
l1:
			call	puts

			call	restore_dos_slot
			ld		c, _TERM0
			jp		bdos

not_detected:
			ld		de, not_detected_message
			jr		l1

title_message:
			ds		"WRTSST [SST FlashROM Writer] v0.00\r\n"
			ds		"Copyright (C)2022 HRA!\r\n"
			db		0
erase_message:
			ds		"Erase ROM datas.\r\n"
			db		0
completed_message:
			ds		"\r\nCompleted.\r\n"
			db		0
not_detected_message:
			ds		"Could not detect flash cartridge.\r\n"
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
get_one:
			ld		a, [hl]
			inc		hl
			dec		b
			ret

command_line_options::
			ld		hl, 0x0080
			ld		a, [hl]				; Length of command line parameter.
			or		a, a
			jp		z, usage
			ld		b, a
			inc		hl
l1:
			call	get_one
			cp		a, '/'
			jr		z, option
			cp		a, ' '
			jr		nz, file_name
l2:
			inc		b
			djnz	l1
			; If no file name is specified, it ends up displaying the usage.
			ld		a, [fcb_fname]
			cp		a, ' '
			jp		z, usage
			ret

option:
			call	get_one
			jp		z, usage
			cp		a, 'S'
			jp		z, option_s
			jp		usage
option_s:
			call	get_one
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
			call	get_one
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
			ld		[target_slot], a
			jp		l1

file_name:
			; If a file name has already been specified, the system displays usage and exits.
			ld		a, [fcb_fname]
			cp		a, ' '
			jp		nz, usage

			ld		c, 8
			ld		de, fcb_fname
			dec		hl
			inc		b
fl1:
			call	get_one
			cp		a, '.'
			jp		z, file_ext
			cp		a, ' '
			jp		z, l1
			ld		[de], a
			inc		de

			inc		b
			dec		b
			ret		z

			dec		c
			jr		nz, fl1
file_ext:
			inc		b
			dec		b
			ret		z

			ld		c, 3
			ld		de, fcb_fext
fl2:
			call	get_one
			cp		a, ' '
			jp		z, l1
			ld		[de], a
			inc		de

			inc		b
			dec		b
			ret		z

			dec		c
			jp		z, l1
			jr		fl2
			endscope

; -----------------------------------------------------------------------------
; file open
; input:
;    none
; output:
;    none
; break:
;    all
; comment:
;    none
; -----------------------------------------------------------------------------
			scope	file_open
file_open::
			ld		de, fcb
			ld		c, _FOPEN
			call	BDOS
			or		a, a						; A=0: Success, 255: Error
			ld		de, cannot_open_message
			jr		nz, put_error

			; Check file size
			ld		hl, [fcb_filsiz]
			ld		a, h
			and		a, 0x1F
			or		a, l
			ld		de, is_not_8kb_message
			jr		nz, put_error

			ld		a, h
			ld		hl, [fcb_filsiz + 2]
			or		a, h
			or		a, l
			ld		de, is_zero_message
			jr		z, put_error

			; calc KB
			ld		hl, [fcb_filsiz + 1]
			srl		h
			rr		l
			srl		h
			rr		l
			ld		[target_size], hl
			ret

put_error:
			call	puts
			or		a, a
			ret

cannot_open_message:
			ds		"Cannot open file.\r\n"
			db		0
is_not_8kb_message:
			ds		"The file size is not a multiple of 8KB.\r\n"
			db		0
is_zero_message:
			ds		"File is empty.\r\n"
			db		0
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
			scope	usage
usage::
			call	restore_dos_slot
			ld		de, usage_message
			call	puts
			ld		c, _TERM0
			jp		BDOS

usage_message:
			ds		"Usage> WRTSST [/Sx][/Sx-y] file_name.rom\r\n"
			ds		"  /Sx ........ Rewrite in SLOT#x.\r\n"
			ds		"  /Sx-y ...... Rewrite in SLOT#x-y.\r\n"
			ds		"  /S omitted . Auto detect.\r\n"
			db		0
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

			ld			de, bar_message
			call		puts

			ld			a, [target_slot]
			rra
			rra
			and			a, 3
			jp			puthex_c
slot_message:
			ds			"SLOT#"
			db			0
bar_message:
			ds			"-"
			db			0
			endscope

; -----------------------------------------------------------------------------
; display target file name
; input:
;    none
; output:
;    none
; break:
;    all
; comment:
;    none
; -----------------------------------------------------------------------------
			scope		display_target_fname
display_target_fname::
			ld			de, fname_message
			call		puts

			ld			hl, fcb_fname
			ld			b, 8
l1:
			ld			a, [hl]
			inc			hl
			cp			a, ' '
			jr			z, s1
			push		hl
			push		bc
			ld			e, a
			ld			c, _DIRIO
			call		BDOS
			pop			bc
			pop			hl
			djnz		l1
s1:
			ld			e, '.'
			ld			c, _DIRIO
			call		BDOS

			ld			hl, fcb_fext
			ld			b, 3
l2:
			ld			a, [hl]
			inc			hl
			cp			a, ' '
			ret			z
			push		hl
			push		bc
			ld			e, a
			ld			c, _DIRIO
			call		BDOS
			pop			bc
			pop			hl
			djnz		l2
			ret

fname_message:
			ds			"File name:"
			db			0
			endscope

; -----------------------------------------------------------------------------
; check target slot
;    none
; output:
;    Zf .... 0: not detected, 1: detected
; break:
;    all
; comment:
;    Search for target slots
; -----------------------------------------------------------------------------
			scope		check_target_slot
check_target_slot::
			ld			a, [target_slot]
			inc			a
			ret			nz					; If a slot number is specified, return without doing anything.

			ld			hl, EXPTBL
l1:
			ld			a, [hl]
			or			a, a
			jp			m, expanded_slot
basic_slot:
			ld			a, l
			sub			a, EXPTBL & 255
			ld			[target_slot], a
			push		hl
			call		detect_target
			pop			hl
			ret			z
			jr			next_slot

expanded_slot:
			or			a, 0x80
			ld			[target_slot], a
			push		hl
			call		detect_target
			pop			hl
			ret			z
			ld			a, [target_slot]
			add			a, 0x04
			cp			a, 0x90
			jr			c, expanded_slot

next_slot:
			ld			a, l
			inc			a
			ld			l, a
			cp			a, (EXPTBL & 255) + 4
			jr			c, l1

			xor			a, a
			inc			a
			ret
			endscope

; -----------------------------------------------------------------------------
; restore DOS slot
; input:
;    none
; output:
;    none
; comment:
;    none
; -----------------------------------------------------------------------------
			scope		restore_dos_slot
restore_dos_slot::
			ld			a, [RAMAD1]
			ld			h, 0x40
			call		ENASLT
			ld			a, [RAMAD2]
			ld			h, 0x80
			call		ENASLT
			ei
			ret
			endscope

; -----------------------------------------------------------------------------
; detect_target
; input:
;    target_slot ..... target slot number
; output:
;    Zf .... 0: not detect, 1: detect
; break:
;    all
; comment:
;    none
; -----------------------------------------------------------------------------
			scope		detect_target
detect_target::
			ld			a, [target_slot]
			call		is_slot_scc
			jp			z, detect_scc

			ld			a, [target_slot]
			call		is_slot_rc755
			jp			z, detect_rc755

			ld			a, [target_slot]
			call		is_slot_simple64k
			jp			z, detect_simple64k
			ret										; Not detected FlashROM.

detect_scc:
			; It is confirmed that the specified slot is SCC.
			ld			a, [target_slot]
			call		setup_slot_scc
			xor			a, a
			ld			[rom_type], a
			jp			common_process

detect_rc755:
			; It is confirmed that the specified slot is ESE-RC755.
			ld			a, [target_slot]
			call		setup_slot_rc755
			ld			a, 1
			ld			[rom_type], a
			jp			common_process

detect_simple64k:
			; It is confirmed that the specified slot is Simple64K.
			ld			a, [target_slot]
			call		setup_slot_simple64k
			ld			a, 2
			ld			[rom_type], a
			jp			common_process

common_process:
			ld			de, manufacture_id_message
			call		puts

			ld			a, [manufacture_id]
			call		get_manufacture_name
			call		puts
			call		puts_crlf

			ld			de, device_id_message
			call		puts

			ld			a, [device_id]
			call		get_device_name
			call		puts
			call		puts_crlf

			ld			de, cartridge_type_message
			call		puts

			ld			hl, cartridge_type_table
			ld			a, [rom_type]
			add			a, a
			ld			e, a
			ld			d, 0
			add			hl, de
			ld			e, [hl]
			inc			hl
			ld			d, [hl]
			call		puts

			xor			a, a
			ret

manufacture_id_message:
			ds			"MANUFACTURE ID:"
			db			0
device_id_message:
			ds			"DEVICE ID     :"
			db			0
cartridge_type_message:
			ds			"CARTRIDGE TYPE:"
			db			0
mega_scc_message:
			ds			"MegaSCC\r\n"
			db			0
rc755_message:
			ds			"ESE-RC755\r\n"
			db			0
simple64k_message:
			ds			"Simple64K\r\n"
			db			0
cartridge_type_table:
			dw			mega_scc_message
			dw			rc755_message
			dw			simple64k_message
			endscope

; -----------------------------------------------------------------------------
;  WORK AREA
; -----------------------------------------------------------------------------
target_slot::
			db		0xFF				; 0xFF: auto, 0bE000DDCC: slot number
target_size::
			dw		0					; KB
manufacture_id::
			db		0
device_id::
			db		0
rom_type::
			db		0					; 0: MegaSCC, 1: RC755, 2: Simple64K

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
			include	"ese_rc755.asm"
			include	"simple64k.asm"

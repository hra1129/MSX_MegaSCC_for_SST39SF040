; -----------------------------------------------------------------------------
;   MegaSCC
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
; May/3rd/2022  t.hara  First release
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; SCC bank registers
; -----------------------------------------------------------------------------
SCC_BANK0_SEL	:= 0x5000
SCC_BANK1_SEL	:= 0x7000
SCC_BANK2_SEL	:= 0x9000
SCC_BANK3_SEL	:= 0xB000

; -----------------------------------------------------------------------------
; FlashROM command address
; -----------------------------------------------------------------------------
SCC_CMD_2AAA		:= 0x0AAA | 0x8000
SCC_CMD_5555		:= 0x0555 | 0xA000

; -----------------------------------------------------------------------------
; is_slot_scc
; input:
;    a ..... Target slot
; output:
;    Zf .... 0: not SCC, 1: SCC
; break:
;    all
; comment:
;    Change page2 to the target slot and do not put it back.
;    Return in DI state.
; -----------------------------------------------------------------------------
			scope	is_slot_scc
is_slot_scc::
			; Change to target slot on page2
			ld		h, 0x80
			call	ENASLT				; DI
			; Change bank2 to SCC
			ld		a, 0x3F
			ld		[SCC_BANK2_SEL], a
			; Check RAM on 0x9800-0x987F (Wave table memory)
			ld		h, 0x98
			ld		b, 0x80
l1:
			dec		b
			ld		l, b
			call	is_rom
			ret		nz
			inc		b
			djnz	l1
			; Check "not RAM" on 0x8000-0x80FF
			ld		h, 0x80
l2:
			dec		b
			ld		l, b
			call	is_rom
			jr		z, not_scc
			inc		b
			djnz	l2
			; Change bank2 to bank#0 (not SCC)
			ld		a, b
			ld		[SCC_BANK2_SEL], a
			; Check "not RAM" on 0x8000-0x80FF
l3:
			dec		b
			ld		l, b
			call	is_rom
			jr		z, not_scc
			inc		b
			djnz	l3
			xor		a, a				; Zf = 1: SCC
			ret
not_scc:
			xor		a, a
			inc		a					; Zf = 0: not SCC
			ret
			endscope

; -----------------------------------------------------------------------------
; setup_slot_scc
; input:
;    a ..... Target slot
; output:
;    e ..... Manufacture ID
;    d ..... Device ID
; break:
;    all
; comment:
;    Change Page1 and Page2 to SCC slots.
;    Change Bank0 and Bank1 to Bank#0.
;    Change Bank2 to Bank#1.
;    Change Bank3 to Bank#6.
;    Return in DI state.
; -----------------------------------------------------------------------------
			scope	setup_slot_scc
setup_slot_scc::
			; Change to target slot on page1
			push	af
			ld		h, 0x40
			call	ENASLT				; DI
			pop		af
			; Change to target slot on page2
			ld		h, 0x80
			call	ENASLT				; DI
			; Set bank registers.
			xor		a, a
			ld		[SCC_BANK0_SEL], a
			ld		[SCC_BANK1_SEL], a
			inc		a
			ld		[SCC_BANK2_SEL], a
			ld		a, 6
			ld		[SCC_BANK3_SEL], a
			; Setup
			ld		hl, scc_flash_jump_table
			call	setup_flash_command
			; Get Manufacture ID
			ld		hl, 0x4000
			ld		a, 0xAA
			ld		[SCC_CMD_5555], a
			ld		a, 0x55
			ld		[SCC_CMD_2AAA], a
			ld		a, 0x90
			ld		[SCC_CMD_5555], a
			ld		e, [hl]
			inc		hl
			ld		a, 0xAA
			ld		[SCC_CMD_5555], a
			ld		a, 0x55
			ld		[SCC_CMD_2AAA], a
			ld		a, 0x90
			ld		[SCC_CMD_5555], a
			ld		d, [hl]
			ld		[manufacture_id], de

			ld		a, 0xF0
			ld		[hl], a

			ld		a, [manufacture_id]
			call	get_manufacture_name
			ret		nz
			ld		a, [device_id]
			call	get_device_name
			ret

scc_flash_jump_table:
			jp		scc_flash_chip_erase
			jp		scc_flash_write_byte
			endscope

; -----------------------------------------------------------------------------
; scc_flash_write_byte
; input:
;    hl .... target address (BANK0: 4000h-5FFFh)
;    a ..... write value
; output:
;    Zf .... 0: Failed, 1: Success
; break:
;    all
; comment:
;
; -----------------------------------------------------------------------------
			scope		scc_flash_write_byte
scc_flash_write_byte::
			push		af
			ld			a, 0xAA
			ld			[SCC_CMD_5555], a
			ld			a, 0x55
			ld			[SCC_CMD_2AAA], a
			ld			a, 0xA0
			ld			[SCC_CMD_5555], a
			pop			af
			ld			[hl], a
			call		scc_restore_bank0
			ld			b, 0
l1:
			ld			c, [hl]
			cp			a, c
			nop
			ret			z
			djnz		l1
			ret
			endscope

; -----------------------------------------------------------------------------
; scc_flash_chip_erase
; input:
;    none
; output:
;    none
; break:
;    all
; comment:
;
; -----------------------------------------------------------------------------
			scope		scc_flash_chip_erase
scc_flash_chip_erase::
			ld			a, 0xAA
			ld			[SCC_CMD_5555], a
			ld			a, 0x55
			ld			[SCC_CMD_2AAA], a
			ld			a, 0x80
			ld			[SCC_CMD_5555], a
			ld			a, 0xAA
			ld			[SCC_CMD_5555], a
			ld			a, 0x55
			ld			[SCC_CMD_2AAA], a
			ld			a, 0x10
			ld			[SCC_CMD_5555], a

			ld			hl, JIFFY
			ld			a, [hl]
			add			a, 10
			ei
wait_l1:
			cp			a, [hl]
			jr			nz, wait_l1
			di
			ret
			endscope

; -----------------------------------------------------------------------------
; scc_set_bank0
; input:
;    a ..... BANK ID
; output:
;    none
; break:
;    all
; comment:
;
; -----------------------------------------------------------------------------
			scope		scc_set_bank0
scc_set_bank0::
			ld			[SCC_BANK0_SEL], a
			ld			[bank0_back], a
			ret
			endscope

; -----------------------------------------------------------------------------
; scc_restore_bank0
; input:
;    none
; output:
;    none
; break:
;    all
; comment:
;
; -----------------------------------------------------------------------------
			scope		scc_restore_bank0
scc_restore_bank0::
			ld			a, [bank0_back]
			ld			[SCC_BANK0_SEL], a
			ret
			endscope

bank0_back:
			db			0

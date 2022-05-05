; -----------------------------------------------------------------------------
;   ESE-RC755
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
RC755_BANK1_SEL	:= 0x6000
RC755_BANK2_SEL	:= 0x8000
RC755_BANK3_SEL	:= 0xA000

; -----------------------------------------------------------------------------
; FlashROM command address
; -----------------------------------------------------------------------------
RC755_CMD_2AAA	:= 0x4AAA
RC755_CMD_5555	:= 0x5555
RC755_FLASH		:= 0x80

; -----------------------------------------------------------------------------
; is_slot_rc755
; input:
;    a ..... Target slot
; output:
;    Zf ................... 0: not RC755, 1: RC755
;    [manufacture_id] ..... Manufacture ID/Device ID
; break:
;    all
; comment:
;    Change page2 to the target slot and do not put it back.
;    Return in DI state.
; -----------------------------------------------------------------------------
			scope	is_slot_rc755
not_rc755:
			xor		a, a
			inc		a
			ret							; Zf = 0: not RC755

is_slot_rc755::
			; Change to target slot on page1 and page2
			push	af
			ld		h, 0x40
			call	ENASLT				; DI
			pop		af
			ld		h, 0x80
			call	ENASLT				; DI
			; Is ROM, Page1 and Page2?
			ld		hl, 0x5000
			call	is_rom
			jr		z, not_rc755
			ld		hl, 0x7000
			call	is_rom
			jr		z, not_rc755
			ld		hl, 0x9000
			call	is_rom
			jr		z, not_rc755
			ld		hl, 0xB000
			call	is_rom
			jr		z, not_rc755
			; Change BANK#0 on BANK1
			xor		a, a
			ld		[RC755_BANK1_SEL], a
			; Change Flash Mode
			ld		a, RC755_FLASH
			ld		[RC755_BANK3_SEL], a
			; Get Manufacture ID
			ld		hl, 0x4000
			ld		a, 0xAA
			ld		[RC755_CMD_5555], a
			ld		a, 0x55
			ld		[RC755_CMD_2AAA], a
			ld		a, 0x90
			ld		[RC755_CMD_5555], a
			ld		e, [hl]
			inc		hl

			ld		a, 0xAA
			ld		[RC755_CMD_5555], a
			ld		a, 0x55
			ld		[RC755_CMD_2AAA], a
			ld		a, 0x90
			ld		[RC755_CMD_5555], a
			ld		d, [hl]

			ld		[manufacture_id], de
			; Change Flash Mode
			ld		a, 0x03
			ld		[RC755_BANK3_SEL], a

			ld		a, e
			call	get_manufacture_name
			ret		nz

			ld		a, [manufacture_id + 1]
			call	get_device_name
			ret		nz

			; Setup
			ld		hl, rc755_flash_jump_table
			call	setup_flash_command
			ret

rc755_flash_jump_table:
			jp		rc755_flash_chip_erase
			jp		rc755_flash_write_byte
			endscope

; -----------------------------------------------------------------------------
; setup_slot_rc755
; input:
;    a ..... Target slot
; output:
;    [manufacture_id] ..... Manufacture ID/Device ID
; break:
;    all
; comment:
;    none
; -----------------------------------------------------------------------------
			scope	setup_slot_rc755
setup_slot_rc755::
			ret
			endscope

			scope	rc755_flash_chip_erase
rc755_flash_chip_erase::
			ret
			endscope

			scope	rc755_flash_write_byte
rc755_flash_write_byte::
			ret
			endscope

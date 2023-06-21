; -----------------------------------------------------------------------------
;   SimpleMegaROM
;
;   Copyright (C)2023 Takayuki Hara (HRA!)
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
; FlashROM command address
; -----------------------------------------------------------------------------
SMEGA_CMD_2AAA		:= 0x2AAA
SMEGA_CMD_5555		:= 0x5555
SMEGA_BANK_REGISTER	:= 0x8000

; -----------------------------------------------------------------------------
; is_slot_simple_mega
; input:
;    a ..... Target slot
; output:
;    Zf ................... 0: not SimpleMegaROM, 1: SimpleMegaROM
;    [manufacture_id] ..... Manufacture ID/Device ID
; break:
;    all
; comment:
;    This is where all of page0-3 are called in the RAM slots.
; -----------------------------------------------------------------------------
			scope	is_slot_simple_mega
is_slot_simple_mega::
			or		a, a
			jp		m, not_support_extended_slot

			; Change to target slot on page1 and page2
			push	af
			ld		h, 0x40
			call	ENASLT				; DI
			pop		af
			ld		h, 0x80
			call	ENASLT				; DI

			; Is ROM, Page1 and Page2?
			ld		hl, 0x4000
			ld		de, 0x0100
			ld		b, 0x80
l1:
			call	is_rom
			jr		z, not_simple_mega
			add		hl, de
			djnz	l1

			call	restore_dos_slot			; EI
			call	transfer_to_page2
			call	simple_mega_p2_get_id

			ld		a, [manufacture_id]
			call	get_manufacture_name
			ret		nz

			ld		a, [manufacture_id + 1]
			call	get_device_name
			ret
not_simple_mega:
not_support_extended_slot:
			xor		a, a
			inc		a
			ret
			endscope

; -----------------------------------------------------------------------------
; setup_slot_simple_mega
; input:
;    a ..... Target slot
; output:
;    [manufacture_id] ..... Manufacture ID/Device ID
;    Zf ................... 0: Error, 1: Success
; break:
;    all
; comment:
;    none
; -----------------------------------------------------------------------------
			scope	setup_slot_simple_mega
setup_slot_simple_mega::
			ld		a, 128
			ld		[rom_size], a			; 128KB

			; Setup
			ld		hl, simple_mega_flash_jump_table
			call	setup_flash_command

			xor		a, a
			ret

simple_mega_flash_jump_table:
			jp		simple_mega_p2_flash_chip_erase
			jp		simple_mega_flash_write_8kb
			jp		simple_mega_set_bank
			jp		simple_mega_get_start_bank
			jp		simple_mega_finish
			endscope

; -----------------------------------------------------------------------------
; simple_mega_set_bank
; input:
;    a ..... BANK ID
; output:
;    none
; break:
;    all
; comment:
;
; -----------------------------------------------------------------------------
			scope	simple_mega_set_bank
simple_mega_set_bank::
			ld		[bank_back], a
			ret
			endscope

; -----------------------------------------------------------------------------
; simple_mega_get_start_bank
; input:
;    hl ..... target size [KB]
; output:
;    a ...... 0 (start bank)
;    Cf ..... 1: too big, 0: success
; break:
;    all
; comment:
;
; -----------------------------------------------------------------------------
			scope	simple_mega_get_start_bank
simple_mega_get_start_bank::
			ld		a, h
			or		a, a
			scf
			ret		nz			; too BIG

			ld		a, l
			cp		a, 129
			ccf
			ret		c			; too BIG

			ld		a, [target_block_for_simple_rom]
			inc		a
			jr		nz, target_address_request

			ld		a, l
			cp		a, 33
			jr		c, file_under_32kb

file_33kb_to_64kb:
			xor		a, a		; 0x0000-
			ld		[target_block_for_simple_rom], a
			ret
file_under_32kb:
			ld		a, 2		; 0x4000-
			ld		[target_block_for_simple_rom], a
			or		a, a
			ret

target_address_request:
			dec		a
			ld		b, a

			ld		a, l
			rrca
			rrca
			rrca
			add		a, b
			cp		a, 9
			ccf
			ret		c			; too BIG

			ld		a, b
			ret
			endscope

; -----------------------------------------------------------------------------
; simple_mega_finish
; input:
;    none
; output:
;    none
; break:
;    none
; comment:
;
; -----------------------------------------------------------------------------
			scope	simple_mega_finish
simple_mega_finish::
			ret
			endscope

; -----------------------------------------------------------------------------
; transfer_to_page2
; input:
;    none
; output:
;    none
; break:
;    all
; comment:
;    This is where all of page0-3 are called in the RAM slots.
;    Routines that run on Page2 are transferred to Page2.
; -----------------------------------------------------------------------------
			scope	transfer_to_page2_smega
transfer_to_page2_smega::
			; transfer subroutines for page2
			ld		hl, transfer_to_page2_smega_start
			ld		de, page2_smega_start
			ld		bc, page2_end - page2_smega_start
			ldir
			ret
			endscope

; -----------------------------------------------------------------------------
; simple_mega_flash_write_8kb
; input:
;    none
; output:
;    Cf .... 0: success, 1: error
; break:
;    all
; comment:
;    Copies the contents of 0x2000-0x3FFF to the area appearing in 0x6000-0x7FFF.
;
;    bank_back      address     routine  address(MSB8bit)
;       0        0x0000-0x1FFF   page2      0x00
;       1        0x2000-0x3FFF   page2      0x20
;       2        0x4000-0x5FFF   page2      0x40
;       3        0x6000-0x7FFF   page2      0x60
;       4        0x8000-0x9FFF   page3      0x80        : with BankRegister
;       5        0xA000-0xBFFF   page3      0xA0        : with BankRegister
;       6        0xC000-0xDFFF   page2      0xC0
;       7        0xE000-0xFFFF   page2      0xE0
;       8        0x0000-0x1FFF   page2      0x00
;       9        0x2000-0x3FFF   page2      0x20
;       10       0x4000-0x5FFF   page2      0x40
;       11       0x6000-0x7FFF   page2      0x60
;       12       0x8000-0x9FFF   page3      0x80        : with BankRegister
;       13       0xA000-0xBFFF   page3      0xA0        : with BankRegister
;       14       0xC000-0xDFFF   page2      0xC0
;       15       0xE000-0xFFFF   page2      0xE0
;
; -----------------------------------------------------------------------------
			scope	simple_mega_flash_write_8kb
simple_mega_flash_write_8kb::
			ld		a, [bank_back]
			; HL = A * 0x2000
			rrca
			rrca
			rrca
			ld		[simple_mega_bank_id], a			; bit0 is bank ID
			and		a, 0xE0
			ld		h, a
			ld		l, 0

			cp		a, 0x80								; goto page3 when 0x80 or 0xA0, goto page2 when others
			jr		z, page3
			cp		a, 0xA0
			jr		z, page3
page2:
			call	simple_mega_p2_flash_write_8kb
			ret
page3:
			di
			exx
			; backup page3 to page1
			ld		hl, 0xC000
			ld		de, 0x4000
			ld		bc, 0x4000
			ldir
			; transfer subroutines for page3
			ld		hl, transfer_to_page3_start
			ld		de, page3_start
			ld		bc, page3_end - page3_start
			ldir
			; copy write data to page3
			ld		hl, 0x2000
			ld		de, 0xC000
			ld		bc, 0x2000
			ldir
			exx
			; Initialize stack pointer
			ld		[save_sp], sp
			ld		sp, 0xFFFF
			; Initialize stack pointer
			call	simple_mega_p3_flash_write_8kb
			; restore stack pointer
			ld		sp, [save_sp]
			; restore page3 from page1
			ld		hl, 0x4000
			ld		de, 0xC000
			ld		bc, 0x3FFF			; Reject Extended Slot Register
			ldir
			ei
			ret
save_sp:
			dw		0
simple_mega_bank_id::
			db		0
			endscope

; -----------------------------------------------------------------------------
; Programs to be placed on A000h- (PAGE2)
; -----------------------------------------------------------------------------
transfer_to_page2_smega_start::
			org		0xA000
page2_smega_start::
; -----------------------------------------------------------------------------
; simple_mega_p2_setup_slot
; input:
;    none
; output:
;    none
; break:
;    a, b, h, l, f
; comment:
;    none
; -----------------------------------------------------------------------------
			scope	simple_mega_p2_setup_slot
simple_mega_p2_setup_slot::
			; save target slot
			ld		a, [target_slot]
			; primary slot
			and		a, 3						; 000000ff
			ld		b, a
			rlca
			rlca
			rlca
			rlca								; 00ff0000
			or		a, b						; 00ff00ff
			rlca
			rlca
			or		a, b						; ff00ffff
			ld		b, a
			in		a, [PPI_PRIMARY_SLOT]
			ld		[p2_save_primary], a
			and		a, 0b00110000				; 00rr0000
			or		a, b						; ffrrffff
			out		[PPI_PRIMARY_SLOT], a
			ret
			endscope

; -----------------------------------------------------------------------------
; simple_mega_p2_restore_slot
; input:
;    none
; output:
;    none
; break:
;    a, f
; comment:
;    none
; -----------------------------------------------------------------------------
			scope	simple_mega_p2_restore_slot
simple_mega_p2_restore_slot::
			; restore primary slot
			ld		a, [p2_save_primary]
			out		[PPI_PRIMARY_SLOT], a
			ret
			endscope

; -----------------------------------------------------------------------------
; get_id_simple_mega
; input:
;    none
; output:
;    e ..... Manufacture ID
;    d ..... Device ID
; break:
;    all
; comment:
;    none
; -----------------------------------------------------------------------------
			scope	simple_mega_p2_get_id
simple_mega_p2_get_id::
			di
			; Initialize stack pointer
			ld		[p2_save_sp], sp
			ld		sp, 0xBFFF
			; Change slot
			call	simple_mega_p2_setup_slot
			; Get Manufacture ID
			ld		hl, 0x0000
			ld		a, 0xAA
			ld		[SMEGA_CMD_5555], a
			ld		a, 0x55
			ld		[SMEGA_CMD_2AAA], a
			ld		a, 0x90
			ld		[SMEGA_CMD_5555], a
			ld		e, [hl]
			inc		hl
			ld		d, [hl]

			ld		a, 0xAA
			ld		[SMEGA_CMD_5555], a
			ld		a, 0x55
			ld		[SMEGA_CMD_2AAA], a
			ld		a, 0xF0
			ld		[SMEGA_CMD_5555], a
			; Restore slot
			call	simple_mega_p2_restore_slot
			ld		[manufacture_id], de
			; Restore stack pointer
			ld		sp, [p2_save_sp]
			ei
			ret
			endscope

; -----------------------------------------------------------------------------
; simple_mega_p2_flash_chip_erase
; input:
;    none
; output:
;    none
; break:
;    all
; comment:
;    none
; -----------------------------------------------------------------------------
			scope	simple_mega_p2_flash_chip_erase
simple_mega_p2_flash_chip_erase::
			di
			; Initialize stack pointer
			ld		[p2_save_sp], sp
			ld		sp, 0xBFFF
			; Change slot
			call	simple_mega_p2_setup_slot
			; Get Manufacture ID
			ld		hl, 0x0000
			ld		a, 0xAA
			ld		[SMEGA_CMD_5555], a
			ld		a, 0x55
			ld		[SMEGA_CMD_2AAA], a
			ld		a, 0x80
			ld		[SMEGA_CMD_5555], a
			ld		a, 0xAA
			ld		[SMEGA_CMD_5555], a
			ld		a, 0x55
			ld		[SMEGA_CMD_2AAA], a
			ld		a, 0x10
			ld		[SMEGA_CMD_5555], a
			; Restore slot
			call	simple_mega_p2_restore_slot
			; Restore stack pointer
			ld		sp, [p2_save_sp]
			; Wait
			ld		hl, JIFFY
			ld		a, [hl]
			add		a, 10
			ei
wait_l1:
			cp		a, [hl]
			jr		nz, wait_l1
			ret
			endscope

; -----------------------------------------------------------------------------
; simple_mega_p2_flash_write_8kb
; input:
;    HL .... Target address
; output:
;    Cf .... 0: success, 1: error
; break:
;    all
; comment:
;    Copies the contents of 0x2000-0x3FFF to the area appearing in 0x6000-0x7FFF.
; -----------------------------------------------------------------------------
			scope	simple_mega_p2_flash_write_8kb
simple_mega_p2_flash_write_8kb::
			di
			; Initialize stack pointer
			ld		[p2_save_smega_sp], sp
			ld		sp, 0xBFFF
			push	hl
			; Transfer write datas
			ld		hl, 0x2000
			ld		de, 0x8000
			ld		bc, 0x2000
			ldir
			; Change slot
			call	simple_mega_p2_setup_slot
			pop		hl

			ld		de, 0x8000				; source address
			ld		bc, 0x2000				; transfer bytes
loop_of_bc:
			ld		a, 0xAA
			ld		[SMEGA_CMD_5555], a
			ld		a, 0x55
			ld		[SMEGA_CMD_2AAA], a
			ld		a, 0xA0
			ld		[SMEGA_CMD_5555], a
			ld		a, [de]
			ld		[hl], a

			push	bc
			ld		bc, 0					; timeout 65536 count
wait_for_write_complete:
			nop
			nop
			cp		a, [hl]
			jr		z, write_complete
			djnz	wait_for_write_complete
			dec		c
			jr		nz, wait_for_write_complete
write_error:
			pop		bc
			call	simple_mega_p2_restore_slot
			ld		sp, [p2_save_smega_sp]
			ei
			scf
			ret
write_complete:
			pop		bc

			inc		de
			inc		hl
			dec		bc
			ld		a, b
			or		a, c
			jr		nz, loop_of_bc

			call	simple_mega_p2_restore_slot
			ld		sp, [p2_save_smega_sp]
			ei
			or		a, a					; Cf = 0
			ret
			endscope

p2_save_smega_sp::
			dw		0
p2_save_smega_primary::
			db		0
page2_smega_end::
			org		transfer_to_page2_smega_start + page2_smega_end - page2_smega_start
transfer_to_page2_smega_end::

; -----------------------------------------------------------------------------
; Programs to be placed on E000h- (PAGE3)
; -----------------------------------------------------------------------------
transfer_to_page3_smega_start::
			org		0xE000
page3_smega_start::
; -----------------------------------------------------------------------------
; simple_mega_p3_setup_slot
; input:
;    none
; output:
;    none
; break:
;    a, b, h, l, f
; comment:
;    none
; -----------------------------------------------------------------------------
			scope	simple_mega_p3_setup_slot
simple_mega_p3_setup_slot::
			; save target slot
			ld		a, [target_slot]
			; primary slot
			and		a, 3						; 000000ff
			ld		b, a
			rlca
			rlca								; 0000ff00
			or		a, b						; 0000ffff
			rlca
			rlca								; 00ffff00
			or		a, b						; 00ffffff
			ld		b, a
			in		a, [PPI_PRIMARY_SLOT]
			ld		[p3_save_smega_primary], a
			and		a, 0b11000000				; rr000000
			or		a, b						; rrffffff
			out		[PPI_PRIMARY_SLOT], a
			ret
			endscope

; -----------------------------------------------------------------------------
; simple_mega_p3_restore_slot
; input:
;    none
; output:
;    none
; break:
;    a, f
; comment:
;    none
; -----------------------------------------------------------------------------
			scope	simple_mega_p3_restore_slot
simple_mega_p3_restore_slot::
			; restore primary slot
			ld		a, [p3_save_smega_primary]
			out		[PPI_PRIMARY_SLOT], a
			ret
			endscope

; -----------------------------------------------------------------------------
; simple_mega_flash_write_8kb_page3
; input:
;    HL .... Target address
; output:
;    Cf .... 0: success, 1: error
; break:
;    all
; comment:
;    Copies the contents of 0x2000-0x3FFF to the area appearing in 0x6000-0x7FFF.
; -----------------------------------------------------------------------------
			scope	simple_mega_p3_flash_write_8kb
simple_mega_p3_flash_write_8kb::
			; Change slot
			call	simple_mega_p3_setup_slot	; SAVE HL

			ld		de, 0xC000				; source address
			ld		bc, 0x2000				; transfer bytes
loop_of_bc:
			ld		a, [ simple_mega_bank_id ]
			and		a, 1
			ld		[SMEGA_BANK_REGISTER], a
			ld		a, 0xAA
			ld		[SMEGA_CMD_5555], a
			ld		a, 0x55
			ld		[SMEGA_CMD_2AAA], a
			ld		a, 0xA0
			ld		[SMEGA_CMD_5555], a
			ld		a, [de]
			ld		[hl], a

			push	bc
			ld		bc, 0					; timeout 65536 count

			; 書き込んだ値の bit0 の値に応じて、バンクまで切り替わってしまうので、所望のバンクに戻す
			ld		a, [ simple_mega_bank_id ]
			and		a, 1
			ld		[SMEGA_BANK_REGISTER], a
			; 書き込み完了待ち
wait_for_write_complete:
			nop
			nop
			cp		a, [hl]
			jr		z, write_complete
			djnz	wait_for_write_complete
			dec		c
			jr		nz, wait_for_write_complete
write_error:
			pop		bc
			call	simple_mega_p3_restore_slot
			scf
			ret
write_complete:
			pop		bc

			inc		de
			inc		hl
			dec		bc
			ld		a, b
			or		a, c
			jr		nz, loop_of_bc

			call	simple_mega_p3_restore_slot
			or		a, a					; Cf = 0
			ret
			endscope

p3_save_smega_primary::
			db		0
page3_smega_end::
			org		transfer_to_page3_smega_start + page3_smega_end - page3_smega_start
transfer_to_page3_smega_end::

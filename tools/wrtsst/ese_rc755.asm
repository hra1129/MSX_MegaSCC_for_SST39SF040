; -----------------------------------------------------------------------------
;   ESE-RC755
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

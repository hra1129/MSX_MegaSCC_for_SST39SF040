; -----------------------------------------------------------------------------
;   MegaSCC
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
SCC_BANK0_SEL	:= 0x5000
SCC_BANK1_SEL	:= 0x7000
SCC_BANK2_SEL	:= 0x9000
SCC_BANK3_SEL	:= 0xB000

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
; is_ram
; input:
;    hl ..... Target address
; output:
;    Zf ..... 0: not RAM, 1: RAM
; break:
;    a
; -----------------------------------------------------------------------------
			scope	is_rom
is_rom::
			ld		a, [hl]
			cpl
			ld		[hl], a
			cp		a, [hl]
			cpl
			ld		[hl], a
			ret
			endscope

; -----------------------------------------------------------------------------
; setup_slot_scc
; input:
;    a ..... Target slot
; output:
;    none
; break:
;    all
; comment:
;    Change Page1 and Page2 to SCC slots.
;    Change Bank0 and Bank1 to Bank#0.
;    Change Bank2 to Bank#1.
;    Change Bank3 to Bank#6.
;    Return in DI state.
; -----------------------------------------------------------------------------
			scope	is_slot_scc
is_slot_scc::
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
			ld		scc_flash_jump_table
			call	setup_flash_command
			ret

scc_flash_jump_table:
			jp		scc_flash_write_byte
			jp		scc_flash_read_byte
			jp		scc_flash_chip_erase
			endscope

; -----------------------------------------------------------------------------
; scc_flash_write_byte
; input:
;    hl .... target address
;    a ..... write value
; output:
;    none
; break:
;    all
; comment:
;
; -----------------------------------------------------------------------------
			scope		scc_flash_write_byte
scc_flash_write_byte::
			endscope

; -----------------------------------------------------------------------------
; scc_flash_read_byte
; input:
;    hl .... target address
; output:
;    a ..... read value
; break:
;    all
; comment:
;
; -----------------------------------------------------------------------------
			scope		scc_flash_read_byte
scc_flash_read_byte::
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
			endscope

; -----------------------------------------------------------------------------
;   Standard I/O
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
; puts
; input:
;    de .... Target address of string (0 terminated)
; output:
;    de .... Next address of target.
; break:
;    all
; -----------------------------------------------------------------------------
			scope	puts_crlf
crlf:
			ds		"\r\n"
			db		0
puts_crlf::
			ld		de, crlf
			endscope

; -----------------------------------------------------------------------------
; puts
; input:
;    de .... Target address of string (0 terminated)
; output:
;    de .... Next address of target.
; break:
;    all
; -----------------------------------------------------------------------------
			scope	puts
puts::
			ld		a, [de]
			inc		de
			or		a, a
			ret		z
			ld		c, _DIRIO
			push	de
			ld		e, a
			call	BDOS
			pop		de
			jr		puts
			endscope

; -----------------------------------------------------------------------------
; puthex16
; input:
;    hl .... Target number
; output:
;    none
; break:
;    all
; -----------------------------------------------------------------------------
			scope	puthex16
puthex16::
			push	hl
			ld		a, h
			call	puthex8
			pop		hl
			ld		a, l
			endscope

; -----------------------------------------------------------------------------
; puthex8
; input:
;    a .... Target number
; output:
;    none
; break:
;    all
; -----------------------------------------------------------------------------
			scope	puthex8
puthex8::
			push	af
			rrca
			rrca
			rrca
			rrca
			call	puthex_c
			pop		af
puthex_c::
			and		a, 0x0F
			ld		hl, hex_characters
			ld		d, 0
			ld		e, a
			add		hl, de
			ld		e, [hl]
			ld		c, _DIRIO
			jp		bdos
hex_characters:
			ds		"0123456789ABCDEF"
			endscope

; -----------------------------------------------------------------------------
; putdec
; input:
;    hl .... Target number
; output:
;    none
; break:
;    all
; -----------------------------------------------------------------------------
			scope	putdec
putdec::
			ld		bc, str
			ld		de, 10000
			call	count_sub
			ld		[bc], a
			inc		bc

			ld		de, 1000
			call	count_sub
			ld		[bc], a
			inc		bc

			ld		de, 100
			call	count_sub
			ld		[bc], a
			inc		bc

			ld		de, 10
			call	count_sub
			ld		[bc], a
			inc		bc

			ld		de, 1
			call	count_sub
			ld		[bc], a

			ld		hl, str
			ld		a, '0'
zero_skip:
			cp		a, [hl]
			jr		nz, zero_skip_exit
			inc		hl
			jr		zero_skip
zero_skip_exit:
			ex		de, hl
			jp		puts

count_sub:
			xor		a, a			; Cf = 0, A = 0
			ld		a, '0'
l1:
			sbc		hl, de
			jr		c, s1
			inc		a
			jr		l1
s1:
			add		hl, de
			ret
str:
			ds		"00000"
			db		0
			endscope

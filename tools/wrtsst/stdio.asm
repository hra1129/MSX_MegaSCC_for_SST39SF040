; -----------------------------------------------------------------------------
;   Standard I/O
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

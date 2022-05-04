; -----------------------------------------------------------------------------
;   Flash ROM Driver
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
MID_AMD			:= 0x01
DID_AM29F040B	:= 0xA4

MID_SST			:= 0xBF
DID_SST39SF010A	:= 0xB5
DID_SST39SF020A	:= 0xB6
DID_SST39SF040	:= 0xB7

; -----------------------------------------------------------------------------
; get_manufacture_name
; input:
;    a .... Target manufacture ID.
; output:
;    de ... Target string address.
;    Zf ... 0: Unkown, 1: Matched
; break:
;    all
; -----------------------------------------------------------------------------
			scope	get_manufacture_name
get_manufacture_name::
			cp		a, MID_AMD
			ld		de, s_amd
			ret		z
			cp		a, MID_SST
			ld		de, s_sst
			ret		z
			ld		de, s_unknown
			ret
s_amd:
			ds		"AMD"
			db		0
s_sst:
			ds		"SST"
			db		0
s_unknown::
			ds		"Unknown"
			db		0
			endscope

; -----------------------------------------------------------------------------
; get_device_name
; input:
;    a .... Target manufacture ID.
; output:
;    de ... Target string address.
;    Zf ... 0: Unkown, 1: Matched
; break:
;    all
; -----------------------------------------------------------------------------
			scope	get_device_name
get_device_name::
			cp		a, DID_AM29F040B
			ld		de, s_am29f040b
			ret		z
			cp		a, DID_SST39SF010A
			ld		de, s_sst39sf010a
			ret		z
			cp		a, DID_SST39SF020A
			ld		de, s_sst39sf020a
			ret		z
			cp		a, DID_SST39SF040
			ld		de, s_sst39sf040
			ret		z
			ld		de, s_unknown
			ret
s_am29f040b:
			ds		"AM29F040B"
			db		0
s_sst39sf010a:
			ds		"SST39SF010A"
			db		0
s_sst39sf020a:
			ds		"SST39SF020A"
			db		0
s_sst39sf040:
			ds		"SST39SF040"
			db		0
			endscope

; -----------------------------------------------------------------------------
; setup_flash_command
; input:
;    hl ... Address table.
; output:
;    none
; break:
;    all
; -----------------------------------------------------------------------------
			scope	setup_flash_command
setup_flash_command::
			ld		de, jump_table
			ld		bc, jump_table_end - jump_table
			ldir
			ret
			endscope

; -----------------------------------------------------------------------------
; jump table
; -----------------------------------------------------------------------------
jump_table:
flash_write_byte::
			jp		0
flash_chip_erase::
			jp		0
jump_table_end:

; -----------------------------------------------------------------------------
;   Flash ROM Driver
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

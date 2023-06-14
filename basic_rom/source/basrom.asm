; =============================================================================
;	MSX-BASIC を ROM化する準備をするツール
; =============================================================================
;	2023/June/14th  t.hara (HRA!)
; =============================================================================

			db			0xfe
			dw			start_address
			dw			end_address
			dw			start_address

			org			0xC000
start_address::
			; 先頭 32bytes を 0フィル
			ld			hl, 0x8000
			ld			de, 0x8001
			ld			bc, 32 - 1
			ld			[hl], 0
			ldir
			; ヘッダを作る
			ld			hl, 'A' | ('B' << 8)
			ld			[0x8000], hl
			ld			hl, 0x8020
			ld			[0x8008], hl
			; BASICプログラムの格納先を指定する
			ld			hl, 0x8021
			ld			[0xF676], hl
			xor			a, a
			ld			[0x8020], a
			ret
end_address::

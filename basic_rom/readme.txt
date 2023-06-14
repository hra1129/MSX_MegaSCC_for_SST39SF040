MSX-BASICのプログラムをROM化する手順
===============================================================================

1. 用意するもの
	(A) ROM化したい MSX-BASIC のプログラム
	(B) basrom.bin <このフォルダに入ってます>
	(C) header_cut.exe <このフォルダに入ってます>

2. 手順
	2-1. (A)(B)(C)を1つのフロッピーディスク、または SDカードドライブなどに格納。
	2-2. NEW を実行
	2-3. BLOAD "basrom.bin",R を実行
	2-4. LOAD "(A)のファイル" を実行
	2-5. BSAVE "ROMファイル名",&H8000,&HBFFF を実行
	2-6. PCへ持ってきて、ROMファイル名なファイルを header_cut.exe にドラッグ＆ドロップする
	2-7. 32768byte になったROMファイル名なファイルを ROMの &H4000-&HBFFF に書き込む
	     → ROMへの書き込みは、Simple 64K ROMカートリッジに、WRTSST で書き込めます。
	        HELLO.ROM を書き込むなら、MSX-DOSから WRTSST HELLO.ROM ですね。

MSX-BASIC�̃v���O������ROM������菇
===============================================================================

1. �p�ӂ������
	(A) ROM�������� MSX-BASIC �̃v���O����
	(B) basrom.bin <���̃t�H���_�ɓ����Ă܂�>
	(C) header_cut.exe <���̃t�H���_�ɓ����Ă܂�>

2. �菇
	2-1. (A)(B)(C)��1�̃t���b�s�[�f�B�X�N�A�܂��� SD�J�[�h�h���C�u�ȂǂɊi�[�B
	2-2. NEW �����s
	2-3. BLOAD "basrom.bin",R �����s
	2-4. LOAD "(A)�̃t�@�C��" �����s
	2-5. BSAVE "ROM�t�@�C����",&H8000,&HBFFF �����s
	2-6. PC�֎����Ă��āAROM�t�@�C�����ȃt�@�C���� header_cut.exe �Ƀh���b�O���h���b�v����
	2-7. 32768byte �ɂȂ���ROM�t�@�C�����ȃt�@�C���� ROM�� &H4000-&HBFFF �ɏ�������
	     �� ROM�ւ̏������݂́ASimple 64K ROM�J�[�g���b�W�ɁAWRTSST �ŏ������߂܂��B
	        HELLO.ROM ���������ނȂ�AMSX-DOS���� WRTSST HELLO.ROM �ł��ˁB

// --------------------------------------------------------------------
//	BSAVEヘッダをカットする
// ====================================================================
//	2023/June/14th  t.hara
// --------------------------------------------------------------------

#include <stdio.h>

static unsigned char zero[ 16384 ];
static unsigned char image[ 7 + 16384 ];

// --------------------------------------------------------------------
static void usage( const char *p_name ) {

	printf( "Usage> %s <file_name>\n", p_name );
	getchar();
}

// --------------------------------------------------------------------
int main( int argc, char *argv[] ) {
	FILE *p_file;
	int image_size;

	printf( "BSAVE header cutter\n" );
	printf( "===========================================================\n" );
	printf( "2023/June/14th t.hara\n" );

	if( argc != 2 ) {
		usage( argv[0] );
		return 0;
	}

	p_file = fopen( argv[1], "rb" );
	if( p_file == NULL ) {
		printf( "[ERROR] Cannot open the '%s'.\n", argv[1] );
		getchar();
		return 0;
	}
	image_size = (int) fread( image, 1, sizeof(image), p_file );
	fclose( p_file );

	if( image_size != sizeof(image) || image[7+0] != 'A' || image[7+1] != 'B' || image[7+8] != 0x20 || image[7+9] != 0x80 ) {
		printf( "[ERROR] '%s' is not a file that can be supported.\n", argv[1] );
		getchar();
		return 0;
	}
	p_file = fopen( argv[1], "wb" );
	if( p_file == NULL ) {
		printf( "[ERROR] Cannot write the '%s'.\n", argv[1] );
		getchar();
		return 0;
	}
	fwrite( zero, 1, sizeof(zero), p_file );
	fwrite( image + 7, 1, sizeof(image) - 7, p_file );
	fclose( p_file );

	printf( "Completed!!\n" );
	getchar();
	return 0;
}

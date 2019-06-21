#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FILE *yyin;
extern int yyparse(void);

int main(int argc, char **argv)
{
	if( argc != 2 ) exit(-1);

	if( (yyin = fopen(argv[argc-1],"r")) == (FILE *)NULL ) exit(-1);

	if( yyparse() ) printf("\nKod niepoprawny!\n");
	else printf("\nKod poprawny.\n");
	
	return 0;
};

/*---------------------------------------------------------------------------*\
\*---------------------------------------------------------------------------*/

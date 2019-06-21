%{
  /* Token definitions from Bison*/
  #include <string.h>
  #include <stdlib.h>
  #include "types.h"

/*------------------------------------------------------------------------*/
#include "parser.h"

extern char *strdup(const char *);

%}

%option noyywrap

ID			[a-z][a-z0-9_]*
INTEGER		[0-9]+
STRING		\"[^"]*\"
SYMBOL		\(|\)|\+|\-|\*|\/|\%|\=|\<|\>|\;|\,

%%

{SYMBOL}		return *yytext;
":="			return ASSIGN;
"<>"			return NE;
"<="			return LE;
">="			return GE;
"=="			return EQSTR;
"!="			return NESTR;
OR				return OR;
AND			return AND;
NOT			return NOT;
BEGIN			return BEGIn;
END			return END;
EXIT			return EXIT;
IF				return IF;
THEN			return THEN;
ELSE			return ELSE;
WHILE			return WHILE;
DO				return DO;
PRINT			return PRINT;
LENGTH		return LENGTH;
POSITION		return POSITION;
CONCATENATE	return CONCATENATE;
SUBSTRING	return SUBSTRING;
READSTR		return READSTR;
READINT		return READINT;
TRUE			{ yylval.i = 1; return TRUE; }
FALSE			{ yylval.i = 0; return FALSE; }

{INTEGER} 	{ yylval.i = (signed int)atoi(yytext); return NUMBER; }
{STRING}		{ 
	*(yytext + strlen(yytext) - 1) = '\0';
	yylval.txt = strdup(yytext + 1);
	return STRING;
}
{ID}			{ yylval.txt = strdup(yytext); return ID; }

[ \n\t\f]+		{ /* Nothing */ }

<<EOF>>			yyterminate();
.							{
	printf("Unknown character: %c(%x)\n",*yytext,*yytext);
	yyterminate();
}

%%

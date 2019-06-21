%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "types.h"

#define IS_TYPELESS(a)	(!(a).i && !(a).t && !(a).b)

int yylex();
int yyerror(char *);

/*----------------------------------------------------------------------------*\
\*----------------------------------------------------------------------------*/

typedef struct VAR {
	char *name;
	TYPE typ;
	union {
		signed int i;
		char *t;
	} val;
	struct VAR *prev;
} VAR;


/*---------------------------------------------------------------------------*/
static VAR *var = (VAR *)NULL;    /* lista zmiennych */

/*---------------------------------------------------------------------------*/
static VAR *var_new(char *name)
{
	VAR *p = (VAR *)malloc( sizeof(VAR) );

	p->name = name;
	p->typ = (TYPE){0,0,0,0};
	p->val.i = 0;
	p->prev = var;

	return (var = p);
};

/*---------------------------------------------------------------------------*/
static VAR *var_find(const char *name)
{
	VAR *p = var;

	while( p )
		if( !strcmp(p->name, name) ) break;
		else p = p->prev;
		
	return p;
};

/*---------------------------------------------------------------------------*/

%}

%union {
	signed int i;
	char *txt;
	struct EXPR ex;
};

%token		BEGIn END EXIT ASSIGN IF THEN ELSE WHILE DO PRINT
%token		LENGTH POSITION CONCATENATE SUBSTRING READSTR READINT
%token<i>	NUMBER TRUE FALSE
%token<txt>	STRING ID

%type<i>		number
%type<txt>	string id
%type<ex>	expr

%left		OR
%left		AND
%left		'=' '<' '>' NE LE GE EQSTR NESTR
%left		'+' '-'
%left		'*' '/' '%'
%right	NOT
%right	USIGN

%expect 1

%start program

%%

program:
	instr
;

instr:
	instr ';' simple.instr
|	simple.instr
;

simple.instr:
	assign.stat
|	if.stat
|	while.stat
|	BEGIn instr END
|	print.stat
|	EXIT { exit(0) }
;

assign.stat:
	id ASSIGN expr
{
	VAR *p = var_find($1);

	if( !p ) p = var_new($1);
	if( $3.typ.b ) yyerror("`ASSIGN`: oczekiwany typ integer lub string.");
	if( $3.typ.i ) {
		p->val.i = $3.val.i;
		p->typ = (TYPE){1,0,0,0};
	}
	else {
		p->val.t = $3.val.t;
		p->typ = (TYPE){0,1,0,0};
	}
};

if.stat:
	IF expr THEN simple.instr ELSE simple.instr { if(!$2.typ.b ) yyerror("`IF`: oczekiwany typ logiczny.") }
|	IF expr THEN simple.instr { if(!$2.typ.b ) yyerror("`IF`: oczekiwany typ logiczny.") }
;

while.stat:
	WHILE expr DO simple.instr { if( !$2.typ.b ) yyerror("`WHILE`: oczekiwany typ logiczny.") }
|	DO simple.instr WHILE expr { if( !$4.typ.b ) yyerror("`DO WHILE`: oczekiwany typ logiczny.") }
;

print.stat:
	PRINT '(' expr ')'	
{
	if( IS_TYPELESS($3.typ) ) $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( $3.typ.i ) printf("%d",$3.val.i);
	else if( $3.typ.t ) printf("%s",$3.val.t);
	else if( $3.typ.b ) printf("%d",$3.typ.b);
}
|	PRINT						{ printf("\n") }
;

expr:
	number					
{ 
	$$.val.i = $1;
	$$.typ = (TYPE){1,0,0,0};
}
|	string					
{ 
	$$.val.t = $1;
	$$.typ = (TYPE){0,1,0,0};
}
|	TRUE
{
	$$.val.i = $1;
	$$.typ = (TYPE){1,0,0,0};
}
|	FALSE
{
	$$.val.i = $1;
	$$.typ = (TYPE){1,0,0,0};
}
|	id
{
	VAR *p = var_find($1);

	if( !p ) p = var_new($1);
	else {
		$$.val.i = p->val.i;
		$$.typ = (TYPE){1,0,0,0};
	};
}
|	'-' expr %prec USIGN
{
	if( IS_TYPELESS($2.typ) ) $2.val.i = 0, $2.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( !$2.typ.i ) yyerror("`-`: oczekiwane wyrazenie typu integer.");

	$$.val.i = -1*$2.val.i;
	$$.typ = (TYPE){1,0,0,0};
}
|	expr '+' expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.i = 0, $1.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.i = 0, $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( $1.typ.b || $3.typ.b ) yyerror("`+`: oczekiwane wyrazenia typu string lub integer.");

	if( $1.typ.i && $3.typ.i ) {
		$$.val.i = $1.val.i + $3.val.i;
		$$.typ = (TYPE){1,0,0,0};
	}
	else if( $1.typ.t && $3.typ.t ) {
		$$.typ = (TYPE){0,1,0,0};
		$$.val.t = $1.val.t;
		$$.val.t = strcat($$.val.t,$3.val.t);
		if( $3.val.t ) free($3.val.t);
	}
	else yyerror("`+`: oczekiwane wyrazenia typu string lub integer.");
}
|	expr '-' expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.i = 0, $1.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.i = 0, $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.i && $3.typ.i) ) yyerror("`-`: oczekiwane wyrazenia typu integer.");
	$$.val.i = $1.val.i + $3.val.i;
	$$.typ = (TYPE){1,0,0,0};
}
|	expr '*' expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.i = 0, $1.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.i = 0, $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.i && $3.typ.i) ) yyerror("`*`: oczekiwane wyrazenia typu integer.");
	$$.val.i = $1.val.i * $3.val.i;
	$$.typ = (TYPE){1,0,0,0};
}
|	expr '/' expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.i = 0, $1.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.i = 0, $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.i && $3.typ.i) ) yyerror("`/`: oczekiwane wyrazenia typu integer.");
	$$.val.i = $1.val.i / $3.val.i;
	$$.typ = (TYPE){1,0,0,0};
}
|	expr '%' expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.i = 0, $1.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.i = 0, $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.i && $3.typ.i) ) yyerror("`%`: oczekiwane wyrazenia typu integer.");
	$$.val.i = $1.val.i % $3.val.i;
	$$.typ = (TYPE){1,0,0,0};
}
|	'(' expr ')'			{ $$ = $2 }
|	expr '=' expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.i = 0, $1.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.i = 0, $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.i && $3.typ.i) ) yyerror("`=`: oczekiwane wyrazenia typu integer.");
	$$.val.i = ($1.val.i == $3.val.i);
	$$.typ = (TYPE){0,0,1,0};
}
|	expr '<' expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.i = 0, $1.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.i = 0, $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.i && $3.typ.i) ) yyerror("`<`: oczekiwane wyrazenia typu integer.");
	$$.val.i = ($1.val.i < $3.val.i);
	$$.typ = (TYPE){0,0,1,0};
}
|	expr '>' expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.i = 0, $1.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.i = 0, $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.i && $3.typ.i) ) yyerror("`>`: oczekiwane wyrazenia typu integer.");
	$$.val.i = ($1.val.i > $3.val.i);
	$$.typ = (TYPE){0,0,1,0};
}
|	expr NE expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.i = 0, $1.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.i = 0, $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.i && $3.typ.i) ) yyerror("`<>`: oczekiwane wyrazenia typu integer.");
	$$.val.i = ($1.val.i != $3.val.i);
	$$.typ = (TYPE){0,0,1,0};
}
|	expr LE expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.i = 0, $1.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.i = 0, $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.i && $3.typ.i) ) yyerror("`<=`: oczekiwane wyrazenia typu integer.");
	$$.val.i = ($1.val.i <= $3.val.i);
	$$.typ = (TYPE){0,0,1,0};
}
|	expr GE expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.i = 0, $1.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.i = 0, $3.typ = (TYPE){1,0,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.i && $3.typ.i) ) yyerror("`>=`: oczekiwane wyrazenia typu integer.");
	$$.val.i = ($1.val.i >= $3.val.i);
	$$.typ = (TYPE){0,0,1,0};
}
|	expr EQSTR expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.t = (char *)NULL, $1.typ = (TYPE){0,1,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.t = (char *)NULL, $3.typ = (TYPE){0,1,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.t && $3.typ.t) ) yyerror("`==`: oczekiwane wyrazenia typu string.");
	$$.val.i = !strcmp($1.val.t, $3.val.t);
	$$.typ = (TYPE){0,0,1,0};
}
|	expr NESTR expr
{
	if( IS_TYPELESS($1.typ) ) $1.val.t = (char *)NULL, $1.typ = (TYPE){0,1,0,0}; /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) $3.val.t = (char *)NULL, $3.typ = (TYPE){0,1,0,0}; /* zmienna niezainicjowana */

	if( !($1.typ.t && $3.typ.t) ) yyerror("`!=`: oczekiwane wyrazenia typu string.");
	$$.val.i = abs( strcmp($1.val.t, $3.val.t) );
	$$.typ = (TYPE){0,0,1,0};
}
|	NOT expr
{
	if( IS_TYPELESS($2.typ) ) yyerror("`OR`: oczekiwane wyrazenie logiczne."); /* zmienna niezainicjowana */

	if( !$2.typ.b ) yyerror("`NOT`: oczekiwane wyrazenie typu logicznego.");
	$$.val.i = ~$2.val.i;
	$$.typ = $2.typ;
}
|	expr OR expr
{
	if( IS_TYPELESS($1.typ) ) yyerror("`OR`: oczekiwane wyrazenie logiczne."); /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) yyerror("`OR`: oczekiwane wyrazenie logiczne."); /* zmienna niezainicjowana */

	if( !($1.typ.b && $3.typ.b) ) yyerror("`OR`: oczekiwane wyrazenie typu logicznego.");
	$$.val.i = $1.val.i || $3.val.i;
	$$.typ = (TYPE){0,0,1,0};
}
|	expr AND expr
{
	if( IS_TYPELESS($1.typ) ) yyerror("`AND`: oczekiwane wyrazenie logiczne."); /* zmienna niezainicjowana */
	if( IS_TYPELESS($3.typ) ) yyerror("`AND`: oczekiwane wyrazenie logiczne."); /* zmienna niezainicjowana */

	if( !($1.typ.b && $3.typ.b) ) yyerror("`AND`: oczekiwane wyrazenie typu logicznego.");
	$$.val.i = $1.val.i && $3.val.i;
	$$.typ = (TYPE){0,0,1,0};
}
|	LENGTH '(' expr ')'
{
	if( IS_TYPELESS($3.typ) ) $3.val.t = (char *)NULL, $3.typ = (TYPE){0,1,0,0}; /* zmienna niezainicjowana */

	if( !$3.typ.t ) yyerror("`LENGTH`: oczekiwane wyrazenie typu string.");
	$$.val.i = ($3.val.t ? (signed int)strlen($3.val.t) : 0);
	$$.typ = (TYPE){1,0,0,0};
}
|	POSITION '(' expr ',' expr ')'
{
	char *s = (char *)NULL;

	if( !($3.typ.t && $5.typ.t) ) yyerror("`POSITION`: oczekiwane wyrazenia typu string.");

	s = strstr($3.val.t, $5.val.t);

	$$.val.i = (s ? s - $3.val.t + 1 : 0);
	$$.typ = (TYPE){1,0,0,0};
}
|	CONCATENATE '(' expr ',' expr ')'
{
	if( !($3.typ.t && $5.typ.t) ) yyerror("`CONCATENATE`: oczekiwane wyrazenia typu string.");
	$$.typ = (TYPE){0,1,0,0};
	$$.val.t = $3.val.t;
	$$.val.t = strcat($$.val.t,$5.val.t);
	if( $5.val.t ) free($5.val.t);
}
|	SUBSTRING '(' expr ',' expr ',' expr ')' 
{
	if( !$3.typ.t ) yyerror("`SUBSTRING`: oczekiwane wyrazenia typu string.");
	if( !($5.typ.i && $7.typ.i) ) yyerror("`SUBSTRING`: oczekiwane wyrazenia typu integer.");
	$$.typ = (TYPE){0,1,0,0};
}
|	READSTR { $$.typ = (TYPE){1,0,0,0} }
|	READINT { $$.typ = (TYPE){0,1,0,0} }
;

id:
	ID { $$ = $1 }
;

number:
	NUMBER { $$ = $1 }
;

string:
	STRING { $$ = $1 }
;

%%

int yyerror(s)
	char *s;
{
    fprintf(stderr, "%s\n", s);
};

typedef struct {
	unsigned char i : 1;
	unsigned char t : 1;
	unsigned char b : 1;
	unsigned char x : 5;
} TYPE;

typedef struct EXPR {
	TYPE typ;
	union {
		signed int i;
		char *t;
	} val;
} EXPR;
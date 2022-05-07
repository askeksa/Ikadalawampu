
#include <math.h>

typedef unsigned char byte;

enum tree_code {
	FANOUT = 0xf5,
	NOPLEAF = 0xf6,
	SAVETRANS = 0xf7,
	REPEAT = 0xf8,
	CONDITIONAL = 0xf9,
	GLOBALDEF = 0xfa,
	SCALE = 0xfb,
	MOVE = 0xfc,
	ROTATE = 0xfd,
	DRAW = 0xfe,
	LABEL = 0xff
};

enum exp_code {
	RANDOM = 0xf7,
	NOTEAT = 0xf8,
	ADD = 0xf9,
	SUB = 0xfa,
	MUL = 0xfb,
	ROUND = 0xfc,
	CLAMP = 0xfd,
	SIN = 0xfe
};

struct matrix2D {
	float m00,m10,m01,m11,x0,y0;
};

struct particle {
	struct matrix2D transform;
	float c0,c1;
};


byte *labels[256];
struct matrix2D matrixstack[1024];
float notepositions[100000];
unsigned int ticks_per_track;
float *constantpool;
byte *tree_root;


byte *traverse(byte *tree, struct matrix2D *matrixstack, struct particle **outp);

float eval(byte **expp);


void init_interpret(byte *tree, unsigned int tree_size, float *cp, byte *musicdata, unsigned int musiclength, unsigned int numtracks, float ticklength) {
	int c,i;
	int l = 0;
	for (i = 0 ; i < tree_size ; i++) {
		if (tree[i] == LABEL) {
			labels[l++] = &tree[i+1];
		}
	}
	tree_root = tree;
	constantpool = cp;

	ticks_per_track = musiclength;
	for (c = 0 ; c < numtracks ; c++) {
		float t = 0.0f;
		for (i = 0 ; i < musiclength ; i++) {
			int tick = c * musiclength + i;
			if ((musicdata[tick>>3] >> (7-(tick&7))) & 1) {
				t = i * ticklength;
			}
			notepositions[tick] = t;
		}
	}
}



unsigned int interpret(float time, struct particle *out)
{
	struct particle *old_out = out;
	matrixstack[0].m00 = 2.0f/320.0f;
	matrixstack[0].m10 = 0.0f;
	matrixstack[0].m01 = 0.0f;
	matrixstack[0].m11 = 2.0f/200.0f;
	matrixstack[0].x0 = 0.0f;
	matrixstack[0].y0 = 0.0f;

	constantpool[0] = time;

	traverse(tree_root, matrixstack, &out);

	return out-old_out;
}

byte *traverse(byte *tree, struct matrix2D *mtop, struct particle **outp)
{
	byte label, var;
	float x,y,c,sinc,cosc;
	struct particle *out;
	switch ((enum tree_code)*tree++) {
	case FANOUT:
		while (*tree != 0) {
			tree = traverse(tree, mtop, outp);
		}
		return tree+1;
	case NOPLEAF:
		return tree;
	case SAVETRANS:
		mtop[1] = mtop[0];
		return traverse(tree, mtop+1, outp);
	case REPEAT:
		label = *tree++;
		if (*tree > 1) {
			*tree -= 1;
			traverse(labels[label], mtop, outp);
			*tree += 1;
		}
		return tree+1;
	case CONDITIONAL:
		c = eval(&tree);
		label = c < 0.0f ? tree[0] : tree[1];
		traverse(labels[label], mtop, outp);
		return tree+2;
	case GLOBALDEF:
		c = eval(&tree);
		var = *tree++;
		constantpool[var] = c;
		return traverse(tree, mtop, outp);
	case SCALE:
		y = eval(&tree);
		x = eval(&tree);
		mtop->m00 *= x;
		mtop->m10 *= x;
		mtop->m01 *= y;
		mtop->m11 *= y;
		return traverse(tree, mtop, outp);
	case MOVE:
		y = eval(&tree);
		x = eval(&tree);
		mtop->x0 += mtop->m00 * x + mtop->m01 * y;
		mtop->y0 += mtop->m10 * x + mtop->m11 * y;
		return traverse(tree, mtop, outp);
	case ROTATE:
		c = eval(&tree);
		c *= (float)(2.0 * 3.14159265358979);
		sinc = sin(c);
		cosc = cos(c);
		x = mtop->m00;
		y = mtop->m01;
		mtop->m00 = x * cosc + y * sinc;
		mtop->m01 = y * cosc - x * sinc;
		x = mtop->m10;
		y = mtop->m11;
		mtop->m10 = x * cosc + y * sinc;
		mtop->m11 = y * cosc - x * sinc;
		return traverse(tree, mtop, outp);
	case DRAW:
		y = eval(&tree);
		x = eval(&tree);
		out = *outp;
		out->transform = mtop[0];
		out->c0 = x;
		out->c1 = y;
		(*outp)++;
		return tree;
	case LABEL:
		return traverse(tree, mtop, outp);
	}

	return tree;
}

float eval(byte **expp) {
	float a,b;
	int r,tick;
	enum exp_code e = (enum exp_code)*(*expp)++;
	switch (e) {
	case RANDOM:
		r = *(int *)&constantpool[1];
		r = (r+7)*16307;
		*(int *)&constantpool[1] = r;
		return (r >> 16) * (1.0f / 32768.0f);
	case NOTEAT:
		a = eval(expp);
		b = eval(expp);
		tick = ((int)a) * ticks_per_track + (int)b;
		return b - notepositions[tick];
	case ADD:
		a = eval(expp);
		b = eval(expp);
		return a+b;
	case SUB:
		a = eval(expp);
		b = eval(expp);
		return a-b;
	case MUL:
		a = eval(expp);
		b = eval(expp);
		return a*b;
	case ROUND:
		a = eval(expp);
		return floorf(a+0.5f);
	case CLAMP:
		a = eval(expp);
		return a < 0.0f ? 0.0f : a;
	case SIN:
		a = eval(expp);
		a *= (float)(2.0 * 3.14159265358979);
		return sin(a);
	default:
		return constantpool[e];
	}
}


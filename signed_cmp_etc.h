#define my_lt(a,b)	((a) <  (b))
#define my_le(a,b)	((a) <= (b))
#define my_eq(a,b)	((a) == (b))
#define my_ne(a,b)	((a) != (b))

/* signed vs unsigned; avoid bubbles */
#define my_lt_su(a,b)	(((a) <  0) | ((a) <  (b)))
#define my_le_su(a,b)	(((a) <  0) | ((a) <= (b)))
#define my_eq_su(a,b)	(((a) >= 0) & ((a) == (b)))
#define my_ne_su(a,b)	(((a) <  0) | ((a) != (b)))

/* unsigned vs signed; avoid bubbles */
#define my_lt_us(a,b)	(((b) >= 0) & ((a) <  (b)))
#define my_le_us(a,b)	(((b) >= 0) & ((a) <= (b)))
#define my_eq_us(a,b)	(((b) >= 0) & ((a) == (b)))
#define my_ne_us(a,b)	(((b) <  0) | ((a) != (b)))

#define ldexp_neg(a,b)	ldexp((a), -(b))
#define ldexp_negl(a,b)	ldexpl((a), -(b))

#define my_ne0(a)	(0 != (a))

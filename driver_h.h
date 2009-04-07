typedef int array_stride, array_ind, array_lim;	/* lim is number of items */
typedef struct { array_stride stride; array_lim lim; } array_form1, *array_form;
typedef const array_form1 *carray_form;

typedef struct {const char* const codes_name; void * const fp; } func_descr;
extern const func_descr * const func_names_p;
extern const int func_names_c;

extern const unsigned char* name_by_t;
extern const unsigned char* const size_by_t_p;
extern const unsigned char* const duplicate_types_s;

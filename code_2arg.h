static void
THIS_OP_NAME(const char *from1_s, const char *from2_s, char *to_s,
 int dim, carray_form from1_form, carray_form from2_form, carray_form to_form)
{
    const SOURCE1_ELT_TYPE *from1 = (const SOURCE1_ELT_TYPE *) from1_s;
    const SOURCE2_ELT_TYPE *from2 = (const SOURCE2_ELT_TYPE *) from2_s;
    TARG_ELT_TYPE *to = (TARG_ELT_TYPE *)to_s;
    array_stride f1stride;
    array_stride f2stride;
    array_stride tstride;
    array_count n;	/* Can't stop by inspecting to: stride may be 0 */

    if (!dim) {
	DO_2OP(to[0], from1[0], from2[0]);
        return;
    }
    n = to_form[dim - 1].count;
    f1stride = from1_form[dim - 1].stride;
    f2stride = from2_form[dim - 1].stride;
    tstride =   to_form[dim - 1].stride;
  
    if (1 == dim) {
	while (n--) {
	  DO_2OP(*to, *from1, *from2);
	  from1 += f1stride;
	  from2 += f2stride;
	  to += tstride;
	}
    } else {
	while (n--) {
	  THIS_OP_NAME((const char*)from1, (const char*)from2, (char*)to, dim-1, from1_form, from2_form, to_form);
	  from1 += f1stride;
	  from2 += f2stride;
	  to += tstride;
	}
    }
}

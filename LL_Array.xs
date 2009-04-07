#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "driver_h.h"

/* Temporary placeholder */
extern void a_accessor__d(AV *av, const char *p_s, int dim, carray_form format);

carray_form
sv_2_carray_form(int dim, SV *sv)
{
    if (SvPOK(sv)) {
	if (SvCUR(sv) < dim * sizeof(array_form1))
	    croak("String given as carray_form is too short: expect len=%d, got %d",
		  dim * sizeof(array_form1), SvCUR(sv));
	return (carray_form)SvPV_nolen(sv);
    }
    if (SvROK(sv)) {
	int d;
	array_form format;
	SV **svp;
	AV *av = (AV*)SvRV(sv);

	if (SvTYPE(av) != SVt_PVAV)
	    croak("Reference given as carray_form is not an ARRAY reference");
	d = av_len(av);			/* Last index */
	if (d < 2*dim - 1)
	    croak("Array given as carray_form is too short: expect len=%d, got %d",
		  2*dim, d);
	New(917, format, dim, array_form1);
	save_freepv((char*)format);	/* Why undocumented?  Savefree() later */
	svp = AvARRAY(av);

	for (d = 0; d < dim; d++) {
	    format[d].stride = SvIV(svp[2*d]);
	    format[d].lim = SvIV(svp[2*d + 1]);
	}
	return (carray_form)format;
    }
}

void
_a_accessor__d(pTHX_ SV *sv, const char *p_s, int dim, SV* format)
{
    AV *av;

    carray_form f = sv_2_carray_form(dim, format);
    if (!SvOK(sv))
	av = 0;
    else if (SvROK(sv) && SvTYPE(SvRV(sv))==SVt_PVAV)
	av = (AV*)SvRV(sv);
    else
	Perl_croak("av is not an array reference");
    a_accessor__d(aTHX_ av, p_s, dim, f);
}

#if 0	/* Code for testing */
void
sc2d_assign_(const signed char *from_s, char *to_s, int dim, carray_form from_form, carray_form to_form)
{
    const signed char *from = (const signed char *) from_s;
    double *to = (double *)to_s;
    const signed char* lim;
    array_stride fstride;
    array_stride tstride;

    if (!dim) {
	to[0] = (double)from[0];
        return;
    }
    lim = from + from_form[dim - 1].lim;
    fstride = from_form[dim - 1].stride;
    tstride =   to_form[dim - 1].stride;
  
    if (1 == dim) {
	while (from < lim) {
	  *to = (double)*from;
	  from += fstride;
	  to += tstride;
	}
    } else {
	while (from < lim) {
	  sc2d_assign_((const char*)from, (char*)to, dim-1, from_form, to_form);
	  from += fstride;
	  to += tstride;
	}
    }
}
#endif

/* #include "driver_c.h" */
const char*
duplicate_types(void)
{
  return duplicate_types_s;
}


array_ind
mInd2ind(int dim, const array_ind *ind, carray_form format)
{
  array_ind ret = 0;

  while (--dim >= 0) {
    ret += format[dim].stride * ind[dim];
  }
  return ret;
}

int
checkfit(IV lim, int len, int dim, const array_ind *start, carray_form format)
{
  IV start_i = mInd2ind(dim, start, format);
  IV min = start_i, max = start_i, diff;
  int m = 0;

  while (m < dim) {			/* We do not check overflow... */
    diff = (format[m].lim - 1) * format[m].stride;
    if (format[m].stride > 0) {
      max += diff;	/* We assume lim[m] >= 1 */
    } else if (min >= -diff) {
      min += diff;
    } else
      return 0;
    m++;
  }
  max *= len;
  if (max * len < lim)
    return 1;
  return 0;
}

double
d_extract_1(char *s, int off)
{
    double *arr = (double *)s;
    return arr[off];
}

SV *
d_extract_as_ref(char *s, int start, int count, int stride)
{
    double *arr = (double *)s;
    AV *av = newAV();
    SV **sv_arr;

    av_fill(av, count-1);
    sv_arr = AvARRAY(av);

    arr += start;

    while (count--) {
	*sv_arr++ = newSVnv(*arr);
	arr += stride;
    }
    return newRV_noinc((SV*)av);
}

#if 0		/* What is the intent of this??? */
void
d_extract_to(SV *sv, char *s, int start, int count, int o_start, int stride, int o_stride)
{
    double *arr = (double *)s;
    AV *av;
    SV **sv_arr;

    av_fill(av, count-1);
    sv_arr = AvARRAY(av);

    arr += start;

    while (count--) {
	*sv_arr++ = newSVnv(*arr);
	arr += stride;
    }
    return newRV_noinc((SV*)av);
}
#endif

MODULE = Numeric::LL_Array		PACKAGE = Numeric::LL_Array

double
d_extract_1(s, off)
    char *s
    int off

void
d_extract(s, start, count, stride = 1)
    char *s
    int start
    int count
    int stride
  PPCODE:
  {
    double *arr = (double *)s;

    EXTEND(SP, count);
    arr += start;

    while (count--) {
	PUSHs(sv_2mortal(newSVnv(*arr)));
	arr += stride;
    }
  }

SV *
d_extract_as_ref(s, start, count, stride = 1)
    char *s
    int start
    int count
    int stride

const char*
duplicate_types()

void
__a_accessor__d(SV *sv, const char *p_s, int dim, SV* format)
    PPCODE:
	/* Temporary wrapper for debugging, especially (1) */
	PUTBACK;
	_a_accessor__d(aTHX_ sv, p_s, dim, format);
	SPAGAIN;


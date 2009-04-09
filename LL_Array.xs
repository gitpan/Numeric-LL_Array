#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "driver_h.h"

void
croak_on_invalid_entry(void)
{
  croak("An invalid entry in dispatch table reached; a naked INTERFACE XSUB exposed?");
}

carray_form
sv_2_carray_form(int dim, SV *sv)
{
    if (!dim)
	return NULL;
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
	    format[d].count = SvIV(svp[2*d + 1]);
	}
	return (carray_form)format;
    }
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
    array_count n;

    if (!dim) {
	to[0] = (double)from[0];
        return;
    }
    n = from_form[dim - 1].count;
    fstride = from_form[dim - 1].stride;
    tstride =   to_form[dim - 1].stride;
  
    if (1 == dim) {
	while (n--) {
	  *to = (double)*from;
	  from += fstride;
	  to += tstride;
	}
    } else {
	while (n--) {
	  sc2d_assign_((const char*)from, (char*)to, dim-1, from_form, to_form);
	  from += fstride;
	  to += tstride;
	}
    }
}
#endif

array_ind
mInd2ind(int dim, const array_ind *ind, carray_form format)
{
  array_ind ret = 0;

  while (--dim >= 0) {
    ret += format[dim].stride * ind[dim];
  }
  return ret;
}

int			/* lim is in bytes, start_i in len bytes */
checkfit(IV lim, int len, int dim, const IV start_i, carray_form format)
{
  IV min = start_i, max = start_i, diff;
  int m = 0;

  while (m < dim) {			/* We do not check overflow... */
    diff = (format[m].count - 1) * format[m].stride;
    if (format[m].stride > 0) {		/* diff > 0 */
      max += diff;	/* We assume count[m] >= 1 */
    } else if (min >= -diff) {		/* diff <= 0 here */
      min += diff;
    } else
      return 0;
    m++;
  }
  if (max * len < lim)
    return 1;
  return 0;
}

int
checkfit_v(IV lim, int len, int dim, const array_ind *start, carray_form format)
{
  IV start_i = mInd2ind(dim, start, format);

  return checkfit(lim, len, dim, start_i, format);
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

static int
find_in_ftable(char *s, func_descr *table, int tcount)
{
  int n;

  for (n = 1; n < tcount; n++) {
    if (0 == strcmp(table[n].codes_name, s))
      return n;
  }
  return 0;
}

static int
find_in_ftables(char *s, int arity)
{
  switch (arity) {
    case -1:	/* Accessor */
	return find_in_ftable(s, (func_descr *)f_ass_names_p,  f_ass_names_c);
    case 0:
	return find_in_ftable(s, (func_descr *)f_0arg_names_p, f_0arg_names_c);
    case 1:
	return find_in_ftable(s, (func_descr *)f_1arg_names_p, f_2arg_names_c);
    case 2:
	return find_in_ftable(s, (func_descr *)f_2arg_names_p, f_2arg_names_c);
    default:
	croak("Unknown table arity for find: %d; expect -1,0,1,2", arity);
  }
  return 0;
}

XS(XS_Numeric__LL_Array___a_accessor__INTERFACE); /* prototype to pass -Wmissing-prototypes */
XS(XS_Numeric__LL_Array__0arg__INTERFACE); /* prototype to pass -Wmissing-prototypes */

static void
init_interface(char *perl_name, int arity, char *code, char *perl_file)
{
  CV *mycv;
  int n = find_in_ftables(code, arity);

  switch (arity) {
    case -1:	/* Accessor */
	mycv = newXS(perl_name, XS_Numeric__LL_Array___a_accessor__INTERFACE, perl_file);
	break;
    case 0:
	mycv = newXS(perl_name, XS_Numeric__LL_Array__0arg__INTERFACE, perl_file);
	break;
/*    case 1:
	return find_in_ftable(s, (func_descr *)f_1arg_names_p, f_2arg_names_c);
    case 2:
	return find_in_ftable(s, (func_descr *)f_2arg_names_p, f_2arg_names_c);
*/
    default:
	croak("Unknown table arity for create: %d; expect -1,0,1,2", arity);
  }
  CvXSUBANY(mycv).any_i32 = n;
}

#define typeNames()		name_by_t
#define typeSizes()		size_by_t_p
#define duplicateTypes()	duplicate_types_s

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

int
find_in_ftables(s, arity)
    char *s
    int arity

void
init_interface(perl_name, arity, code, perl_file)
    char *perl_name
    int arity
    char *code
    char *perl_file

void
__a_accessor__INTERFACE(SV *p, I32 offset = 0, int dim = 0, SV* format = Nullsv, SV *sv = Nullsv, bool keep = FALSE)
    PPCODE:
   {
       AV *av;
       const char *p_s;
       STRLEN sz;
       dXSI32;		/* ix */
       int sizeof_elt = f_ass_names_p[ix].codes_name[0];

       if (!sv || !SvOK(sv))
	   av = 0;
       else if (!SvROK(sv) && SvTRUE(sv)) {
	   if (dim) {
	       av = newAV();
	       PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
	   } else
	       av = 0;
       } else if (SvROK(sv) && SvTYPE(SvRV(sv))==SVt_PVAV) {
	   av = (AV*)SvRV(sv);
	   if (!keep)
	       av_clear(av);
	   PUSHs(sv);
       } else
	   Perl_croak("av is not an array reference");
       if (dim && !format)
	   Perl_croak("format should be present if dim is 0");
       p_s = SvPV(p, sz);
       PUTBACK;
       {
         carray_form f = sv_2_carray_form(dim, format);

         if (!checkfit(sz, sizeof_elt, dim, offset, f))
             croak("Array not fitting into a playground");
         (f_ass_names_p[ix].fp)(aTHX_ av, p_s + sizeof_elt*offset, dim, f);
       }
       SPAGAIN;    
   }

void
_0arg__INTERFACE(SV *p, I32 offset = 0, int dim = 0, SV* format = Nullsv)
    PPCODE:
   {
       char *p_s;
       STRLEN sz;
       dXSI32;		/* ix */
       int sizeof_elt = f_0arg_names_p[ix].codes_name[0];

       if (dim && !format)
	   Perl_croak("format should be present if dim is 0");
       p_s = SvPV(p, sz);
       {
         carray_form f = sv_2_carray_form(dim, format);

         if (!checkfit(sz, sizeof_elt, dim, offset, f))
             croak("Array not fitting into a playground");
         (f_0arg_names_p[ix].fp)(p_s + sizeof_elt*offset, dim, f);
       }
       XSRETURN_YES;
   }

#if 0 && defined(do_1arg_later)


void
_1arg__INTERFACE(SV *s_p, SV *p, I32 s_offset = 0, I32 offset = 0, int dim = 0, SV* sformat = Nullsv, SV* format = Nullsv)
    PPCODE:
   {
       AV *av;
       char *p_s;
       const char *sp_s;
       STRLEN sz, ssz;
       dXSI32;		/* ix */
       int sizeof_elt   = f_1arg_names_p[ix].codes_name[0];
       int s_sizeof_elt = f_1arg_names_p[ix].codes_name[1];

       if (dim && !(format && sformat))
	   Perl_croak("format should be present if dim is 0");
       p_s = SvPV(p, sz);
       sp_s = SvPV(s_p, ssz);
       PUTBACK;
       {
         carray_form f = sv_2_carray_form(dim, format);
         carray_form s_f = sv_2_carray_form(dim, format);

         if (!checkfit(sz, sizeof_elt, dim, offset, f))
             croak("Target array not fitting into a playground");
         if (!checkfit(ssz, s_sizeof_elt, dim, s_offset, s_f))
             croak("Source array not fitting into a playground");
         (f_1arg_names_p[ix].fp)(aTHX_ av, p_s + sizeof_elt*offset, dim, f);
       }
       SPAGAIN;    
   }

#endif

#if 0

void
__a_accessor__d_old(SV *p, I32 offset = 0, int dim = 0, SV* format = Nullsv, SV *sv = Nullsv, bool keep = FALSE)
    PPCODE:
   {	/* Temporary wrapper for debugging, especially (1) */
       AV *av;
       const char *p_s;
       STRLEN sz;
       int sizeof_elt = sizeof(double);

       if (!sv || !SvOK(sv))
	   av = 0;
       else if (!SvROK(sv) && SvTRUE(sv)) {
	   if (dim) {
	       av = newAV();
	       PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
	   } else
	       av = 0;
       } else if (SvROK(sv) && SvTYPE(SvRV(sv))==SVt_PVAV) {
	   av = (AV*)SvRV(sv);
	   if (!keep)
	       av_clear(av);
	   PUSHs(sv);
       } else
	   Perl_croak("av is not an array reference");
       if (dim && !format)
	   Perl_croak("format should be present if dim is 0");
       p_s = SvPV(p, sz);
       PUTBACK;
       {
         carray_form f = sv_2_carray_form(dim, format);

         if (!checkfit(sz, sizeof_elt, dim, offset, f))
             croak("Array not fitting into a playground");
         a_accessor__d(aTHX_ av, p_s + sizeof_elt*offset, dim, f);
       }
       SPAGAIN;    
   }

#endif

const char*
typeNames()

const char*
typeSizes()

const char*
duplicateTypes()


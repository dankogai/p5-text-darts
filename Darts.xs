#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "darts.h"
#define MAX_NMATCH 1024

static int da_make(AV *av){
    Darts::DoubleArray *dp = new Darts::DoubleArray;
    std::vector <const Darts::DoubleArray::key_type *> keys;
    int i, l;
    for (i = 0, l = av_len(av)+1; i < l; i++){
	keys.push_back(SvPV_nolen(AvARRAY(av)[i]));
    }
    dp->build(keys.size(), &keys[0], 0, 0);
    return PTR2IV(dp);
}

static int da_free(int dpi){
    delete INT2PTR(Darts::DoubleArray *, dpi);
}

static int da_open(char *filename){
    Darts::DoubleArray *dp = new Darts::DoubleArray;
    if (dp->open(filename) == -1){
	delete dp;
	return 0;
    }
    return PTR2IV(dp);
}

static int da_search(int dpi, char *str){
    Darts::DoubleArray *dp = INT2PTR(Darts::DoubleArray *, dpi);
    Darts::DoubleArray::result_pair_type  result_pair [MAX_NMATCH];
    size_t num = dp->commonPrefixSearch(str, result_pair, sizeof(result_pair));
    return num;
}


static SV *do_callback(SV *callback, SV *s){
    dSP;
    int argc;
    SV *retval;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    XPUSHs(s);
    PUTBACK;
    argc = call_sv(callback, G_SCALAR);
    SPAGAIN;
    if (argc != 1){
        croak("fallback sub must return scalar!");
    }
    retval = newSVsv(POPs);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

static SV *do_hvlookup(SV *hashref, char *str, size_t len){
    SV **val = hv_fetch((HV *)SvRV(hashref), str, len, 0 );
    return val && *val ? *val : &PL_sv_undef;
}


static SV *da_gsub(int dpi, SV *src, SV *rep){
    SV *result = newSV(SvCUR(src));
    Darts::DoubleArray *dp = INT2PTR(Darts::DoubleArray *, dpi);
    Darts::DoubleArray::result_pair_type  result_pair[MAX_NMATCH];

    char *head = SvPV_nolen(src);
    char *tail = head + SvCUR(src);

    while (head < tail) {
	char *ohead = head;
	size_t size, rlen = 0;
	while(head < tail){
	    size = 
		dp->commonPrefixSearch(head,result_pair, sizeof(result_pair));
	    if (size) break;
	    head++;
	}
	if (head != ohead){
	    size_t d = (head - ohead);
	    rlen += d;
	    if (rlen > SvCUR(result)) SvGROW(result, SvCUR(result)*2);
	    sv_catpvn(result, ohead, d);
	}
	if (size) {
	    size_t seekto = 0;       
	    for (size_t i = 0; i < size; ++i) {
		if (seekto < result_pair[i].length)
		    seekto = result_pair[i].length;
	    }
	    if (seekto) {
		SV *ret = SvTYPE(SvRV(rep)) == SVt_PVCV
		    ? do_callback(rep, newSVpvn(head, seekto))
		    : do_hvlookup(rep, head, seekto);
		rlen += SvCUR(ret);
		if (rlen > SvCUR(result)) SvGROW(result, SvCUR(result)*2);
		sv_catpvn(result, SvPVX(ret), SvCUR(ret));
		head += seekto;
	    }
	}
    }
    return result;
}

MODULE = Text::Darts		PACKAGE = Text::Darts		

int
xs_make(av)
   AV *av
CODE:
   RETVAL = da_make(av);
OUTPUT:
   RETVAL

int
xs_free(dpi)
    int  dpi;
CODE:
    RETVAL = da_free(dpi);
OUTPUT:
    RETVAL

int
xs_open(filename)
   char *filename
CODE:
   RETVAL = da_open(filename);
OUTPUT:
   RETVAL

SV *
xs_gsub(dpi, src, rep)
   int dpi;
   SV *src;
   SV *rep; 
CODE:
   RETVAL = da_gsub(dpi, src, rep);
OUTPUT:
   RETVAL

int
xs_search(dpi, str)
    int  dpi;
    char *str;
CODE:
    RETVAL = da_search(dpi, str);
OUTPUT:
    RETVAL

char *
DARTS_VERSION()
CODE:
    RETVAL = DARTS_VERSION;
OUTPUT:
    RETVAL

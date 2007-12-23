#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <darts.h>
#define MAX_NMATCH 1024

int da_make(AV *av){
    Darts::DoubleArray *dp = new Darts::DoubleArray;
    std::vector <Darts::DoubleArray::key_type *> keys;
    int i, l;
    for (i = 0, l = av_len(av)+1; i < l; i++){
	keys.push_back(SvPV_nolen(AvARRAY(av)[i]));
    }
    dp->build(keys.size(), &keys[0], 0, 0);
    return PTR2IV(dp);
}

int da_free(int dpi){
    delete INT2PTR(Darts::DoubleArray *, dpi);
}

int da_open(char *filename){
    Darts::DoubleArray *dp = new Darts::DoubleArray;
    if (dp->open(filename) == -1){
	delete dp;
	return 0;
    }
    return PTR2IV(dp);
}

int da_search(int dpi, char *str){
    Darts::DoubleArray *dp = INT2PTR(Darts::DoubleArray *, dpi);
    Darts::DoubleArray::result_pair_type  result_pair [MAX_NMATCH];
    size_t num = dp->commonPrefixSearch(str, result_pair, sizeof(result_pair));
    return num;
}


static SV *
do_callback(SV *callback, SV *s){
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

SV *da_gsub(int dpi, SV *src, SV *callback){
    SV *result = newSV(0);
    Darts::DoubleArray *dp = INT2PTR(Darts::DoubleArray *, dpi);
    Darts::DoubleArray::result_pair_type  result_pair[MAX_NMATCH];

    char *head = SvPV_nolen(src);
    char *tail = head + SvCUR(src);

    while (head < tail) {
	size_t size = 
	    dp->commonPrefixSearch(head,result_pair, sizeof(result_pair));
	size_t seekto = 0;       
	if (size) {
	    for (size_t i = 0; i < size; ++i) {
		if (seekto < result_pair[i].length)
		    seekto = result_pair[i].length;
	    }
	    if (seekto) {
		SV *ret = do_callback(callback, newSVpvn(head, seekto));
		sv_catsv(result, ret);
		head += seekto;
	    }
	}
	if (seekto == 0) {
	    sv_catpvn(result, head, 1);
	    ++head; 
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
xs_gsub(dpi, src, callback)
   int dpi;
   SV *src;
   SV *callback; 
CODE:
   RETVAL = da_gsub(dpi, src, callback);
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

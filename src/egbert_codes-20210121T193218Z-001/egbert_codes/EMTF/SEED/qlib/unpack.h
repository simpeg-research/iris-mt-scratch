/*  Routines in unpack.c						*/
/*	@(#)unpack.h	1.3 5/24/96 15:44:25	*/

#ifndef	__unpack_h
#define	__unpack_h

#include "steim.h"

#ifdef	__cplusplus
extern "C" {
#endif

int	unpack_steim1 (FRAME *, int, int, int, int *, int *, int *, int *, char **);
int	unpack_steim2 (FRAME *, int, int, int, int *, int *, int *, int *, char **);
int	unpack_int_32 (int *, int, int, int, int *, char **);
int	unpack_int_16 (int *, int, int, int, int *, char **);
int	unpack_int_24 (int *, int, int, int, int *, char **);

#ifdef	__cplusplus
}
#endif

#endif

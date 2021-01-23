/*  Routines in ms_utils.c						*/
/*	@(#)ms_utils.h	1.2 5/24/96 15:44:16	*/

#ifndef	__ms_utils_h
#define	__ms_utils_h

#include <stdio.h>
#include "data_hdr.h"
#include "sdr.h"

#ifdef	__cplusplus
extern "C" {
#endif

int	read_ms_ (DATA_HDR *, void *, int *, FILE **);
int	read_ms (DATA_HDR **, void *, int, FILE *);
int	read_ms_hdr (DATA_HDR **, FILE *);
int	read_ms_bkt (DATA_HDR *, FILE *, char *);
int	read_ms_data (DATA_HDR *, void *, int, FILE *);
DATA_HDR *decode_fixed_data_hdr (SDR_HDR *);

#ifdef	__cplusplus
}
#endif

#endif

/*  Routines in qda_utils.c					*/
/*	@(#)qda_utils.h	1.2 5/24/96 15:44:17	*/

#ifndef	__qda_utils_h
#define	__qda_utils_h

#include "timedef.h"
#include "qda.h"
#include "seismo.h"

#ifdef	__cplusplus
extern	"C" {
#endif

INT_TIME decode_time_qda (QDA_TIME, int);
void	decode_flags_qda (int *, int, unsigned char *, 
			  unsigned char *, unsigned char *);
void	encode_flags_qda (int, unsigned char *, unsigned char, 
			  unsigned char, unsigned char);
char	*get_component_name (char *, int);
DATA_HDR *decode_hdr_qda (QDA_HDR *, int *);

#ifdef	__cplusplus
}
#endif

#endif

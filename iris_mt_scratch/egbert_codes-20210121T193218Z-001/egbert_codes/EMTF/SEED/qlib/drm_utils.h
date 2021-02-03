/*  Routines in drm_utils.c					*/
/*	@(#)drm_utils.h	1.2 5/24/96 15:44:15	*/

#ifndef	__drm_utils_h
#define	__drm_utils_h

#ifdef	__cplusplus
extern "C" {
#endif

INT_TIME decode_time_drm (DA_TIME);
DA_TIME	encode_time_drm (INT_TIME);
void	decode_flags_drm (int *, int, unsigned char *,
			  unsigned char *, unsigned char *);
void	endode_flags_drm (int, unsigned char *, unsigned char, 
			  unsigned char, unsigned char);
DATA_HDR *decode_hdr_drm (STORE_DATA *, int *);
STORE_DATA *encode_hdr_drm (DATA_HDR *);

#ifdef	__cplusplus
}
#endif

#endif

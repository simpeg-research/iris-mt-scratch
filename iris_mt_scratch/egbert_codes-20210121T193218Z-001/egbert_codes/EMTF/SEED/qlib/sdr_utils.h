/*  Routines in sdr_utils.c						*/
/*	@(#)sdr_utils.h	1.4 5/24/96 15:44:20	*/

#ifndef	__sdr_utils_h
#define	__sdr_utils_h

#include    "timedef.h"
#include    "sdr.h"
#include    "data_hdr.h"

#ifdef	__cplusplus
extern "C" {
#endif

INT_TIME decode_time_sdr (SDR_TIME);
SDR_TIME encode_time_sdr (INT_TIME);
DATA_HDR *decode_hdr_sdr (SDR_HDR *, int *);
char	*asc_sdr_time (char *, SDR_TIME);
time_t	unix_time_drm_sdr_time (SDR_TIME);
int	read_blockettes (DATA_HDR *, char *);
BS	*find_blockette (DATA_HDR *, int);
BS	*find_pblockette (BS *bs, int n);
int	blockettecmp (BS *bs1, BS *bs2);
int	write_blockettes (DATA_HDR *, char *);
int	add_blockette (DATA_HDR *, char *, int, int);
int	delete_blockette (DATA_HDR *, int);
int	delete_pblockette (DATA_HDR *, BS *);
void	free_data_hdr(DATA_HDR *);
int	eval_rate (int sample_rate_factor, int sample_rate_mult);

#ifdef	__cplusplus
}
#endif

#endif

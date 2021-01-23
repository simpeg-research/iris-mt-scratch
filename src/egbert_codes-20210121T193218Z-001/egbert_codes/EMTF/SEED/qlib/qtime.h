/*  Routines in qtime.c						*/
/*	@(#)qtime.h	1.4 5/24/96 15:44:18	*/

#ifndef	__qtime_h
#define	__qtime_h

#include "timedef.h"

#ifdef	__cplusplus
extern "C" {
#endif

void	dy_to_mdy (int, int, int *, int *);
int	mdy_to_doy (int, int, int);
EXT_TIME normalize_ext (EXT_TIME);
INT_TIME normalize_time (INT_TIME);
EXT_TIME int_to_ext (INT_TIME);
INT_TIME ext_to_int (EXT_TIME);
int	sec_per_year (int);
int	missing_time (INT_TIME);
INT_TIME add_time (INT_TIME, int, int);
void	time_interval (int, int, int *, int *);
double	dsamples_in_time (int, double);
int	samples_in_time (int, int);
double	tdiff (INT_TIME, INT_TIME);
char	*time_to_str (INT_TIME, int);
char	*etime_to_str (INT_TIME, int, int);
char	*interval_to_str (EXT_TIME, int);
INT_TIME *parse_date (char *);
EXT_TIME *parse_interval (char *);
int	valid_span (char *);
INT_TIME end_of_span(INT_TIME, char *);
INT_TIME add_interval (INT_TIME, EXT_TIME);
time_t	unix_time_from_int_time (INT_TIME);
time_t	unix_time_from_ext_time (EXT_TIME);
INT_TIME int_time_from_time_tm (struct tm *);
EXT_TIME ext_time_from_det_time (long, int);
INT_TIME int_time_from_timeval (struct timeval *);

#ifdef	__cplusplus
}
#endif

#endif

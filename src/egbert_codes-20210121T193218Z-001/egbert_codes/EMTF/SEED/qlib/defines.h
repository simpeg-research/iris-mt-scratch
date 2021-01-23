/*	@(#)defines.h	1.4 5/24/96 15:44:14	*/

#ifndef	IS_LEAP

#define	IS_LEAP(yr)	( yr%400==0 || (yr%4==0 && yr%100!=0) )
#define	SEC_PER_MINUTE	60
#define	SEC_PER_HOUR	3600
#define	SEC_PER_DAY	86400
#define SEC_PER_YEAR(yr) sec_per_year(yr)
#define	TICKS_PER_SEC	10000
#define	TICKS_PER_MSEC	(TICKS_PER_SEC/1000)
#define USEC_PER_SEC	1000000
#define	    DAYS_PER_YEAR(yr)	    \
			(365 + ((yr%4==0)?1:0) + \
			 ((yr%100==0)?-1:0) + \
			 ((yr%400==0)?1:0))
#define	SPS_RATE(hdr_rate)	((hdr_rate > 0) ? (double)hdr_rate : -1/(double)hdr_rate)
#define	BIT(a,i)	((a >> i) & 1)
#define	IHUGE		(65536*32767)
#define	DIHUGE		(140737488355328.)

#ifndef	MAX
#define MAX(a,b)	((a >= b) ? a : b)
#endif
#ifndef	MIN
#define MIN(a,b)	((a <= b) ? a : b)
#endif

#define	UNKNOWN_STREAM	"UNK"
#define	UNKNOWN_COMP	"U"

#define	JULIAN_FMT	0
#define	JULIAN_FMT_1	1
#define	MONTH_FMT	2
#define	MONTH_FMT_1	3
#define	JULIANC_FMT	4
#define	JULIANC_FMT_1	5
#define	MONTHS_FMT	6
#define	MONTHS_FMT_1	7

#endif

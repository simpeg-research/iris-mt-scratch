/*	Header file for time structures.			*/
/*	@(#)timedef.h	1.3 5/24/96 15:44:24	*/

#ifndef	__timedef_h
#define	__timedef_h

#include <time.h>
#include <sys/time.h>

/*	Time structures.					*/

typedef struct _ext_time {
    int		year;		/*  Year.			*/
    int		doy;		/*  Day of year (1-366)		*/
    int		month;		/*  Month (1-12)		*/
    int		day;		/*  Day of month (1-31)		*/
    int		hour;		/*  Hour (0-23)			*/
    int		minute;		/*  Minute (0-59)		*/
    int		second;		/*  Second (0-60 (leap))	*/
    int		ticks;		/*  Ticks (0-9999)		*/
} EXT_TIME;

typedef struct	_int_time {
    int		year;		/*  Year.			*/
    int		second;		/*  Seconds in year (0-...)	*/
    int		ticks;		/*  Ticks (0-9999)		*/
} INT_TIME;

#endif

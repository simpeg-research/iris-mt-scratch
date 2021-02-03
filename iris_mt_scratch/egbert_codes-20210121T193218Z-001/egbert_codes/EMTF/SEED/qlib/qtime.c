/************************************************************************/
/*  Time routines for Quanterra data processing.			*/
/*									*/
/*	Douglas Neuhauser						*/
/*	Seismographic Station						*/
/*	University of California, Berkely				*/
/*	doug@seismo.berkeley.edu					*/
/*									*/
/************************************************************************/

#ifndef lint
static char sccsid[] = "@(#)qtime.c	1.8 1/25/95 12:19:36";
#endif

#include    <stdio.h>
#include    <math.h>
#include    <time.h>
#include    <tzfile.h>
#include    <sys/param.h>
#include    <stdlib.h>
#include    <string.h>

#include    "qlib.h"

/*  Leapsecond file definition.  May be overridden at runtime by the	*/
/*  LEAPSECONDS environment variable.					*/
/*  Use this definition if you supply your own leapsecond file.		*/
#ifndef	    LEAPSECONDS
#define	    LEAPSECONDS	    "/usr/local/lib/leapseconds"
#endif

/*  Use this definition if your system comes with a leapsecond file.	*/
#ifndef	    LEAPSECONDS
#define	    LEAPSECONDS	    "/usr/share/lib/zoneinfo/leapseconds"
#endif

/*  Define max number of leaps we can handle if system does not define.	*/
#ifndef	    TZ_MAX_LEAPS
#define	    TZ_MAX_LEAPS    100
#endif

#define	LDOY(y,m)	(DOY[m] + (IS_LEAP(y) && m >= 2))
#define	SYNTAX_ERROR	{ ++error; break; }
#define LEAPLINELEN	255


/************************************************************************/
/*	Information on dates (for non-leap years)			*/
/*		Names of months, days per months, and day of year.	*/

char	    *MON[] = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
			"Jul", "Aug", "Sep", "Oct", "Nov", "Dec", NULL};
/*		         Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec */
int	    DPM[] = { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
int	    DOY [] = { 0, 31, 59, 90,120,151,181,212,243,273,304,334,365 };

/************************************************************************/
/*  Leapseconds.							*/
/*	In order to handle leapseconds, we have to keep a table of when	*/
/*	they ocurr.  This table needs to be indexed by external time	*/
/*	(eg year, day, hour, minute, second) as well as true second	*/
/*  	offset within the year.  When converting between external time	*/
/*	and internal time, use this table to determine if we need to	*/
/*	add &/or remove leap seconds.					*/
/************************************************************************/

/************************************************************************/
/*	Leap second time structures.					*/
/************************************************************************/
typedef struct lsinfo {
    EXT_TIME	exttime;	/*  External def. of leap time.		*/
    INT_TIME	inttime;	/*  Internal def. of leap time,		*/
				/*  incl. prior leaps this year.	*/
    int		leap_value;	/*  Leap increment in seconds.		*/
} LSINFO;

struct lstable {
    int		initialized;	/*  Leap second table inited?		*/
    int		nleapseconds;	/*  Total leap second entries.		*/
    LSINFO	lsinfo[TZ_MAX_LEAPS];
				/*  Info for each leapsecond.		*/
} lstable;

/************************************************************************/
/*  init_leap_second_table:						*/
/*	Initialize leap second table from external file.		*/
/************************************************************************/
void
init_leap_second_table ()
{
    FILE    *lf;
    char    line[LEAPLINELEN+1], keywd[10], s_month[10], corr[10], type[10];
    int	    i, l, ls;
    int	    lnum = 0;
    char    leap_file[MAXPATHLEN];
    char    *ep;
    LSINFO  *p;
    EXT_TIME et;

    if (lstable.initialized) return;
    lstable.initialized = 1;

    /*	If the environment variable LEAPSECONDS exists, it should	*/
    /*	override the default LEAPSECONDS file.				*/
    if ((ep=getenv("LEAPSECONDS"))!=NULL)
	strcpy(leap_file,ep);
    else strcpy(leap_file, LEAPSECONDS);
    if ((lf=fopen(leap_file, "r"))==NULL) {
	fprintf (stderr, "warning - no leap second file: %s\n",leap_file);
	return;
    }

    while (fgets(line,LEAPLINELEN,lf)!=NULL) {
	++lnum;
	line[LEAPLINELEN]='\0';
	trim(line);
	l = strlen(line);
	if (l>0 && line[l-1]=='\n') line[--l] = '\0';
	if (l<=0 || line[0]=='#') continue;
	if ((ls=lstable.nleapseconds) >= TZ_MAX_LEAPS) {
	    fprintf (stderr, "too many leapsecond entries - line %d\n", lnum);
	    exit(1);
	}
 	p = &lstable.lsinfo[ls];
	if ((l=sscanf(line,"%s %d %s %d %d:%d:%d %s %s", keywd, &p->exttime.year, 
		      s_month, &p->exttime.day, &p->exttime.hour, &p->exttime.minute, 
		      &p->exttime.second, corr, type))!= 9) {
	    fprintf (stderr, "invalid leapsecond line - line %d\n", lnum);
	    exit(1);
	}
	i = 0;
	while (MON[i] != 0) {
	    if (strcasecmp(MON[i],s_month)==0) {
		p->exttime.month = i+1;
		p->exttime.doy = DOY[i] + p->exttime.day +
		    ( IS_LEAP(p->exttime.year) && (p->exttime.month > 2) );
		break;
	    }
	    ++i;
	}
	p->exttime.ticks = 0;
	switch (corr[0]) {
	    case '+':	p->leap_value = 1; break;
	    case '-':	p->leap_value = -1; break;
	    default:
		fprintf(stderr, "invalid leapsecond correction - line %d\n", lnum);
		exit(1);
	}
	/* Ensure that the INT_TIME field does not wrap into the next	*/
	/* year for leapseconds occurring at the end of the year.	*/
	et = p->exttime;
	et.second -= p->leap_value;
	p->inttime = ext_to_int (et);
	p->inttime.second += p->leap_value;
	++lstable.nleapseconds;
    }
    fclose(lf);
}

/************************************************************************/
/*  is_leap_second:							*/
/*	Return lsinfo structure if this second is in leap second table.	*/
/************************************************************************/
LSINFO *
is_leap_second(it)
    INT_TIME	it;
{
    int		i;
    /*	Search leap second table.   */
    if (!lstable.initialized) init_leap_second_table();
    for (i=0; i<lstable.nleapseconds; i++) {
	if (it.year == lstable.lsinfo[i].inttime.year &&
	    it.second == lstable.lsinfo[i].inttime.second)
	    return (&lstable.lsinfo[i]);
    }
    return(NULL);
}

/************************************************************************/
/*  sec_per_min:							*/
/*	Return the number of seconds in this minute.			*/
/************************************************************************/
int
sec_per_min(et)
    EXT_TIME	et;
{
    /*	Search leap second table.   */
    int i;
    if (!lstable.initialized) init_leap_second_table();
    for (i=0; i<lstable.nleapseconds; i++) {
	if (et.year < lstable.lsinfo[i].exttime.year) break;
	if (et.year == lstable.lsinfo[i].exttime.year &&
	    et.month == lstable.lsinfo[i].exttime.month &&
	    et.day == lstable.lsinfo[i].exttime.day &&
	    et.hour == lstable.lsinfo[i].exttime.hour &&
	    et.minute == lstable.lsinfo[i].exttime.minute)
	    return (60+lstable.lsinfo[i].leap_value);
    }
    return(60);
}

/************************************************************************/
/*  prior_leaps_in_ext_time:						*/
/*	Return the number of leap seconds that must be added to this	*/
/*	EXT_TIME in order to compute the accurate number of seconds	*/
/*	within the year.						*/
/************************************************************************/
int
prior_leaps_in_ext_time (et)
    EXT_TIME	et;
{
    LSINFO	*p;
    int		i;
    int		result = 0;
    if (!lstable.initialized) init_leap_second_table();
    for (i=0; i<lstable.nleapseconds; i++) {
	p = &lstable.lsinfo[i];
	if (et.year == p->exttime.year && 
	    (et.doy > p->exttime.doy ||
	     (et.doy == p->exttime.doy &&
	      (et.hour > p->exttime.hour ||
	       (et.hour == p->exttime.hour &&
		(et.minute > p->exttime.minute ||
		 (et.minute == p->exttime.minute &&
		  (et.second > p->exttime.second))))))))
	    result += p->leap_value;
    }
    return(result);
}

/************************************************************************/
/*  prior_leaps_in_int_time:						*/
/*	Return the accumulated number of leap seconds in this year	*/
/*	prior to time.							*/
/************************************************************************/
int
prior_leaps_in_int_time (it)
    INT_TIME	it;
{
    /*	Return the number of leap seconds that occurred prior to this 	*/
    /*	time within this year.						*/
    LSINFO	*p;
    int		i;
    int		result = 0;
    if (!lstable.initialized) init_leap_second_table();
    for (i=0; i<lstable.nleapseconds; i++) {
	p = &lstable.lsinfo[i];
	if (it.year == p->inttime.year && 
	    (it.second > p->inttime.second))
	    result += p->leap_value;
    }
    return(result);
}

/************************************************************************/
/*  dy_to_mdy:								*/
/*	Return month and day from day,year info.  Handle leap years.	*/
/************************************************************************/
void
dy_to_mdy (day, year, month, mday)
    int		day;
    int		year;
    int		*month;
    int		*mday;
{
    int leap_day;
    *month=1;
    *mday = day;
    while (day > LDOY(year,*month)) ++*month;
    *mday = day - LDOY(year,*month-1);
}

/************************************************************************/
/*  mdy_to_doy:								*/
/*	Return day_of_year from month, day, year info.			*/
/*	Don't forget about leap year.					*/
/************************************************************************/
int
mdy_to_doy (month, day, year)
    int		month;
    int		day;
    int		year;
{
    return(LDOY(year,month-1) + day);
}

/************************************************************************/
/*  normalize_ext:							*/
/*	Normalize time in an EXT_TIME structure.			*/
/************************************************************************/
EXT_TIME
normalize_ext (et)
    EXT_TIME	et;
{
    int seconds_per_minute;
    /*  Normalize external time from the minute up.			*/
    while (et.minute >= 60) { et.minute -= 60; ++(et.hour); }
    while (et.hour >= 24) { et.hour -= 24; ++(et.doy); }
    while (et.doy > DAYS_PER_YEAR(et.year)) {
	et.doy -= DAYS_PER_YEAR(et.year);
	++(et.year);
    }
    dy_to_mdy (et.doy, et.year, &et.month, &et.day);
    /* Now worry about seconds, which may span a leap day.		*/
    while ((seconds_per_minute=sec_per_min(et)) <= et.second) {
	et.second -= seconds_per_minute;
	++et.minute;
    }
    /* Now renormalize from the minute up again...			*/
    while (et.minute >= 60) { et.minute -= 60; ++(et.hour); }
    while (et.hour >= 24) { et.hour -= 24; ++(et.doy); }
    while (et.doy > DAYS_PER_YEAR(et.year)) {
	et.doy -= DAYS_PER_YEAR(et.year);
	++(et.year);
    }
    dy_to_mdy (et.doy, et.year, &et.month, &et.day);
    return (et);
}

/************************************************************************/
/*  normalize_time:							*/
/*  	Normalize an INT_TIME time structure.				*/
/************************************************************************/
INT_TIME
normalize_time(it)
    INT_TIME	it;
{
    int		s_p_y;

    while (it.ticks < 0) {
	--(it.second);
	it.ticks += TICKS_PER_SEC;
    }
    while (it.ticks >= TICKS_PER_SEC) {
	++(it.second);
	it.ticks -= TICKS_PER_SEC;
    }
    while (it.second < 0) {
	--(it.year);
	it.second += sec_per_year(it.year);
    }
    while (it.second >= (s_p_y = sec_per_year(it.year))) {
	it.second -= s_p_y;
	++(it.year);
    }
    return(it);
}

/************************************************************************/
/*  int_to_ext:								*/
/*	Convert internal time to external time, accounting for		*/
/*	leap seconds.							*/
/************************************************************************/
EXT_TIME
int_to_ext (it)
    INT_TIME	it;
{
    EXT_TIME et;
    int		leaps;
    LSINFO	*lp;

    /*	Add or remove leap seconds that occur before this time within	*/
    /*	the year so that we can convert it to a string using code	*/
    /*	that is independent of leapseconds.  The only trick is that	*/
    /*	if the time is an exact leapsecond, we have to know it, since	*/
    /*	second 60 would normally be considered second 0 of the next	*/
    /*	minute.								*/
    /*  If the time is a "negative leap second", we just add 1 second	*/
    /*  to accomodate the skip.	 Since the time should be initially	*/
    /*	normalized, we can never represent a negative leapsecond at	*/
    /*	the end of the year, so we don't have to worry about		*/
    /*	re-normalizing and possibly crossing year boundaries.		*/

    et.year = it.year;
    et.second = it.second;
    leaps = prior_leaps_in_int_time (it);

    et.second = et.second - leaps;
    if ((lp = is_leap_second (it)) && (lp->leap_value < 0))
	/*  For a missing second, adjust accordingly.			*/
	et.second = et.second - lp->leap_value;

    if (lp && lp->leap_value > 0) {
	/*  This corresponds to an entry for a positive leap_second.	*/
	/*  If it is an added second, use the info in the returned	*/
	/*  leap_second structure for computing the external date.	*/
	et.doy = lp->exttime.doy;
	et.month = lp->exttime.month;
	et.day = lp->exttime.day;
	et.hour = lp->exttime.hour;
	et.minute = lp->exttime.minute;
	et.second = lp->exttime.second;
    }
    else {
	et.doy = (et.second / SEC_PER_DAY) + 1;
	et.second = et.second % SEC_PER_DAY;
	et.hour = et.second / SEC_PER_HOUR;
	et.second = et.second % SEC_PER_HOUR;
	et.minute = et.second / SEC_PER_MINUTE;
	et.second = et.second % SEC_PER_MINUTE;
    }
    et.ticks = it.ticks;
    dy_to_mdy (et.doy, et.year, &et.month, &et.day);
    return (et);
}

/************************************************************************/
/*  ext_to_int:								*/
/*	Convert external time to internal time, accounting for		*/
/*	leap seconds.							*/
/************************************************************************/
INT_TIME 
ext_to_int (et)
    EXT_TIME	et;
{
    INT_TIME	it;
    int		leaps;
    int i;
    i = 0;
    et = normalize_ext(et);
    leaps = prior_leaps_in_ext_time (et);
    it.year = et.year;
    it.second = (et.doy-1) * (int)SEC_PER_DAY +
		et.hour * (int)SEC_PER_HOUR +
		et.minute * (int)SEC_PER_MINUTE +
		et.second + leaps;
    it.ticks = et.ticks;
    return(normalize_time(it));
}

/************************************************************************/
/*  sec_per_year:							*/
/*	Return number of seconds in the year, accounting for 		*/
/*	leap seconds.							*/
/************************************************************************/
int
sec_per_year(year)
    int		year;
{
    int		i;
    int		result = ( SEC_PER_DAY * (365 + IS_LEAP(year)) );
    /*	Search leap second table.   */
    if (!lstable.initialized) init_leap_second_table();
    for (i=0; i<lstable.nleapseconds; i++) {
	if (year == lstable.lsinfo[i].inttime.year)
	    result += lstable.lsinfo[i].leap_value;
    }
    return(result);
}

/************************************************************************/
/*  missing_time:							*/
/*  	Check for an empty INT_TIME structure.				*/
/************************************************************************/
int
missing_time (time)
    INT_TIME	time;
{
    return (time.year == 0 && time.second == 0 && time.ticks == 0);
}

/************************************************************************/
/*  add_time:								*/
/*	Add an increment to an INT_TIME.  Return INT_TIME structure.	*/
/************************************************************************/
INT_TIME
add_time (it, second, ticks)
    INT_TIME	it;
    int		second, ticks;
{
    it.ticks += ticks;
    it.second += second;
    return(normalize_time(it));
}

/************************************************************************/
/*  time_interval:							*/
/*  	Compute the time interval for n points at a given sample rate.	*/
/************************************************************************/
void
time_interval(n,rate,second,ticks)
    int n, rate;
    int *second, *ticks;
{
    double dtime, dsecond, dticks, dtmp;
    
    dtime = n/SPS_RATE(rate);
    dticks = modf (dtime, &dsecond);
    *second = dsecond;

    /* Correct for roundoff error.  */
    dticks *= TICKS_PER_SEC;
    *ticks = roundoff(dticks);
}

/************************************************************************/
/*  dsamples_in_time:							*/
/*	Compute the dp number of samples that ocurr within a specified 	*/
/*	time given a sample rate.					*/
/************************************************************************/
double
dsamples_in_time (rate, dticks)
    int rate;
    double dticks;
{
    double dsamples;

    dsamples = (SPS_RATE(rate)*dticks/TICKS_PER_SEC);
    return (dsamples);
}

/************************************************************************/
/*  samples_in_time:							*/
/*	Compute the integer number of samples that ocurr within a 	*/
/*	specified time given a sample rate.				*/
/*	WARNING - this routine may overflow when dealing with 4K-byte	*/
/*	block of ULP data.						&/
/************************************************************************/
int
samples_in_time (rate, ticks)
    int rate, ticks;
{
    double dticks = ticks;
    int nsamples;
    
    nsamples = ceil(dsamples_in_time(rate,dticks));
    return (nsamples);
}

/************************************************************************/
/*  tdiff:								*/
/*	Compare 2 times, and return the difference (t1-t2) in ticks.	*/
/*	If overflow would ocurr, return appropriate DIHUGE value.	*/
/************************************************************************/
double
tdiff (it1, it2)
    INT_TIME	it1, it2;
{
    INT_TIME	x1, x2;
    int i;
    int m = 1;
    double second, ticks;
    int	d[3];

    /* Ensure x1 >& x2	*/

    d[0] = it1.year - it2.year;
    d[1] = it1.second - it2.second;
    d[2] = it1.ticks - it2.ticks;

    for (i=0; i<3; i++) {
	if (d[i] > 0) break;
	if (d[i] < 0) {
	    m = -1;
	    break;
	}
    }
    if (m == 1) {
	x1 = it1; x2 = it2;
    }
    else {
	x1 = it2; x2 = it1;
	m = -1;
    }

    /* Check for gross differences that would generate over/underflows.	*/
    if ( (x1.year - x2.year >= 2) ) return (IHUGE * m);

    /* Normalize to a common year.   */
    while (x1.year > x2.year) {
	    --x1.year;
	    x1.second += sec_per_year(x1.year);
    }

    /* Compute ticks difference.	*/
    second = (x1.second - x2.second);
    if (second > (DIHUGE/TICKS_PER_SEC)) return (DIHUGE * m);
    ticks = (x1.ticks - x2.ticks);
    ticks += second*TICKS_PER_SEC;
    ticks *= m;

    return (ticks);
}

/************************************************************************/
/*  time_to_str:							*/
/*	Convert internal time to printable string.			*/
/************************************************************************/
char *
time_to_str (it, fmt)
    INT_TIME	it;
    int		fmt;
{
    static char str[80];	    /* contains printable time string.	*/
    int delim;
    EXT_TIME	et = int_to_ext (it);

    switch (fmt) {
	case MONTH_FMT:
	case MONTH_FMT_1:
	    delim = (fmt == MONTH_FMT) ? ' ' : ',';
	    sprintf (str, "%04d.%02d.%02d%c%02d:%02d:%02d.%04d",
		     et.year, et.month, et.day, delim, et.hour, 
		     et.minute, et.second, et.ticks);
	    break;
	case MONTHS_FMT:
	case MONTHS_FMT_1:
	    delim = (fmt == MONTHS_FMT) ? ' ' : ',';
	    sprintf (str, "%04d/%02d/%02d%c%02d:%02d:%02d.%04d",
		     et.year, et.month, et.day, delim, et.hour, 
		     et.minute, et.second, et.ticks);
	    break;
	case JULIANC_FMT:
	case JULIANC_FMT_1:
	    delim = (fmt == JULIANC_FMT) ? ' ' : ',';
	    sprintf (str, "%04d,%03d%c%02d:%02d:%02d.%04d",
		     et.year, et.doy, delim, et.hour, 
		     et.minute, et.second, et.ticks);
	    break;
	case JULIAN_FMT:
	case JULIAN_FMT_1:
	default:
	    delim = (fmt == JULIAN_FMT) ? ' ' : ',';
	    sprintf (str, "%04d.%03d%c%02d:%02d:%02d.%04d",
		     et.year, et.doy, delim, et.hour, 
		     et.minute, et.second, et.ticks);
	    break;
    }
    return (str);
}

/************************************************************************/
/*  etime_to_str:							*/
/*	Convert extended internal time to printable string.		*/
/************************************************************************/
char *
etime_to_str (it, usec99, fmt)
    INT_TIME	it;
    int		usec99;
    int		fmt;
{
    static char str[80];	    /* contains printable time string.	*/
    int delim;
    EXT_TIME	et = int_to_ext (it);

    switch (fmt) {
	case MONTH_FMT:
	case MONTH_FMT_1:
	    delim = (fmt == MONTH_FMT) ? ' ' : ',';
	    sprintf (str, "%04d.%02d.%02d%c%02d:%02d:%02d.%04d%02d",
		     et.year, et.month, et.day, delim, et.hour, 
		     et.minute, et.second, et.ticks, usec99);
	    break;
	case JULIAN_FMT:
	case JULIAN_FMT_1:
	default:
	    delim = (fmt == JULIAN_FMT) ? ' ' : ',';
	    sprintf (str, "%04d.%03d%c%02d:%02d:%02d.%04d%02d",
		     et.year, et.doy, delim, et.hour, 
		     et.minute, et.second, et.ticks, usec99);
	    break;
    }
    return (str);
}

/************************************************************************/
/*  interval_to_str:							*/
/*	Convert interval store in EXT_TIME format to printable string.	*/
/************************************************************************/
char *
interval_to_str (et, fmt)
    EXT_TIME	et;
    int		fmt;
{
    static char str[80];	    /* contains printable time string.	*/
    int		delim = ',';
    sprintf (str, "%d.%d%c%02d:%02d:%02d.%04d",
	     et.year,et.doy, delim, et.hour, et.minute, et.second, et.ticks);
    return (str);
}

#define YMD_FMT		3
#define	YDOY_FMT	2
#define	DATE_DELIMS	"/.,"
/************************************************************************/
/*  parse_date:								*/
/*	Parse a date string and return ptr to INT_TIME structure.	*/
/*	Return NULL if error parsing the date string.			*/
/************************************************************************/
INT_TIME *
parse_date(str)
    char	*str;
{
    /*
    Permissible input formats: 
        [19]yy/mm/dd/hh:mm:ss.ffff
        [19]yy/mm/dd.hh:mm:ss.ffff
        [19]yy/mm/dd,hh:mm:ss.ffff
        [19]yy.ddd.hh:mm:ss.ffff
        [19]yy.ddd,hh:mm:ss.ffff
        [19]yy,ddd,hh:mm:ss.ffff
    where
	yy = year, either yy or yyyy
	mm = month (1-12)
	dd = day (1-31)
	dddd = day-of-year (1-365)
	hh = hour (0-23)
	mm = minute (0-59)
	ss = second (0-59)
	ffff = fractional part of second
    The time is optional.  If not specified, it is 00:00:00.0000
    */

    char	*p, *q;
    char	*delim;
    EXT_TIME	et;
    int		trip, nd;
    int		error = 0;
    static INT_TIME	it;
    int		format;
    int		ndelim;

    et.year = et.doy = et.month = et.day = 0;
    et.hour = et.minute = et.second = et.ticks = 0;

    /* Scan for first ":", and then determine the number of		*/
    /* delimiters before to determine year.doy or year.mm.dd format.	*/
    q = strchr(str,':');
    if (q == NULL) q = str+strlen(str);
    ndelim = 0;
    for (p=str; p!=q; p++) {
	if (strchr(DATE_DELIMS,*p)) ++ndelim;
    }
    if (*q == ':') switch (ndelim) {
	case 2:	format=YDOY_FMT; break;
	case 3: format=YMD_FMT; break;
	default: ++error;
    }
    else switch (ndelim) {
	case 1:	format=YDOY_FMT; break;
	case 2: format=YMD_FMT; break;
	default: ++error;
    }

    if (error) {
	return ((INT_TIME *)NULL);
    }

    p = str;
    for (trip=0; trip<1; trip++) {
	/* Parse date.	*/
	et.year = strtol (p, &delim, 10);
	if (delim == p) SYNTAX_ERROR
	if (et.year > 0 && et.year <= 99) et.year += 1900;
	if (strchr(DATE_DELIMS, *delim) == NULL) SYNTAX_ERROR
	if (format == YMD_FMT) {
	    /* Syntax should be yy/mm/dd    */
	    p = ++delim;
	    et.month = strtol (p, &delim, 10);
	    if (delim == p) SYNTAX_ERROR
	    if (et.month < 1 | et.month > 12) SYNTAX_ERROR
	    if (strchr(DATE_DELIMS, *delim) == NULL) SYNTAX_ERROR
	    p = ++delim;
	    et.day = strtol (p, &delim, 10);
	    if (delim == p) SYNTAX_ERROR
	    if (et.day < 1 | et.day > DPM[et.month] + (IS_LEAP(et.year) && et.month == 2))
		SYNTAX_ERROR
	    et.doy = DOY[et.month-1] + et.day +
		    ( IS_LEAP(et.year) && (et.month > 2) );
	}
	else {
	    /* Syntax should be yy.ddd	    */
	    p = ++delim;
	    et.doy= strtol (p, &delim, 10);
	    if (delim == p) SYNTAX_ERROR
	    if (et.doy < 1 | et.doy > 365 + IS_LEAP(et.year)) SYNTAX_ERROR
	    dy_to_mdy (et.doy, et.year, &et.month, &et.day);
	    if (*delim == 0) break;
	}
    
	/* Parse time.	*/
	if (*delim == 0) break;
	if (strchr(DATE_DELIMS, *delim) == NULL) SYNTAX_ERROR
	p = ++delim;
	et.hour = strtol(p, &delim, 10);
	if (delim == p) SYNTAX_ERROR
	if (et.hour < 0 | et.hour >= 24) SYNTAX_ERROR

	if (*delim == 0) break;
	if (*delim != ':') SYNTAX_ERROR
	p = ++delim;
	et.minute = strtol(p, &delim, 10);
	if (delim == p) SYNTAX_ERROR
	if (et.minute < 0 | et.hour >= 60) SYNTAX_ERROR

	if (*delim == 0) break;
	if (*delim != ':') SYNTAX_ERROR
	p = ++delim;
	et.second = strtol(p, &delim, 10);
	if (delim == p) SYNTAX_ERROR
	/*  Allow leap second.	*/
	if (et.second < 0 | et.hour > 60) SYNTAX_ERROR

	if (*delim == 0) break;
	if (*delim != '.') SYNTAX_ERROR
	p = ++delim;
	et.ticks = strtol(p, &delim, 10);
	if (delim == p) SYNTAX_ERROR
	if (*delim != 0) SYNTAX_ERROR
	nd = delim-p;
	if (nd < 0 | nd > 4) SYNTAX_ERROR
	while (nd < 4) {
	    et.ticks *= 10;
	    nd++;
	}
    }
    if (error) {
	return ((INT_TIME *)NULL);
    }

/*::
    printf ("year = %d, doy = %d, hour = %d, min = %d, sec = %d, ticks = %d\n",
	    et.year, et.doy, et.hour, et.minute, et.second, et.ticks);
::*/

    it = ext_to_int (et);
    return (&it);
}

#define	SETSIGN(p,sign)	\
	switch (*p) { \
	  case '+': sign=+1; p++; break; \
	  case '-': sign=-1; p++; break; \
	  default:  break; \
	}
/************************************************************************/
/*  parse_interval:							*/
/*	Parse a time interval into an EXT_TIME struct.			*/
/*	Return NULL if error parsing the date string.			*/
/*	Note that we must use an EXT_TIME strucuture since we need to	*/
/*	preserve all units as they were specified.  Only once we add	*/
/*	the interval to	a base time can we convert to an INT_TIME,	*/
/*	due to the possible presence of leapseconds.			*/
/************************************************************************/
EXT_TIME *
parse_interval(str)
    char	*str;
{
    /*
    Permissible input formats: 
	yy,ddd,hh:mm:ss.ffff
    where
        yy = year
	ddd = day-of-year (1-n)
	hh = hour (0-23)
	mm = minute (0-59)
	ss = second (0-59)
	ffff = fractional part of second
    The time is optional.  If not specified, it is 00:00:00.0000
    */

    static EXT_TIME	et;
    char	*p = str;
    char	*delim;
    int		trip, nd;
    int		error = 0;
    int		sign = 1;

    et.year = et.doy = et.month = et.day = 0;
    et.hour = et.minute = et.second = et.ticks = 0;
    for (trip=0; trip<1; trip++) {

	/* Parse year */
	SETSIGN(p,sign)
	et.year = sign * strtol (p, &delim, 10);
	if (delim == p) SYNTAX_ERROR
	if (*delim == 0) SYNTAX_ERROR

	/* Parse date.	*/
	if (*delim != '.' && *delim != '/' && *delim != ',') SYNTAX_ERROR
	p = ++delim;
	SETSIGN(p,sign)
	et.doy = sign * strtol (p, &delim, 10);
	if (delim == p) SYNTAX_ERROR
	if (*delim == 0) SYNTAX_ERROR

	/* Parse time.	*/
	if (*delim != '.' && *delim != '/' && *delim != ',') SYNTAX_ERROR
	p = ++delim;
	SETSIGN(p,sign)
	et.hour = sign * strtol(p, &delim, 10);
	if (delim == p) SYNTAX_ERROR
	if (*delim == 0) SYNTAX_ERROR

	if (*delim != ':') SYNTAX_ERROR
	p = ++delim;
	SETSIGN(p,sign)
	et.minute = sign * strtol(p, &delim, 10);
	if (delim == p) SYNTAX_ERROR

	if (*delim == 0) break;
	if (*delim != ':') SYNTAX_ERROR
	p = ++delim;
	SETSIGN(p,sign)
	et.second = sign * strtol(p, &delim, 10);
	if (delim == p) SYNTAX_ERROR

	if (*delim == 0) break;
	if (*delim != '.') SYNTAX_ERROR
	p = ++delim;
	SETSIGN(p,sign)
	et.ticks = sign * strtol(p, &delim, 10);
	if (delim == p) SYNTAX_ERROR
	if (*delim != 0) SYNTAX_ERROR
	nd = delim-p;
	if (nd < 0 | nd > 4) SYNTAX_ERROR
	while (nd < 4) {
	    et.ticks *= 10;
	    nd++;
	}
    }
    if (error) {
	return ((EXT_TIME *)NULL);
    }

/*::
    printf ("year = %d, doy = %d, hour = %d, min = %d, sec = %d, ticks = %d\n",
	    et.year, et.doy, et.hour, et.minute, et.second, et.ticks);
::*/
    return (&et);
}

/************************************************************************/
/*  valid_span:								*/
/*	Ensure time span has valid syntax.				*/
/************************************************************************/
int
valid_span (span)
    char	*span;
{
    char	*p;
    int		span_value = strtol(span,&p,10);
    return ((span_value == 0 || p == span || (int)strlen(p) > 1 ||
	     (strlen(p)==1 && strchr ("FSMHdmy",*p) == NULL)) ? 0 : 1);
}

/************************************************************************/
/*  end_of_span:							*/
/*	Compute the end time of a time span.				*/
/************************************************************************/
INT_TIME
end_of_span (it, span)
    INT_TIME	it;
    char	*span;
{
    EXT_TIME	et;
    char	*p;
    int		l;
    int		span_value;
    int		second = 0;
    int		ticks = 0;

    /*	Compute end of span time based on initial time and specified	*/
    /*	span value.  Units for span values can be:			*/
    /*	    F -			Ticks.					*/
    /*	    S (or nothing) -	Seconds.				*/
    /*	    M -			Minutes.				*/
    /*	    H -			Hours.					*/
    /*	    d -			Days.					*/
    /*	    m -			Month					*/
    /*	    y -			Year.					*/
    /*	Process the span by:						*/
    /*	    Convert beginning internal time to external time.		*/
    /*	    Add the span value to the corresponding external time field.*/
    /*		(for months, normalize and get doy).			*/
    /*	    Normalize external time.					*/
    /*	    Convert external time back to internal time.		*/

    et = int_to_ext (it);
    span_value = strtol(span,&p,10);
    if ( p == span || span_value == 0 || (l=(int)strlen(p) > 1) ) {
	fprintf (stderr, "invalid span value: %s\n", span);
	exit(1);
    }

    switch (*p) {
      case  0:
      case 'S':	et.second += span_value; break;
      case 'F':	et.ticks += span_value; break;
      case 'M':	et.minute += span_value; break;
      case 'H':	et.hour += span_value; break;
      case 'd':	et.doy += span_value; break;
      case 'm':	et.month += span_value;
	while (et.month > 12) { ++et.year; et.month -=12; }
	while (et.month <= 0) { --et.year; et.month +=12; }
	et.doy = mdy_to_doy (et.month, et.day, et.year);
	break;
      case 'y':	et.year += span_value; break;
      default:
	fprintf (stderr, "invalid span value: %s\n", span);
	exit(1);
    }
    return (ext_to_int(normalize_ext(et)));
}

/************************************************************************/
/*  add_interval:							*/
/*	Add interval to specified internal time, and return result.	*/
/************************************************************************/
INT_TIME
add_interval (it, interval)
    INT_TIME	it;
    EXT_TIME	interval;
{
    INT_TIME	it2;
    EXT_TIME	et;
    if (interval.doy && (interval.month || interval.day)) {
	fprintf (stderr, "Interval may not have month,day and doy\n");
	exit(1);
    }

    /*	Add in the various parts of the interval in a specified order.	*/
    /*	Start with the highest unit first, and go down from there.	*/
    /*	Normalize after each unit is added.				*/
    /*	Note that seconds must be accrued in int_time format.		*/
    et = int_to_ext (it);
    if (interval.year)	{ 
	et.year += interval.year; 
	et = normalize_ext(et);
    }
    if (interval.doy)	{ 
	et.doy += interval.doy; 
	et = normalize_ext(et); 
    }
    if (interval.month)	{ 
	et.month += interval.month; 
	et = normalize_ext(et);
    }
    if (interval.day)	{ 
	et.day += interval.day; 
	et = normalize_ext(et);
    }
    if (interval.hour)	{
	et.hour += interval.hour;
	et = normalize_ext(et);
    }
    if (interval.minute) {
	et.minute += interval.minute;
	et = normalize_ext(et);
    }
    it2 = ext_to_int (et);
    if (interval.second) { it2.second += interval.second; it2 = normalize_time(it2); }
    if (interval.ticks)	{ it2.ticks += interval.ticks; it2 = normalize_time(it2); }
    return (it2);
}

/************************************************************************/
/*  int_time_from_time_tm:						*/
/*	Convert unix time_t structure to INT_TIME.			*/
/************************************************************************/
INT_TIME
int_time_from_time_tm (tm)
    struct tm	*tm;
{
    EXT_TIME	et;
    et.year = tm->tm_year + 1900;
    et.doy = tm->tm_yday + 1;
    et.month = tm->tm_mon + 1;
    et.day = tm->tm_mday;
    et.hour =tm->tm_hour;
    et.minute = tm->tm_min;
    et.second = tm->tm_sec;
    et.ticks = 0;
    return (ext_to_int(et));
}

/************************************************************************/
/*  unix_time_from_ext_time:						*/
/*	Convert EXT_TIME to unix timestamp.				*/
/************************************************************************/
time_t
unix_time_from_ext_time (et)
    EXT_TIME	et;
{    
    struct tm tm;
    int month, mday;
    time_t gtime;
    long save_timezone, save_altzone;

    /* Map into units required by unix time routines.		*/
    /*	NOTE - Posix time does not deal with leapseconds.	*/
    /*	Therefore, if this is a leapsecond, set it to be the	*/
    /*	the previous second.					*/

    tm.tm_sec = (et.second < 60) ? et.second : 59;
    tm.tm_min = et.minute;
    tm.tm_hour = et.hour;
    tm.tm_mday = et.day;			/* 1-31		*/
    tm.tm_mon = et.month - 1;			/* 0-11		*/
    tm.tm_year = et.year - 1900;		/* year - 1900	*/
    tm.tm_wday = 0;
    tm.tm_yday = et.doy - 1;			/* 0-365	*/
    tm.tm_isdst =0;
#ifndef SOLARIS2
    tm.tm_zone = "GMT";
    tm.tm_gmtoff = 0;
    gtime = timegm (&tm);
#else
    /* Set timezone offsets to 0 to compute clock in UTC time.	*/
    /* Reset when done.						*/
    save_timezone = timezone;
    save_altzone = altzone;
    timezone = altzone = 0;
    gtime = mktime(&tm);
    timezone = save_timezone;
    altzone = save_altzone;
#endif
    return (gtime);
}

/************************************************************************/
/*  unix_time_from_int_time:						*/
/*  	Convert INT_TIME to unix timestamp.				*/
/************************************************************************/
time_t
unix_time_from_int_time (it)
    INT_TIME	it;
{
    return (unix_time_from_ext_time(int_to_ext(it)));
}

/************************************************************************/
/*  det_time_to_ext:							*/
/*	Convert quanterra detection time to internal time, ignoring	*/
/*	leap seconds.							*/
/************************************************************************/

/* Number of seconds in a year, ignoring leap seconds.			*/
#define	fixed_sec_per_year(yr)	\
    ( (365 + IS_LEAP(yr)) * SEC_PER_DAY )

EXT_TIME
det_time_to_int_time (evtsec, msec)
    long	evtsec;	
    int		msec;
{
    EXT_TIME	et;
    int		n;

    /*  NOTE:  The quanterra detection time is represented as:		*/
    /*  a.	(long) #seconds since Jan 1 1984			*/
    /*  b.	(short) milliseconds.					*/
    /*  The #seconds was computed in the quanterra from an EXT_TIME	*/
    /*	with NO KNOWLEDGE OF LEAP SECONDS.  Therefore, we must convert	*/
    /*  if back without using leap second info.				*/
    /*	Note that we expect msec argument to be an int.			*/

    /*	Determine the proper year.					*/
    et.year = 1984;
    while (evtsec > (n = fixed_sec_per_year(et.year))) {
	evtsec -= n;
	++et.year;
    }

    /*	Determine the rest of the year information.			*/
    et.doy = (et.second / SEC_PER_DAY) + 1;
    et.second = et.second % SEC_PER_DAY;
    et.hour = et.second / SEC_PER_HOUR;
    et.second = et.second % SEC_PER_HOUR;
    et.minute = et.second / SEC_PER_MINUTE;
    et.second = et.second % SEC_PER_MINUTE;
    et.ticks = msec * TICKS_PER_MSEC;
    dy_to_mdy (et.doy, et.year, &et.month, &et.day);
    return (et);
}

/************************************************************************/
/*  int_time_from_timeval:						*/
/*	Convert unix timeval structure to INT_TIME.			*/
/************************************************************************/
INT_TIME
int_time_from_timeval (tv)
	struct timeval *tv;
{
	INT_TIME it;
	it = int_time_from_time_tm(gmtime(&(tv->tv_sec)));
	it.ticks = tv->tv_usec * (TICKS_PER_SEC/USEC_PER_SEC);
	return (it);
}

/************************************************************************/
/* Fortran interludes to qtime routines.				*/
/************************************************************************/

/* Add a number of second and ticks to INT_TIME, and return result.	*/
void add_time_ (it, second, ticks, ot)
    INT_TIME	*it;		/* Initial time.			*/
    int	*second;		/* Number of seconds to add.		*/
    int *ticks;			/* Number of ticks to add.		*/
    INT_TIME	*ot;		/* Resultant time.			*/
{
    *ot = add_time(*it, *second, *ticks);
}

/* Return the time spanned by N samples at RATE sample rate.		*/
/* Returned time is represented by seconds and ticks.			*/
void time_interval_ (n, rate, second, ticks)
    int *n;			/* number of samples.			*/
    int *rate;			/* sample rate.				*/
    int *second;		/* result interval for n samples (sec)	*/
    int *ticks;			/* result interval for n samples (ticks)*/
{
    time_interval (*n, *rate, second, ticks);
}

/* Compute the number of samples that would span the specified time	*/
/* (in ticks) at the specified sample rate.				*/
double dsamples_in_time_ (rate, dticks)
    int *rate;			/* sample rate.				*/
    double *dticks;		/* number of ticks.			*/
{
    return (dsamples_in_time(*rate, *dticks));
}

/* Compute the time difference in ticks of time1 - time2.		*/
double tdiff_ (it1, it2)
    INT_TIME *it1, *it2;	/* time1, time2.  Return (time1-time2)	*/
{
    return (tdiff(*it1,*it2));
}

/* Convert INT_TIME to EXT_TIME.					*/
void int_to_ext_ (it,et)
    INT_TIME *it;		/* input INT_TIME to be convert.	*/
    EXT_TIME *et;		/* returned equivalent EXT_TIME.	*/
{
    *et = int_to_ext(*it);
}

/* Convert EXT_TIME to INT_TIME.					*/
void ext_to_int_ (et,it)
    EXT_TIME *et;		/* input EXT_TIME to be converted.	*/
    INT_TIME *it;		/* returned equivalent INT_TIME.	*/
{
    *it = ext_to_int(*et);
}

/* Convert INT_TIME to ascii string, according to specified format.	*/
void time_to_str_ (it, fmt, str, slen)
    INT_TIME *it;		/* INT_TIME to be converted.		*/
    int *fmt;			/* format number for string.		*/
    char *str;			/* output characters string.		*/
    int slen;			/* (fortran supplied) length of string.	*/
{
    char *tstr;
    int tlen, mlen, i;
    tstr = time_to_str(*it, *fmt);
    mlen = strlen(tstr);
    mlen = (slen < mlen) ? slen : mlen;
    strncpy (str, tstr, mlen);
    /* blank pad if necessary */
    for (i=mlen; i<slen; i++) str[i] = ' ';
}

/* Int function to parse a date/time string into an INT_TIME structure.	*/
/* Return 1 if successful, 0 if unsuccessful.				*/
int parse_date_ (it, str, slen)
    INT_TIME *it;		/* INT_TIME to be converted.		*/
    char *str;			/* output characters string.		*/
    int slen;			/* (fortran supplied) length of string.	*/
{
    INT_TIME *pt;
    char tstr[40];
    int tlen = 40;
    int i;

    i = (slen < tlen) ? slen : tlen-1;
    strncpy (tstr, str, i);
    tstr[i] = 0;
    trim (tstr);
    pt = parse_date(tstr);
    if (pt != NULL) {
	*it = *pt;
	return (1);
    }
    else return (0);
}

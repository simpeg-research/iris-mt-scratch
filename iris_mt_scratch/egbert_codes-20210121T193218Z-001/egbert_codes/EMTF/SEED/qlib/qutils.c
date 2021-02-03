/************************************************************************/
/*  Utility routines for Quanterra data processing.			*/
/*									*/
/*	Douglas Neuhauser						*/
/*	Seismographic Station						*/
/*	University of California, Berkely				*/
/*	doug@seismo.berkeley.edu						*/
/*									*/
/************************************************************************/

#ifndef lint
static char sccsid[] = "@(#)qutils.c	1.4 12/3/95 12:06:35";
#endif

#include    <stdio.h>
#include    <stdlib.h>
#include    <math.h>
#include    <errno.h>

#include    "qlib.h"

#define	    N_NULL_CHECK    32
extern int errno;

/************************************************************************/
/*  SEED channel to station/stream mapping tables.			*/
/*									*/
/*  This information is STATION/TIME SPECIFIC, and should NOT be hard	*/
/*  coded.  It is currenly used only for 2 UCB stations, and is		*/
/*  consistent between those 2 stations.				*/
/************************************************************************/

typedef struct stream_map {
    char    *seed_stream;
    char    *stream;
    char    *component;
} STREAM_MAP;

/************************************************************************/
/*  Table of known and valid streama.					*/
/************************************************************************/

STREAM_MAP known_streams[] = {
/*  Broadband data streams:						*/
/*  VSP - 80 SPS from broadband seismometer.				*/
    "HHZ",  "VSP",  "Z",
    "HHN",  "VSP",  "N",
    "HHE",  "VSP",  "E",
/*  Old (incorrect) names for VSP 80 SPS broadband data.		*/
/*  Used for some station's VSP 100 SPS data.				*/
    "EHZ",  "VSP",  "Z",
    "EHN",  "VSP",  "N",
    "EHE",  "VSP",  "E",
/*  VBB - 20 SPS from broadband seismometer.				*/
    "BHZ",  "VBB",  "Z",
    "BHN",  "VBB",  "N",
    "BHE",  "VBB",  "E",
/*  LP - 1 SPS from broadband seismometer.				*/
    "LHZ",  "LP",   "Z",
    "LHN",  "LP",   "N",
    "LHE",  "LP",   "E",
/*  VLP - 1/10 SPS from broadband seismometer.				*/
    "VHZ",  "VLP",  "Z",
    "VHN",  "VLP",  "N",
    "VHE",  "VLP",  "E",
/*  ULP - 1/100 SPS from broadband seismometer.				*/
    "UHZ",  "ULP",  "Z",
    "UHN",  "ULP",  "N",
    "UHE",  "ULP",  "E",
/*  LG - 80 SPS (low gain) force balance accelerometer (fba) data.	*/
    "HLZ",  "LG",  "Z",
    "HLN",  "LG",  "N",
    "HLE",  "LG",  "E",
/*  Old (incorrect) LG - 80 SPS (low gain) FBA data.			*/
    "ELZ",  "LG",   "Z",
    "ELN",  "LG",   "N",
    "ELE",  "LG",   "E",
/*  BKS VBB channels from ULP instrument.				*/
    "BHA",  "UBB",   "Z",
    "BHB",  "UBB",   "N",
    "BHC",  "UBB",   "E",
/*  Experimental channels.						*/
/*::
    "LXZ",  "LX",   "Z",
    "LXN",  "LX",   "N",
    "LXE",  "LX",   "E",
    NULL,   UNKNOWN_STREAM,  UNKNOWN_COMP,
    UNKNOWN_STREAM,   NULL,   NULL,
::*/
/*  Table terminator.							*/
    NULL,   NULL,   NULL };

/************************************************************************/
/*  seed_to_comp:							*/
/*	Determine "common" stream & component name from SEED channel.	*/
/************************************************************************/
void
seed_to_comp (seed, stream, component)
    char *seed;
    char **stream;
    char **component;
{
    STREAM_MAP	*p = known_streams;
    while ( p->seed_stream != NULL && (strcmp(p->seed_stream, seed) != 0) )
	++p;
    *stream = p->stream;
    *component = p->component;
    /*	Create a geoscope channel name for unknown streams. */
    if (*stream==NULL) {
	if ((*stream = malloc(3)) != NULL) {
	    strncpy (*stream, seed, 2);
	    *((*stream)+2) = '\0';
	}
	if ((*component = malloc(2)) != NULL) {
	    strncpy (*component, seed+2, 1);
	    *((*component)+1) = '\0';
	}
    }
}

/************************************************************************/
/*  comp_to_seed:							*/
/*	Determine SEED name from "common" stream and component name.	*/
/************************************************************************/
void
comp_to_seed (stream, component, seed)
    char *stream;
    char *component;
    char **seed;
{
    STREAM_MAP	*p = known_streams;
    while ( p->seed_stream != NULL && 
	   ((strcmp(p->stream, stream) != 0) |
	    (strcmp(p->component, component) != 0)) )
	++p;
    *seed= p->seed_stream;
}

/************************************************************************/
/*  charncpy:								*/
/*	strncpy through N characters, but ALWAYS add NULL terminator.	*/
/*	Output string is dimensioned one longer than max string length.	*/
/************************************************************************/
char *
charncpy (out, in, n)
    char    *out, *in;
    int	    n;
{
    char    *p = out;

    while ( (n-- > 0) && (*p++ = *in++) ) ;
    *p = '\0';
    return (out);
}

/************************************************************************/
/*  charvncpy:								*/
/*	strncpy through N characters, but ALWAYS add NULL terminator.	*/
/*	Output string is dimensioned one longer than max string length.	*/
/*	Copy the i-th SEED variable-length string (terminated by ~).	*/
/************************************************************************/
char *
charvncpy (out, in, n, i)
    char    *out, *in;
    int	    n;
{
    char    *p = out;
    while (i > 0) {
	if (*in++ == '~') --i;
    }

    while ( (n-- > 0) && (*in != '~') ) *p++ = *in++;
    *p = '\0';
    return (out);
}

/************************************************************************/
/*  trim:								*/
/*	Trim trailing blanks from a string.  Return pointer to string.	*/
/************************************************************************/
char *
trim (str)
    char *str;
{
	char *p = str + strlen(str);
	while (--p >= str) 
		if (*p == ' ') *p = '\0'; else break;
	return (str);
}

/************************************************************************/
/*  allnull:								*/
/*	Determine whether the specified block of characters is "null".	*/
/*	Due to a bug in some of the Quanterra data packing software, 	*/
/*	extraneous blocks of NULL characters may be present every 16-th	*/
/*	SEED data record.						*/
/*	Changed:	02/24/92 by doug@seismo.berkeley.edu		*/
/*	Experience shows that only the first 32-40 bytes may be null,	*/
/*	and the rest will be garbage.					*/
/************************************************************************/
int
allnull (p, n)
    char *p;
    int n;
{
    int ncheck = MIN(n,N_NULL_CHECK);
    while (ncheck-- > 0)
	if (*p++) return (0);
    return (1);
}

/************************************************************************/
/*  roundoff:								*/
/*	Round a value to the closest integer.				*/
/************************************************************************/
int
roundoff (d)
    double d;
{
    int sign, result;
    double ad;

    sign = (d > 0) ? 1 : -1;
    ad = fabs(d);
    result = sign * (int)(ad+.5);
    return (result);
}

/************************************************************************/
/*  xread:								*/
/*	Read input buffer.  Continue reading until N bytes are read	*/
/*	or until error or EOF reached.					*/
/************************************************************************/
int xread (fd, buf, n)
    int fd;
    char *buf;
    int n;
{
    int nr;
    int togo = n;
    while (togo > 0) {
	nr = read(fd,buf+(n-togo),togo);
	if ( nr <= 0) return (n-togo);
	togo -= nr;
    }
    return (n);
}

#define MAX_RETRIES 20
/************************************************************************/
/*  xwrite:								*/
/*	Write output buffer.  Continue writing until all N bytes are	*/
/*	written or until error.						*
/************************************************************************/
int xwrite (fd, buf, n)
    int fd;
    char buf[];
    int n;
{
    int nw;
    int left = n;
    int retries = 0;
    while (left > 0) {
	if ( (nw = write (fd, buf+(n-left), left)) <= 0 && errno != EINTR) {
	    fprintf (stderr, "error writing output, unit= %d errno = %d\n", fd, errno);
	    exit (1);
	}
	if (nw == -1) {
	    fprintf (stderr, "Interrupted write unit = %d, retry %d.\n", fd, retries);
	    ++retries;
	    if (retries > MAX_RETRIES) {
		fprintf (stderr, "Giving up, unit = %d ...\n", fd);
		return(n-left);
	    }
	    continue;
	}
	left -= nw;
    }
    return (n);
}

/************************************************************************/
/*  cstr_to_fstr:							*/
/*	Convert C null-terminated string to Fortran blank-padded string.*/
/*	Initial string MUST BE dimensioned long enough.			*/
/************************************************************************/
void cstr_to_fstr (str, flen)
    char *str;
    int flen;
{
    int i, n;
    n = strlen(str);
    for (i=n; i<flen; i++) str[i] = ' ';
}

/************************************************************************/
/*  date_fmt_num:							*/
/*	Convert a date_fmt string to the corresponding numeric value.	*/
/************************************************************************/
int date_fmt_num (str)
    char *str;
{
    if (str == NULL || strlen(str)==0) return (JULIAN_FMT);

    if (strcasecmp(str,"j")==0) return (JULIAN_FMT);	/* julian	*/
    if (strcasecmp(str,"j1")==0) return (JULIAN_FMT_1);	/* julian1	*/
    if (strcasecmp(str,"m")==0) return (MONTH_FMT);	/* month	*/
    if (strcasecmp(str,"m1")==0) return (MONTH_FMT_1);	/* month1	*/
    if (strcasecmp(str,"jc")==0) return (JULIANC_FMT);	/* julian comma	*/
    if (strcasecmp(str,"jc1")==0) return (JULIANC_FMT_1);/* julian1 comma*/
    if (strcasecmp(str,"ms")==0) return (MONTHS_FMT);	/* month slash	*/
    if (strcasecmp(str,"ms1")==0) return (MONTHS_FMT_1);/* month1 slash	*/

    if (strcasecmp(str,"jt")==0) return (JULIAN_FMT_1);	/* julian	*/
    if (strcasecmp(str,"mt")==0) return (MONTH_FMT_1);	/* month tag	*/

    if (strcasecmp(str,"mc")==0) return (MONTHS_FMT);	/* month comma	*/
    if (strcasecmp(str,"mc1")==0) return (MONTHS_FMT_1);/* month1 comma	*/
    return (0);
}

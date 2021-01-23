/************************************************************************/
/*  Routines for processing DRM Quanterra data.				*/
/*									*/
/*	Douglas Neuhauser						*/
/*	Seismographic Station						*/
/*	University of California, Berkely				*/
/*	doug@seismo.berkeley.edu					*/
/*									*/
/************************************************************************/

#ifndef lint
static char sccsid[] = "@(#)drm_utils.c	1.4 1/25/95 12:19:57";
#endif

#include    <stdio.h>
#include    <stdlib.h>
#include    <memory.h>
#include    <string.h>

#include    "qlib.h"

int  herrno;			/*  errno from header routines.		*/

#ifdef	QLIB_DEBUG
extern FILE *info;		/*:: required only for debugging	*/
extern int  debug_option;	/*:: required only for debugging	*/
#endif

/************************************************************************/
/*  decode_time_drm:							*/
/*	Convert from DRM format time to INT_TIME.			*/
/************************************************************************/
INT_TIME
decode_time_drm (dt)
    DA_TIME	dt;		/*  DRM time structure.			*/
{
    INT_TIME	it;
    EXT_TIME	et;
    int day;

#ifdef	QLIB_DEBUG
    if (debug_option & 128) 
    fprintf (info, "time = %02d/%02d/%02d %02d:%02d:%02d:%04d\n",
	     dt.time_sample[0], dt.time_sample[1], dt.time_sample[2],
	     dt.time_sample[3], dt.time_sample[4], dt.time_sample[5],
	     dt.millisec*TICKS_PER_MSEC);
#endif

    /*	KLUDGE to add in century.					*/
    /*	Assume NOT data before 1970.					*/
    /*	This code will BREAK on 78 years...				*/
    et.year = dt.time_sample[0];
    if (et.year < 70)	et.year +=2000;
    else if (et.year < 100)	et.year +=1900;
	
    et.month = dt.time_sample[1];
    et.day = dt.time_sample[2];
    et.hour = dt.time_sample[3];
    et.minute = dt.time_sample[4];
    et.second = dt.time_sample[5];
    et.ticks = dt.millisec * TICKS_PER_MSEC;
    et.doy = mdy_to_doy(et.month,et.day,et.year);
    return (normalize_time(ext_to_int(et)));
}

/************************************************************************/
/*  encode_time_drm:							*/
/*	Convert from INT_TIME to DRM format time.			*/
/************************************************************************/
DA_TIME
encode_time_drm (it)
    INT_TIME	it;
{
    DA_TIME	dt;
    EXT_TIME	et;

    et = int_to_ext (it);
    dt.time_sample[0] = et.year % 100;
    dt.time_sample[1] = et.month;
    dt.time_sample[2] = et.day;
    dt.time_sample[3] = et.hour;
    dt.time_sample[4] = et.minute;
    dt.time_sample[5] = et.second;
    dt.millisec = et.ticks / TICKS_PER_MSEC;

#ifdef	QLIB_DEBUG
    if (debug_option & 128) 
    fprintf (info, "time = %02d/%02d/%02d %02d:%02d:%02d:%04d\n",
	     dt.time_sample[0], dt.time_sample[1], dt.time_sample[2],
	     dt.time_sample[3], dt.time_sample[4], dt.time_sample[5],
	     dt.millisec*TICKS_PER_MSEC);
#endif
    return (dt);
}

/************************************************************************/
/*  decode_flags_drm:							*/
/*	Create SEED flags from DRM SOH flag.				*/
/************************************************************************/
void
decode_flags_drm (pclock, soh, pa, pi, pq)
    int    *pclock;
    int	    soh;
    unsigned char   *pa, *pi, *pq;
{
    /* The DRM flags should be the same as the QDA flags.		*/
    /* Therefore, just call that routine.				*/
    decode_flags_qda (pclock, soh, pa, pi, pq);
}

/************************************************************************/
/*  encode_flags_drm:							*/
/*	Create DRM SOH flag from SEED flags.				*/
/************************************************************************/
void
encode_flags_drm (old_soh, soh, pa, pi, pq)
    int	    old_soh;
    unsigned char   *soh;
    unsigned char    pa, pi, pq;
{
    /* The DRM flags should be the same as the QDA flags.		*/
    /* Therefore, just call that routine.				*/
    encode_flags_qda (old_soh, soh, pa, pi, pq);
}

/************************************************************************/
/*  decode_hdr_drm:							*/
/*	Decode DRM header stored with each DRM data block,		*/
/*	and return ptr to dynamically allocated DATA_HDR structure.	*/
/*	Fill in structure with the information in a easy-to-use format.	*/
/*	WARNING:  The station_id, location_id, and channel_id are	*/
/*	NOT AVAILABLE in the block header, and are therefore are not	*/
/*	filled in at this point.  They MUST be filled in by the caller.	*/
/************************************************************************/
DATA_HDR *
decode_hdr_drm (ihdr, pblksize)
    STORE_DATA		*ihdr;
    int			*pblksize;
{
    char		tmp[80];
    DATA_HDR		*ohdr;
    char		*s, *c, *sc, *pc;
    int			i, next_seq;
    int			second, ticks;

    /* Perform data integrity check, and pick out pertinent header info.*/
    herrno = 0;

    if ((ohdr = (DATA_HDR *)malloc(sizeof(DATA_HDR)))==NULL) return(NULL);
    memset ((void *)ohdr, 0, sizeof(DATA_HDR));
    ohdr->seq_no = ihdr->packet_seq;

    ohdr->begtime = decode_time_drm (ihdr->da_begtime);
    ohdr->hdrtime = decode_time_drm (ihdr->da_begtime);
    ohdr->num_samples = ihdr->num_samples;
    ohdr->sample_rate = ihdr->rate;

    /* Stream,  channel, location and network are NOT in the block	*/
    /* header but only in the file header.  They will be left empty.	*/
    /* The caller should fill them in.					*/

    ohdr->seq_no = ihdr->packet_seq;
    ohdr->num_blockettes = 0;
    ohdr->num_ticks_correction = ihdr->clock_corr * 10;
    ohdr->first_data = (char *)&ihdr->da_d[0][0].bdiff[0] - (char *)ihdr;
    ohdr->first_blockette = 0;
    ohdr->pblockettes = NULL;

    /*	NOTE: store original clock_corr and SOH in extra header storage	*/
    /*	for possible future format-specific use.			*/
    ohdr->extra[0] = ihdr->clock_corr;
    ohdr->extra[1] = ihdr->soh;

    decode_flags_drm (&ohdr->num_ticks_correction, ihdr->soh, 
		&ohdr->activity_flags, &ohdr->io_flags, 
		&ohdr->data_quality_flags);

    /*	There should never be any time correction since any correction 	*/
    /*	is already included in the beginning and end time.		*/
    ohdr->num_ticks_correction = 0;

    /*	Calculate the end time, since the value stored in the field has	*/
    /*	only millisecond resolution.  This prevents us from using the 	*/
    /*	end time stored in the DRM header.				*/
    time_interval(ohdr->num_samples - 1, ohdr->sample_rate, &second, &ticks);
    ohdr->endtime = add_time (ohdr->begtime, second, ticks);
    ohdr->data_type = UNKNOWN_DATATYPE;
    return(ohdr);
}

/************************************************************************/
/*  encode_hdr_drm:							*/
/*	Convert DATA_HDR back to DRM block header.			*/
/************************************************************************/
STORE_DATA *
encode_hdr_drm (ihdr)
    DATA_HDR		*ihdr;
{
    STORE_DATA		*ohdr;

    /* Perform data integrity check, and pick out pertinent header info.*/
    herrno = 0;

    if ((ohdr = (STORE_DATA *)malloc(sizeof(STORE_DATA)))==NULL) return(NULL);
    memset ((void *)ohdr, 0,  sizeof(STORE_DATA));
    ohdr->packet_seq = ihdr->seq_no;

    /*	Since clock correction is assumed to already added in,		*/
    /*	use begtime instead of hdrtime for the beginning time.		*/
    ohdr->da_begtime = encode_time_drm(ihdr->begtime);
    ohdr->da_endtime = encode_time_drm(ihdr->endtime);
    ohdr->num_samples = ihdr->num_samples;
    ohdr->rate = ihdr->sample_rate;

    /*	See comment in decode_hdr_drm concerning extra info.		*/
    ohdr->clock_corr = ihdr->extra[0];
    encode_flags_drm (ihdr->extra[1], &ohdr->soh, 
		ihdr->activity_flags, ihdr->io_flags, 
		ihdr->data_quality_flags);
    return(ohdr);
}

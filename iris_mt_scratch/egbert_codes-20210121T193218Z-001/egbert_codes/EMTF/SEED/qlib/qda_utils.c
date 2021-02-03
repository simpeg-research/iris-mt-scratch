/************************************************************************/
/*  Routines for processing native binary dialup (QDA) Quanterra data.	*/
/*									*/
/*	Douglas Neuhauser						*/
/*	Seismographic Station						*/
/*	University of California, Berkely				*/
/*	doug@seismo.berkeley.edu					*/
/*									*/
/************************************************************************/

#ifndef lint
static char sccsid[] = "@(#)qda_utils.c	1.5 12/3/95 12:06:37";
#endif

#include    <stdio.h>
#include    <stdlib.h>
#include    <memory.h>
#include    <string.h>

#include    "qlib.h"

#define	RECORD_HEADER_1	1

int  herrno;			/*  errno from header routines.		*/

#ifdef	QLIB_DEBUG
extern FILE *info;		/*:: required only for debugging	*/
extern int  debug_option;	/*:: required only for debugging	*/
#endif

/************************************************************************/
/*  Table used to map stream numbers to common stream names.		*/
/*  This mapping is currently hard-coded in the Quanterra software.	*/
/************************************************************************/
char	*stream_name[] = {
    "VBB", "VSP", "LG", "MP", "VP", "VLP", "ULP", NULL };


/************************************************************************/
/*  Table used to map channel number to common component name.		*/
/*  This really needs to be externally table driven, based on station.	*/
/************************************************************************/
char	*component_name[] = {
    "Z", "N", "E", "V4", "V5", "V6", "M1", "M2", "M3",
    "Z", "N", "E", "L4", "L5", "L6", "L7", "L8", "L9", 
    "R1", "R2", NULL };

/************************************************************************/
/*  get_component_name:							*/
/*	Return the component name bases on the station and component	*/
/*	number.
/************************************************************************/
char *
get_component_name(station, comp)
    char	*station;
    int		comp;
{
    return (component_name[comp]);
}

/************************************************************************/
/*  decode_time_qda:							*/
/*	Convert from QDA format time to INT_TIME.			*/
/************************************************************************/
INT_TIME
decode_time_qda (qt, ticks)
    QDA_TIME	qt;
    int		ticks;
{
    EXT_TIME	et;
    INT_TIME	it;

#ifdef	QLIB_DEBUG
    if (debug_option & 128) 
    fprintf (info, "time = %02d/%02d/%02d %02d:%02d:%02d:%04d\n",
	     qt.year,	qt.month,   qt.day,
	     qt.hour,	qt.minute,  qt.second,
	     ticks);
#endif

    /*	KLUDGE to add in century.					*/
    /*	Assume NOT data before 1970.					*/
    /*	This code will BREAK on 78 years...				*/
    et.year = qt.year;
    if (et.year < 70)	et.year +=2000;
    else if (et.year < 100)	et.year +=1900;
	
    et.month = qt.month;
    et.day = qt.day;
    et.hour = qt.hour;
    et.minute = qt.minute;
    et.second = qt.second;
    et.ticks = ticks;
    et.doy = mdy_to_doy(et.month,et.day,et.year);
    return(normalize_time(ext_to_int(et)));
}

/************************************************************************/
/*  decode_flags_qda:							*/
/*	Create SEED flags from QDA SOH flag.				*/
/************************************************************************/
void
decode_flags_qda (pclock, soh, pa, pi, pq)
    int    *pclock;
    int	    soh;
    unsigned char   *pa, *pi, *pq;
{
    *pa = 0;
    *pi = 0;
    *pq = 0;

    /*	Updated 01/23/91 to be consistent with Quanterra's processing	*/
    /*	of SOH -> SEED flags.						*/

    /*	ACTIVITY flags:							*/
    if (soh & SOH_BEGINNING_OF_EVENT) *pa |= ACTIVITY_BEGINNING_OF_EVENT;
    if (soh & SOH_CAL_IN_PROGRESS) *pa |= ACTIVITY_CALIB_PRESENT;
    if (soh & SOH_EVENT_IN_PROGRESS) *pa |= ACTIVITY_EVENT_IN_PROGRESS;

    /*	IO flags:   They have no mapping.				*/

    /* If there is a clock correction, it is already added in		*/
    /* (according to Joe Steim).					*/
    /* This means that we should be able to IGNORE it.			*/
    /* In fact, we currently MUST zero it, since otherwise we must	*/
    /* set the ACTIVITY_TIME_GAP flag to indicated that it has been	*/
    /* added in already.						*/
    *pclock = 0;

    /*	QUALITY flags:							*/
    /* Map other information into QUALITY_QUESTIONABLE_TIMETAG flag.	*/
    if (soh & SOH_GAP) *pq |= QUALITY_MISSING;
    if (soh & SOH_INACCURATE) *pq |= QUALITY_QUESTIONABLE_TIMETAG;
    if (((soh ^ SOH_EXTRANEOUS_TIMEMARKS) & 
	(SOH_EXTRANEOUS_TIMEMARKS | SOH_EXTERNAL_TIMEMARK_TAG)) == 0)
	*pq |= QUALITY_QUESTIONABLE_TIMETAG;

    /*	We can't do anything with					*/
    /*		SOH_EXTERNAL_TIMEMARK_TAG				*/
    /*		SOH_RECEPTION_GOOD					*/
    /*	since they don't appear to be turned on in every packet.	*/
    /*	Their absence does NOT appear to indicate inaccurate timing.	*/

    /* PUNT on ACTIVITY_END_OF_EVENT flag for the moment.		*/
    /*	It requires history.						*/

    return;
}

/************************************************************************/
/*  encode_flags_qda:							*/
/*	Create QDA SOH flag from SEED flags.				*/
/************************************************************************/
void
encode_flags_qda (int old_soh, unsigned char *soh, unsigned char pa, 
		  unsigned char pi, unsigned char pq)
{
    /*	Updated 01/23/91 to be consistent with Quanterra's processing	*/
    /*	of SOH -> SEED flags.						*/

    /*	ACTIVITY flags:							*/
    if (pa & ACTIVITY_BEGINNING_OF_EVENT) *soh |=  SOH_BEGINNING_OF_EVENT;
    if (pa & ACTIVITY_CALIB_PRESENT) *soh |= SOH_CAL_IN_PROGRESS;
    if (pa & ACTIVITY_EVENT_IN_PROGRESS) *soh |= SOH_EVENT_IN_PROGRESS;

    /*	IO flags:   They have no mapping.				*/

    /*	QUALITY flags:							*/
    /* Map other information into QUALITY_QUESTIONABLE_TIMETAG flag.	*/
    if (pq & QUALITY_MISSING) *soh |= SOH_GAP;

    /*	I'm not sure how to remap the QUALITY_QUESTIONALBLE_TIMETAG.	*/
    /*	There is not a 1-1 mapping between it and a single SOH bit.	*/
    /*	Just map it to SOH_INACCURATE.					*/
    if (pq & QUALITY_QUESTIONABLE_TIMETAG) 
	*soh |= (old_soh & (SOH_INACCURATE | SOH_EXTRANEOUS_TIMEMARKS));
    *soh |= (old_soh & (SOH_RECEPTION_GOOD | SOH_EXTERNAL_TIMEMARK_TAG));

    /*	We can't do anything with					*/
    /*		SOH_EXTERNAL_TIMEMARK_TAG				*/
    /*		SOH_RECEPTION_GOOD					*/
    /*	since they don't appear to be turned on in every packet.	*/
    /*	Their absence does NOT appear to indicate inaccurate timing.	*/

    /* PUNT on ACTIVITY_END_OF_EVENT flag for the moment.		*/
    /*	It requires history.	*/

    return;
}

/************************************************************************/
/*  decode_hdr_qda:							*/
/*	Decode QDA header stored with each DRM data block,		*/
/*	and return ptr to dynamically allocated DATA_HDR structure.	*/
/*	Fill in structure with the information in a easy-to-use format.	*/
/************************************************************************/
DATA_HDR *
decode_hdr_qda (ihdr, pblksize)
    QDA_HDR		*ihdr;
    int			*pblksize;
{
    char		tmp[80];
    DATA_HDR		*ohdr;
    char		*s, *c, *sc, *pc;
    int			i, next_seq;
    int			second, ticks;

    /* Perform data integrity check, and pick out pertinent header info.*/
    herrno = 0;
    if ( (ihdr->frame_type != RECORD_HEADER_1) |
	(ihdr->header_flag != 0) ) {
	/*  Don't have a RECORD_HEADER_1.  See if the entire header is	*/
	/*  composed of NULLS.  If so, print warning and return NULL.	*/
	/*  Some early Quanterras output a spurious block with null	*/
	/*  header info every 16 blocks.  That block should be ignored.	*/
	if (allnull((char *)ihdr, sizeof(QDA_HDR))) {
	    return((DATA_HDR *)NULL);
	}
	else {
	    herrno = 1;
	    return((DATA_HDR *)NULL);
	}
    }

    if ((ohdr = (DATA_HDR *)malloc(sizeof(DATA_HDR)))==NULL) return(NULL);
    memset ((void *)ohdr, 0, sizeof(DATA_HDR));
    ohdr->seq_no = ihdr->seq_no;

    /*	Attempt to determine blocksize if current setting is 0.		*/
    /*	QDA files can be either 512 byte or 4K byte blocks.		*/
    if (*pblksize == 0) {
	for (i=1; i< 4; i++) {
	    pc = ((char *)(ihdr)) + (i*512);
	    if ( allnull ( pc,sizeof(QDA_HDR)) )
		continue;
	    next_seq = ((QDA_HDR *)pc)->seq_no;
	    if (next_seq == ohdr->seq_no + i) {
		*pblksize = 512;
		break;
	    }
	}
	/* Can't determine the blocksize.   */
    }
	
    charncpy (ohdr->station_id, ihdr->station_id, 4);
    charncpy (ohdr->location_id, "  ", 2);
    charncpy (ohdr->network_id, "  ", 2);
    trim (ohdr->station_id);
    trim (ohdr->location_id);
    trim (ohdr->network_id);

    ohdr->begtime = decode_time_qda(ihdr->time, ihdr->millisecond*10);
    ohdr->hdrtime = decode_time_qda(ihdr->time, ihdr->millisecond*10);
    ohdr->num_samples = ihdr->num_samples;
    ohdr->sample_rate = ihdr->sample_rate;

    s = stream_name[ihdr->stream];
    c = get_component_name(ohdr->station_id, ihdr->component);
    comp_to_seed(s, c, &sc);
    if (sc != NULL) {
	charncpy (ohdr->channel_id, sc, 3);
	trim (ohdr->channel_id);
    }
    else {
/*::
	fprintf (stderr, "unable to determine seed stream from %s %s, sample rate = %d\n",
	    s, c, ohdr->sample_rate);
::*/
    }

    ohdr->num_blockettes = 0;
    ohdr->num_ticks_correction = ihdr->clock_corr * 10;
    ohdr->first_data = 64;
    ohdr->first_blockette = 0;
    ohdr->pblockettes = NULL;

    decode_flags_qda (&ohdr->num_ticks_correction, ihdr->soh, 
		&ohdr->activity_flags, &ohdr->io_flags, 
		&ohdr->data_quality_flags);

    /*	If the time correction has not already been added, we should	*/
    /*	add it to the begtime.  Do NOT change the ACTIVITY flag, since	*/
    /*	it refers to the hdrtime, NOT the begtime/endtime.		*/

    if ( ohdr->num_ticks_correction != 0 && 
	((ohdr->activity_flags & ACTIVITY_TIME_GAP) == 0) ) {
	ohdr->begtime = add_time (ohdr->begtime, 0, ohdr->num_ticks_correction);
    }

    time_interval(ohdr->num_samples - 1, ohdr->sample_rate,
		  &second, &ticks);
    ohdr->endtime = add_time (ohdr->begtime, second, ticks);
    ohdr->data_type = UNKNOWN_DATATYPE;
    return(ohdr);
}

/************************************************************************/
/*  Routines for processing SEED Data Record (SDR) Quanterra data.	*/
/*									*/
/*	Douglas Neuhauser						*/
/*	Seismographic Station						*/
/*	University of California, Berkely				*/
/*	doug@seismo.berkeley.edu						*/
/*									*/
/************************************************************************/

#ifndef lint
static char sccsid[] = "@(#)sdr_utils.c	1.13 2/2/96 13:01:13";
#endif

#include    <stdio.h>
#include    <stdlib.h>
#include    <memory.h>
#include    <string.h>
#include    <time.h>
#include    <math.h>

double exp2(double x);

#include    "qlib.h"

#define	DATA_HDR_IND	'D'
#define	VOL_HDR_IND	'V'

int  herrno;			/*  errno from header routines.		*/

#ifdef	QLIB_DEBUG
extern FILE *info;		/*:: required only for debugging	*/
extern int  debug_option;	/*:: required only for debugging	*/
#endif

int	    read_blockettes (DATA_HDR *, char *);

/************************************************************************/
/*  decode_time_sdr:							*/
/*	Convert from SDR format time to INT_TIME.			*/
/************************************************************************/
INT_TIME
decode_time_sdr (st)
    SDR_TIME	st;
{
    EXT_TIME	et;

#ifdef	QLIB_DEBUG
    if (debug_option & 128) 
    fprintf (info, "time = %02d.%02d %02d:%02d:%02d:%04d\n",
	     st.year,	st.day,	    st.hour,
	     st.minute,	st.second,  st.ticks);
#endif

    et.year = st.year;
    et.doy = st.day;
    et.hour = st.hour;
    et.minute = st.minute;
    et.second = st.second;
    et.ticks = st.ticks;
    dy_to_mdy (et.doy, et.year, &et.month, &et.day);
    return (normalize_time(ext_to_int(et)));
}

/************************************************************************/
/*  encode_time_sdr:							*/
/*	Convert from INT_TIME to SDR format time.			*/
/************************************************************************/
SDR_TIME
encode_time_sdr(it)
    INT_TIME	it;
{
    SDR_TIME	st;
    EXT_TIME	et = int_to_ext(it);
    st.year = et.year;
    st.day = et.doy;
    st.hour = et.hour;
    st.minute = et.minute;
    st.second = et.second;
    st.pad = 0;
    st.ticks = et.ticks;
    return (st);
}

/************************************************************************/
/*  decode_hdr_sdr:							*/
/*	Decode SDR header stored with each DRM data block,		*/
/*	and return ptr to dynamically allocated DATA_HDR structure.	*/
/*	Fill in structure with the information in a easy-to-use format.	*/
/*	Skip over vol_hdr record, which may be on Quanterra Ultra-Shear	*/
/*	tapes.								*/
/************************************************************************/
DATA_HDR *
decode_hdr_sdr (ihdr, pblksize)
    SDR_HDR		*ihdr;
    int			*pblksize;
{
    char		tmp[80];
    DATA_HDR		*ohdr;
    char		*pc;
    int			i, next_seq;
    int			second, ticks;

    /* Perform data integrity check, and pick out pertinent header info.*/
    herrno=0;
    if (!(ihdr->data_hdr_ind == DATA_HDR_IND || ihdr->data_hdr_ind == VOL_HDR_IND)) {
	/*  Don't have a DATA_HDR_IND.  See if the entire header is	*/
	/*  composed of NULLS.  If so, print warning and return NULL.	*/
	/*  Some early Quanterras output a spurious block with null	*/
	/*  header info every 16 blocks.  That block should be ignored.	*/
	if (allnull((char *)ihdr, sizeof(SDR_HDR))) {
	    return((DATA_HDR *)NULL);
	}
	else {
	    herrno = 1;
	    return ((DATA_HDR *)NULL);
	}
    }

    /* Handle volume header */
    if (ihdr->data_hdr_ind == VOL_HDR_IND) {
	/* If volume header has blockette 8, get blksize from that. */
	char *p;
	char lrl[3];
	p = (char *)ihdr;
	if (strncmp(p+8,"008",3)==0) {
	    strncpy(lrl,p+19,2);
	    lrl[2] = '\0';
	    *pblksize = exp2(atoi(lrl));
	}
	return (NULL);
    }

    if ((ohdr = (DATA_HDR *)malloc(sizeof(DATA_HDR)))==NULL) return(NULL);
    memset ((void *)ohdr, 0, sizeof(DATA_HDR));
    ohdr->seq_no = atoi (charncpy (tmp, ihdr->seq_no, 6) );

    charncpy (ohdr->station_id, ihdr->station_id, 5);
    charncpy (ohdr->location_id, ihdr->location_id, 2);
    charncpy (ohdr->channel_id, ihdr->channel_id, 3);
    charncpy (ohdr->network_id, ihdr->network_id, 2);
    trim (ohdr->station_id);
    trim (ohdr->location_id);
    trim (ohdr->channel_id);
    trim (ohdr->network_id);
    ohdr->hdrtime = ohdr->begtime = decode_time_sdr(ihdr->time);
    ohdr->num_samples = ihdr->num_samples;
    ohdr->sample_rate = eval_rate(ihdr->sample_rate_factor, 
				  ihdr->sample_rate_mult);

    /*	WARNING - may need to convert flags to independent format	*/
    /*	if we ever choose a different flag format for the DATA_HDR.	*/
    ohdr->activity_flags = ihdr->activity_flags;
    ohdr->io_flags = ihdr->io_flags;
    ohdr->data_quality_flags = ihdr->data_quality_flags;

    ohdr->num_blockettes = ihdr->num_blockettes;
    ohdr->num_ticks_correction = ihdr->num_ticks_correction;
    ohdr->first_data = ihdr->first_data;
    ohdr->first_blockette = ihdr->first_blockette;
    ohdr->data_type = 0;		/* assume unknown datatype.	*/
    if (ihdr->num_blockettes == 0) ohdr->pblockettes = (BS *)NULL;
    else {
	if (! read_blockettes (ohdr, (char *)ihdr)) {
	    free(ohdr);
	    return((DATA_HDR *)NULL);
	}
    }

    /*	If the time correction has not already been added, we should	*/
    /*	add it to the begtime.  Do NOT change the ACTIVITY flag, since	*/
    /*	it refers to the hdrtime, NOT the begtime/endtime.		*/
    if ( ohdr->num_ticks_correction != 0 && 
	((ohdr->activity_flags & ACTIVITY_TIME_GAP) == 0) ) {
	ohdr->begtime = add_time (ohdr->begtime, 0, ohdr->num_ticks_correction);
    }

    time_interval(ohdr->num_samples - 1, ohdr->sample_rate,
		  &second, &ticks);
    ohdr->endtime = add_time(ohdr->begtime, second, ticks);

    /*	Process any blockettes that follow the fixed data header.	*/
    /*	If a blockette 1000 exists, fill in the datatype.		*/
    /*	Otherwise, leave the datatype as unknown.			*/
    ohdr->data_type = UNKNOWN_DATATYPE;
    if (ohdr->num_blockettes != 0) {
	int	block_type;
	int	blockette_offset = ihdr->first_blockette;
	char	*p = (char *) ihdr;
	do {
	    block_type = ((BLOCKETTE_HDR *)(p+blockette_offset))->type;
	    switch (block_type) {
	      case 1000:
		ohdr->data_type = ((BLOCKETTE_1000 *)(p+blockette_offset))->format;
		*pblksize = exp2(((BLOCKETTE_1000 *)(p+blockette_offset))->data_rec_len);
		blockette_offset = ((BLOCKETTE_HDR *)(p+blockette_offset))->next;
		break;
	      default:
		blockette_offset = ((BLOCKETTE_HDR *)(p+blockette_offset))->next;
		break;
	    }
	} while (blockette_offset > 0);
    }

    /*	Attempt to determine blocksize if current setting is 0.		*/
    /*	We can detect files of either 512 byte or 4K byte blocks.	*/
    if (*pblksize == 0) {
	for (i=1; i< 4; i++) {
	    pc = ((char *)(ihdr)) + (i*512);
	    if ( allnull ( pc,sizeof(SDR_HDR)) )
		continue;
	    next_seq = atoi (charncpy (tmp, ((SDR_HDR *)pc)->seq_no, 6) );
	    if (next_seq == ohdr->seq_no + i) {
		*pblksize = 512;
		break;
	    }
	}
	/* Can't determine the blocksize.   */
    }

    /* Return NULL if we don't have a data block. */
    if (ihdr->data_hdr_ind != DATA_HDR_IND) {
	free(ohdr);
	return((DATA_HDR *)NULL);
    }
	
    return(ohdr);
}

/************************************************************************/
/*  asc_sdr_time:							*/
/*	Convert SDR_TIME to ascii string.				*/
/*	Note that we output string in IRIS-style format with commas.	*/
/************************************************************************/
char *
asc_sdr_time(str, st) 
    char	*str;
    SDR_TIME	st;
{
    sprintf(str,"%04d,%03d,%02d:%02d:%02d.%04d", st.year,
	    st.day, st.hour, st.minute, st.second, st.ticks);
    return (str);
}

/************************************************************************/
/*  unix_time_from_sdr_time:						*/
/*	Convert SDR_TIME to unix timestamp.				*/
/************************************************************************/
time_t
unix_time_from_sdr_time (sdr)
    SDR_TIME	*sdr;
{    
    EXT_TIME	et;
    et.year = sdr->year;
    et.doy = sdr->day;
    et.hour = sdr->hour;
    et.minute = sdr->minute;
    et.second = sdr->second;
    et.ticks = sdr->ticks;
    dy_to_mdy (et.doy, et.year, &et.month, &et.day);
    return (unix_time_from_ext_time(et));
}

/************************************************************************/
/*  SEED Data Blockette routines.					*/
/************************************************************************/

/************************************************************************/
/*  read_blockettes:							*/
/*	Read binary blockettes that follow the SEED fixed data header.	*/
/*	Return 1 on success, 0 on error.				*/
/************************************************************************/
int
read_blockettes (hdr, str)
    DATA_HDR	*hdr;		/* data_header structure.		*/
    char	*str;		/* ptr to fixed data header.		*/
{
    BS		*bs, *pbs;
    char	*b;
    int		offset, bl_len, bl_next, bl_type, i;

    bs = pbs = (BS *)NULL;
    offset = hdr->first_blockette;
    hdr->pblockettes = (BS *)NULL;
    bl_next = 0;

    /*	Run through each blockette, allocate a linked list structure	*/
    /*	for it, and verify that the blockette structures are OK.	*/
    /*	There is a LOT of checking to ensure proper structure.		*/
    for (i=0; i<hdr->num_blockettes; i++) {

	if (i > 0 && bl_next == 0) {
	    fprintf (stderr, "zero offset to next blockette\n");
	    exit(1);
	}

	if ( (bs=(BS *)malloc(sizeof(BS))) == NULL ) {
	    fprintf (stderr, "unable to malloc BS\n");
	    exit(1);
	}
	bs->next = (BS *)NULL;

	/*  Decide how much space the blockette takes up.		*/
	/*  In order to allow for variable blockette size for either	*/
	/*  newer SEED version or vendor-specific additions,		*/
	/*  attempt to determine the required space by the offset to	*/
	/*  the next blockette.  If this is the last blockette, 	*/
	/*  then just use the length of the blockette as it is defined.	*/
	bl_type = ((BLOCKETTE_HDR *)(str+offset))->type;
	bl_next = ((BLOCKETTE_HDR *)(str+offset))->next;
	if (bl_next > 0) {
	    bl_len = (bl_next-offset);
	}
	else {
	    /* No further blockettes.  Assume length of blockette structure.*/
	    switch (bl_type) {
	      case 100: bl_len = sizeof (BLOCKETTE_100); break;
	      case 200: bl_len = sizeof (BLOCKETTE_200); break;
	      case 201: bl_len = sizeof (BLOCKETTE_201); break;
	      case 300: bl_len = sizeof (BLOCKETTE_300); break;
	      case 310: bl_len = sizeof (BLOCKETTE_310); break;
	      case 320: bl_len = sizeof (BLOCKETTE_320); break;
	      case 390: bl_len = sizeof (BLOCKETTE_390); break;
	      case 395: bl_len = sizeof (BLOCKETTE_395); break;
	      case 400: bl_len = sizeof (BLOCKETTE_400); break;
	      case 405: bl_len = sizeof (BLOCKETTE_405); break;
	      case 500: bl_len = sizeof (BLOCKETTE_500); break;
	      case 1000: bl_len = sizeof (BLOCKETTE_1000); break;
	      case 1001: bl_len = sizeof (BLOCKETTE_1001); break;
	      default: bl_type = 0; bl_len = 0; break;
	    }
	    /* Ensure that the blockette length does not exceed space	*/
	    /* available for it after the header and before first_data.	*/
	    if (hdr->first_data - offset > 0 && bl_len > hdr->first_data - offset)
		bl_len = hdr->first_data - offset;
	}

	if (bl_next != 0 && bl_len != 0) {
	    /* Verify length for known blockettes when possible. */
/*::
	    if (bl_len != bl_next-offset) {
		fprintf (stderr, "blockette %d apparent size %d does not match known length %d\n",
			 bl_type, bl_next-offset, bl_len);
		exit(1);
	    }
::*/
	}
	else if (bl_len == 0 && bl_type == 0) {
	    /* Assume the blockette reaches to first data.  */
	    /* If first data == 0, then abort -- we don't know this blockette.	*/
	    if (hdr->first_data <= offset) {
		fprintf (stderr, "Unknown blockette type %d - unable to determine size\n",
			 ((BLOCKETTE_HDR *)(str+offset))->type);
		fflush(stderr);
		free(bs);
		continue;
	    }
	    else bl_len = hdr->first_data - offset;
	}
	if ((bs->pb = (char *)malloc(bl_len))==NULL) {
	    fprintf (stderr, "unable to malloc blockettd\n");
	    exit(1);
	}
	memcpy (bs->pb,str+offset,bl_len);
	bs->len = bl_len;
	offset += bl_len;
	if (i == 0) hdr->pblockettes = bs;
	else pbs->next = bs;
	pbs = bs;
    }

    /* Ensure there are no more blockettes. */
    if (bl_next != 0) {
	fprintf (stderr, "extra blockette found\n");
	return (0);
    }
    return (1);
}

/************************************************************************/
/*  find_blockette:							*/
/*	Find a specified blockette in our linked list of blockettes.	*/
/************************************************************************/
BS *
find_blockette (hdr,n) 
    DATA_HDR	*hdr;
    int		n;
{
    BS		*bs = hdr->pblockettes;
    while (bs != (BS *)NULL) {
	if ( ((BLOCKETTE_HDR*)(bs->pb))->type == n) return (bs);
	bs = bs->next;
    }
    return(bs);
}

/************************************************************************/
/*  find_pblockette:							*/
/*	Find the next specified blockette starting with the BS* from	*/
/*	the linked list of blockettes.					*/
/*	This function is required because there can be more than 1	*/
/*	occurance of a numbered blockette.				*/
/************************************************************************/
BS *
find_pblockette (bs,n) 
    BS		*bs;		/* BS* to start with.			*/
    int		n;
{
    while (bs != (BS *)NULL) {
	if ( ((BLOCKETTE_HDR*)(bs->pb))->type == n) return (bs);
	bs = bs->next;
    }
    return(bs);
}

/************************************************************************/
/*  blockettecmp:							*/
/*	Compare the contents of 2 blockettes, and return result.	*/
/*	Ignore the ptr to next blockette at the beginning blockette	*/
/************************************************************************/
int
blockettecmp(BS *b1, BS *b2)
{
    int l1, l2, type1, type2, status;
    if (b1 == NULL && b2 == NULL) return (0);
    if (b1 == NULL) return (-1);
    if (b2 == NULL) return (1);
    type1 = ((BLOCKETTE_HDR *)(b1->pb))->type;
    type2 = ((BLOCKETTE_HDR *)(b1->pb))->type;
    if (type1-type2) return (type1-type2);
    l1 = b1->len;
    l2 = b2->len;
    if (l1-l2) return (l1-l2);
    status = memcmp(((char *)b1->pb)+4,((char*)b2->pb)+4, l1);
    return (status);
}

/************************************************************************/
/*  write_blockettes:							*/
/*	Write the blockettes contained in the linked list of		*/
/*	blockettes to the output SEED data records.			*/
/************************************************************************/
int
write_blockettes (hdr, str) 
    DATA_HDR	*hdr;		/* ptr to data_hdr			*/
    char	*str;		/* ptr to output SDR.			*/
{
    SDR_HDR	*ohdr =	(SDR_HDR *)str;
    BS		*bs = hdr->pblockettes;
    int		offset = hdr->first_blockette;

    while (bs != (BS *)NULL) {
	/* Ensure offset to next blockette is correct.			*/
	((BLOCKETTE_HDR *)(bs->pb))->next = 
	    (bs->next == NULL) ? 0 : offset + bs->len;
	memcpy (str+offset,bs->pb,bs->len);
	offset += bs->len;
	bs = bs->next;
    }
    if (hdr->first_data > 0 && offset > hdr->first_data) {
	fprintf (stderr, "blockettes won't fit between hdr and data.\n");
	exit(1);
    }
    return (0);
}

/************************************************************************/
/*  add_blockette:							*/
/*	Add the specified blockette to the linked list of blockettes.	*/
/************************************************************************/
int
add_blockette (hdr, str, l, where) 
    DATA_HDR	*hdr;		/* ptr to data_hdr.			*/
    char	*str;		/* pre-constructed blockette.		*/
    int		l;		/* length of blockette.			*/
    int		where;		/* i -> i-th blockette from start,	*/
				/* -1 -> append as last blockette.	*/
{
    BLOCKETTE_HDR   *bh = (BLOCKETTE_HDR *)str;
    BS		    *bs;
    BS		    *prev;
    /*	BEWARE:								*/
    /*	We always have to add blockettes at the beginning since we may	*/
    /*	If we a blockette of unknown length, we should always add as	*/
    /*	first blockette in order to keep unknown blockette at end.	*/
    /*	Don't worry about updating the offset within the blockette	*/
    /*	headers, since we will do that on output.			*/

    if ((bs=(BS *)malloc(sizeof(BS)))==NULL) {
	fprintf (stderr, "unable to malloc BS\n");
	exit(1);
    }
    if ((bs->pb=(char *)malloc(l))==NULL) {
	fprintf (stderr, "unable to malloc blockette\n");
	exit(1);
    }
    memcpy (bs->pb, str, l);
    bs->len = l;

    prev = hdr->pblockettes;
    if (prev == NULL || where == 0) {
	/* Insert at beginning of the blockette list.	*/
	bs->next = hdr->pblockettes;
	hdr->pblockettes = bs;
    }
    else {
	while (--where != 0 && prev->next != NULL) {
	    prev = prev->next;
	}
	/* Insert blockette after prev.. */
	bs->next = prev->next;
	prev->next = bs;
    }
    if (hdr->num_blockettes == 0) hdr->first_blockette = 48;
    ++(hdr->num_blockettes);
    return(1);
}

/************************************************************************/
/*  delete_blockette:							*/
/*	Delete the specified blockette from the linked list of		*/
/*	blockettes.							*/
/*	Return the number of blockettes that were deleted.		*/
/************************************************************************/
int 
delete_blockette (hdr,n) 
    DATA_HDR	*hdr;
    int		n;	/* blockette # to delete.  -1 -> ALL blockettes.*/
{
    BS		*bs = hdr->pblockettes;
    BS		*pbs = (BS *)NULL;
    BS		*dbs;
    int		num_deleted = 0;

    /*	Don't worry about updating the offset within the blockette	*/
    /*	headers, since we will do that on output.			*/
    while (bs != (BS *)NULL) {
	if ( n < 0 || n == ((BLOCKETTE_HDR*)(bs->pb))->type) {
	    if (pbs == NULL)
		hdr->pblockettes = bs->next;
	    else 
		pbs->next = bs->next;
	    --(hdr->num_blockettes);
	    if (hdr->num_blockettes <= 0) 
		hdr->first_blockette = 0;
	    dbs = bs;
	    bs = bs->next;
	    free (dbs->pb);
	    free (dbs);
	    ++num_deleted;
	}
	else {
	    pbs = bs;
	    bs = bs->next;
	}
    }
    return (num_deleted);
}

/************************************************************************/
/*  delete_pblockette:							*/
/*	Delete the blockette specified by the BS* from the linked	*/
/*	list of blockettes.						*/
/*	Return the number of blockettes that were deleted.		*/
/************************************************************************/
int 
delete_pblockette (hdr,dbs) 
    DATA_HDR	*hdr;
    BS		*dbs;		/* BS* to delete.			*/
{
    BS		*bs = hdr->pblockettes;
    BS		*pbs = (BS *)NULL;
    int		num_deleted = 0;

    /*	Don't worry about updating the offset within the blockette	*/
    /*	headers, since we will do that on output.			*/
    pbs = NULL;
    while (bs != (BS *)NULL) {
	if (bs == dbs) {
	    if (pbs == NULL)
		hdr->pblockettes = bs->next;
	    else
		pbs->next = bs->next;
	    free (dbs->pb);
	    free (dbs);
	    --(hdr->num_blockettes);
	    if (hdr->num_blockettes <= 0) 
		hdr->first_blockette = 0;
	    ++num_deleted;
	    break;
	}
	else {
	    pbs = bs;
	    bs = bs -> next;
	}
    }
    return (num_deleted);
}

/************************************************************************/
/*  free_data_hdr:							*/
/*	Free all malloced space associated with a DATA_HDR		*/
/************************************************************************/
void
free_data_hdr(p_hdr)
    DATA_HDR	    *p_hdr;
{
    if (p_hdr == NULL) return;
    if (p_hdr->pblockettes != NULL) delete_blockette (p_hdr, -1);
    free (p_hdr);
    return;
}

/************************************************************************/
/*  eval_rate:								*/
/*	Evaluate sample rate.						*/
/*	Return >0 if samples/second, <0 if seconds/sample, 0 if 0.	*/
/************************************************************************/
int eval_rate (int sample_rate_factor, int sample_rate_mult)
{
    double drate;
    int rate;

    if (sample_rate_factor > 0 && sample_rate_mult > 0) 
	drate = (double)sample_rate_factor * (double)sample_rate_mult;
    else if (sample_rate_factor > 0 && sample_rate_mult < 0) 
	drate = -1. * (double)sample_rate_factor / (double)sample_rate_mult;
    else if (sample_rate_factor < 0 && sample_rate_mult > 0) 
	drate = -1. * (double)sample_rate_mult / (double)sample_rate_factor;
    else if (sample_rate_factor < 0 && sample_rate_mult < 0) 
	drate = (double)sample_rate_mult / (double)sample_rate_factor;
    else drate = 0.;

    if (drate == 0.) rate = 0;
    else if (drate >= 1.) rate = roundoff(drate);
    else rate = -1 * roundoff(1./drate);
    return (rate);
}

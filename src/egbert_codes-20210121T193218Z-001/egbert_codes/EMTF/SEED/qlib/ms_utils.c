/************************************************************************/
/*  Routines for processing Mini_SEED Data files.			*/
/*									*/
/*	Douglas Neuhauser						*/
/*	Seismographic Station						*/
/*	University of California, Berkely				*/
/*	doug@seismo.berkeley.edu					*/
/*									*/
/************************************************************************/

#ifndef lint
static char sccsid[] = "@(#)ms_utils.c	1.8 5/24/96 15:50:35";
#endif

#include    <stdio.h>
#include    <stdlib.h>
#include    <memory.h>
#include    <string.h>
#include    <math.h>

double exp2(double x);

#include    "qlib.h"

#define	DATA_HDR_IND	'D'
#define ERROR		-2
#define MAXBLKSIZE	32768
#define	FIXED_DATA_HDR_SIZE 48

/************************************************************************/
/*	Fortran interlude to Routines to read Mini-SEED volumes.	*/
/************************************************************************/
int read_ms_ (fhdr, data_buffer, maxpts, pfp) 
    DATA_HDR *fhdr;		/* pointer to FORTRAN DATA_HDR.		*/
    void    *data_buffer;	/* pointer to output data buffer.	*/
    int	    *maxpts;		/* max # data points to return.		*/
    FILE    **pfp;		/* FILE pointer for input file.		*/
{
    DATA_HDR	*hdr;		/* pointer to DATA_HDR.			*/
    int nread;

    nread = 0;
    nread = read_ms (&hdr, data_buffer, *maxpts, *pfp);
    /* Copy hdr to fortran structure, and convert char strings.		*/
    /* For FORTRAN use, I will not return the blockettes, since they	*/
    /* can't reference them directly.					*/
    if (nread > 0 && hdr == NULL) return (ERROR);
    if (hdr != NULL) {
	*fhdr = *hdr;
	cstr_to_fstr(fhdr->station_id, DH_STATION_LEN+1);
	cstr_to_fstr(fhdr->location_id, DH_LOCATION_LEN+1);
	cstr_to_fstr(fhdr->channel_id, DH_CHANNEL_LEN+1);
	cstr_to_fstr(fhdr->network_id, DH_NETWORK_LEN+1);
	free_data_hdr (hdr);
	fhdr->pblockettes = NULL;
    }
    return (nread);
}

/************************************************************************/
/*	Routine to read Mini-SEED volumes.				*/
/************************************************************************/
int read_ms (phdr, data_buffer, max_num_points, fp)
    DATA_HDR **phdr;		/* pointer to pointer to DATA_HDR.	*/
    void    *data_buffer;	/* pointer to output data buffer.	*/
    int	    max_num_points;	/* max # data points to return.		*/
    FILE    *fp;		/* FILE pointer for input file.		*/
{
    int status;

    if (max_num_points < 0) return (ERROR);
    if (max_num_points == 0) return (0);
    if ((status = read_ms_hdr (phdr, fp)) > 0)
	status = read_ms_data (*phdr, data_buffer, max_num_points, fp);
    return (status);
}

/************************************************************************/
/*	Routine to read Mini-SEED Fixed Data Header and blockettes.	*/
/************************************************************************/
int read_ms_hdr (phdr, fp)
    DATA_HDR **phdr;		/* pointer to pointer to DATA_HDR.	*/
    FILE    *fp;		/* FILE pointer for input file.		*/
{
    char buf[MAXBLKSIZE];	/* Local buffer for hdr and blockettes.	*/
    DATA_HDR *hdr;		/* pointer to DATA_HDR.			*/
    BS *bs;			/* ptr to blockette structure.		*/
    int nskip = 0;
    int offset = 0;
    int nread;
    int	blksize;		/* blocksize of miniSEED record.	*/
    int bl_limit;		/* offset of data (blksize if no data).	*/

    /* Read and decode SEED Fixed Data Header.				*/
    *phdr = (DATA_HDR *)NULL;
    if ((nread = fread(buf, FIXED_DATA_HDR_SIZE, 1, fp)) != 1)
	return ((nread == 0) ? EOF : ERROR);
    offset = FIXED_DATA_HDR_SIZE;
    if ((hdr = decode_fixed_data_hdr((SDR_HDR *)buf)) == NULL) return (ERROR);

    /* Read blockettes.  Mini-SEED should have at least blockette 1000.	*/
    if (hdr->num_blockettes > 0) {
	if (hdr->first_blockette < offset) {
	    free_data_hdr(hdr);
	    return(ERROR);
	}
	if (hdr->first_blockette > offset) {
	    nskip = hdr->first_blockette - offset;
	    if (fread (buf+offset, nskip, 1, fp) != 1) {
		free_data_hdr(hdr);
		return (ERROR);
	    }
	    offset += nskip;
	}
	if ((offset = read_ms_bkt (hdr, fp, buf)) < 0) {
	    return (ERROR);
	}
    }

    /* Determine blocksize and data format from the blockette 1000.	*/
    /* If we don't have one, it is an error.				*/
    if ((bs = find_blockette (hdr, 1000)) == NULL) {
	return (ERROR);
    }
    blksize = exp2(((BLOCKETTE_1000 *)(bs->pb))->data_rec_len);

    /* Skip over space between blockettes (if any) and data.		*/
    bl_limit = (hdr->first_data) ? hdr->first_data : blksize;
    if (bl_limit < offset) {
	    free_data_hdr(hdr);
	    return(ERROR);
	}
    if (bl_limit > offset) {
	nskip = bl_limit - offset;
	if (fread (buf+offset, nskip, 1, fp) != 1) {
	    free_data_hdr(hdr);
	    return (ERROR);
	}
	offset += nskip;
    }

    *phdr = hdr;
    return (1);		/* Header successfully read.			*/
}

/************************************************************************/
/*  read_ms_bkt:							*/
/*	Read binary blockettes that follow the SEED fixed data header.	*/
/*	Return offset of next byte to be read.				*/
/************************************************************************/
int
read_ms_bkt (hdr, fp, str)
    DATA_HDR	*hdr;		/* data_header structure.		*/
    FILE	*fp;		/* FILE pointer for input file.		*/
    char	*str;		/* ptr to fixed data header.		*/
{
    BS		*bs, *pbs;
    char	*b;
    int		offset, bl_len, bl_next, bl_type, bl_limit, i;
    int		bh_len = sizeof(BLOCKETTE_HDR);
    int		blksize = 0;

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
	if (i == 0) hdr->pblockettes = bs;
	else pbs->next = bs;
	pbs = bs;

	/*  Read blockette header.					*/
	if (fread (str+offset, bh_len, 1, fp) != 1) 
	    return (-1);

	/*  Decide how much space the blockette takes up.  If we know 	*/
	/*  blockette type, then allocate the appropriate space.	*/
	/*  Otherwise, determine the required space by the offset to	*/
	/*  the next blockette, or by the offset to the first data if	*/
	/*  this is the last blockette.					*/
	/*  If there is not data, then ensure that we know the length	*/
	/*  of the blockette.  If not, consider it to be a fatal error,	*/
	/*  since we have no idea how long it should be.		*/
	/*								*/
	/*  We cannot allow it to extend to the blksize, since we use	*/
	/*  this routine to process blockettes from packed miniSEED	*/
	/*  files.  Packed miniSEED files contain records that are a	*/
	/*  multiple of the packsize (currently 128 bytes) with a block	*/
	/*  whose size is specified in the b1000 blksize field.		*/
	bl_type = ((BLOCKETTE_HDR *)(str+offset))->type;
	bl_next = ((BLOCKETTE_HDR *)(str+offset))->next;
	bl_limit = (bl_next) ? bl_next : 
		   (hdr->first_data) ? hdr->first_data :
		   0;
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
	  default:
	    fprintf (stderr, "Warning - unknown blockette %d\n",bl_type);
	    bl_len = 0;
	    break;
	}

	/* Perform integrity checks on blockette.			*/
	if (bl_len != 0) {
	    /* Known blockettes:					*/
	    /* Check that the presumed blockette length is correct.	*/
	    if (bl_limit > 0 && bl_len > bl_limit-offset) {
		/* Warning only if blockette is too short.		*/
		/* Allow padding between blockettes.			*/
		fprintf (stderr, "Warning: short blockette %d len=%d, expected len=%d\n",
			 bl_type, bl_limit-offset, bl_len);
	    }
	    /* Be safe and extend the effective length of the blockette	*/
	    /* to the limit (next blockette or first data) if there is	*/
	    /* a limit.							*/
	    bl_len = (bl_limit) ? bl_limit - offset : bl_len;
	    /* Check that we do not run into the data portion of record.*/
	    if (hdr->first_data != 0 && bl_len+offset > hdr->first_data) {
		fprintf (stderr, "Warning: blockette %d	at offset=%d len=%d first_data=%d\n",
			 bl_type, bl_limit-offset, bl_len);
		bl_len = bl_limit - offset;
	    }
	}
	else {
	    /* Unknown blockettes:					*/
	    if (bl_limit == 0) {
		fprintf (stderr, "Error - unknown blockette and no length limit\n");
		return (-1);
	    }
	    /* For unknown blockettes ensure that we have a max len.	*/
	    bl_len = bl_limit - offset;
	}

	if ((bs->pb = (char *)malloc(bl_len))==NULL) {
	    fprintf (stderr, "unable to malloc blockettd\n");
	    return (-1);
	}
	/* Read the body of the blockette, and copy entire blockette.	*/
	if (fread(str+offset+bh_len, bl_len-bh_len, 1, fp) != 1)
	    return(-1);
	memcpy (bs->pb,str+offset,bl_len);
	bs->len = bl_len;
	if (bl_type == 1000) {
	    blksize = exp2(((BLOCKETTE_1000 *)(str+offset))->data_rec_len);
	}
	offset += bl_len;
    }

    /* Ensure there are no more blockettes. */
    if (bl_next != 0) {
	fprintf (stderr, "extra blockette found\n");
	return(-1);
    }
    return (offset);
}

/************************************************************************/
/*	Routine to read Mini-SEED Data portion of block.		*/
/************************************************************************/
int read_ms_data (hdr, data_buffer, max_num_points, fp)
    DATA_HDR *hdr;		/* pointer to pointer to DATA_HDR.	*/
    void    *data_buffer;	/* pointer to output data buffer.	*/
    int	    max_num_points;	/* max # data points to return.		*/
    FILE    *fp;		/* FILE pointer for input file.		*/
{
    BS *bs;			/* ptr to blockette structure.		*/
    BLOCKETTE_1000 *b1000;	/* ptr to blockette 1000.		*/
    int format;
    int blksize;
    int datasize;
    int nsamples;
    char *dbuf;
    int *databuff;
    int *diffbuff;

    /* Determine blocksize and data format from the blockette 1000.	*/
    /* If we don't have one, it is an error.				*/
    if ((bs = find_blockette (hdr, 1000)) == NULL) {
	return (ERROR);
    }
    b1000 = (BLOCKETTE_1000 *)bs->pb;
    format = b1000->format;
    blksize = ldexp (1., b1000->data_rec_len);
    datasize = blksize - hdr->first_data;
    if ((dbuf = (char *)malloc(datasize)) == NULL) {
	fprintf (stderr, "unable to malloc data buffer in ms_read_data\n");
	exit(1);
    }
    if (fread (dbuf, datasize, 1, fp) != 1) {
	free (dbuf);
	return (ERROR);
    }

    /* Decide if this is a format that we can decode.			*/
    switch (format) {
      case STEIM1:
	if ((diffbuff = (int *)malloc(hdr->num_samples * sizeof(int))) == NULL) {
	    fprintf (stderr, "unable malloc diff buffer in ms_read\n");
	    exit(1);
	}
	nsamples = unpack_steim1 ((void *)dbuf, datasize, hdr->num_samples,
				  max_num_points, data_buffer, diffbuff, 
				  &hdr->x0, &hdr->xn, NULL);
	free (diffbuff);
	break;
      case STEIM2:
	if ((diffbuff = (int *)malloc(hdr->num_samples * sizeof(int))) == NULL) {
	    fprintf (stderr, "unable malloc diff buffer in ms_read\n");
	    exit(1);
	}
	nsamples = unpack_steim2 ((void *)dbuf, datasize, hdr->num_samples,
				  max_num_points, data_buffer, diffbuff, 
				  &hdr->x0, &hdr->xn, NULL);
	free (diffbuff);
	break;
      case INT_16:
	nsamples = unpack_int_16 ((void *)dbuf, datasize, hdr->num_samples,
				  max_num_points, data_buffer, NULL);
	break;
      case INT_32:
	nsamples = unpack_int_32 ((void *)dbuf, datasize, hdr->num_samples,
				  max_num_points, data_buffer, NULL);
	break;
      case INT_24:
	nsamples = unpack_int_24 ((void *)dbuf, datasize, hdr->num_samples,
				  max_num_points, data_buffer, NULL);
	break;
     default:
	fprintf (stderr, "Currently unable to read format %d\n", format);
	exit(-1);
    }
    free (dbuf);
    if (nsamples > 0) {
	return (nsamples);
    }
    return (ERROR);
}

/************************************************************************/
/*  decode_fixed_data_hdr:						*/
/*	Decode SEED Fixed Data Header in the specified buffer,		*/
/*	and return ptr to dynamically allocated DATA_HDR structure.	*/
/*	Fill in structure with the information in a easy-to-use format.	*/
/*	Do not try to parse blockettes -- that will be done later.	*/
/************************************************************************/
DATA_HDR *
decode_fixed_data_hdr (ihdr)
    SDR_HDR		*ihdr;
{
    char		tmp[80];
    DATA_HDR		*ohdr;
    char		*pc;
    int			i, next_seq;
    int			second, ticks;

    /* Perform data integrity check, and pick out pertinent header info.*/
    if (ihdr->data_hdr_ind != DATA_HDR_IND) return ((DATA_HDR *)NULL);
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
    ohdr->sample_rate = eval_rate (ihdr->sample_rate_factor, 
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
    ohdr->pblockettes = (BS *)NULL;	/* Do not parse blockettes here.*/

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
    return(ohdr);
}

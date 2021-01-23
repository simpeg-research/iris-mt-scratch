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
static char sccsid[] = "@(#)unpack.c	1.3 5/24/96 15:50:36";
#endif

#include    <stdio.h>
#include    <stdlib.h>
#include    <math.h>
#include    <memory.h>

#include    "steim.h"
#include    "steim1.h"
#include    "steim2.h"

#define	info	stderr
#define	VALS_PER_FRAME	(16-1)		/* # of ints for data per frame.*/

#define	X0  pf->w[0].fw
#define	XN  pf->w[1].fw

/************************************************************************/
/*  unpack_steim1:							*/
/*	Unpack STEIM1 data frames and place in supplied buffer.		*/
/*	Data is divided into frames.					*/
/************************************************************************/
int
unpack_steim1 (pf, nbytes, num_samples, req_samples, databuff, 
	       diffbuff, px0, pxn, p_errmsg)
    FRAME	*pf;		/* ptr to Steim1 data frames.		*/
    int		nbytes;		/* number of bytes in all data frames.	*/
    int		num_samples;	/* number of data samples in all frames.*/
    int		req_samples;	/* number of data desired by caller.	*/
    int		*diffbuff;	/* ptr to unpacked diff array.		*/
    int		*databuff;	/* ptr to unpacked data array.		*/
    int		*px0;		/* return X0, first sample in frame.	*/
    int		*pxn;		/* return XN, last sample in frame.	*/
    char	**p_errmsg;	/* ptr to ptr to error message.		*/
{
    int		*diff = diffbuff;
    int		*data = databuff;
    int		*prev;
    int		num_data_frames = nbytes / sizeof(FRAME);
    int		nd = 0;		/* # of data points in packet.		*/
    int		fn;		/* current frame number.		*/
    int		wn;		/* current work number in the frame.	*/
    int		c;		/* current compression flag.		*/
    int		nr, last_data, i;
    static char	errmsg[256];

    if (num_data_frames * sizeof(FRAME) != nbytes) return (-1);
    if (req_samples < 0 || num_samples <= 0) return (-1);

    /* Extract forward and reverse integration constants in first frame.*/
    *px0 = X0;
    *pxn = XN;

    /*	Decode compressed data in each frame.				*/
    for (fn = 0; fn < num_data_frames; fn++) {
	for (wn = 0; wn < VALS_PER_FRAME; wn++) {
	    if (nd >= num_samples) break;
	    c = (pf->ctrl >> ((VALS_PER_FRAME-wn-1)*2)) & 0x3;
	    switch (c) {
		case STEIM1_SPECIAL_MASK:
		    /* Headers info -- skip it.				*/
		    break;
		case STEIM1_BYTE_MASK:
		    /* Next 4 bytes are 4 1-byte differences.		*/
		    /* NOTE: THIS CODE ASSUMES THAT CHAR IS SIGNED.	*/
		    for (i=0; i<4 && nd<num_samples; i++,nd++)
			*diff++ = pf->w[wn].byte[i];
		    break;
		case STEIM1_HALFWORD_MASK:
		    /* Next 4 bytes are 2 2-byte differences.		*/
		    for (i=0; i<2 && nd<num_samples; i++,nd++)
			*diff++ = pf->w[wn].hw[i];
		    break;
		case STEIM1_FULLWORD_MASK:
		    /* Next 4 bytes are 1 4-byte difference.		*/
		    *diff++ = pf->w[wn].fw;
		    nd++;
		    break;
		default:
		    /* Should NEVER get here.				*/
		    fprintf (info, "invalid ck = %d\n", c);
		    exit(1);
		    break;
	    }
	}
	++pf;
    }

    /*	For now, assume sample count in header to be correct.		*/
    /*	One way of "trimming" data from a block is simply to reduce	*/
    /*	the sample count.  It is not clear from the documentation	*/
    /*	whether this is a valid or not, but it appears to be done	*/
    /*	by other program, so we should not complain about its effect.	*/
    nd = num_samples;
    nr = req_samples;

    /* Compute first value based on last_value from previous buffer.	*/
    /* The two should correspond in all cases EXCEPT for the first	*/
    /* record for each component (because we don't have a valid xn from	*/
    /* a previous record).  Although the Steim compression algorithm	*/
    /* defines x(-1) as 0 for the first record, this only works for the	*/
    /* first record created since coldstart of the datalogger, NOT the	*/
    /* first record of an arbitrary starting record for an event.	*/

    /* In all cases, assume x0 is correct, since we don't have x(-1).	*/
    data = databuff;
    diff = diffbuff;
    last_data = *px0;
    if (nr > 0) *data = *px0; 

    /* Compute all but first values based on previous value.		*/
    /* Compute all data values in order to compare last value with xn,	*/
    /* but only return the number of values desired by calling routine.	*/
    prev = data - 1;
    while (--nr > 0 && --nd > 0)
	last_data = *++data = *++diff + *++prev;
    while (--nd > 0)
	last_data = *++diff + last_data;

    /* Verify that the last value is identical to xn.			*/
    if (last_data != *pxn) {
	sprintf(errmsg, "%s, last_data=%d, xn=%d\n", 
		"Data integrity for STEIM1 data frame",
		 last_data, *pxn);
	if (p_errmsg) *p_errmsg = errmsg;
	else fprintf (info, errmsg);
	return (-1);
    }

    return ((req_samples<num_samples) ? req_samples : num_samples);
}

/************************************************************************/
/*  unpack_steim2:							*/
/*	Unpack STEIM2 data frames and place in supplied buffer.		*/
/*	Data is divided into frames.					*/
/************************************************************************/
int
unpack_steim2 (pf, nbytes, num_samples, req_samples, databuff, 
	       diffbuff, px0, pxn, p_errmsg)
    FRAME	*pf;		/* ptr to Steim2 data frames.		*/
    int		nbytes;		/* number of bytes in all data frames.	*/
    int		num_samples;	/* number of data samples in all frames.*/
    int		req_samples;	/* number of data desired by caller.	*/
    int		*diffbuff;	/* ptr to unpacked diff array.		*/
    int		*databuff;	/* ptr to unpacked data array.		*/
    int		*px0;		/* return X0, first sample in frame.	*/
    int		*pxn;		/* return XN, last sample in frame.	*/
    char	**p_errmsg;	/* ptr to ptr to error message.		*/
{
    int		*diff = diffbuff;
    int		*data = databuff;
    int		*prev;
    int		num_data_frames = nbytes / sizeof(FRAME);
    int		nd = 0;		/* # of data points in packet.		*/
    int		fn;		/* current frame number.		*/
    int		wn;		/* current work number in the frame.	*/
    int		c;		/* current compression flag.		*/
    int		nr, last_data, i;
    int		n, bits, m1, m2;
    int		val, dnib;
    static char	errmsg[256];

    if (num_data_frames * sizeof(FRAME) != nbytes) return (-1);
    if (req_samples < 0 || num_samples <= 0) return (-1);

    /* Extract forward and reverse integration constants in first frame.*/
    *px0 = X0;
    *pxn = XN;

    /*	Decode compressed data in each frame.				*/
    for (fn = 0; fn < num_data_frames; fn++) {
	for (wn = 0; wn < VALS_PER_FRAME; wn++) {
	    if (nd >= num_samples) break;
	    c = (pf->ctrl >> ((VALS_PER_FRAME-wn-1)*2)) & 0x3;
	    switch (c) {
	      case STEIM2_SPECIAL_MASK:
		/* Headers info -- skip it.				*/
		break;
	      case STEIM2_BYTE_MASK:
		/* Next 4 bytes are 4 1-byte differences.		*/
		/* NOTE: THIS CODE ASSUMES THAT CHAR IS SIGNED.	*/
		for (i=0; i<4 && nd<num_samples; i++,nd++)
		    *diff++ = pf->w[wn].byte[i];
		break;
	      case STEIM2_123_MASK:
		val = pf->w[wn].fw;
		dnib =  pf->w[wn].fw >> 30 & 0x3;
		switch (dnib) {
		  case 1:	/*	1 30-bit difference.		*/
		    bits = 30; n = 1; m1 = 0x3fffffff; m2 = 0x20000000; break;
		  case 2:	/*  2 15-bit differences.		*/
		    bits = 15; n = 2; m1 = 0x00007fff; m2 = 0x00004000; break;
		  case 3:	/*  3 10-bit differences.		*/
		    bits = 10; n = 3; m1 = 0x000003ff; m2 = 0x00000200; break;
		  default:	/*	should NEVER get here.		*/
		    sprintf (errmsg, "invalid ck, dnib, fn, wn = %d, %d, %d, %d\n", c, dnib, fn, wn);
		    if (p_errmsg) *p_errmsg = errmsg;
		    else fprintf (info, errmsg);
		    return(-1);
		    break;
		}
		/*  Uncompress the differences.			*/
		for (i=(n-1)*bits; i>=0 && nd<num_samples; i-=bits,nd++) {
		    *diff = (val >> i) & m1;
		    *diff++ = (*diff & m2) ? *diff | ~m1 : *diff;
		}
		break;
	      case STEIM2_567_MASK:
		val = pf->w[wn].fw;
		dnib =  pf->w[wn].fw >> 30 & 0x3;
		switch (dnib) {
		  case 0:	/*  5 6-bit differences.		*/
		    bits = 6; n = 5; m1 = 0x0000003f; m2 = 0x00000020; break;
		  case 1:	/*  6 5-bit differences.		*/
		    bits = 5; n = 6; m1 = 0x0000001f; m2 = 0x00000010; break;
		  case 2:	/*  7 4-bit differences.		*/
		    bits = 4; n = 7; m1 = 0x0000000f; m2 = 0x00000008; break;
		  default:
		    sprintf (errmsg, "invalid ck, dnib, fn, wn = %d, %d, %d, %d\n", c, dnib, fn, wn);
		    if (p_errmsg) *p_errmsg = errmsg;
		    else fprintf (info, errmsg);
		    return(-1);
		    break;
		}
		/*  Uncompress the differences.			*/
		for (i=(n-1)*bits; i>=0 && nd < num_samples; i-=bits,nd++) {
		    *diff = (val >> i) & m1;
		    *diff++ = (*diff & m2) ? *diff | ~m1 : *diff;
		}
		break;
	      default:
		/* Should NEVER get here.				*/
		fprintf (info, "invalid ck, fn, wn = %d, %d %d\n", c);
		exit(1);
		break;
	    }
	}
	++pf;
    }

    /*	For now, assume sample count in header to be correct.		*/
    /*	One way of "trimming" data from a block is simply to reduce	*/
    /*	the sample count.  It is not clear from the documentation	*/
    /*	whether this is a valid or not, but it appears to be done	*/
    /*	by other program, so we should not complain about its effect.	*/
    nd = num_samples;
    nr = req_samples;

    /* Compute first value based on last_value from previous buffer.	*/
    /* The two should correspond in all cases EXCEPT for the first	*/
    /* record for each component (because we don't have a valid xn from	*/
    /* a previous record).  Although the Steim compression algorithm	*/
    /* defines x(-1) as 0 for the first record, this only works for the	*/
    /* first record created since coldstart of the datalogger, NOT the	*/
    /* first record of an arbitrary starting record for an event.	*/

    /* In all cases, assume x0 is correct, since we don't have x(-1).	*/
    data = databuff;
    diff = diffbuff;
    last_data = *px0;
    if (nr > 0) *data = *px0; 

    /* Compute all but first values based on previous value.		*/
    /* Compute all data values in order to compare last value with xn,	*/
    /* but only return the number of values desired by calling routine.	*/
    prev = data - 1;
    while (--nr > 0 && --nd > 0)
	last_data = *++data = *++diff + *++prev;
    while (--nd > 0)
	last_data = *++diff + last_data;

    /* Verify that the last value is identical to xn.			*/
    if (last_data != *pxn) {
	sprintf(errmsg, "%s, last_data=%d, xn=%d\n", 
		"Data integrity for STEIM2 data frame",
		 last_data, *pxn);
	if (p_errmsg) *p_errmsg = errmsg;
	else fprintf (info, errmsg);
	return (-1);
    }

    return ((req_samples<num_samples) ? req_samples : num_samples);
}

/************************************************************************/
/*  unpack_int_16:							*/
/*	Unpack int_16 miniSEED data and place in supplied buffer.	*/
/************************************************************************/
int
unpack_int_16 (ibuf, nbytes, num_samples, req_samples, databuff, 
	       p_errmsg)
    short int	*ibuf;		/* ptr to input data.			*/
    int		nbytes;		/* number of bytes in all data frames.	*/
    int		num_samples;	/* number of data samples in all frames.*/
    int		req_samples;	/* number of data desired by caller.	*/
    int		*databuff;	/* ptr to unpacked data array.		*/
    char	**p_errmsg;	/* ptr to ptr to error message.		*/
{
    int		*data = databuff;
    int		nd = 0;		/* # of data points in packet.		*/
    int		i;
    static char	errmsg[256];

    if (req_samples < num_samples) return (-1);
    if (req_samples < 0 || num_samples <= 0) return (-1);

    for (nd=0; nd<req_samples; nd++) {
	databuff[nd] = ibuf[nd];
    }

    return (nd);
}

/************************************************************************/
/*  unpack_int_32:							*/
/*	Unpack int_32 miniSEED data and place in supplied buffer.	*/
/************************************************************************/
int
unpack_int_32 (ibuf, nbytes, num_samples, req_samples, databuff, 
	       p_errmsg)
    int		*ibuf;		/* ptr to input data.			*/
    int		nbytes;		/* number of bytes in all data frames.	*/
    int		num_samples;	/* number of data samples in all frames.*/
    int		req_samples;	/* number of data desired by caller.	*/
    int		*databuff;	/* ptr to unpacked data array.		*/
    char	**p_errmsg;	/* ptr to ptr to error message.		*/
{
    int		*data = databuff;
    int		nd = 0;		/* # of data points in packet.		*/
    int		nr, last_data, i;
    static char	errmsg[256];

    if (req_samples < num_samples) return (-1);
    if (req_samples < 0 || num_samples <= 0) return (-1);

    for (nd=0; nd<req_samples; nd++) {
	databuff[nd] = ibuf[nd];
    }

    return (nd);
}

/* Macro to return i-th bit (bit 0 is rightmost bit).			*/
#define	getbit(c,i) (c >> i & ~(~0 << 1))

/************************************************************************/
/*  unpack_int_24:							*/
/*	Unpack int_24 miniSEED data and place in supplied buffer.	*/
/************************************************************************/
int
unpack_int_24 (ibuf, nbytes, num_samples, req_samples, databuff, 
	       p_errmsg)
    unsigned char *ibuf;	/* ptr to input data.			*/
    int		nbytes;		/* number of bytes in all data frames.	*/
    int		num_samples;	/* number of data samples in all frames.*/
    int		req_samples;	/* number of data desired by caller.	*/
    int		*databuff;	/* ptr to unpacked data array.		*/
    char	**p_errmsg;	/* ptr to ptr to error message.		*/
{
    U_DIFF	tmp;
    int		*data = databuff;
    int		nd = 0;		/* # of data points in packet.		*/
    int		nr, last_data, i;
    static char	errmsg[256];

    if (req_samples < num_samples) return (-1);
    if (req_samples < 0 || num_samples <= 0) return (-1);

    /* Copy data from input to output buffer.				*/
    /* Ensure sign bit of input value is properly extended.		*/
    for (nd=0; nd<req_samples; nd++) {
	memcpy (&tmp.byte[1], ibuf, 3);
	/* Propogate sign bit.						*/
	tmp.byte[0] = (getbit(tmp.byte[1],7)) ? 0xff : 0x00;
	databuff[nd] = tmp.fw;
	ibuf += 3;
    }

    return (nd);
}

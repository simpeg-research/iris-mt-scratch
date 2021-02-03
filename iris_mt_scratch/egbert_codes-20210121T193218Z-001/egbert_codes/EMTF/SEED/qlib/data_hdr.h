/*  Internal data header used to store info in easy-to-access manner.	*/
/*	@(#)data_hdr.h	1.2 5/24/96 15:44:13	*/

#ifndef	__data_hdr_h
#define	__data_hdr_h

#define	DH_STATION_LEN	7
#define	DH_CHANNEL_LEN	3
#define	DH_LOCATION_LEN	2
#define DH_NETWORK_LEN	2

#include "timedef.h"
#include "datatypes.h"

typedef struct _bs {			/* blockette structure.		*/
    char	*pb;			/* ptr to actual blockette.	*/
    int		len;			/* length of blockette in bytes.*/
    struct _bs	*next;			/* ptr to next blockette struct.*/
} BS;

/*                                                                      */
/************************************************************************/
typedef struct	data_hdr {
    int		seq_no;			/* sequence number		*/
    char	station_id[DH_STATION_LEN+1];	/* station name		*/
    char	location_id[DH_LOCATION_LEN+1];	/* location id		*/
    char	channel_id[DH_CHANNEL_LEN+1];	/* channel name		*/
    char	network_id[DH_NETWORK_LEN+1];	/* network id		*/
    INT_TIME	begtime;		/* begin time with corrections	*/
    INT_TIME	endtime;		/* end time of packet		*/
    INT_TIME	hdrtime;		/* begin time in hdr		*/
    int		num_samples;		/* number of samples		*/
    int		num_data_frames;	/* number of data frames	*/
    int		sample_rate;		/* sample rate			*/
    unsigned char activity_flags;	/* activity flags		*/
    unsigned char io_flags;		/* i/o flags			*/
    unsigned char data_quality_flags;	/* data quality flags		*/
    int		num_blockettes;		/* # of blockettes (0)		*/
    int		num_ticks_correction;	/* time correction in ticks	*/
    int		first_data;		/* offset to first data		*/
    int		first_blockette;	/* offset of first blockette	*/
    BS		*pblockettes;		/* ptr to blockette structures	*/
    int		data_type;		/* data_type (for logs or data)	*/
    int		x0;			/* first value (STEIM compress)	*/
    int		xn;			/* last value (STEIM compress)	*/
    int		extra[4];		/* future expansion.		*/
} DATA_HDR;

#endif

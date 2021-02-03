/*  Data types for SEED data records.					*/
/*	@(#)datatypes.h	1.2 1/26/96 11:10:33	*/

#ifndef	SEED_BIG_ENDIAN

/*  Define UNKNOWN datatype.		*/
#define	UNKNOWN_DATATYPE		0

/*  General datatype codes.		*/
#define	INT_16				1
#define	INT_24				2
#define	INT_32				3
#define	IEEE_FP_SP			4
#define IEEE_FP_DP			5

/*  FDSN Network codes.			*/
#define	STEIM1				10
#define	STEIM2				11
#define	GEOSCOPE_MULTIPLEX_24		12
#define	GEOSCOPE_MULTIPLEX_16_GR_3	13
#define	GEOSCOPE_MULTIPLEX_16_GR_4	14
#define	USNN				15
#define	CDSN				16
#define	GRAEFENBERG_16			17
#define	IPG_STRASBOURG_16		18

/*  Older Network codes.		*/
#define	SRO				30
#define	HGLP				31
#define	DWWSSN_GR			32
#define	RSTN_16_GR			33

/*  Definitions for blockette 1000	*/
#define SEED_LITTLE_ENDIAN		0
#define	SEED_BIG_ENDIAN			1

#define	IS_STEIM_COMP(n)    ((n==STEIM1 || n==STEIM2) ? 1 : 0)

#endif

/*  Steim compression information.					*/
/*	@(#)steim.h	1.2 5/24/96 15:44:22	*/

#ifndef	__steim_h
#define	__steim_h

typedef union u_diff {			/* union for steim 1 objects.	*/
    char	    byte[4];		/* 4 1-byte differences.	*/
    short	    hw[2];		/* 2 halfword differences.	*/
    int		    fw;			/* 1 fullword difference.	*/
} U_DIFF;

typedef struct frame {			/* frame in a seed data record.	*/
    unsigned int    ctrl;		/* control word for frame.	*/
    U_DIFF	    w[15];		/* compressed data.		*/
} FRAME;

#endif

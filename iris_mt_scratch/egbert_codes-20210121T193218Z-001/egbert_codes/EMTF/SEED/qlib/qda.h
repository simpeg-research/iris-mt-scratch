/*  Field definitions used in QDA data record headers.		*/
/*	@(#)qda.h	1.2 5/24/96 15:44:16	*/

#ifndef	__qda_h
#define	__qda_h

#define	SOH_INACCURATE		    0x80    /* inaccurate time tagging, in SOH  */
#define	SOH_GAP			    0x40    /* time gap detected, in SOH	*/
#define	SOH_EVENT_IN_PROGRESS	    0x20    /* record contains event data	*/
#define	SOH_BEGINNING_OF_EVENT	    0x10    /* record is first of event sequence	*/
#define	SOH_CAL_IN_PROGRESS	    0x08    /* record contains calibration data	*/
#define	SOH_EXTRANEOUS_TIMEMARKS    0x04    /* too many time marks received during this record*/
#define	SOH_EXTERNAL_TIMEMARK_TAG   0x02    /* record time-tagged at a mark    */
#define	SOH_RECEPTION_GOOD	    0x01    /* time reception is adequate   */

typedef struct _qda_time {
    char	year;
    char	month;
    char	day;
    char	hour;
    char	minute;
    char	second;
} QDA_TIME;

/*  Fixed QDA header	*/
typedef struct qda_hdr {	    /*	byte offset  */
    int		header_flag;		    /*  0   */
    char	frame_type;		    /*  4   */
    char	component;		    /*  5   */
    char	stream;			    /*	6   */
    char	soh;			    /*	7   */
    char	station_id[4];		    /*	8   */
    short	millisecond;		    /*	12  */
    short	time_mark;		    /*	14  */
    int		samp_1;			    /*	16  */
    short	clock_corr;		    /*	20  */
    short	num_samples;		    /*	22  */
    char	sample_rate;		    /*	24  */
    char	reserved;		    /*	25  */
    QDA_TIME	time;			    /*	36  */
    int		seq_no;			    /*	32  */
} QDA_HDR;

#endif

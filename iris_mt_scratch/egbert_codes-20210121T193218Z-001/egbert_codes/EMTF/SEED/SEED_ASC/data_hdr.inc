c Internal data header used to store info in easy-to-access manner.	*/
c @(#)data_hdr.inc	1.1 11/1/94 09:50:37

c
c Parameters for SEED data header data structures
c
	integer DH_STATION_LEN, DH_CHANNEL_LEN, DH_LOCATION_LEN, 
     1		DH_NETWORK_LEN
	parameter (	
     1		DH_STATION_LEN = 8,
     2		DH_CHANNEL_LEN = 4,
     3		DH_LOCATION_LEN	= 3,
     4		DH_NETWORK_LEN	= 3 )
c
	integer TICKS_PER_SEC, TICKS_PER_MSEC
	parameter (
     1		TICKS_PER_SEC = 10000,
     2		TICKS_PER_MSEC = (TICKS_PER_SEC/1000) )
c
c Date/Time data structure used for time calculations.
c
	structure /INT_TIME/
		integer year
		integer second
		integer ticks
	end structure
c
c Date/Time data structure used for external interface.
c
	structure /EXT_TIME/
		integer year
		integer doy
		integer month
		integer day
		integer hour
		integer minute
		integer second
		integer ticks
	end structure
c
c Data Header structure containing data from SEED Fixed Data Header
c WARNING - this assumes pointers take the same space as an integer.
c
	structure /DATA_HDR/
		integer seq_no
		character*(DH_STATION_LEN) station_id
		character*(DH_LOCATION_LEN) location_id
		character*(DH_CHANNEL_LEN) channel_id
		character*(DH_NETWORK_LEN) network_id
		record /INT_TIME/ begtime
		record /INT_TIME/ endtime
		record /INT_TIME/ hdrtime
		integer num_samples
		integer num_data_frames
		integer sample_rate
		character activity_flags
		character io_flags
		character data_quality_flags
		integer num_blockettes
		integer num_ficks_correction
		integer first_data
		integer first_blockette
		integer pblockettes
		integer data_type
		integer x0
		integer xn
		integer extra(4)
	end structure

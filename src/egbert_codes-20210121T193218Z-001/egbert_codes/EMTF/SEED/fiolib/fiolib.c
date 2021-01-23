/* fiolib.c  C-style file I/O routines for FORTRAN */

#include <stdio.h>

/*
 * EXAMPLE:
 *
 *	integer fd
 *	real data(1024)
 *	integer n
 *	integer iopen, iread, iclose
 *
 *	fd = iopen('waveform.dat', 0, 0)
 *	if ( fd .lt. 0 ) then
 *	   call perror('opening data file')
 *	   call exit(1)
 *	endif
 *	n = iread(fd, data, 1024*4)
 *	if ( n .lt. 0 ) then
 *	   call perror('reading data file')
 *	   call exit(1)
 *	endif
 *	if ( n .ne. 1024 * 4 ) then
 *	   print *, 'not enough data in file'
 *	   call exit(1)
 *	endif
 *	if ( iclose(fd) .ne. 0 ) then
 *	   call perror('closing data file')
 *	   call exit(1)
 *	endif
 *	...
 */

/*
 *	fd = iopen(path, flags, mode)
 *	integer*4 fd		! file descriptor (negative for error)
 *	character*(*) path	! file name
 *	integer*4 flags		! 'open' flags (see /usr/include/sys/fcntl.h)
 *	integer*4 mode		! eg. '660'O
 */

int
iopen_(path, flags, mode, pathlen)
char *path;
int *flags;
int *mode;
int pathlen;
{
	char cpath[1024];
	int len;
	int i;

	len = pathlen;
	while ( (len > 0) && (path[len-1] == ' ') )
		len--;
	if ( len >= 1024 ) {
		fprintf(stderr, "iopen: path too long (%d)\n", len);
		fflush(stderr);
		return(-1);
	}
	bcopy(path, cpath, len);
	cpath[len] = 0;
	i = open(cpath, *flags, *mode);
	return(i);
}


/*
 *	n = iread(fd, buf, bytes)
 *	integer*4 n		! number of bytes actually read (neg for error)
 *	integer*4 fd		! file descriptor (from iopen)
 *	any kind of array or variable	! data buffer
 *	integer*4 bytes		! number of bytes to read
 */

int
iread_(fd, buf, bytes)
int *fd;
char *buf;
int *bytes;
{
	int i;
	i = read(*fd, buf, *bytes);
	return(i);
}


/*
 *	n = iwrite(fd, buf, bytes)
 *	integer*4 n		! number of bytes actually written (neg for error)
 *	integer*4 fd		! file descriptor (from iopen)
 *	any kind of array or variable	! data buffer
 *	integer*4 bytes		! number of bytes to write
 */

int
iwrite_(fd, buf, bytes)
int *fd;
char *buf;
int *bytes;
{
	return(write(*fd, buf, *bytes));
}


/*
 *	pos = lseek(fd, offset, whence)
 *	integer*4 pos		! new file position (neg for error)
 *	integer*4 fd		! file descriptor (from iopen)
 *	integer*4 offset	! see man page for lseek
 *	integer*4 whence	! ditto
 */

int
lseek_(fd, offset, whence)
int *fd;
int *offset;
int *whence;
{
	return(lseek(*fd, *offset, *whence));
}


/*
 *	code = iclose(fd)
 *	integer*4 code		! 0 => success; -1 => failure
 *	integer*4 fd		! file descriptor (from iopen)
 */

int
iclose_(fd)
int *fd;
{
	return(close(*fd));
}

/************************************************************************/

/* ffiolib.c  C-style buffered file I/O routines for FORTRAN */

#include <stdio.h>

/*
 * EXAMPLE:
 *
 *	integer fp
 *	real data(1024)
 *	integer n
 *	integer iopen, iread, iclose
 *
 *	fp = ifopen('waveform.dat', 'r')
 *	if ( fp .eq. 0 ) then
 *	   call perror('opening data file')
 *	   call exit(1)
 *	endif
 *	i = 1
 * C    Loop reading until we get all that we want.
 *	nread = 0
 *	left = 1024
 * 100	n = ifread(data, 4, left, fp)
 *	if ( n .le. 0 ) then
 *	   call perror('reading data file')
 *	   call exit(1)
 *	endif
 *	left = left - n
 *	if (left .gt. 0 .and. n .gt. 0) goto 100
 *	if (left .gt. 0) then
 *	    call perror ('not enough data in data file')
 *	    call exit(1)
 *	endif
 *	if ( ifclose(fp) .ne. 0 ) then
 *	   call perror('closing data file')
 *	   call exit(1)
 *	endif
 *	...
 */

/*
 *	fp = ifopen(path, type)
 *	integer*4 fp		! file pointer (0 (NULL) for error)
 *	character*(*) path	! file name
 *	character*(*) type	! file type ("r", "w", ...)
 */

int
ifopen_(path, type, pathlen, typelen)
char *path;
char *type;
int pathlen;
int typelen;
{
	char cpath[1024];
	char ctype[4];
	int len;
	int i;
	FILE *fp;

	len = pathlen;
	while ( (len > 0) && (path[len-1] == ' ') )
		len--;
	if ( len >= 1024 ) {
		fprintf(stderr, "ifopen: path too long (%d)\n", len);
		fflush(stderr);
		return(-1);
	}
	bcopy(path, cpath, len);
	cpath[len] = 0;
	len = typelen;
	while ( (len > 0) && (type[len-1] == ' ') )
		len--;
	if ( len >= 4 ) {
		fprintf(stderr, "ifopen: type too long (%d)\n", len);
		fflush(stderr);
		return(-1);
	}
	bcopy(type, ctype, len);
	ctype[len] = 0;
	fp = fopen(cpath, ctype);
	return((int)fp);
}


/*
 *	n = ifread(buf, size, nelem, fp)
 *	any kind of array or variable	! data buffer
 *	integer*4 size		! size of element in bytes
 *	integer*4 nelem		! number of elements to read
 *	integer*4 fp		! file pointer (from ifopen)
 */

int
ifread_(buf, size, nelem, fp)
char *buf;
int *size;
int *nelem;
FILE **fp;
{
	int i;
	i = fread(buf, *size, *nelem, *fp);
	return(i);
}


/*
 *	n = ifwrite(buf, size, nelem, fp)
 *	any kind of array or variable	! data buffer
 *	integer*4 size		! size of element in bytes
 *	integer*4 nelem		! number of elements to write
 *	integer*4 fp		! file pointer (from ifopen)
 */

int
ifwrite_(buf, size, nelem, fp)
char *buf;
int *size;
int *nelem;
FILE **fp;
{
	int i;
	i = fwrite(buf, *size, *nelem, *fp);
	return(i);
}


/*
 *	resule = ifseek(fp, offset, whence)
 *	integer*4 result	! 0 for OK, -1 for error
 *	integer*4 fp		! file pointer (from ifopen)
 *	integer*4 offset	! see man page (3s) for fseek
 *	integer*4 whence	! ditto
 */

int
ifseek_(fp, offset, whence)
int *fp;
int *offset;
int *whence;
{
	return(fseek(*fp, *offset, *whence));
}


/*
 *	code = ifflush(fp)
 *	integer*4 code		! 0 => success; -1 => failure
 *	integer*4 fp		! file pointer (from ifopen)
 */

int
ifflush_(fp)
int *fp;
{
	return(fflush(*fp));
}


/*
 *	code = ifclose(fp)
 *	integer*4 code		! 0 => success; -1 => failure
 *	integer*4 fp		! file pointer (from ifopen)
 */

int
ifclose_(fp)
int *fp;
{
	return(fclose(*fp));
}

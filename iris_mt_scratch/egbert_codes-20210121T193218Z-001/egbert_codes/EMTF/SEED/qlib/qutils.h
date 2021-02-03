/*  Routines in qutils.c					*/
/*	@(#)qutils.h	1.3 5/24/96 15:44:19	*/

#ifndef	__qutils_h
#define	__qutils_h

#ifdef	__cplusplus
extern "C" {
#endif

void	seed_to_comp (char *, char **, char **);
void	comp_to_seed (char *, char *, char **);
char	*charncpy (char *, char *, int);
char	*trim (char *);
int	allnull (char *, int);
int	roundoff (double);
int	xread  (int, char *, int);
int	xwrite (int, char *, int);
void	cstr_to_fstr (char *, int);
int	date_fmt_num (char *);

#ifdef	__cplusplus
}
#endif

#endif

# Makefile for fiolib.a

LIBDIR = /usr/local/lib
MANDIR = /usr/local/man
MANEXT = 3

TARGET = libfio.a

CFLAGS = -g

${TARGET} : fiolib.o
	ar cr ${TARGET} fiolib.o
	ranlib ${TARGET}

install :
	cp -p ${TARGET} ${LIBDIR}/${TARGET}
	cp fiolib.man ${MANDIR}/man${MANEXT}/fiolib.${MANEXT}

DIR=fiolib
tar:
	(cd ..; tar cf - $(DIR)/*.c $(DIR)/Makefile \
		$(DIR)/*.man $(DIR)/$(TARGET)) \
		| compress > /tmp/$(DIR).tar.Z

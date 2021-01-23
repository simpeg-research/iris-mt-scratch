BIN_DIR= /home/ohm/data/egbert/HOL/bin

FC = f77
FFLAGS=  -L../qlib  -L../fiolib -g

SOURCED=	../../D/afcor.f ../../D/autocor.f ../../D/badrec.f \
		../../D/bdrcsu.f ../../D/ft_subs.f ../../D/chdec.f \
                ../../D/cldrft.f ../../D/cmove.f ../../D/dcfilt.f \
		../../D/dcimte.f ../../D/decset.f ../../D/demean.f \
                ../../D/dtrnd.f ../../D/fcorsu.f \
		../../D/filtcor.f ../../D/freqout.f ../../D/frstdif.f \
                ../../D/getsp.f ../../D/ltslv.f ../../D/mkset.f \
		../../D/ptdist.f ../../D/pterst.f ../../D/sort.f \
                ../../D/resptbl.f ../../D/inpu_bin.f ../../D/out_pack.f \
		../../D/mk_offst.f ../../D/phs_shft.f ../../D/inpu_asc.f \
		dnff_seed.f

OBJECTSD =	dnff_seed.o afcor.o autocor.o badrec.o  bdrcsu.o \
		ft_subs.o chdec.o cldrft.o cmove.o dcfilt.o dcimte.o \
		decset.o demean.o dtrnd.o fcorsu.o filtcor.o freqout.o \
		frstdif.o getsp.o ltslv.o mkset.o ptdist.o pterst.o sort.o \
		resptbl.o inpu_bin.o out_pack.o  mk_offst.o phs_shft.o \
		inpu_asc.o

SOURCE_SEED =  ../SEED_ASC/init_seed.f ../SEED_ASC/init_files.f ../SEED_ASC/rdblk_seed.f ../SEED_ASC/align_seed.f ../SEED_ASC/rec_num.f ../SEED_ASC/pshftsd.f

OBJECTS_SEED = ../SEED_ASC/init_seed.o ../SEED_ASC/init_files.f ../SEED_ASC/rdblk_seed.o ../SEED_ASC/align_seed.o ../SEED_ASC/rec_num.o ../SEED_ASC/pshftsd.o

INCLUDE =	../SEED_ASC/seed.inc ../qlib/data_hdr.inc \
		../../include/datsz.inc  ../../include/nchmx.inc\
		../../D/input.inc params1.inc \
		../../D/decimate.inc ../../D/iounits.inc ../../D/params2.inc

LIBRARIES = -lqlib -lfio

dnff_seed:	$(SOURCED) $(SOURCE_SEED) $(INCLUDE)
	$(FC) $(FFLAGS) -o dnff_seed $(SOURCED) $(SOURCE_SEED) $(LIBRARIES)

clean:
	rm *.o

install:
	\mv dnff_seed $(BIN_DIR)/.

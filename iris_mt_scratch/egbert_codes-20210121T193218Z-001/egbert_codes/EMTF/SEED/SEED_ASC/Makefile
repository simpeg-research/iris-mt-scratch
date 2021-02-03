FC = f77
FFLAGS = -u -g
BIN_DIR= $(HOME)/bin
LIBRARIES = -L../qlib -L../fiolib
seed_merge_asc:	seed_merge_asc.f seed.inc ../../include/nchmx.inc init_seed.f rdblk_seed.f wrt_time.f align_seed.f rec_num.f set_doy.f
	$(FC) $(FFLAGS) $(LIBRARIES) -o seed_merge_asc seed_merge_asc.f init_seed.f wrt_time.f rdblk_seed.f align_seed.f rec_num.f set_doy.f -lqlib -lfio 

install:
	\mv seed_merge_asc $(BIN_DIR)/.

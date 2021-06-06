"""
based on Gary's
TSTFTarray.m in
iris_mt_scratch/egbert_codes-20210121T193218Z-001/egbert_codes/matlabPrototype_10-13-20/TF/classes
"""
def consistent_headers(header1, header2):
    #do some checking
    return True

class TSTFTArray(object):
    """
    class to support creating FC arrays from STFT objects stored as mat files
    %   class to support creating FC arrays from STFT objects stored as mat files
    %      simplified -- not a subclass of TFC -- cannot be used for array
    %      processing without additional features/changes.  Just intended
    %      for SS and RR processing

    """
    def __init__(self):
        """
        ivar: ArrayInfo   % cell array containing list of STFT file names  (
        created  from tranmt.cfg + band setup file, array name
        ivar: array: % cell array containing all STFT objects
        ?STFTCollection()?
        ivar: FCdir =  root path for STFT files --
        EstimationBands % array of dimension (nBands, 3) giving decimation
        levels and band limits, as returned by function  ReadBScfg.
        ivar: Header % TArrayHeader object -- mostly just an array of site
        headers
        ivar: iBand % current band number
        ivar: OneBand % data for one band --  data for one band -- a TFC1Dec
        object, containing all FCs for all sites / runs for band iBand,
        merged and aligned
        ivar: T % period for center of  current band--could be dependent

        """
        self.array_info = None
        self.array = None
        self.FCdir = None
        self.estimation_bands = None
        self.header = None
        self.T


    @property
    def number_of_sites(self):
        return len(self.array)

    def number_of_bands(self):
        return len(self.estimation_bands)


    def initialize_from_config(self, tranmt_config_file, FCdir=None):
        if FCdir is not None:
            self.FCdir = FCdir
        self.array_info = ReadTranMTcfg(tranmt_config_file)

    def load_stft_arrays(self):
        """
        initialize and load all STFT objects - - for now no checks on consistency
        Note that the selection of what "runs" or FCFiles are going to be used
        is actually controlled by the
        Returns
        -------

        """
        self.array = cell(length(obj.ArrayInfo.Files), 1)
        #read in estimation bands
        self.EstimationBands = ReadBScfg(self.ArrayInfo.bandFile);
        #load all STFT files for all sites / runs
        SiteHeaders[self.number_of_sites] = TSiteHeader();
        for j in range(self.number_of_sites):
            nFCfiles = length(self.array_info.Files{j}.FCfiles);
            #this just creates an array of empty TSTFT objects of length
            # nFCfiles - - one for each run
            self.Array{j}(nFCfiles) = TSTFT();
            for k in range(nFCfiles):
                #full pathname of file to load
                cfile = [self.FCdir obj.ArrayInfo.Files{j}.FCfiles{k}];
                load(cfile, '-mat', 'FTobj')
                self.Array{j}(k) = FTobj;
                if k == 1:
                    SiteHeaders[j] = self.Array{j}(k).Header;
                else:
                    header_ok = consistent_headers(SiteHeaders[j],
                                                   self.Array{j}(k).Header)
                    if not header_ok:
                        print('Headers for two runs are not consistent')
        self.Header = TArrayHeader(self.ArrayInfo.ArrayName, SiteHeaders);
        # probably should carry a Header for this object;
        #Also should compare headers to make sure that runs for a given site are
        #consistent, and that sites are consistent
        #(use same Windows, start times, and also overlap in time?)


    def extractFCband(self, i_band, AllSites=None):
        """
        Usage: T = extractFCband(obj, ib);
        loads FCs for full array for frequency band ib into TSTFTarray object,
        storing in OneBand.
        Parameters
        ----------
        self
        i_band

        Returns: T - 1 / f_center where f_center is center frequency of band

        -------

        """
        self.iBand = ib; # could add some error checking
        band = self.estimation_bands[ib,:];
        AllSites = self.number_of_sites * [TFC1Dec()]
        for j in range(self.number_of_sites):
        #first extract TFC1Dec objects defined by band for one site
            nFCfiles = length(self.array[j]);
            AllRuns = nFCfiles * [TFC1Dec()]
            for k = range(nFCfiles):
                AllRuns[k] = self.array[j][k].FC(band[0]).extractBand(band[1:2])
                # make sure all objects have ordered segments,
                # complete block
                AllRuns(k).timeSort;
                AllRuns(k).reblock;
            # merge all runsfor site j
            AllSites[j] = AllRuns.mergeRuns;

        #merge all sites into a single TFC1Dec object
        self.OneBand = AllSites.mergeSites;
        # nominal period for estimation band: 1 / f_center
        T = 1. / mean(self.OneBand.freqs);
        return T

    def get_mt_tf_data(self, transfer_function_header):
        """
        Usage: [H,E] = obj.getMTTFdata(TFHD);
        [H,E,R] = obj.getMTTF(TFHD);
        extracts arrays needed for estimation of MT transfer functions:
        H(NSeg,2) == magnetic field FCs
        E(NSeg,Nch) = electric field (and optionally vertical magnetic) field
        FCs; E(:,1) is Hz if this is returned;
        R(NSeg,2) = reference fields for RR estimation (optional)
        TFHD is TFHeader object, whioch defines local and (optionally) remote
        sites, and channels at these sites that will be used for processing.
        TFHeader.ArrayHeader2TFHeader creates this header from TArrayHeader,
        using default assumptions about channels (i.e., use horizontal mags
        at local as input channels, at remote for reference, etc.

        Parameters
        ----------
        tfhd

        Returns
        -------

        """
        # find local site numbrt
        LocalInd = find(strcmp(transfer_function_header.LocalSite.SiteID,
                               self.Header.SiteIDs));
        Hind = transfer_function_header.ChIn + self.Header.ih(LocalInd)-1;
        Eind = transfer_function_header.ChOut + self.Header.ih(LocalInd)-1;
        H = self.OneBand.FC(Hind,:,:);
        [nch, nfc, nseg] = size(H);
        H = reshape(H, nch, nfc * nseg).';
        E = obj.OneBand.FC(Eind,:,:);
        [nch, nfc, nseg] = size(E);
        E = reshape(E, nch, nfc * nseg).';
        if strcmp(TFHD.Processing, 'RR'):
            #find reference site number if a character string is provide
            RemoteInd = find(strcmp(TFHD.RemoteSite.SiteID,
                                    self.Header.SiteIDs));
            Rind = transfer_function_header.ChRef + self.Header.ih(RemoteInd) -1
            R = self.OneBand.FC(Rind,:);
            [nch, nfc, nseg] = size(R);
            R = reshape(R, nch, nfc * nseg).';
        return H,E,R

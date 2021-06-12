"""
follows Gary's TFHeader.m
iris_mt_scratch/egbert_codes-20210121T193218Z-001/egbert_codes/matlabPrototype_10-13-20/TF/classes
"""

#Questions for Gary:
#
class TransferFunctionHeader(object):
    """
    class for storing metadata for a TF estimate
    """

    def __init__(self):
        """
        Parameters
        ivar: local_site: Station header (metadata object) for local site
        (location, channel_azimuths, etc.)
        ivar: remote_site: same object type as local site
        ivar: output_channels: these are the channels being fit by the input
        channels, sometimes called the "predicted" channels.
        This is a channel list -- usually [ex,ey,hz]
        ivar: input_channels: these are the channels being provided as
        input to the regression.  Sometimes called the "predictor" channels.
        This is a channel list -- usually [hx,hy]
        ivar: reference_channels: these are the channels being used
        from the RR station. This is a channel list -- usually [?, ?]
        ivar: processing_scheme:
        string, "single station", "remote reference", "multivariate array",
         "multiple remote", etc.

        """
        self.processing_scheme = None
        self.local_site = None
        self.input_channels = []
        self.output_channels = None
        self.reference_channels = None
        self.remote_site = None
        self.user_meta_data = None #placeholder for anythin

    @property
    def num_input_channels(self):
        return len(self.input_channels)

    @property
    def num_output_channels(self):
        return len(self.output_channels)


    def array_header_to_tf_header(self, array_header, sites):
        """
        This will likely be made from MTH5.  The overarching point of this
        Methods is to review the available processing 
        %   Usage: obj = ArrayHeader2TFHeader(obj,ArrayHD, OPTIONS)
            %        given an input TArrayHeader,
            %   and SITES, a structure defining:
            %          RR    -- true for RR processing, otherwise SS
            %          LocalSite   -- site ID or number for local site
            %          RemoteSite  -- site ID or number for Reference site
            %          VTF     --  true if Vertical Field TF should also be estimated
            %
            %          Could add more if we want to generalize to other
            %          estimation schemes
            %    this always uses horizontal magnetics for ChIn and ChRef,
            %          electrics and Hz for ChOut -- could generalize

        Parameters
        ----------
        array_header
        sites

        Returns
        -------

        """
        #find local site number if a character string is provide
        if ischar(SITES.LocalSite):
            LocalInd = find(strcmp(SITES.LocalSite, ArrayHD.SiteIDs));
        else:
            LocalInd = SITES.LocalSite;
        end

        # find local magnetic and electric field channel numbers
        obj.LocalSite = ArrayHD.Sites(LocalInd);
        obj.ChIn =[];
        obj.ChOut =[];
        HZind =[];
        for ich = 1:obj.LocalSite.Nch:
            if isa(obj.LocalSite.Channels(ich), 'MagneticChannel'):
                if obj.LocalSite.Channels(ich).vertical:
                    HZind =[HZind; ich];
                else:
                    obj.ChIn =[obj.ChIn; ich];
            elif isa(obj.LocalSite.Channels(ich), 'ElectricChannel'):
                obj.ChOut =[obj.ChOut; ich]
            end
        end
        if self.num_input_channels != 2:
            print('did not find exactly 2 horizontal magnetic channels for '
                 'local site')

        if SITES.VTF:
            if isempty(HZind):
                print('no vertical magnetic channel found for local site')
            elif length(HZind) > 1:
                print('more than one vertical magnetic channel found for local '
                  'site')
            else
                obj.ChOut =[HZind;obj.ChOut];

        if SITES.RR:
            self.processing_scheme = 'RR'
            #find refertence site number if a character string is provide
            if ischar(SITES.RemoteSite):
                ReferenceInd = find(strcmp(SITES.RemoteSite, obj.Header.SiteIDs));
            else:
                ReferenceInd = SITES.RemoteSite;
            end
            # extract reference channels --  here we assume these are always
            # magnetic (the normal approach), but this code could easily be
            # modified to allow more general reference channels
            obj.RemoteSite = ArrayHD.Sites(ReferenceInd);
            obj.ChRef =[];
            for channel in RemoteSite.channels::
                if channel.is_mangetic & not channel.is_vertical:
                    obj.ChRef = [obj.ChRef; ich];
            if length(obj.ChRef) != 2:
                print('did not find exactly 2 horizontal magnetic channels '
                      'for reference site')
        else:
            self.processing_scheme = 'SS';

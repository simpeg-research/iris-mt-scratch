"""
follows Gary's TTFestBand in
iris_mt_scratch/egbert_codes-20210121T193218Z-001/egbert_codes/matlabPrototype_10-13-20/TF/classes


TODO: Make this class Extend TRME
"""
import numpy as np
from iter_control import IterContol

class TFBandEstimator(object):
    """
    This is a simple but general robust transfer function esimation class:
    Robust estimation of transfer functions between NchIn input channels and
    NchOut output channels.  A reference(NChIN channels) can be provided as
    input, as can a set of weights for each segment x output channel.

    All arrays can have NaNs, to indicate missing data

    The main thing that this does is manage several types of weights, namely:
    segment weights (as for example leverage downweitghting) same for all
    output channels; there is a routine here for computing these "edf weights"
    as in tranmt) and weights which are channel dependent(but also depend on
    segments). These would for instance be calculate from broadband coherence
    between X and Y.

    This method also worries about masking nans in X, Y, R
    """

    def __init__(self, X, Y, R=None, weights=None):
        """
        Parameters:
        X : numpy array
            (Nseg, NchIn) design matrix (input channels)
        Y : numpy array
            (Nseg, NchOut) predicted (output) channels
        R : numpy array
            (Nseg, NchIn) matrix of reference variables NchIn by default = 2
            as we are doing MT / quasi - uniform sources
        segment_weights : numpy array (num_segments)
            called WtSeg in Matlab codes.  Weights for segments
            (e.g., edf, coherence of X / R)
        channel_weights : numpy array (num_segments, num_output_channels)
            called WtCh in Matlab codes.  These are like segment weights but
            we allow for variable values in each channel.
            (eg coh of X / Y)
        iter_control : IterControl() object
            manages convergence criteria and (currently) regression-M estimator
            params. See doc in transfer_function.iter_control.IterControl()
            TODO: Factor Regression M-Estimate params into own module
        RegrEst : object of class TRegression.RegressionEstimator()
            Normally TRME, but could be another scheme
            Contains the final iterative estimate
        SSorRR : str
            specifies if Regression estiamtion will use a remote reference or not
            ["SS", "RR"]
        EDFparam : ????
            strucure containing parameters used to control leverage
            downweighting
        weights : numpy_array
            If this is 1-dimensional it is interpretted as being segment
            weights.  If it is 2-dimensional it is interpretted as being the
            channel weights.
            TODO: Deprecate this, rather accept a kwarg for segment_weights
            and a separate kwarg for channel_weights

        DERIVED PROPERTIES
        num_output_channels: int
            usually 1, 2, or 3
        num_segments : int
            how many FFT-ed segments are in X, Y, R


        obj = TTFestBand(X, Y, R, wt)
        """
        self.X = X
        self.Y = Y
        self.R = R
        self.weights = weights
        self.segment_weights = None
        self.channel_weigths = None
        self.weight_type = None #["channel", "segment", "both"]
        self.SSorRR = None
        self.xyr_are_valid()
        self.weights_are_valid()
        self.iter_control = IterControl()
        self.iter_control.maximum_number_of_iterations = 50;
        self.iter_control.redescend = False
        self.iter_control.r0 = 1.5
        #these are default EDF weights used in tranmt
        self.EDFparam = {"edfl1": 10, "alpha":.5, "c1": 2.0, "c2": 10.0}
        #TODO Make an EDFparm object?
        return

    @property
    def num_segments(self):
        return self.X.shape[0]

    @property
    def num_input_channels(self):
        return self.X.shape[1]

    @property
    def num_output_channels(self):
        """Usually 1,2 or 3"""
        return self.Y.shape[1]

    @property
    def xyr_are_valid(self):
        """
        Sanity check on sizes of X, Y, R.
        Karl has already coded these methods in TRegression.
        Returns
        -------

        """
        if self.num_segments != self.Y.shape[0]
            print('TTFestBand: number of segments in X and Y must be equal')
            raise Exception
        if self.R is not None:
            if self.num_segments != self.R.shape[0]:
                print('TTFestBand: R must be same size as X');
                raise Exception
            self.SSorRR = "RR"
        else:
            self.SSorRR = "SS"
        return True

    @property
    def weights_are_valid(self):
        """I dont like this, lets be explicit about the weights when they
        are given, not deduce it from the data.  When the weights were being
        calcualted there was a scheme in mind.  That context should accompany them"""
        m, n = self.weights.shape
        if (m == self.num_segments) &  (n == 1):
            self.segment_weights = self.weights
            self.weight_type = "segment"
            # obj.WtSeg = wt;
            # obj.weights = 'Seg';
        elif (n != self.num_output_channels) | (m == self.num_segments):
            #cond1 = n != self.num_output_channels
            #cond2 = m == self.num_segments
            #if (cond1 | cond2):
            self.channel_weights = self.weights;
            self.weight_type = "channel"
        else:
            print('TTFestBand: WtCh must be same size as Y');
            raise Exception
        return True

    def valid_indices(self, XYR, dim=1):
        """
        Parameters
        ----------
        XYR : 2d numpy array, representing X, Y or R
        dim : int, the dimension along which to excute the "all" command
        This is normally 1, as we want to identify the rows that have nan,
        thus we do all(axis=columns)

        Returns
        -------

        """
        """
        TODO replace this with masked array module.
        For now follow Garys recipe.  We

        Returns
        -------

        """
        valid_indices = np.all(~np.isnan(XYR), dim)
        return valid_indices

    def estimate(self):
        """
        THere is a notion here of data that is going to be input to the
        regrssion, specifically X, Y, R.  Probably best to create a class
        method called "dropna" that unilaterally removes nans from whichever of
        X,Y,R are active.  This can be extended later for MMT.

        Could access these through a dcit called "self.regression_data" which
        is just a view on X,Y,R, MM
        Returns
        -------


        TODO: Use masked Arrays here
        Mask = nan_data and zero_weights
        """
        self.RegrEst = self.num_output_channels * [None]
        if self.SSorRR=="SS":

            #self.identify_zero_segment_weight_indices
            #self.dropna_and_drop_zero_weight_segments()
            #self.apply_weights_to_X_and_Y()
            #self.identify_nan_output_data_indices()

            #<IDENTIFY NAN-DATA & ZERO-WEIGHTS; REMOVE FROM ESTIMATOR INPUTS>
            #Remove Nans from Input to Estimator
            #eliminate all segments with any magnetics missing #?dropna here?
            valid_input_indices = self.valid_indices(self.X)
            #indX = all(~isnan(obj.X), 2); #boolean
            #assuming here that weights are never missing (unless something
            # else is)
            if self.weight_type in ["segment", "both"]:
                valid_input_indices = (self.segment_weights > 0) & valid_input_indices;
                Wtt = self.segment_weights[valid_input_indices];
            else:
                Wtt = np.ones(sum(valid_input_indices), 1);

            Xt = self.X[valid_input_indices,:];
            Yt = self.Y[valid_input_indices,:];
            # </IDENTIFY NAN-DATA & ZERO-WEIGHTS; REMOVE FROM ESTIMATOR INPUTS>

            # <APPLY SEGMENT WEIGHTS>
            for k in range(self.num_input_channels):
                Xt[:, k] *= Wtt
            for k in range(self.num_output_channels):
                Yt(:, k) *= Wtt
            # </APPLY SEGMENT WEIGHTS>

            # now process channel-by-channel, omitting all missing / bad
            # segments for that channel
            for i_channel in range(self.num_output_channels):
                #<HANDLE CHANNEL WEIGHTS>
                indY = ~isnan(Yt(:, i_channel));
                if self.weight in ["channel", "both"]:
                    channel_weights = self.channel_weights[valid_input_indices, i_channel]
                    indY = self.channel_weights[valid_input_indices, i_channel] & indY
                    channel_weights = channel_weights[indY];
                else:
                    channel_weights = np.ones(sum(indY), 1);

                # <HANDLE CHANNEL WEIGHTS>

                n = sum(indY);
                W = spdiags(channel_weights, 0, n, n);
                self.RegrEst[i_channel] = TRME(W * Xt[indY,:],
                                               W * Yt[indY,i_channel].T,
                                               self.iter_control);
                self.RegrEst[i_channel].Estimate;
        elif self.SSorRR == "RR":
            # eliminate all segments with any magnetics missing
            valid_input_indices = all(~isnan(obj.X), 2) & all(~isnan(obj.R), 2)
            if self.weight_type in ["segment", "both"]:
                valid_input_indices = (self.segment_weights > 0) & valid_input_indices;
                Wtt = self.segment_weights[valid_input_indices];
            else:
                Wtt = np.ones(sum(valid_input_indices), 1);

            Xt = self.X[valid_input_indices,:];
            Yt = self.Y[valid_input_indices,:];
            Rt = self.R[valid_input_indices,:];

            # <APPLY SEGMENT WEIGHTS>
            for k in range(self.num_input_channels):
                Xt[:, k] *= Wtt
                Rt[:, k] *= Wtt
            for k in range(self.num_output_channels):
                Yt(:, k) *= Wtt
            # </APPLY SEGMENT WEIGHTS>
            # now process channel-by-channel, omitting all missing / bad
            # segments for that channel

            for i_channel in range(self.num_output_channels):
                #<HANDLE CHANNEL WEIGHTS>
                indY = ~isnan(Yt(:, i_channel));
                if self.weight in ["channel", "both"]:
                    channel_weights = self.channel_weights[valid_input_indices, i_channel]
                    indY = self.channel_weights[valid_input_indices, i_channel] & indY
                    channel_weights = channel_weights[indY];
                else:
                    channel_weights = np.ones(sum(indY), 1);

                # <HANDLE CHANNEL WEIGHTS>

                n = sum(indY);
                W = spdiags(channel_weights, 0, n, n);
                self.RegrEst{i_channel} = TRME_RR(W * Xt[indY,:],
                                                  W * Yt[indY, i_channel].T,
                                                  W * Rt(indY,:),
                                                  self.iter_control);
                self.RegrEst{i_channel}.Estimate;

                ...

    def edfwts(self):
        """
        Updates the segment weights.
        "Effective_degrees_of_freedom_weights"
        emulates edfwts() from tranmt

        b: its the "input channel data" nan-masked
        dimension 2 x n_points
        p1 = c1* n_points**alpha
        p2 = c2* n_points**alpha

        indX: indices_of_non_nan_inputs
        Returns
        -------

        """
        if (self.num_input_channels != 2):
            print('edfwts only works for 2 input channels')
            raise Exception

        indX = all(~isnan(obj.X), 2);
        npts = sum(indX);
        b = self.X(indX,:);
        if self.weight_type in ["segment", "both"]:
            for k = range(self.num_input_channels):
                b[:, k] = b[:, k].*self.segment_weights[indX];
        elif self.weight_type == "channel":
            #initialize for segment weights if not already in use
            self.segment_weights = np.ones(self.num_segments)
            obj.weight_type = 'both';
        else:
            #no weights yet
            self.segment_weights = np.ones(self.num_segments)
            self.weight_type = 'segment';

        b = b.T;

        p1 = npts ** self.EDFparam.alpha;
        p2 = self.EDFparam.c2 * p1;
        p1 = self.EDFparam.c1 * p1;

        # determine initial robust B-field cross-power matrix
        n_use = npts;
        n_omit = n_use;
        use = ones(npts, 1);
        use = logical(use); %  # ok<LOGL>
        while n_omit > 0:
            bTb = b(:, use)*b(:, use).T/n_use;
            h = inv(bTb);
            #edf = real(b(1,:).*conj(b(1,:))*h(1, 1) + b(2,:).*conj(b(2,
            # :)).*h(2,2) + 2 * real(conj(b(2,:)).*b(1,:)*h(2, 1)));
            cross_power_term = 2 * np.real(np.conj(b[1,:]).*b[0,:]*h[1, 0])
            bx_term = h[0, 0] * np.abs(b[0,:]) ** 2
            by_term = h[1, 1] * np.abs(b[1,:]) ** 2
            edf = bx_term + by_term + cross_power_term;
            edf = np.real(edf)
            use = edf <= self.EDFparam.edfl1;
            n_omit = nuse - sum(use);
            n_use = sum(use);

        wt = np.ones(npts);
        wt(edf > p2) = 0;
        ind = (edf <= p2) & (edf > p1);
        wt[ind] = np.sqrt(p1. / edf[ind]);
        self.segment_weights[indX] = self.segment_weights[indX] .* wt;

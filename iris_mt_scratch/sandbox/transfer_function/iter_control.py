"""
follows Gary's IterControl.m in
iris_mt_scratch/egbert_codes-20210121T193218Z-001/egbert_codes/matlabPrototype_10-13-20/TF/classes


Questions for Gary:
1. why does this class need arguments in pairs?
seems to be because it wants maximum_number_of_iterations and tolerance
"""
import numpy as np

class IterControl(object):
    """

    """

    def __init__(self):
        """

        """
        self._number_of_iterations = 0; #private variable, wont show up in
                                        #tab completion.
                                        #Internal to codebase and should not
                                        #be relied upon in functons by users.
        self.max_number_of_iterations = 10; #0 for OLS
        self.tolerance = 0.005
        self.epsilon = 1000

        #<regression-M estimator params>
        #separate block/class, etc.
        self.r0 = 1.5   #infinty for OLS
        #L2 norm between 0 and 1.5 stderr
        #L1 norm above r0 (large residuals)
        self.redescend = False
        self.number_of_redescending_iterations = 0
        self.max_number_of_redescending_iterations = 1 #2 at most is fine
        self.u0 = 2.8 #what is it?
        # u0 is a parameter for the redescending
        #some double exponential formula and u0 controlls it
        # it makes for severe downweigthing about u0
        # its a continuous function so its "math friendly"
        #and you can prove theroems about it etc.
        # </regression-M estimator params>


        #<Additional properties>
        # #sed sometimes to control one or another of the iterative algorithms
        self.return_covariance = False
        self.save_cleaned = False
        self.robust_diagonalize = False
        # </Additional properties>


    def converged(self, b, b0):
        """
        TODO: add some feedback to user, i.e. if convergence achieved then tell
        us why: max_number_of_iterations reached or  max_change less than or
        eqaul to tolerance

        I think Gary was returning this:
        notConverged = (maxChng > ITER.tolerance) & ...
        (ITER.niter < ITER.iterMax);

        Parameters
        ----------
        b
        b0

        Returns
        -------

        """

        converged = False
        b *= 1.0 #float
        maximum_change = np.max(np.abs(1 - b/b0))
        cond1 = maximum_change > self.tolerance
        cond2 = self.number_of_iterations < self.max_number_of_iterations

        if cond1 & cond2:
            converged = False
        else:
            converged = True

        return converged


    def redescend_maxxed_out(self):
        pass
        #   if self.number_of_redescending_iterations >


    @property
    def correction_factor(self):
        """
        TODO: Note that IterControl itself should probably be factored.
        A base class can be responsible for iteration_watcher and convergence checks
        etc.  But u0, and r0 are specific to the Robust methods.

        In the regression esimtate you downweight things with large errors, but
        you need to define what's large.  You estimate the standard devation
        (sigma) of the errors from the residuals BUT with this cleaned data
        approach (Yc) sigma is smaller than it should be, you need to
        compensate for this by using a correction_factor. It's basically the
        expectation, if the data really were Gaussian, and you estimated from
        the corrected data. This is how much too small the estiamte would be.

        If you change the penalty functional you may need a pencil, paper and
        some calculus.  The relationship between the corrected-data-residuals
        and the gaussin residauls could change if you change the penalty
        Returns float
        -------

        """
        cfac = 1. / (2 * (1. - (1. + self.r0) * np.exp(-self.r0)))
        return cfac
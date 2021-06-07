"""
follows Gary's IterControl.m in
iris_mt_scratch/egbert_codes-20210121T193218Z-001/egbert_codes/matlabPrototype_10-13-20/TF/classes


Questions for Gary:
1. why does this class need arguments in pairs?
seems to be because it wants maximum_number_of_iterations and tolerance
""""

class IterControl(object):

    def __init__(self):
        self.number_of_iterations = 0;
        self.maximum_number_of_iterations = 10;
        self.tolerance = 0.005
        self.epsilon = 1000

        #<regression-M estimator params>
        #separate block/class, etc.
        self.r0 = 1.5
        self.redescend = False
        self.number_of_redescending_iterations = 0
        self.maximum_number_of_redescending_iterations = 1
        self.u0 = 2.8 #what is it?
        # </regression-M estimator params>


        #<Additional properties>
        # #sed sometimes to control one or another of the iterative algorithms
        self.return_covariance = True
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
        maximum_change = max(abs(1 - b/b0))
        cond1 = maximum_change > self.tolerance
        cond2 = self.number_of_iterations < self.maximum_number_of_iterations

        if cond1 & cond2:
            converged = False
        else:
            converged = True

        return converged


    def redescend_maxxed_out(self):
        pass
        #   if self.number_of_redescending_iterations >

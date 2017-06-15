# ECoGFeatureSelection

The project addresses the problem of feature selection in regression models in application to ECoG-based motion decoding. The task is to predict hand trajectories from the voltage time series of cortical activity. Feature description of a each point resides in spatial-temporal-frequency domain and include the voltage time series themselves and their spectral characteristics. Feature selection is crucial for adequate solution of this regression problem, since electrocorticographic data is highly dimensional and the measurements are correlated both in time and space domains.

We propose a multi-way formulation of quadratic programming feature selection (QPFS), a recent approach to filtering-based feature selection proposed by Katrutsa and Strijov, ``Comprehensive study of feature selection methods to solve multicollinearity problem according to evaluation criteria''.

## Files arrangement:
* 'code' - MATLAB code for reproducing results from the paper
* 'doc' - .pdf files with description of the proposed method
* 'data' - experometal data for processing
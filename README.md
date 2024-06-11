# Session_cleaning

------------------------------------------- README -------------------------------------------

-------- The data cleaning framework for session milk yield records on conventional milking systems --------

-------- Citation: Multi-strategy optimization of data cleaning for large-scale session milk yield records on conventional milking systems (In the process of submission)

-------- Install and load packages
1. quantreg: Koenker R (2023). quantreg: Quantile Regression. R package version 5.97

2. isotree: Cortes D (2023). isotree: Isolation-Based Outlier Detection. R package version 0.5.24-3

3. dplyr: Wickham H, Fran?ois R, Henry L, Müller K, Vaughan D (2023). dplyr: A Grammar of Data Manipulation. R package version 1.1.4

4. imputeTS: Moritz, S., Bartz-Beielstein, T., 2017. ImputeTS: time series missing value imputation in R. The R Journal. 9(1), 207.

5. reshape2: Hadley Wickham (2007). Reshaping Data with the reshape Package. Journal of Statistical Software, 21(12), 1-20.

-------- Anomaly detection
1. Data preparation:
    Input variable: Cow ID; parity; Days in milk (DIM); Milk in morning session (kg); Milk in afternoon session (kg); Milk in evening session (kg)
    Colnames: ID/Parity/DIM/milk1/milk2/milk3
    
2. The code is for session milk yields recorded from 1-305d post-calving only, please see the manuscript for pre-quality control of the data.

3. Ensure that the ID in the first column is unique for each cow.

4. When session milk yield is a missing value, mark it as NA.

5. Usage: anomaly_detection(data, IQRn=1.5, iforestn=0.65)

6. Arguments:
    data: data to be detected (data frame)
    IQRn: the threshold in the IQR method, which defaults to 1.5 (range of values: >0)
    iforestn: the threshold in the isolated forest, which defaults to 0.65 (range of values: 0-1)

7. Key parameters that may need to be modified:
    Parameters in the function "isolation.forest" (Rows 41, 48, 55 in Functions in anomaly detection.R)

8. Result: same format as input data.

9. Save your raw data in a safe space or have another copy!!!


-------- Imputation of missing data
1. Data preparation:
    Input variable: Cow ID; parity; Days in milk (DIM); Milk in morning session (kg); Milk in afternoon session (kg); Milk in evening session (kg)
    Colnames: ID/Parity/DIM/milk1/milk2/milk3

2. The code is for session milk yields recorded from 1-305d post-calving only, please see the manuscript for pre-quality control of the data.

3. Ensure that the ID in the first column is unique for each cow.

4. When session milk yield is a missing value, mark it as NA.

5. Please impute the data after removing anomalies.

6. Usage: missing_imputation(data, method=3, windown=10, refn=1000, num_used=20)

7. Arguments: 
    data: data to be imputed (data frame)
    method: method code, 1 = LWMA; 2 = reference population-based method (one step); 3 = reference population-based method (two step); default to 3
    windown: the window size of LWMA method, which defaults to 10 (range of values: >=1)
    refn: the number of lactations in the reference population, which defaults to 1000 (range of values: >1)
    num_used: the number of nearest lactations in the reference population used to impute the missing data, which defaults to 20 (range of values: >1)

8. Key parameters that may need to be modified:
    Parameters in the function "na_ma" (Row 28 in Functions in imputation.R)

9. Result: same format as input data.

10. The value of the parameter "refn" and the size of the number of lactations in the input data would be automatically compared, and the smaller value would be chosen as the size of the reference population. The parameter "num_used" needs to be smaller than this minimum value.

11. Please ensure that all sessions in the data to be imputed contain some true values when using Methods 2 or 3, especially for DIMs 1-5 and 300-305. When the number of lactations to be imputed is small, we recommend pre-calculating the number of lactations in the data to be imputed, using all lactations as a reference population, or using Method 1.

12. Save your raw data in a safe space or have another copy!!!

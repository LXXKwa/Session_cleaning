##### >>>>>>>>>>>>>> The data cleaning framework for session milk yield or daily milk yield records on conventional milking systems <<<<<<<<<<<<<<<<<<<<<

# -----------------------------------------------------------------------------------------------------------------------------------

##### For session milk yield records:
##### Input variable: Cow ID; parity; Days in milk (DIM); Milk in morning session (kg); Milk in afternoon session (kg); Milk in evening session (kg)
##### Colnames: ID/Parity/DIM/milk1/milk2/milk3

##### For daily milk yield records:
##### Input variable: Cow ID; parity; Days in milk (DIM); Daily milk yield (kg)
##### Colnames: ID/Parity/DIM/milk

##### The code is for session milk yields or daily milk yield recorded from 1-305d post-calving only, please see the manuscript for pre-quality control of the data
##### Please read 'READ ME' before analysis
##### Ensure that the ID in the first column is unique for each cow
##### When session milk yield or daily milk yield is a missing value, mark it as NA
##### If necessary, key parameters can be modified from the code to adapt to the population to be analyzed
##### Save your raw data in a safe space or have another copy!!!

##### Citation: Towards standardization and completeness of milk yield recording on conventional milking systems through multi-strategy optimization (In the process of submission)
# -----------------------------------------------------------------------------------------------------------------------------------

##### Install and load packages
pkg<-c('quantreg','isotree','dplyr','imputeTS','reshape2')
for (i in pkg){
  if (!requireNamespace(i,quietly = T)) install.packages(i)
}
lapply(pkg, library, character.only = T)
rm(list = ls());gc()
# -----------------------------------------------------------------

##### Anomaly detection and removal
setwd()
data<-read.csv()
source('Functions in anomaly detection.R')
colnames(data)<-c('ID','Par','DIM','milk1','milk2','milk3')

result<-anomaly_detection(data = data, session = 3, IQRn = 1.5, iforestn = 0.65, taun = 0.5)
    ##### data: data to be detected (data frame)
    ##### session: 1 = daily milk yield records; 3 = session milk yield records (default to 3);
    ##### IQRn: the threshold in the IQR method, which defaults to 1.5 (range of values: >0; recommend: 1.3-1.8)
    ##### iforestn: the threshold in the isolated forest, which defaults to 0.65 (range of values: 0-1; recommend: 0.55-0.65)
    ##### taun: the quantile settings in quantile regression, which defaults to 0.5 (range of values: 0-1; recommend: 0.4-0.7)
# ------------------------------------------------------------------

##### Imputation of missing data
setwd()
data<-read.csv()
source('Functions in imputation.R')
colnames(data)<-c('ID','Par','DIM','milk1','milk2','milk3')

result<-missing_imputation(data = data, session = 3, method = 3, windown = 10, refn = 1000, num_used = 20)
    ##### data: data to be imputed (data frame)
    ##### session: 1 = daily milk yield records; 3 = session milk yield records (default to 3);
    ##### method: method code, 1 = LWMA; 2 = reference population-based method (one step); 3 = reference population-based method (two step); default to 3
          ##### For daily milk yield records, the method 2 and 3 are the same
    ##### windown: the window size of LWMA method, which defaults to 10 (range of values: 1-305; recommend: 10-20)
    ##### refn: the number of lactations in the reference population, which defaults to 1000 (range of values: >1; Depends on the actual number of lactations)
    ##### num_used: the number of nearest lactations in the reference population used to impute the missing data, which defaults to 20 (range of values: >1)
# ------------------------------------------------------------------

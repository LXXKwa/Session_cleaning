##### >>>>>>>>>>>>>> The data cleaning framework for session milk yield records on conventional milking systems <<<<<<<<<<<<<<<<<<<<<

# -----------------------------------------------------------------------------------------------------------------------------------
##### Input variable: Cow ID; parity; Days in milk (DIM); Milk in morning session (kg); Milk in afternoon session (kg); Milk in evening session (kg)
##### Colnames: ID/Parity/DIM/milk1/milk2/milk3

##### The code is for session milk yields recorded from 1-305d post-calving only, please see the manuscript for pre-quality control of the data
##### Ensure that the ID in the first column is unique for each cow
##### When session milk yield is a missing value, mark it as NA
##### If necessary, key parameters can be modified from the code to adapt to the population to be analyzed
##### Save your raw data in a safe space or have another copy

##### Citation: Multi-strategy optimization of data cleaning for large-scale session milk yield records on conventional milking systems (In the process of submission)
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

result<-anomaly_detection(data = data,IQRn = 1.5,iforestn = 0.65)
    ##### data: data to be detected (data frame)
    ##### IQRn: the threshold in the IQR method, which defaults to 1.5 (range of values: >0)
    ##### iforestn: the threshold in the isolated forest, which defaults to 0.65 (range of values: 0-1)
# ------------------------------------------------------------------

##### Missing imputation
setwd()
data<-read.csv()
source('Functions in imputation.R')
colnames(data)<-c('ID','Par','DIM','milk1','milk2','milk3')

result<-missing_imputation(data = data, method = 3, windown = 10, refn = 1000, num_used=20)
    ##### data: data to be imputed (data frame)
    ##### method: method code, 1 = LWMA; 2 = reference population-based method (one step); 3 = reference population-based method (two step); default to 3
    ##### windown: the window size of LWMA method, which defaults to 10 (range of values: >=1)
    ##### refn: the number of lactations in the reference population, which defaults to 1000 (range of values: >1)
    ##### num_used: the number of nearest lactations in the reference population used to impute the missing data, which defaults to 20 (range of values: >1)
# ------------------------------------------------------------------

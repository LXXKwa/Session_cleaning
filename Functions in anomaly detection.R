##### >>>>>>>>>>>>>> The data cleaning framework for session milk yield records on conventional milking systems <<<<<<<<<<<<<<<<<<<<<

# -----------------------------------------------------------------------------------------------------------------------------------
##### The functions needed in anomaly detection and removal
##### Citation: Multi-strategy optimization of data cleaning for large-scale session milk yield records on conventional milking systems (In the process of submission)

##### The code is for session milk yields recorded from 1-305d post-calving only, please see the manuscript for pre-quality control of the data
##### Ensure that the ID in the first column is unique for each cow
##### When session milk yield is a missing value, mark it as NA
##### If necessary, key parameters can be modified from the code to adapt to the population to be analyzed
##### Save your raw data in a safe space or have another copy!!!
# -----------------------------------------------------------------------------------------------------------------------------------

##### The function used for Wood model
funwood<-function(a,b,c,t){
  y<-a*t^b*exp(-c*t)
  return(y)
}

##### The function used for anomaly detection and removal
anomaly_detection<-function(data,IQRn=1.5,iforestn=0.65){
  data$code<-paste0(data$ID,data$Par)
  ucode<-unique(data$code)
  result<-data.frame()
  pb <- txtProgressBar(style=3)
  for(i in 1:length(ucode)){
    dt<-subset(data,data$code==ucode[i])
    dt<-dt[order(dt$DIM),]
    dt$iqrmilk1<-ifelse(is.na(dt$milk1),apply(dt[,c(4:6)],1,function(x) max(x,na.rm=T)),dt$milk1)
    dt$iqrmilk2<-ifelse(is.na(dt$milk2),apply(dt[,c(4:6)],1,function(x) max(x,na.rm=T)),dt$milk2)
    dt$iqrmilk3<-ifelse(is.na(dt$milk3),apply(dt[,c(4:6)],1,function(x) max(x,na.rm=T)),dt$milk3)
    dt$iqrmilk<-apply(dt[,c(8:10)],1,sum)
    y<-dt$iqrmilk;tt<-dt$DIM
    model_quantile<-nlrq(y~funwood(a,b,c,t=tt),tau=0.5,start=list(a=10,b=0.2,c=0.002)) 
    deviation_y<-y-predict(model_quantile)
    anomaly_daily<-as.data.frame(cbind(tt,deviation_y))
    anomaly_daily<-subset(anomaly_daily,anomaly_daily$deviation_y>=(quantile(deviation_y,0.75)+IQRn*(quantile(deviation_y,0.75)-quantile(deviation_y,0.25))))
    
    anomaly_morning<-dt[,c(3,8)]
    az<-as.matrix(anomaly_morning)
    iso<-isolation.forest(az,ntrees = 100)
    pred<-predict(iso,az)
    anomaly_morning<-cbind(anomaly_morning,pred)
    dt<-left_join(dt,anomaly_morning[,c(1,3)],by='DIM')
    
    anomaly_afternoon<-dt[,c(3,9)]
    az<-as.matrix(anomaly_afternoon)
    iso<-isolation.forest(az,ntrees = 100)
    pred<-predict(iso,az)
    anomaly_afternoon<-cbind(anomaly_afternoon,pred)
    dt<-left_join(dt,anomaly_afternoon[,c(1,3)],by='DIM')
    
    anomaly_evening<-dt[,c(3,10)]
    az<-as.matrix(anomaly_evening)
    iso<-isolation.forest(az,ntrees = 100)
    pred<-predict(iso,az)
    anomaly_evening<-cbind(anomaly_evening,pred)
    dt<-left_join(dt,anomaly_evening[,c(1,3)],by='DIM')
    
    colnames(dt)[c(12:14)]<-c('pred1','pred2','pred3')
    dt[which(dt$DIM%in%anomaly_daily$tt&dt$pred1>iforestn&dt$iqrmilk1>median(dt$iqrmilk1)),4]<-NA
    dt[which(dt$DIM%in%anomaly_daily$tt&dt$pred2>iforestn&dt$iqrmilk2>median(dt$iqrmilk2)),5]<-NA
    dt[which(dt$DIM%in%anomaly_daily$tt&dt$pred3>iforestn&dt$iqrmilk3>median(dt$iqrmilk3)),6]<-NA
    dt<-dt[,c(1:6)]
    
    result<-rbind(result,dt)
    setTxtProgressBar(pb, i/length(ucode))
  }
  data<-subset(result,!(is.na(result$milk1)&is.na(result$milk2)&is.na(result$milk3)))
  return(data)
}
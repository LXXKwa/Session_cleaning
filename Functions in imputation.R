##### >>>>>>>>>>>>>> The data cleaning framework for session milk yield or daily milk yield records on conventional milking systems <<<<<<<<<<<<<<<<<<<<<

# -----------------------------------------------------------------------------------------------------------------------------------
##### The functions needed in imputation of missing data

##### The code is for session milk yields or daily milk yield recorded from 1-305d post-calving only, please see the manuscript for pre-quality control of the data
##### Please read 'READ ME' before analysis
##### Ensure that the ID in the first column is unique for each cow
##### When session milk yield or daily milk yield is a missing value, mark it as NA
##### If necessary, key parameters can be modified from the code to adapt to the population to be analyzed
##### Save your raw data in a safe space or have another copy!!!

##### Citation: Improving accuracy and completeness of high-throughput milk yield records of dairy cattle in conventional milking systems through a multi-strategy framework (In review)
# -----------------------------------------------------------------------------------------------------------------------------------

missing_imputation<-function(data,session=3,method=3,windown=10,refn=1000,num_used=20){
  
  funwood<-function(a,b,c,t){
    y<-a*t^b*exp(-c*t)
    return(y)
  }  # The function used for Wood model
  
  optimize_model <- function(milk_col, data, windown, tt) {
    yy<-log(data[,milk_col])
    curwood<-lm(yy~tt+I(log(tt)))
    summarywood<-coef(curwood)
    premilk <- exp(summarywood[1]) * tt^summarywood[3] * exp(summarywood[2] * tt)
    res <- premilk - data[[milk_col]]
    res_ma <- na_ma(res, k = windown, weighting = "linear")
    milk <- ifelse(is.na(data[[milk_col]]), premilk - res_ma, data[[milk_col]])
    return(data.frame(DIM=c(1:305),premilk = premilk, res = res, milk = milk))
  }  # The functions used for LWMA
  
  data$code<-paste0(data$ID,data$Par)
  ucode<-unique(data$code)
  result<-data.frame()
  
  if(session==1){
    data<-subset(data,!is.na(data$milk))
    
    if(method==1){
      pb <- txtProgressBar(style=3)
      for(i in 1:length(ucode)){
        dt<-subset(data,data$code==ucode[i])
        dt<-dt[order(dt$DIM),]
        tt<-c(1:305)
        dt_all<-data.frame(DIM=c(1:305),n=c(1:305))
        dt_all<-left_join(dt_all,dt[,c(3:4)],by = 'DIM')
        dt_all<-left_join(dt_all,optimize_model('milk',dt_all,windown,tt),by = 'DIM')
        dt<-cbind(dt$ID[1],dt$Par[1],dt_all[,c(1,6)])
        colnames(dt)<-c('ID','Par','DIM','milk')
        result<-rbind(result,dt)
        setTxtProgressBar(pb, i/length(ucode))
      }
      n<-min(abs(result$milk))
      result[which(result$milk<0),4]<-n
    }
    
    if(method==2|method==3){
      
      refer_population2<-function(data,refn){
        num_refer<-as.data.frame(tapply(data$milk,data$code,length))
        num_refer<-as.data.frame(cbind(row.names(num_refer),num_refer))
        colnames(num_refer)<-c('code','Freq')
        num_refer<-num_refer[order(-num_refer$Freq),]
        refn<-min(refn,length(num_refer$code))
        refdata<-subset(data,data$code%in%num_refer$code[1:refn])
        refdata<-reshape2::dcast(refdata[,c(5,3,4)],code~DIM,value.var = 'milk')
        refdata$milk<-apply(refdata[,c(2:306)],1,function(x) mean(x,na.rm=T))
        refdata[,c(2:306)]<-refdata[,c(2:306)]/refdata$milk
        dmatrix<-refdata[,c(1:306)]
        row.names(dmatrix)<-dmatrix[,1]
        dmatrix<-dmatrix[,-1]
        return(dmatrix)
      }      # The functions used for reference population construction
      
      process_session2<- function(n, dmatrix20, dk,dt_matrix,num_used) {
        dmatrix20 <- as.matrix(dmatrix20[, c(dk$DIM)])
        dis<-(t(dmatrix20) - c(dt_matrix$milk.y.y)[c(dk$DIM)])^2
        distx20 <- sqrt(colSums(dis, na.rm = TRUE)/colSums(!is.na(dis))*nrow(dis))
        win52<-as.data.frame(cbind(row.names(dmatrix20),distx20))
        win52$distx20<-as.numeric(win52$distx20)
        win52<-win52[order(win52$distx20),]
        dmatrix20<-subset(dmatrix20,row.names(dmatrix20)%in%win52$V1[1:num_used])
        mean(dmatrix20[,which(colnames(dmatrix20)%in%n)])
      }      # The functions used for reference population-based method
      
      dmatrix<-refer_population2(data,refn = refn)
      result<-data.frame()
      pb <- txtProgressBar(style=3)
      for(i in 1:length(ucode)){
        dt<-subset(data,data$code==ucode[i])
        dt<-dt[order(dt$DIM),]
        dt1<-subset(dt,!is.na(dt$milk))
        tt<-c(1:305)
        dt_all<-data.frame(DIM=c(1:305),n=c(1:305))
        dt_all<-left_join(dt_all,dt[,c(3:4)],by = 'DIM')
        dt_all<-left_join(dt_all,optimize_model('milk',dt_all,windown,tt),by = 'DIM')
        dt<-as.data.frame(cbind(dt$ID[1],dt$Par[1],dt_all[,c(1,3)],dt$code[1],dt_all[,6]))
        colnames(dt)[c(1,2,5:6)]<-c('ID','Par','code','milk.y')
        dt[which(!dt$DIM%in%c(dt1$DIM[1]:dt1$DIM[length(dt1$DIM)])),6]<-NA
        if(is.na(dt$milk.y[1])|is.na(dt$milk.y[length(dt$milk.y)])){
          dtclass3<-subset(dt,is.na(dt$milk.y))
          dtclass3<-dtclass3[,c(3,6)]
          colnames(dtclass3)[2]<-'milk'
          nn<-mean(dt$milk.y,na.rm = T)
          dtt<-dt
          dtt$milk.y<-dtt$milk.y/nn
          dt_matrix<-left_join(dt_all,dtt[,c(3,6)],by='DIM')
          dtclass3$milk<-unlist(lapply(1:length(dtclass3$DIM), function(k) {
            n <- dtclass3$DIM[k]
            dttt<-subset(dtt,!(is.na(dtt$milk.y)&dtt$DIM!=dtclass3$DIM[k]))
            dk<-dttt[(c(which(dttt$DIM==n)-5):(which(dttt$DIM==n)+5))[which((c(which(dttt$DIM==n)-5):(which(dttt$DIM==n)+5))>0&((c(which(dttt$DIM==n)-5):(which(dttt$DIM==n)+5)))<=length(dttt$code))],]
            dmatrix20<-subset(dmatrix,!is.na(dmatrix[,dtclass3$DIM[k]]))
            process_session2(n, dmatrix20, dk,dt_matrix,num_used)
          }))
          dtclass3$milk<-dtclass3$milk*nn
          for(kk in 1:length(dtclass3$DIM)){
            dt[which(dt$DIM==dtclass3$DIM[kk]),4]<-dtclass3$milk[kk]
          }
        }
        dt<-dt[,c(1:4)]
        colnames(dt)[4]<-'milk'
        result<-rbind(result,dt)
        setTxtProgressBar(pb, i/length(ucode))
      }
      n1<-min(abs(result$milk))
      result[which(result$milk<0),4]<-n1
    }
  }
  
  if(session==2){
    data<-subset(data,!(is.na(data$milk1)&is.na(data$milk2)))
    
    if(method==1){
      pb <- txtProgressBar(style=3)
      for(i in 1:length(ucode)){
        dt<-subset(data,data$code==ucode[i])
        dt<-dt[order(dt$DIM),]
        tt<-c(1:305)
        dt_all<-data.frame(DIM=c(1:305),n=c(1:305))
        dt_all<-left_join(dt_all,dt[,c(3:5)],by = 'DIM')
        for (milk_col in c("milk1", "milk2")) {
          dt_all<-left_join(dt_all,optimize_model(milk_col,dt_all,windown,tt),by = 'DIM')
        }
        dt<-cbind(dt$ID[1],dt$Par[1],dt_all[,c(1,7,10)])
        colnames(dt)<-c('ID','Par','DIM','milk1','milk2')
        result<-rbind(result,dt)
        setTxtProgressBar(pb, i/length(ucode))
      }
      n1<-min(abs(result$milk1))
      n2<-min(abs(result$milk2))
      result[which(result$milk1<0),4]<-n1
      result[which(result$milk2<0),5]<-n2
    }
    
    if(method==2|method==3){
      
      refer_population<-function(data,refn){
        data$num_milk<-rowSums(!is.na(data[,c(4:5)]))
        num_refer<-as.data.frame(tapply(data$num_milk,data$code,sum))
        num_refer<-as.data.frame(cbind(row.names(num_refer),num_refer))
        colnames(num_refer)<-c('code','Freq')
        num_refer<-num_refer[order(-num_refer$Freq),]
        refn<-min(refn,length(num_refer$code))
        refdata<-subset(data,data$code%in%num_refer$code[1:refn])
        refdata1<-reshape2::dcast(refdata[,c(6,3,4)],code~DIM,value.var = 'milk1')
        refdata2<-reshape2::dcast(refdata[,c(6,3,5)],code~DIM,value.var = 'milk2')
        refdata1$milk<-apply(refdata1[,c(2:306)],1,function(x) mean(x,na.rm=T))
        refdata1[,c(2:306)]<-refdata1[,c(2:306)]/refdata1$milk
        refdata2$milk<-apply(refdata2[,c(2:306)],1,function(x) mean(x,na.rm=T))
        refdata2[,c(2:306)]<-refdata2[,c(2:306)]/refdata2$milk
        dmatrix<-cbind(refdata1[,c(1:306)],refdata2[,c(2:306)])
        row.names(dmatrix)<-dmatrix[,1]
        dmatrix<-dmatrix[,-1]
        return(dmatrix)
      }     # The functions used for reference population construction
      
      process_session <- function(n, session, dmatrix20, dk,dt_matrix,num_used) {
        dmatrix20 <- as.matrix(dmatrix20[, c(dk$DIM, dk$DIM + 305)])
        dis<-(t(dmatrix20) - c(dt_matrix$milk1.y, dt_matrix$milk2.y)[c(dk$DIM, dk$DIM + 305)])^2
        distx20 <- sqrt(colSums(dis, na.rm = TRUE)/colSums(!is.na(dis))*nrow(dis))
        win52<-as.data.frame(cbind(row.names(dmatrix20),distx20))
        win52$distx20<-as.numeric(win52$distx20)
        win52<-win52[order(win52$distx20),]
        dmatrix20<-subset(dmatrix20,row.names(dmatrix20)%in%win52$V1[1:num_used])
        mean(dmatrix20[,which(colnames(dmatrix20)%in%n)+length(dk$code)*(session-1)])
      }    # The functions used for reference population-based method
      
      if(method==3){
        dmatrix<-refer_population(data,refn = refn)
        result<-data.frame()
        pb <- txtProgressBar(style=3)
        for(i in 1:length(ucode)){
          dt<-subset(data,data$code==ucode[i])
          dt<-dt[order(dt$DIM),]
          dt1<-subset(dt,!is.na(dt$milk1))
          dt2<-subset(dt,!is.na(dt$milk2))
          tt<-c(1:305)
          dt_all<-data.frame(DIM=c(1:305),n=c(1:305))
          dt_all<-left_join(dt_all,dt[,c(3:5)],by = 'DIM')
          for (milk_col in c("milk1", "milk2")) {
            dt_all<-left_join(dt_all,optimize_model(milk_col,dt_all,windown,tt),by = 'DIM')
          }
          dt <- left_join(dt, dt_all[, c(1,7,10)], by = 'DIM')
          dt[which(!dt$DIM%in%c(dt1$DIM[1]:dt1$DIM[length(dt1$DIM)])),7]<-NA
          dt[which(!dt$DIM%in%c(dt2$DIM[1]:dt2$DIM[length(dt2$DIM)])),8]<-NA
          dt$s <- rowSums(!is.na(dt[,7:8]))
          colnames(dt)[7:8]<-c('milk1.y','milk2.y')
          if(dt$s[1]!=2|dt$s[length(dt$s)]!=2){
            dtclass3<-subset(dt,dt$s!=2)
            dtclass3<-melt(dtclass3[,c(3,7:8)],id='DIM')
            dtclass3<-subset(dtclass3,is.na(dtclass3$value))
            dtclass3$variable<-as.numeric(gsub("[^0-9]", "", dtclass3$variable))
            colnames(dtclass3)[2]<-'session'
            n1<-mean(dt$milk1,na.rm = T)
            n2<-mean(dt$milk2,na.rm = T)
            dtt<-dt
            dtt$milk1<-dtt$milk1/n1
            dtt$milk2<-dtt$milk2/n2
            dt_matrix<-left_join(dt_all,dtt[,c(3:5)],by='DIM')
            dtclass3$value<-unlist(lapply(1:length(dtclass3$DIM), function(k) {
              n <- dtclass3$DIM[k]
              dk<-dtt[(c(which(dtt$DIM==n)-5):(which(dtt$DIM==n)+5))[which((c(which(dtt$DIM==n)-5):(which(dtt$DIM==n)+5))>0&((c(which(dtt$DIM==n)-5):(which(dtt$DIM==n)+5)))<=length(dtt$code))],]
              dmatrix20<-subset(dmatrix,!is.na(dmatrix[,dtclass3$DIM[k]+305*(dtclass3$session[k]-1)]))
              process_session(n, dtclass3$session[k], dmatrix20, dk,dt_matrix,num_used)
            }))
            dtclass3$value<-ifelse(dtclass3$session==1,dtclass3$value*n1,dtclass3$value)
            dtclass3$value<-ifelse(dtclass3$session==2,dtclass3$value*n2,dtclass3$value)
            for(kk in 1:length(dtclass3$DIM)){
              dt[which(dt$DIM==dtclass3$DIM[kk]),dtclass3$session[kk]+6]<-dtclass3$value[kk]
            }
          }
          dt<-dt[,c(1:3,7:8,6)]
          colnames(dt)[c(4:5)]<-c('milk1','milk2')
          result<-rbind(result,dt)
          setTxtProgressBar(pb, i/length(ucode))
        }
        data<-result
      }
      
      dmatrix<-refer_population(data,refn = refn)
      result<-data.frame()
      pb <- txtProgressBar(style=3)
      for(i in 1:length(ucode)){
        dt<-subset(data,data$code==ucode[i])
        dt<-dt[order(dt$DIM),]
        dt1<-subset(dt,!is.na(dt$milk1))
        dt2<-subset(dt,!is.na(dt$milk2))
        tt<-c(1:305)
        dt_all<-data.frame(DIM=c(1:305),n=c(1:305))
        dt_all<-left_join(dt_all,dt[,c(3:5)],by = 'DIM')
        for (milk_col in c("milk1", "milk2")) {
          dt_all<-left_join(dt_all,optimize_model(milk_col,dt_all,windown,tt),by = 'DIM')
        }
        dt<-as.data.frame(cbind(dt$ID[1],dt$Par[1],dt_all[,c(1,3:4)],dt$code[1],dt_all[,c(7,10)]))
        colnames(dt)[c(1,2,6:8)]<-c('ID','Par','code','milk1.y','milk2.y')
        dt[which(!dt$DIM%in%c(dt1$DIM[1]:dt1$DIM[length(dt1$DIM)])),7]<-NA
        dt[which(!dt$DIM%in%c(dt2$DIM[1]:dt2$DIM[length(dt2$DIM)])),8]<-NA
        dt$s <- rowSums(!is.na(dt[,7:8]))
        if(dt$s[1]!=2|dt$s[length(dt$s)]!=2){
          dtclass3<-subset(dt,dt$s!=2)
          dtclass3<-melt(dtclass3[,c(3,7:8)],id='DIM')
          dtclass3<-subset(dtclass3,is.na(dtclass3$value))
          dtclass3$variable<-as.numeric(gsub("[^0-9]", "", dtclass3$variable))
          colnames(dtclass3)[2]<-'session'
          n1<-mean(dt$milk1,na.rm = T)
          n2<-mean(dt$milk2,na.rm = T)
          dtt<-dt
          dtt$milk1<-dtt$milk1/n1
          dtt$milk2<-dtt$milk2/n2
          dt_matrix<-left_join(dt_all,dtt[,c(3:5)],by='DIM')
          dtclass3$value<-unlist(lapply(1:length(dtclass3$DIM), function(k) {
            n <- dtclass3$DIM[k]
            dttt<-subset(dtt,!(dtt$s==0&dtt$DIM!=dtclass3$DIM[k]))
            dk<-dttt[(c(which(dttt$DIM==n)-5):(which(dttt$DIM==n)+5))[which((c(which(dttt$DIM==n)-5):(which(dttt$DIM==n)+5))>0&((c(which(dttt$DIM==n)-5):(which(dttt$DIM==n)+5)))<=length(dttt$code))],]
            dmatrix20<-subset(dmatrix,!is.na(dmatrix[,dtclass3$DIM[k]+305*(dtclass3$session[k]-1)]))
            process_session(n, dtclass3$session[k], dmatrix20, dk,dt_matrix,num_used)
          }))
          dtclass3$value<-ifelse(dtclass3$session==1,dtclass3$value*n1,dtclass3$value)
          dtclass3$value<-ifelse(dtclass3$session==2,dtclass3$value*n2,dtclass3$value)
          for(kk in 1:length(dtclass3$DIM)){
            dt[which(dt$DIM==dtclass3$DIM[kk]),dtclass3$session[kk]+6]<-dtclass3$value[kk]
          }
        }
        dt<-dt[,c(1:3,7:8,6)]
        colnames(dt)[c(4:5)]<-c('milk1','milk2')
        result<-rbind(result,dt)
        setTxtProgressBar(pb, i/length(ucode))
      }
      n1<-min(abs(result$milk1))
      n2<-min(abs(result$milk2))
      result[which(result$milk1<0),4]<-n1
      result[which(result$milk2<0),5]<-n2
      result<-result[,-6]
    }
  }
  
  if(session==3){
    data<-subset(data,!(is.na(data$milk1)&is.na(data$milk2)&is.na(data$milk3)))
    
    if(method==1){
      pb <- txtProgressBar(style=3)
      for(i in 1:length(ucode)){
        dt<-subset(data,data$code==ucode[i])
        dt<-dt[order(dt$DIM),]
        tt<-c(1:305)
        dt_all<-data.frame(DIM=c(1:305),n=c(1:305))
        dt_all<-left_join(dt_all,dt[,c(3:6)],by = 'DIM')
        for (milk_col in c("milk1", "milk2", "milk3")) {
          dt_all<-left_join(dt_all,optimize_model(milk_col,dt_all,windown,tt),by = 'DIM')
        }
        dt<-cbind(dt$ID[1],dt$Par[1],dt_all[,c(1,8,11,14)])
        colnames(dt)<-c('ID','Par','DIM','milk1','milk2','milk3')
        result<-rbind(result,dt)
        setTxtProgressBar(pb, i/length(ucode))
      }
      n1<-min(abs(result$milk1))
      n2<-min(abs(result$milk2))
      n3<-min(abs(result$milk3))
      result[which(result$milk1<0),4]<-n1
      result[which(result$milk2<0),5]<-n2
      result[which(result$milk3<0),6]<-n3
    }
    
    if(method==2|method==3){
      
      refer_population<-function(data,refn){
        data$num_milk<-rowSums(!is.na(data[,c(4:6)]))
        num_refer<-as.data.frame(tapply(data$num_milk,data$code,sum))
        num_refer<-as.data.frame(cbind(row.names(num_refer),num_refer))
        colnames(num_refer)<-c('code','Freq')
        num_refer<-num_refer[order(-num_refer$Freq),]
        refn<-min(refn,length(num_refer$code))
        refdata<-subset(data,data$code%in%num_refer$code[1:refn])
        refdata1<-reshape2::dcast(refdata[,c(7,3,4)],code~DIM,value.var = 'milk1')
        refdata2<-reshape2::dcast(refdata[,c(7,3,5)],code~DIM,value.var = 'milk2')
        refdata3<-reshape2::dcast(refdata[,c(7,3,6)],code~DIM,value.var = 'milk3')
        refdata1$milk<-apply(refdata1[,c(2:306)],1,function(x) mean(x,na.rm=T))
        refdata1[,c(2:306)]<-refdata1[,c(2:306)]/refdata1$milk
        refdata2$milk<-apply(refdata2[,c(2:306)],1,function(x) mean(x,na.rm=T))
        refdata2[,c(2:306)]<-refdata2[,c(2:306)]/refdata2$milk
        refdata3$milk<-apply(refdata3[,c(2:306)],1,function(x) mean(x,na.rm=T))
        refdata3[,c(2:306)]<-refdata3[,c(2:306)]/refdata3$milk
        dmatrix<-cbind(refdata1[,c(1:306)],refdata2[,c(2:306)],refdata3[,c(2:306)])
        row.names(dmatrix)<-dmatrix[,1]
        dmatrix<-dmatrix[,-1]
        return(dmatrix)
      }     # The functions used for reference population construction
      
      process_session <- function(n, session, dmatrix20, dk,dt_matrix,num_used) {
        dmatrix20 <- as.matrix(dmatrix20[, c(dk$DIM, dk$DIM + 305, dk$DIM + 610)])
        dis<-(t(dmatrix20) - c(dt_matrix$milk1.y, dt_matrix$milk2.y, dt_matrix$milk3.y)[c(dk$DIM, dk$DIM + 305, dk$DIM + 610)])^2
        distx20 <- sqrt(colSums(dis, na.rm = TRUE)/colSums(!is.na(dis))*nrow(dis))
        win52<-as.data.frame(cbind(row.names(dmatrix20),distx20))
        win52$distx20<-as.numeric(win52$distx20)
        win52<-win52[order(win52$distx20),]
        dmatrix20<-subset(dmatrix20,row.names(dmatrix20)%in%win52$V1[1:num_used])
        mean(dmatrix20[,which(colnames(dmatrix20)%in%n)+length(dk$code)*(session-1)])
      }    # The functions used for reference population-based method
      
      if(method==3){
        dmatrix<-refer_population(data,refn = refn)
        result<-data.frame()
        pb <- txtProgressBar(style=3)
        for(i in 1:length(ucode)){
          dt<-subset(data,data$code==ucode[i])
          dt<-dt[order(dt$DIM),]
          dt1<-subset(dt,!is.na(dt$milk1))
          dt2<-subset(dt,!is.na(dt$milk2))
          dt3<-subset(dt,!is.na(dt$milk3))  
          tt<-c(1:305)
          dt_all<-data.frame(DIM=c(1:305),n=c(1:305))
          dt_all<-left_join(dt_all,dt[,c(3:6)],by = 'DIM')
          for (milk_col in c("milk1", "milk2", "milk3")) {
            dt_all<-left_join(dt_all,optimize_model(milk_col,dt_all,windown,tt),by = 'DIM')
          }
          dt <- left_join(dt, dt_all[, c(1,8,11,14)], by = 'DIM')
          dt[which(!dt$DIM%in%c(dt1$DIM[1]:dt1$DIM[length(dt1$DIM)])),8]<-NA
          dt[which(!dt$DIM%in%c(dt2$DIM[1]:dt2$DIM[length(dt2$DIM)])),9]<-NA
          dt[which(!dt$DIM%in%c(dt3$DIM[1]:dt3$DIM[length(dt3$DIM)])),10]<-NA
          dt$s <- rowSums(!is.na(dt[,8:10]))
          colnames(dt)[8:10]<-c('milk1.y','milk2.y','milk3.y')
          if(dt$s[1]!=3|dt$s[length(dt$s)]!=3){
            dtclass3<-subset(dt,dt$s!=3)
            dtclass3<-melt(dtclass3[,c(3,8:10)],id='DIM')
            dtclass3<-subset(dtclass3,is.na(dtclass3$value))
            dtclass3$variable<-as.numeric(gsub("[^0-9]", "", dtclass3$variable))
            colnames(dtclass3)[2]<-'session'
            n1<-mean(dt$milk1,na.rm = T)
            n2<-mean(dt$milk2,na.rm = T)
            n3<-mean(dt$milk3,na.rm = T)
            dtt<-dt
            dtt$milk1<-dtt$milk1/n1
            dtt$milk2<-dtt$milk2/n2
            dtt$milk3<-dtt$milk3/n3
            dt_matrix<-left_join(dt_all,dtt[,c(3:6)],by='DIM')
            dtclass3$value<-unlist(lapply(1:length(dtclass3$DIM), function(k) {
              n <- dtclass3$DIM[k]
              dk<-dtt[(c(which(dtt$DIM==n)-5):(which(dtt$DIM==n)+5))[which((c(which(dtt$DIM==n)-5):(which(dtt$DIM==n)+5))>0&((c(which(dtt$DIM==n)-5):(which(dtt$DIM==n)+5)))<=length(dtt$code))],]
              dmatrix20<-subset(dmatrix,!is.na(dmatrix[,dtclass3$DIM[k]+305*(dtclass3$session[k]-1)]))
              process_session(n, dtclass3$session[k], dmatrix20, dk,dt_matrix,num_used)
            }))
            dtclass3$value<-ifelse(dtclass3$session==1,dtclass3$value*n1,dtclass3$value)
            dtclass3$value<-ifelse(dtclass3$session==2,dtclass3$value*n2,dtclass3$value)
            dtclass3$value<-ifelse(dtclass3$session==3,dtclass3$value*n3,dtclass3$value)
            for(kk in 1:length(dtclass3$DIM)){
              dt[which(dt$DIM==dtclass3$DIM[kk]),dtclass3$session[kk]+7]<-dtclass3$value[kk]
            }
          }
          dt<-dt[,c(1:3,8:10,7)]
          colnames(dt)[c(4:6)]<-c('milk1','milk2','milk3')
          result<-rbind(result,dt)
          setTxtProgressBar(pb, i/length(ucode))
        }
        data<-result
      }
      
      dmatrix<-refer_population(data,refn = refn)
      result<-data.frame()
      pb <- txtProgressBar(style=3)
      for(i in 1:length(ucode)){
        dt<-subset(data,data$code==ucode[i])
        dt<-dt[order(dt$DIM),]
        dt1<-subset(dt,!is.na(dt$milk1))
        dt2<-subset(dt,!is.na(dt$milk2))
        dt3<-subset(dt,!is.na(dt$milk3))  
        tt<-c(1:305)
        dt_all<-data.frame(DIM=c(1:305),n=c(1:305))
        dt_all<-left_join(dt_all,dt[,c(3:6)],by = 'DIM')
        for (milk_col in c("milk1", "milk2", "milk3")) {
          dt_all<-left_join(dt_all,optimize_model(milk_col,dt_all,windown,tt),by = 'DIM')
        }
        dt<-as.data.frame(cbind(dt$ID[1],dt$Par[1],dt_all[,c(1,3:5)],dt$code[1],dt_all[,c(8,11,14)]))
        colnames(dt)[c(1,2,7:10)]<-c('ID','Par','code','milk1.y','milk2.y','milk3.y')
        dt[which(!dt$DIM%in%c(dt1$DIM[1]:dt1$DIM[length(dt1$DIM)])),8]<-NA
        dt[which(!dt$DIM%in%c(dt2$DIM[1]:dt2$DIM[length(dt2$DIM)])),9]<-NA
        dt[which(!dt$DIM%in%c(dt3$DIM[1]:dt3$DIM[length(dt3$DIM)])),10]<-NA
        dt$s <- rowSums(!is.na(dt[,8:10]))
        if(dt$s[1]!=3|dt$s[length(dt$s)]!=3){
          dtclass3<-subset(dt,dt$s!=3)
          dtclass3<-melt(dtclass3[,c(3,8:10)],id='DIM')
          dtclass3<-subset(dtclass3,is.na(dtclass3$value))
          dtclass3$variable<-as.numeric(gsub("[^0-9]", "", dtclass3$variable))
          colnames(dtclass3)[2]<-'session'
          n1<-mean(dt$milk1,na.rm = T)
          n2<-mean(dt$milk2,na.rm = T)
          n3<-mean(dt$milk3,na.rm = T)
          dtt<-dt
          dtt$milk1<-dtt$milk1/n1
          dtt$milk2<-dtt$milk2/n2
          dtt$milk3<-dtt$milk3/n3
          dt_matrix<-left_join(dt_all,dtt[,c(3:6)],by='DIM')
          dtclass3$value<-unlist(lapply(1:length(dtclass3$DIM), function(k) {
            n <- dtclass3$DIM[k]
            dttt<-subset(dtt,!(dtt$s==0&dtt$DIM!=dtclass3$DIM[k]))
            dk<-dttt[(c(which(dttt$DIM==n)-5):(which(dttt$DIM==n)+5))[which((c(which(dttt$DIM==n)-5):(which(dttt$DIM==n)+5))>0&((c(which(dttt$DIM==n)-5):(which(dttt$DIM==n)+5)))<=length(dttt$code))],]
            dmatrix20<-subset(dmatrix,!is.na(dmatrix[,dtclass3$DIM[k]+305*(dtclass3$session[k]-1)]))
            process_session(n, dtclass3$session[k], dmatrix20, dk,dt_matrix,num_used)
          }))
          dtclass3$value<-ifelse(dtclass3$session==1,dtclass3$value*n1,dtclass3$value)
          dtclass3$value<-ifelse(dtclass3$session==2,dtclass3$value*n2,dtclass3$value)
          dtclass3$value<-ifelse(dtclass3$session==3,dtclass3$value*n3,dtclass3$value)
          for(kk in 1:length(dtclass3$DIM)){
            dt[which(dt$DIM==dtclass3$DIM[kk]),dtclass3$session[kk]+7]<-dtclass3$value[kk]
          }
        }
        dt<-dt[,c(1:3,8:10,7)]
        colnames(dt)[c(4:6)]<-c('milk1','milk2','milk3')
        result<-rbind(result,dt)
        setTxtProgressBar(pb, i/length(ucode))
      }
      n1<-min(abs(result$milk1))
      n2<-min(abs(result$milk2))
      n3<-min(abs(result$milk3))
      result[which(result$milk1<0),4]<-n1
      result[which(result$milk2<0),5]<-n2
      result[which(result$milk3<0),6]<-n3
      result<-result[,-7]
    }
  }
  
  return(result)
}

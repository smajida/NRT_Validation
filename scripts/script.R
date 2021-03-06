# script.R
# Version 1.1
# Processing Tools
#
# Project: NRT_Compare
# By xjtang
# Created On: 5/27/2016
# Last Update: 8/1/2016
#
# Version 1.0 - 5/27/2016
#   Script created for analysing the reference dataset
#
# Updates of Version 1.1 - 7/1/2016
#   1.Added new function to analyse change dates.
#
# Updates of Version 1.2 - 8/1/2016
#   1.Bug fix.
#   2.Added new function to make plots of group events.
#   3.Optimized code.
#
# -------------------------------------------------------

# library
library(png)

# conf_mat
# create confusion matrix
conf_mat <- function(file,res,ref,output){
  
  # read table
  main <- read.table(file,sep=',',stringsAsFactors=F,header=T)
  
  # get data
  res_vec <- main[,res]
  ref_vec <- main[,ref]
  
  # initialize result
  res_class <- sort(unique(res_vec))
  ref_class <- sort(unique(ref_vec))
  r <- matrix(0,length(ref_class),length(res_class))
  
  # caculate matrix
  for(i in 1:length(res_vec)){
    r[ref_class==ref_vec[i],res_class==res_vec[i]] <- r[ref_class==ref_vec[i],res_class==res_vec[i]] + 1
  }
  rownames(r)=ref_class
  colnames(r)=res_class
  
  # export result
  write.table(r,output,sep=',',col.names=NA)
  
  # done
  
}

# sum_dates
# summarize date information
eFile <- 'I:/NRT/Analysis/Date/CSV/event_join.csv'
pFile <- 'I:/NRT/Analysis/Date/CSV/mc.csv'
oPath <- 'I:/NRT/Analysis/Date/CSV/mc/'
oFile <- 'I:/NRT/Analysis/Date/CSV/mc_result.csv'
sum_dates <-function(eventFile,pieceFile,outPath,outFile){
  
  # read input file
  events <- read.table(eventFile,sep=',',stringsAsFactors=F,header=T)
  pieces <- read.table(pieceFile,sep=',',stringsAsFactors=F,header=T)
  
  # initilize overall output file
  rall <- matrix(0,nrow(events),13)
  colnames(rall) <- c('PID','EAREA','DAREA','PROP','DLASTF','DFSTNF','DEXPD','DEVENT','DCLEAR','D25','D50','D75','LAG')
  
  # loop through all events
  for(i in 1:nrow(events)){
    
    # get information
    rall[i,'PID'] <- events[i,'PID']
    rall[i,'EAREA'] <- events[i,'AREA2']
    rall[i,'DLASTF'] <- events[i,'D_LAST_F']
    rall[i,'DFSTNF'] <- events[i,'D_FIRST_NF']
    rall[i,'DEXPD'] <- events[i,'D_EXPAND']
    rall[i,'DEVENT'] <- events[i,'D_EVENT']
    rall[i,'DCLEAR'] <- events[i,'D_CLEAR']
    event_pieces <- pieces[pieces[,'PID']==rall[i,'PID'],]
    if(max((event_pieces[,'DATE']>=2013000)&(event_pieces[,'DATE']<2016000))){
      event_dates <- sort(unique(event_pieces[(event_pieces[,'DATE']>=2013000)&(event_pieces[,'DATE']<2016000),'DATE']))
    }else{
      next  
    }
    
    # initialize results
    r <- matrix(0,length(event_dates),6)
    colnames(r) <- c('PID','EAREA','DATE','DAREA','CAREA','PROP')
    r[,'PID'] <- rall[i,'PID']
    r[,'EAREA'] <- rall[i,'EAREA']
    areasum <- 0
        
    # calculate areas and proportions
    for(j in 1:length(event_dates)){
      date_pieces <- event_pieces[event_pieces[,'DATE']==event_dates[j],]
      r[j,'DATE'] <- event_dates[j]
      r[j,'DAREA'] <- sum(date_pieces[,'PAREA'])
      areasum <- areasum+r[j,'DAREA']
      r[j,'CAREA'] <- areasum
      r[j,'PROP'] <- r[j,'CAREA']/rall[i,'EAREA']
      
      # update overall results
      if((rall[i,'D25']==0)&(r[j,'PROP']>=0.25)){
        rall[i,'D25'] <- r[j,'DATE']
      }
      if((rall[i,'D50']==0)&(r[j,'PROP']>=0.5)){
        rall[i,'D50'] <- r[j,'DATE']
      }
      if((rall[i,'D75']==0)&(r[j,'PROP']>=0.75)){
        rall[i,'D75'] <- r[j,'DATE']
      }
      
    }
    
    # update overall results
    rall[i,'DAREA'] <- r[nrow(r),'CAREA']
    rall[i,'PROP'] <- r[nrow(r),'PROP']
    if(rall[i,'DEVENT']==0){
      rall[i,'LAG'] <- sub_doy(rall[i,'D25'],rall[i,'DFSTNF'])
    }else{
      rall[i,'LAG'] <- sub_doy(rall[i,'D25'],rall[i,'DEVENT'])
    }
    
    # export result
    write.table(r,paste(outPath,'event_',rall[i,'PID'],'.csv',sep=''),sep=',',
                row.names=F,col.names=T)
  }
  
  # export overall results
  write.table(rall,outFile,sep=',',row.names=F,col.names=T)
  
  # done
  return(0)
  
}

# gen_plot
# generate plots for dates analysis
rPath <- 'I:/NRT/Analysis/Date/CSV/'
oPath2 <- 'I:/NRT/Analysis/Date/CSV/PNG/'
gen_plot <- function(eventFile,resultPath,outPath){
  
  # read event file
  events <- read.table(eventFile,sep=',',stringsAsFactors=F,header=T)
  
  # loop through all events
  for(i in 1:nrow(events)){
       
    # read input file
    totalfile <- 0 
    if(file.exists(paste(resultPath,'fu/event_',events[i,'PID'],'.csv',sep=''))){
      r1 <- read.table(paste(resultPath,'fu/event_',events[i,'PID'],'.csv',sep=''),sep=',',stringsAsFactors=F,header=T)
      totalfile <- totalfile+1
    }else{
      r1 <- matrix(0,2,2)
      colnames(r1) <- c('DATE','PROP')
    }
    if(file.exists(paste(resultPath,'mc/event_',events[i,'PID'],'.csv',sep=''))){
      r2 <- read.table(paste(resultPath,'mc/event_',events[i,'PID'],'.csv',sep=''),sep=',',stringsAsFactors=F,header=T)
      totalfile <- totalfile+1
    }else{
      r2 <- matrix(0,2,2)
      colnames(r2) <- c('DATE','PROP')
    }
    if(file.exists(paste(resultPath,'ti/event_',events[i,'PID'],'.csv',sep=''))){
      r3 <- read.table(paste(resultPath,'ti/event_',events[i,'PID'],'.csv',sep=''),sep=',',stringsAsFactors=F,header=T)
      totalfile <- totalfile+1
    }else{
      r3 <- matrix(0,2,2)
      colnames(r3) <- c('DATE','PROP')
    }
    if(totalfile==0){next}
    
    # initialize plot file
    png(file=paste(outPath,'event_',events[i,'PID'],'.png',sep=''),width=2000,height=1500,pointsize=20)
    cPar <- par(mfrow=c(3,1))
    
    # make plot
    x <- doy2dy(r1[,'DATE'])
    plot(x,r1[,'PROP'],type='p',col='black',pch=16,
         main='Fusion',ylab='Detect Ratio',xlab='Date of Detection',
         xlim=c(2013,2016),ylim=c(0,1),xaxt='n'
    )
    axis(1,at=c(2013,2014,2015,2016))
    if(events[i,'D_EVENT']>0){
      abline(v=doy2dy(events[i,'D_EVENT']),col='red')
    }else{
      abline(v=doy2dy(events[i,'D_FIRST_NF']),col='red')
    }
    if(events[i,'D_CLEAR']>0){
      abline(v=doy2dy(events[i,'D_CLEAR']),col='blue')
    }
    if(events[i,'D_EXPAND']>0){
      abline(v=doy2dy(events[i,'D_EXPAND']),col='green')
    }
    x <- doy2dy(r2[,'DATE'])
    plot(x,r2[,'PROP'],type='p',col='black',pch=16,
         main='MCCDC',ylab='Detect Ratio',xlab='Date of Detection',
         xlim=c(2013,2016),ylim=c(0,1),xaxt='n'
    )
    axis(1,at=c(2013,2014,2015,2016))
    if(events[i,'D_EVENT']>0){
      abline(v=doy2dy(events[i,'D_EVENT']),col='red')
    }else{
      abline(v=doy2dy(events[i,'D_FIRST_NF']),col='red')
    }
    if(events[i,'D_CLEAR']>0){
      abline(v=doy2dy(events[i,'D_CLEAR']),col='blue')
    }
    if(events[i,'D_EXPAND']>0){
      abline(v=doy2dy(events[i,'D_EXPAND']),col='green')
    }
    x <- doy2dy(r3[,'DATE'])
    plot(x,r3[,'PROP'],type='p',col='black',pch=16,
         main='Terra-i',ylab='Detect Ratio',xlab='Date of Detection',
         xlim=c(2013,2016),ylim=c(0,1),xaxt='n'
    )
    axis(1,at=c(2013,2014,2015,2016))
    if(events[i,'D_EVENT']>0){
      abline(v=doy2dy(events[i,'D_EVENT']),col='red')
    }else{
      abline(v=doy2dy(events[i,'D_FIRST_NF']),col='red')
    }
    if(events[i,'D_CLEAR']>0){
      abline(v=doy2dy(events[i,'D_CLEAR']),col='blue')
    }
    if(events[i,'D_EXPAND']>0){
      abline(v=doy2dy(events[i,'D_EXPAND']),col='green')
    }
    
    # close plot 
    dev.off()
  }
  
  # done
  return(0)
}

# grp_plot
# make plots with groups of events
dPath <- 'I:/NRT/Analysis/Date/CSV/'
oPath3 <- 'I:/NRT/Analysis/Date/CSV/group_plot/'
grp_plot <- function(d,dataPath,outPath){
  
  # initialize plot
  png(file=paste(outPath,'event_',events[i,'PID'],'.png',sep=''),width=2000,height=1500,pointsize=20)
  cPar <- par(mfrow=c(3,1))
  
  # loop through datasets
  for(i in 1:3){
    # loop through events
    for(j in 1:nrow(d)){
      # grab info
      pid <- d[j,'PID']
      baseDate <- min(d[j,'D_FIRST_NF'],d[j,'D_EVENT'])
      # read file
      if(i==1){
        eventFile <- paste(dataPath,'fu/event_',pid,'.png',sep='')
        e <- read.table(,sep=',',stringsAsFactors=F,header=T)
      }else if(i==2){
        eventFile <- paste(dataPath,'mc/event_',pid,'.png',sep='')
        e <- read.table(,sep=',',stringsAsFactors=F,header=T)
      }else{
        eventFile <- paste(dataPath,'ti/event_',pid,'.png',sep='')
        e <- read.table(,sep=',',stringsAsFactors=F,header=T)
      }
      
      
    }
  }
  
  # complete plot
  dev.off()
  
  # done
  return(0)
}

# substract doy
sub_doy <- function(x,y){
  return((floor(x/1000)-floor(y/1000))*365+((x-floor(x/1000)*1000)-(y-floor(y/1000)*1000)))
}

# doy to decimal year
doy2dy <- function(x){
  return(floor(x/1000)+(x-floor(x/1000)*1000)/365)
}

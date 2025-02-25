
#!/usr/bin/env Rscript --vanilla

if (!requireNamespace("dplyr", quietly = TRUE))
  install.packages("dplyr", repos = "http://cran.us.r-project.org")
if (!requireNamespace("openxlsx2", quietly = TRUE))
  install.packages("openxlsx2", repos = "http://cran.us.r-project.org")
if (!requireNamespace("utils", quietly = TRUE))
  install.packages("utils", repos = "http://cran.us.r-project.org")

library(openxlsx2)
library(dplyr)
library(utils)

collection <- function(){

  argu <- commandArgs(trailingOnly = T)
  workingPath <- argu[1]
  setwd("/home/yrc/ACMG_info_collect") #
  print(getwd())
  
compile <- openxlsx2::read_xlsx(tail(list.files(path = getwd(), 
                           pattern = "compile", full.names = T, recursive = T), 1), check.names = F)
cols <- colnames(compile)[which(colnames(compile)=="Chromosome"):which(colnames(compile)=="Protein")]
  
  if (file.exists(paste("ACMG_collection", gsub(".+/(\\d+.+)/$","\\1",workingPath),sep="_"))){
    Rlog <- paste("ACMG_collection", gsub(".+/(\\d+.+)/$","\\1",workingPath),sep="_")
    logrc <- read.table(Rlog)
    factors <- unique(logrc[,1]) 
    done_list <- logrc[logrc[,1] %in% tail(factors,1),] ; done_list <- done_list[,2]
    cat("Already done:", done_list,sep = "\n")
   } else {
    Rlog <- file(paste("ACMG_collection", gsub(".+/(\\d+.+)/$","\\1",workingPath),sep="_"))
  }

  sink(Rlog, append = T, type = c("output","message"),split = T)
  
  cat("\n")
  print(paste("Running time",Sys.time(),sep = ":"))
  
files <- list.files(path = workingPath, pattern = "merge.xlsx",recursive = T, full.names = T) %>% gsub(".+/(\\w{2}\\d{2}_\\d{3,4}_\\w+_merge).+","\\1",.) 

if (exists("done_list")){
  filename <- setdiff(files, done_list)
  if (length(filename)==0){ print("no new sample");sink();q(save = "no")}
} else {filename=files}

for (i in filename){
  
  files.csv <- write.csv(openxlsx2::read_xlsx(paste(workingPath,"Merge/",i,".xlsx",sep = "")),sprintf("%s.csv",i), row.names = F)
  cat(paste("\n","Sample:",i))
  wb <- read.csv(sprintf("%s.csv",i))
  
  add <- data.frame(matrix(ncol = 1)) ; colnames(add) <- names(compile)[2]
  ri <- wb %>% .[,cols] 
  ri[,c("Position")] <- as.character(ri[,c("Position")])
  
  same <- ri[ri[,c("Gene")] %in% compile[,c("Gene")] & ri[,c("Coding")] %in% compile[,c("Coding")],]
  same_c <- compile[compile[,c("Gene")] %in% ri[,c("Gene")] & compile[,c("Coding")] %in% ri[,c("Coding")],]
  cat("\n")
  if (nrow(same) > 0){
  same_list <- split(same_c, f=list(same_c$Gene,same_c$Coding), drop = T, sep=" ")
  new <-cbind(add,ri)
  for (j in rownames(same)) {
  variant <- which( names(same_list)==paste(same[j,]$Gene, same[j,]$Coding, sep = " ") ) 
    if (identical(variant, integer(0))){
    #print(paste("drop",same[j,]$Gene,same[j,]$Coding, sep = " "))
      variant= variant}
    if (length(variant)!=0){
    new[j,]$Suspect <- paste0(NULL,compile[rownames(same_list[[variant]]),]$Suspect, collapse ='|') 
    print(paste(i,":",same[j,]$Gene,", ",same[j,]$Coding,", ",new[j,]$Suspect, sep = ""))}}
  
  } else {print(paste(i,":","No variant has been reported before",sep = ""))}
  file.remove(paste(i,".csv",sep = ""))
  
  Sys.sleep(0.5)
  gc()
}
  sink()
}

collection()

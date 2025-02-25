#!/usr/bin/env Rscript --vanilla


if (!requireNamespace("dplyr", quietly = TRUE))
  install.packages("dplyr", repos = "http://cran.us.r-project.org")
if (!requireNamespace("tibble", quietly = TRUE))
  install.packages("tibble", repos = "http://cran.us.r-project.org")


suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tibble))

argu <- commandArgs(trailingOnly = T)

setwd(argu[1])# argu[1]
directory <- argu[2] #argu[2]
PC <- argu[3] #argu[3]
c <- argu[4] #argu[4]

cat(paste("\n","Current working directory : ",getwd(), sep = ""))
cat(paste("\n","Positive control : ",PC,sep = ""))
cat(paste("\n","Confidence : ",c,sep = ""))

options(scipen = 999)
standard <- read.delim("D6311_composition.txt") # 
standard_genus <- gsub("(.) .*[[:space:]]?","\\1",standard[[1]])
standard_species <- gsub(" subtilis", "",standard[[1]])

total <- read.delim(list.files(directory, pattern = "bracken_sorted.txt", full.name = T)) %>% select(matches("new_est_reads")) %>% sum()

final <- data.frame(matrix(ncol = 10, nrow = 1)) %>%
  `colnames<-`(gsub("[[:space:]]","_",standard$Species) %>% gsub("_subtillis", "",.)) %>%
  add_column(Confidence=paste(PC,c,sep = "_"), .before = "Listeria_monocytogenes")

species<- data.frame(matrix(ncol = 2, nrow = 0)) %>% `colnames<-`(.,c("name","new_est_reads"))


check <- function(x,y,z){
  
  file <-list.files(x,pattern = y, full.names = T)  ## x, y
  result <- read.delim(file) %>% head(-1) %>% 
           select(matches(c("name","new_est_reads")))
           
  sum_genus <<- result %>% add_column(Genus=paste(gsub("(.) .*[[:space:]]?","\\1",.$name)), .before = "new_est_reads") %>%
                group_by(Genus) %>% summarise(Sum = sum(as.numeric(new_est_reads))/total*100,.groups = 'drop') %>% arrange(desc(Sum)) %>% as.data.frame()
 
  species <<- rbind(species,result)

 SD <- standard %>% .[z,] #z
 SD_list <- SD$Species %>% gsub(" subtilis", "",.)
 SD_list_genus <- SD_list %>% gsub("(.) .*[[:space:]]?","\\1",.) %>% gsub("subtilis", "",.)

 j=0
 for (i in SD_list){
   j=j+1
   k= SD_list_genus[j]
 if (grepl(i, species[1])){
   row <- which(sum_genus[1]==k)
   ratio <- sum_genus[row,"Sum"]
   comp <- SD[j, "Composition_in_percent"]
   lowest <- SD[j, "Lowest_accepted_value"]
   highest <- SD[j, "Highest_accepted_value"]
   
     if ( ratio >= lowest & ratio <= highest){
      cat(paste("\nPASS!",SD_list[j],"was","detected","within","normal","range"))
      final[1, grep(k,colnames(final))] <<- paste("PASS",formatC(ratio-comp,digits = 4,format = "fg"), sep = "|")
     } else {
       cat(paste("\nNote!!!",SD_list[j],"was","detected","OUTSIDE","OF","normal","range"))
       final[1, grep(k,colnames(final))] <<- paste("OOR",formatC(ratio-comp,digits = 4,format = "fg"), sep = "|")}

 }else {cat(paste("\nWarning!!!",SD_list[j],"was","not","detected","!"))
        final[1, grep(k,colnames(final))] <<- paste("Undetected", formatC(as.numeric(SD[j, "Composition_in_percent"])*(-1),digits = 4,format = "fg"),sep = "|")}
 }
   
}

check(directory,"bacteria.txt",c(1:3,5:8,10))
check(directory,"fungi.txt",c(4,9))

species <- species %>% arrange(desc(as.numeric(new_est_reads)))

if (length(grep("Undetected",final[1,])) == 0){
  last_item <- as.character(standard[10,1]) 
} else if (length(grep("Undetected",final[1,])) == 1 & grepl("Undetected",final[1,11])){
  last_item <- as.character(standard[9,1])
} else {
  last_item <- colnames(final)[tail(grep("OOR|PASS",final[1,]),1)] %>% gsub("_"," ",.)
  final <- final %>% add_column(NOTE="Too_High_Confidence")}

detection=c()

for (i in c(2:11)){
  if (grepl("\\|",final[1,i])){
    cate <- unlist(strsplit(final[1,i],"\\|"))[1]
  } else {cat("Error while reading pathogen detection results !!! ")}
  detection <- append(detection,cate)
}

OOR_number <- c(unlist(gregexpr("OOR",detection, useBytes = F))) %>% .[.== 1] %>% sum()

if ( !("NOTE" %in% colnames(final)) & OOR_number >= 3 ){
  final<- final %>% add_column(NOTE="LikelyContamination")
} else if (!("NOTE" %in% colnames(final))) {final <- final %>% add_column(NOTE="None")}

unexpect <- c()
for (i in c(1:grep(last_item,species[[1]]))){
  if (!(grepl(paste(standard_genus,collapse = "|"),species[i,1]))){
    unexpect <- append(unexpect,i)
  }
} 


if (length(unexpect) > 0){
  final <- final %>% add_column(Unexpected=length(unexpect))
  }else if (length(unexpect) == 0){
  final <- final %>% add_column(Unexpected= 0) 
}


detection <- detection %>% gsub("PASS",1,.) %>% gsub("OOR",0,.) %>% gsub("Undetected",-1,.) %>% as.numeric() %>% matrix(.,nrow=1,ncol=10)
points <-matrix(c(rep(1,10)),nrow = 10)
QC_points <- as.numeric(detection %*% points)    

final <- final %>% add_column(QC=QC_points) %>% add_column(abs_deviation = sum(abs(as.numeric(gsub("[[:alpha:]]*\\|","",final[1,2:11])))) )

final$others_N <- as.integer(length(species[[1]][!grepl(paste(standard_genus,collapse = "|"),species[[1]])]))

filename <- final$Confidence

write.table(final,file = paste(filename,"_","QC",".txt",sep = ""), sep = "\t",row.names = F, quote = F)

if (file.exists(paste("Confidence_list",".txt",sep = ""))){
  write.table(final,file = paste("Confidence_","list",".txt",sep = ""), sep = "\t",row.names = F, append = T, col.names = F, quote = F)
}else {  write.table(final,file = paste("Confidence_","list",".txt",sep = ""), sep = "\t",row.names = F, append = T, col.names = T, quote = F)}

cat("\n")
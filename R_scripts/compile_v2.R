
compile <- function(X){
  setwd(X)
  library(openxlsx)
  library(tidyverse)
  library(data.table)
  
old.compile <- tail(list.files(path = "", 
                               pattern = "compile", full.names = T, recursive = T), 1) #old compile.xlsx path
complist <- read.xlsx(old.compile) %>% select(.,matches("SampleID")) %>% unique()

final=data.frame()
final=rbind(final,read.xlsx(old.compile))

for (i in complist[,1]){
  deleting <- list.files(path = getwd(), pattern = paste(i), full.names = T, recursive = T)
  file.remove(deleting)
}

excel.files <- list.files(path = getwd(), pattern = "Pa.xlsx",full.names = T, recursive = T)

joh <- read.xlsx(tail(fs::dir_ls(path = "", regexp = ""),1)) %>% subset(., Platform =="MGI_WES" & Result =="Positive") # import files from other collection

joh_gene <- joh %>% select(.,matches("Sample_ID|Panel$|Gene|coding_change|amino_acid_change|Pathogenicity")) %>% unique() %>% `row.names<-`(.,1:nrow(.))

same <- c()
for (i in 1:nrow(final)){
  same_list <- which(joh_gene$Gene == final[i, "Gene"] & joh_gene$coding_change == final[i,"Coding"])
  same <- append(same, same_list)  %>% unique()
  newest <- tail(which(joh_gene$Gene == final[i, "Gene"] & joh_gene$coding_change == final[i,"Coding"]),1)
  if (length(newest) > 0 & is.na(final[i, "Chromosome"]) & is.na(final[i, "Position"])){
    final[i, "SampleID"] <- paste(joh_gene[newest, "Sample_ID"],gsub("Hereditary Cancer","gTumor",joh_gene[newest, "Panel"], ignore.case = T),sep = "_")}
  }



dif <- joh_gene[-c(same),]

x <- nrow(dif)

update <- function(){

lists <- lapply(excel.files, function(x){openxlsx::read.xlsx(x,check.names =  F)})

filename <- gsub(".+/(\\w{2}\\d{2}_\\d{3,4}_\\w+)_.+","\\1",excel.files)

names(lists) <- c(filename)

trim.lists <- lapply(lists, function(x){x[,c(which(colnames(x)=="Suspect"|colnames(x)=="suspect"):which(colnames(x)=="PP4"),which(colnames(x)=="Chromosome"):which( colnames(x)=="Protein" ))]})

Ponly.list <- lapply(trim.lists, function(x){ data.table::setnames(x,1,str_to_title); x[!is.na(x[,1]),]})

Ponly.list_m <- lapply(Ponly.list, function(x){
  if (nrow(x) == 0) {
    x[nrow(x)+1,] = c("X", rep("NA", length(x)-1))
    return(x)
  } else {x=x}
})

sample <- as.list(names(Ponly.list_m))
library(data.table)
h=0
for (i in 1:length(Ponly.list_m)){
  h=h+1
  final.list <- cbind(SampleID = paste(sample[[i]]),Ponly.list_m[[h]])
  final <- rbind(final,final.list)
}
 return(final)
}

collect_joh <- function(x){
for (i in 1:x){
  final[nrow(final)+1,] <-c(paste(dif[i,"Sample_ID"],gsub("Hereditary Cancer","gTumor",dif[i,"Panel"], ignore.case = T),sep = "_"), 
                            paste(dif[i,"Pathogenicity"],"collected from Johnny",sep = "; "),rep(NA,21),dif[i,"Gene"],NA, dif[i,"coding_change"], dif[i,"amino_acid_change"])
  
}
  return(final)
}


if (length(excel.files)== 0 & nrow(dif) == 0) {
  try(stop(),silent = T);cat("no need to update")
} else if (length(excel.files) != 0 & nrow(dif) == 0){
   final <- update(); cat("Updated Pa infomation")
} else if (nrow(dif) != 0 & length(excel.files)== 0){
  final <- collect_joh(x); cat("Updated information from Johnny")
} else if (nrow(dif) != 0 & length(excel.files) != 0) {
  cat("\nUpdated information from Pa and Johnny")
  final <- update(); cat(paste("\nRows after updating Pa info",nrow(final),sep = ":"))
  final <- collect_joh(x); cat(paste("\nRows after updating Johnny's collection",nrow(final),sep = ":"))
} else { cat("ERROR !! Unable to update !") }
  
openxlsx::write.xlsx(final,paste("Pvariant_compile","_",format(Sys.time(),"%m%d%Y"),".xlsx",sep = ""))

}

compile("filedirectory")

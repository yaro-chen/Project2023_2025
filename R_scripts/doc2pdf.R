
pdfconv <- function(){
  
setwd("D:/Healthcare/")
library(doconv)
target="" # move files to the target destination

files <- setdiff(list.files(path = getwd(), pattern = ".docx",full.names = T,recursive = T),
                   list.files(path = file.path(getwd(),"old",fsep = "/"),pattern = ".docx",full.names = T,recursive = T))
print(files)

for (i in files){
  try(docx2pdf(input = i, output =  gsub("docx", "pdf", i)) )
  filename <- gsub(".+/(JB\\d+_\\d{3,4}_.+)\\.docx","\\1",i)

  dir <- gsub(".+/(JB\\d+_\\d{3,4})/.+HM.*","\\1",i)
  
  if(dir.exists(paste(target,dir,sep = ""))){cat("");print("Skip creating new folder")
  }else {dir.create(paste(target,dir,sep = ""));cat("\n");print(paste("Folder",dir,"was created",sep = " "))}
  
  if (file.exists(gsub("docx","pdf",i))){
    print(paste(filename,".docx"," was successfully converted",sep = ""))
    movingdoc <- list.files(path = gsub("(.+/).*$","\\1",i), pattern = ".docx|\\.pdf|HM.xlsx",full.names = F)
    for (j in movingdoc){
    if (file.exists(paste(target,dir,"/",j, sep = ""))){ cat(" ")
    }else{
    file.copy(from = paste(gsub("(.+/).*$","\\1",i),j,sep = ""), to = paste(target,dir,"/",j, sep = ""),overwrite = T )
    print(paste(j,"was copied to Teams",sep = " "))  }
      }
    
  } else { print(paste("Error while converting",filename, sep = " ")) }
  
  Sys.sleep(0.5)
  gc()
}


}

pdfconv()



#!/usr/bin/env Rscript --vanilla

if (!requireNamespace("dplyr", quietly = TRUE))
  install.packages("dplyr", repos = "http://cran.us.r-project.org")
if (!requireNamespace("seqinr", quietly = TRUE))
  install.packages("seqinr", repos = "http://cran.us.r-project.org")

library(seqinr)
library(dplyr)

setwd("/home/yrc/ncbi_datasets/AMR_gene_index")

argu <- commandArgs(trailingOnly = T)

file = argu[1]

gene <- file %>% gsub(".*/(.*)\\.fasta","\\1",.)

input <- read.fasta(file,as.string = T) 

test <-data.frame(matrix(ncol = 2,nrow = 0)) %>% `colnames<-`(.,c("ID","Seq"))

for (i in 1:length(input)){
  test[nrow(test)+1, ] <- c(attr(input[[i]], "Annot"),input[[i]][1])
}


uni_fa <- test %>% distinct(Seq,.keep_all = T) %>% .[order(.$ID),]

output <- do.call(rbind, lapply(seq(nrow(uni_fa)),function(i){t(uni_fa[i,])}))

write.table(output,file = paste(gene,"_uniq",".fasta",sep = ""),row.names = F,col.names = F, quote = F)

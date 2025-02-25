#!/usr/bin/env Rscript --vanilla

if (!requireNamespace("openxlsx2", quietly = TRUE))
  install.packages("openxlsx2", repos = "http://cran.us.r-project.org")
if (!requireNamespace("dplyr", quietly = TRUE))
  install.packages("dplyr", repos = "http://cran.us.r-project.org")

suppressPackageStartupMessages(library(openxlsx2))
suppressPackageStartupMessages(library(dplyr))

argu <- commandArgs(trailingOnly = T)

torun <- argu[1]

statistics <- function(){
  
workingpath <- argu[2]

input <- argu[3]

log <- argu[4]

setwd(workingpath)

sink(log, append = T, type = c("output","message"),split = T)

kingdom <- input %>% gsub("(^[[:alpha:]]+)_[[:alpha:]]+_*.*","\\1",.)

bmda <- read.delim(input) %>% mutate(across(everything(), ~ifelse(.=="", "N/A", as.character(.))))

genus <- as.data.frame(table(bmda$genome.genus)) %>% `colnames<-`(.,c("Genus", "Genome_number")) %>% arrange(desc(Genome_number))

sp <- as.data.frame(table(bmda$genome.species)) %>% `colnames<-`(.,c("Species", "Genome_number")) %>% arrange(desc(Genome_number))

host <- as.data.frame(table(bmda$genome.host_group)) %>% `colnames<-`(.,c("Host_group", "Genome_number")) %>% arrange(desc(Genome_number))

count_hg <- as.data.frame(table(bmda$genome.genus, bmda$genome.host_group)) %>% filter(., Freq !=0) %>% `colnames<-`(.,c("Genus", "Host","Genome_number")) %>% arrange(desc(Genome_number))

host_list <- split(bmda, f=bmda$genome.host_group)

final <- data.frame(matrix(ncol = 5,nrow = 0)) 

summary_list <- data.frame(Total_genome_number = nrow(bmda),
                           Total_genus_number= nrow(genus),
                           Total_species_number= nrow(sp),
                           Total_host_number = nrow(host))

h=0
for (i in names(host_list)){
  h=h+1
  new <- c(i,nrow(host_list[[h]]),length(table(host_list[[h]]$genome.genus)), 
           length(table(host_list[[h]]$genome.species)),length(table(host_list[[h]]$genome.taxon_id)))
  final <- rbind(final, new)
}

colnames(final) = c("Host","Genome_number","Genus_number","Species_number","Taxon_number")

final[,2:ncol(final)] <- lapply(final[,2:ncol(final)],function(x){as.numeric(x)})

wb <- wb_workbook()

wb$add_worksheet(sheet = paste("Summary",kingdom, sep = "_") ) #summary_list
wb$add_worksheet(sheet = "Summary_by_host") #final
wb$add_worksheet(sheet = "Total_Genus_list") #genus
wb$add_worksheet(sheet = "Genus_list_by_host") #count_hg

wb$add_data(sheet = 1, summary_list)
wb$add_data(sheet = 2, final)
wb$add_data(sheet = 3, genus)
wb$add_data(sheet = 4, count_hg)

wb_save(wb, file = paste(kingdom,"_","ref","_","stats",".xlsx",sep = ""))
wb_save(wb, file = paste(kingdom,"_","ref","_","stats",".xls",sep = ""))

if ( file.exists(paste(kingdom,"_","ref","_","stats",".xlsx",sep = "")) && 
     file.exists(paste(kingdom,"_","ref","_","stats",".xls",sep = ""))){
  cat(paste("\n","[",format(Sys.time(), "%H:%M:%S"),"]"," Statistics for ",
            kingdom," ","ref_database"," ","was"," ","created",sep = "")); cat("\n")
} else {cat(paste("\n","[",format(Sys.time(), "%H:%M:%S"),"]"," ERROR while doing statistics",sep = ""));cat("\n")}

Sys.sleep(0.5)
gc()
sink()

}

stats_eu <- function(){

workingpath <- argu[2]

input <- argu[3]

log <- argu[4]

setwd(workingpath)

Eupa <- read.delim(input)

sink(log, append = T, type = c("output","message"),split = T)

species_count <- as.data.frame(table(Eupa$Species)) %>% `colnames<-`(c("Species","Genome_number"))

Eupa$Genus <- gsub(" .*$","",Eupa$Species)

genus_count <- as.data.frame(table(Eupa$Genus)) %>% `colnames<-`(c("Genus","Genome_number"))%>% arrange(desc(Genome_number))

summary_list <- data.frame(Total_genome_number = nrow(Eupa),
                           Total_genus_number = nrow(genus_count),
                           Total_species_number = nrow(species_count),
                           Total_host_number = "N/A")

wb <- wb_workbook()

wb$add_worksheet(sheet = "Summary" ) #summary_list
wb$add_worksheet(sheet = "Genus_list") #genus_count

wb$add_data(sheet = 1, summary_list) 
wb$add_data(sheet = 2, genus_count)

wb_save(wb, file = "EuPatho_ref_stats.xls")
wb_save(wb,file = "EuPatho_ref_stats.xlsx")

if ( file.exists("EuPatho_ref_stats.xls") && file.exists("EuPatho_ref_stats.xlsx"))
{
  cat(paste("\n","[",format(Sys.time(), "%H:%M:%S"),"]"," Statistics for Eukaryotic pathogen ref_database"," ","was"," ","created",sep = ""));cat("\n")
} else {cat(paste("\n","[",format(Sys.time(), "%H:%M:%S"),"]"," ERROR while doing statistics",sep = ""));cat("\n")}

sink()

}

if (torun == "Pro"){
  statistics()
} else if (torun == "Eu") {
  stats_eu()
} else {print("ERROR in your arguments")}



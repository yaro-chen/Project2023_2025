
files <-fs::dir_ls(path = "", regexp = "DNA.*2024.*.docx",recurse = T)
print(files)

library(stringr)
dates <- str_extract(files, "[0-9]{8}") #find dates

latest_file <- files[which.max(dates)] ##find new file

print(latest_file) #output path
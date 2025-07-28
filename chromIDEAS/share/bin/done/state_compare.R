# load the environment
if (T) {
  rm(list = ls())
  options(stringAsFactors = F)
  args = commandArgs(trailingOnly=TRUE)  
  
  file <- args[1]
  cell1 <- args[2]
  cell2 <- args[3]
  method <- args[4]
  heatmap <- args[5]
  heatmap_name <- args[6]
  heatmap_mat <- args[7]
  
  options(warn = -1)
  suppressPackageStartupMessages(library(aricode))
  options(warn = 0)
}

# test data
if (F) {
  rm(list = ls())
  
  file <- "data/raw_data/2.states/chromIDEAS.state"
  cell1 <- "cd34"
  cell2 <- "thp1"
  method <- "ARI"
  heatmap <- "F"
  heatmap_name <- "heat.pdf"
  heatmap_mat <- "heat.mat"
}

# get the data
if (T) {
  c1_name <- cell1
  c2_name <- cell2
  
  dat <- data.table::fread(file, header = T, sep = " ", data.table = F)
  cell1 <- dat[, cell1]
  cell2 <- dat[, cell2]
  rm(dat)
}

# calculate the stat
if (T) {
  H = entropy(cell1, cell2)
  
  if (method == "All") {
    RI = RI(cell1, cell2)
    ARI = ARI(cell1, cell2)
    MI = -H$UV + H$U + H$V
    VI = H$UV - MI
    NVI = 1 - MI/H$UV
    ID = max(H$U, H$V) - MI
    NID = 1 - MI/max(H$U, H$V)
    NMI = MI/max(H$U, H$V)
    
    result <- list(
      H_Cell1 = H$U, 
      H_Cell2 = H$V, 
      RI = RI, 
      ARI = ARI, 
      MI = MI, 
      VI = VI, 
      NVI = NVI, 
      ID = ID, 
      NID = NID, 
      NMI = NMI
    )
    
    sapply(result, c)
  } else if (method == "H") {
    result <- list(
      H_Cell1 = H$U, 
      H_Cell2 = H$V
    )
    
    sapply(result, c)
  } else if (method == "RI") {
    RI = RI(cell1, cell2)
    result <- list(
      RI = RI
    )
    
    sapply(result, c)
  } else if (method == "ARI") {
    ARI = ARI(cell1, cell2)
    result <- list(
      ARI = ARI
    )
    
    sapply(result, c)
  } else if (method == "MI") {
    MI = -H$UV + H$U + H$V
    result <- list(
      MI = MI
    )
    
    sapply(result, c)
  } else if (method == "VI") {
    MI = -H$UV + H$U + H$V
    VI = H$UV - MI
    result <- list(
      VI = VI
    )
    
    sapply(result, c)
  } else if (method == "NVI") {
    MI = -H$UV + H$U + H$V
    NVI = 1 - MI/H$UV
    result <- list(
      NVI = NVI
    )
    
    sapply(result, c)
  } else if (method == "ID") {
    MI = -H$UV + H$U + H$V
    ID = max(H$U, H$V) - MI
    result <- list(
      ID = ID
    )
    
    sapply(result, c)
  } else if (method == "NID") {
    MI = -H$UV + H$U + H$V
    NID = 1 - MI/max(H$U, H$V)
    result <- list(
      NID = NID
    )
    
    sapply(result, c)
  } else if (method == "NMI") {
    MI = -H$UV + H$U + H$V
    NMI = MI/max(H$U, H$V)
    result <- list(
      NMI = NMI
    )
    
    sapply(result, c)
  }
}

# Heatmap
if (heatmap) {
  # stat
  if (T) {
    tab <- table(cell1, cell2)
    tab <- as.data.frame.table(tab)
  }
  
  # format: long2wide
  if (T) {
    tab <- reshape2::dcast(tab, cell1~cell2, value.var = "Freq")
    rownames(tab) <- paste0(c1_name, "_", tab$cell1)
    colnames(tab) <- paste0(c2_name, "_", colnames(tab))
    tab <- tab[, -1]
  }
  
  # tab output
  if (! is.na(heatmap_mat)) {
    otab <- tab
    otab <- cbind(Cell1 = rownames(otab), otab)
    write.table(tab, file = heatmap_mat, quote = F, sep = "\t", col.names = T, row.names = F)
  }
  
  # heatmap
  if (T) {
    dat <- log(tab-min(tab) + 1)
    
    pheatmap::pheatmap(dat, 
                       cluster_rows = F, cluster_cols = F, 
                       filename = heatmap_name,
                       legend = F, 
                       border_color = "#000000")
  }
}
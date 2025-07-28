# load the environment
if (T) {
  rm(list = ls())
  options(stringAsFactors = F)
  args = commandArgs(trailingOnly=TRUE)  
  
  type <- args[1]
  input <- args[2]
  output_figure <- args[3]
  regionFile <- args[4]
  sampleID <- args[5]
  output_matrix <- args[6]
  body_num <- as.numeric(args[7])
  up_num <- as.numeric(args[8])
  down_num <- as.numeric(args[9])
  startLabel <- args[10]
  endLabel <- args[11]
  refPointLabel <- args[12]
  scale_type <- args[13]
  width <- as.numeric(args[14])
  height <- as.numeric(args[15])
  colors <- args[16]
  num_per_row <- as.numeric(args[17])
  order_of_CS <- args[18]
  reverse_order <- args[19]
  nthreads <- as.numeric(args[20])
  
  options(warn = -1)
  suppressPackageStartupMessages(library(ggplot2))
  suppressPackageStartupMessages(library(data.table))
  suppressPackageStartupMessages(library(reshape2))
  suppressPackageStartupMessages(library(stringr))
  suppressPackageStartupMessages(library(GenomicRanges))
  options(warn = 0)
}

# test data
if (F) {
  rm(list = ls())
  
  type <- "Body"
  
  input <- "data/raw_data/2.states/chromIDEAS.state"
  regionFile <- "gencode.v40.annotation.gtf1"
  
  sampleID <- "All"
  
  output_figure <- "body.pdf"
  output_matrix <- "body.tab"
  
  body_num <- 10
  up_num <- 5
  down_num <- 5
  
  scale_type <- "genomic"
  order_of_CS <- "cs"
  reverse_order <- "F"
  colors <- "Auto"
  num_per_row <- 5
  
  startLabel <- "TSS"
  endLabel <- "TES"
  refPointLabel <- "TSS"
  
  width <- 10
  height <- 8
  
  nthreads <- 4
}

# load the data and format the data
if (T) {
  # load the genome CS segmentation
  if (T) {
    state <- data.table::fread(file = input, header = T, sep = " ", fill = T, skip = "", data.table=F)
    colnames(state)[1] <- "ID"
    state[, c(1,3,4)] <- sapply(state[, c(1,3,4)], as.numeric)
    bin_chr <- unique(state$CHR)
  }
  
  # get the target samples
  if (T) {
    if (sampleID != "All") {
      sampleID <- strsplit(sampleID, ",")[[1]]
      state <- state[, c(1:4, which(colnames(state) %in% sampleID))]
    } else {
      sampleID <- colnames(state)[-c(1:4)]
    }
  }
  
  # get windows bin ID
  if (T) {
    bin <- GRanges(seqnames = state[,2],
                   ranges = IRanges(start = state[,3]+1,
                                    end = state[,4]),
                   ID = state[,1])
  }
  
  # get target region
  if (T) {
    region <- fread(regionFile, header = F, sep = "\t", fill = T, skip = "", data.table=F)
    region <- region[, 1:4]
    region[, c(2,3)] <- sapply(region[, c(2,3)], as.numeric)
    
    region[, 4] <- ifelse(region[, 4] == "*", "+", region[, 4])
    
    region$gene_id <- paste0("g", 1:nrow(region))
    region <- region[region[, 1] %in% bin_chr, ]
    region <- GRanges(seqnames = region[,1],
                      ranges = IRanges(start = region[,2]+1,
                                       end = region[,3]),
                      strand = region[,4], 
                      gene_id = region$gene_id)
    
    rm(bin_chr)
  }
}

# prepare the csID_mat matrix
if (T) {
  cat("############################## Prepare the CS matrix ##############################\n")
  # TSS
  if (type == "TSS") {
    # tss regions
    if (T) {
      chr <- seqnames(region)
      start <- start(region)
      end <- end(region)
      strand <- as.vector(strand(region))
      
      tss <- GRanges(seqnames = chr, 
                     ranges = IRanges(start = ifelse(strand == "+", start, end),
                                      end = ifelse(strand == "+", start, end)), 
                     gid = region$gene_id)
      rm(chr, start, end)
    }
    
    # TSS bin ID
    if (T) {
      # find overlap
      overlapTSS <- findOverlaps(tss, bin, type="any")
      
      # summary the results
      tssID <- data.frame(tx_id = tss$gid[queryHits(overlapTSS)], 
                          Bin_ID = (bin$ID)[subjectHits(overlapTSS)], 
                          Strand = strand[queryHits(overlapTSS)])
      
      rm(strand, tss, overlapTSS)
    }
    
    # TSS up down matrix
    if (T) {
      head(tssID)
      csID_mat <- data.frame(gene_id = tssID$tx_id)
      
      total_bin_num <- up_num+1+down_num
      
      for (bin_id in 1:total_bin_num) {
        name <- ifelse(bin_id<up_num+1, paste0("U", up_num-bin_id+1), 
                       ifelse(bin_id==up_num+1, "TSS", paste0("D", bin_id-down_num-1)))
        if (bin_id != total_bin_num) {
          cat(paste0(name, " "))
        } else {
          cat(paste0(name, "\n"))
        }
        
        csID_mat[, name] <- ifelse(rep(bin_id<up_num+1, nrow(tssID)), 
                                   (ifelse(tssID$Strand == "+", tssID$Bin_ID-(up_num-bin_id+1), tssID$Bin_ID+(up_num-bin_id+1))), 
                                   ifelse(rep(bin_id==up_num+1, nrow(tssID)), 
                                          tssID$Bin_ID, 
                                          (ifelse(tssID$Strand == "+", tssID$Bin_ID+(bin_id-down_num-1), tssID$Bin_ID-(bin_id-down_num-1)))))
      }
    }
    
    # remove the end point
    if (T) {
      bin$Chr <- seqnames(bin)
      ends <- do.call(rbind, tapply(bin$ID, bin$Chr, range))
      ends_bins <- c(ends)
      
      # the ends locate in the tx
      torf <- apply(csID_mat, 1, function(x) {
        # x <- csID_mat[1, ]
        up <- as.numeric(x[paste0("U", up_num-1)])
        down <- as.numeric(x[paste0("D", down_num-1)])
        
        torf <- sum(up:down %in% ends_bins)>0
        
        return(torf)
      })
      
      # the number of tx location in chromatin ends
      if (sum(torf)>0) {
        mess <- paste0("There are ", sum(torf), " location in chromatin ends, these locations will be removed.\n")
        cat(mess)
        csID_mat <- csID_mat[!torf, ]
      }
    }
  }
  
  # Body
  if (type == "Body") {
    # tx region
    if (T) {
      chr <- seqnames(region)
      start <- start(region)
      end <- end(region)
      strand <- as.vector(strand(region))
    }
    
    # TSS bin ID
    if (T) {
      tss <- GRanges(seqnames = chr, 
                     ranges = IRanges(start = ifelse(strand == "+", start, end),
                                      end = ifelse(strand == "+", start, end)), 
                     gid = region$gene_id)
      
      # find overlap
      overlapTSS <- findOverlaps(tss, bin, type="any")
      
      # summary the results
      tssID <- data.frame(tx_id = tss$gid[queryHits(overlapTSS)], 
                          Bin_ID = (bin$ID)[subjectHits(overlapTSS)], 
                          Strand = strand[queryHits(overlapTSS)])
      
      cat(paste0("There are ", nrow(tssID), "/", length(tss), " TSSs of target regions have chromatin state info.\n"))
      
      rm(overlapTSS, tss)
    }
    
    # TES bin ID
    if (T) {
      tes <- GRanges(seqnames = chr, 
                     ranges = IRanges(start = ifelse(strand == "+", end, start),
                                      end = ifelse(strand == "+", end, start)), 
                     gid = region$gene_id)
      
      # find overlap
      overlapTES <- findOverlaps(tes, bin, type="any")
      
      # summary the results
      tesID <- data.frame(tx_id = tes$gid[queryHits(overlapTES)], 
                          Bin_ID = (bin$ID)[subjectHits(overlapTES)], 
                          Strand = strand[queryHits(overlapTES)])
      
      cat(paste0("There are ", nrow(tesID), "/", length(tes), " TESs of target regions have chromatin state info.\n"))
      
      rm(overlapTES, tes, chr, start, end, strand)
    }
    
    # get tx with tes and tss at same time
    if (T) {
      over <- intersect(tesID$tx_id, tssID$tx_id)
      
      if (length(over) < length(region)) {
        cat(paste0("There are ", length(over), " target regions where both the TSS (", nrow(tssID), ") and TES (", nrow(tesID), ") have chromatin state information.\n"))
      }
      
      tssID <- tssID[match(over, tssID$tx_id), ]
      tesID <- tesID[match(over, tesID$tx_id), ]
      if (identical(tssID$tx_id, tesID$tx_id)) {
        gene_body_ID <- data.frame(tx_id = over, 
                                   tss_BinID = tssID$Bin_ID, 
                                   tes_BinID = tesID$Bin_ID, 
                                   strand = tssID$Strand)
        head(gene_body_ID)
      }
      
      gene_body_ID$Len <- ifelse(gene_body_ID$strand == "+", 
                                 gene_body_ID$tes_BinID - gene_body_ID$tss_BinID + 1, 
                                 gene_body_ID$tss_BinID - gene_body_ID$tes_BinID + 1)
      rm(over, tssID, tesID)
    }
    
    # filter txs: length >= 3
    if (T) {
      torf <- gene_body_ID$Len >= 3
      
      if (sum(torf) < nrow(gene_body_ID)) {
        cat(paste0("The minimum length should be more than 3, including at least tss, tes, and a gene body bin.\n"))
        
        mess <- paste0("Filter out ", sum(! torf), "/", nrow(gene_body_ID), " (", round(sum(! torf)/nrow(gene_body_ID)*100, 2), 
                       "%) regions, whose length is less than 3 bins.\n")
        cat(mess)
        
        gene_body_ID <- gene_body_ID[torf, ]
        
        rm(mess)
      }
      
      rm(torf)
    }
    
    # manual
    if (F) {
      ## name:
      ##     bin_id<up_num+1: paste0("U", up_num+1-bin_id)
      ##     bin_id==up_num+1: "TSS"
      ##     bin_id<up_num+body_num+2: paste0("B", bin_id-(up_num+1))
      ##     bin_id==up_num+body_num+2: "TES"
      ##     else:
      ##         paste0("D", bin_id-(up_num+body_num+2))
      ## 
      ## csID_mat[, name]:
      ##     rep(bin_id<up_num+1, nrow(csID_mat)):
      ##         "+": gene_body_ID$tss_BinID-(up_num+1-bin_id)
      ##         "-": gene_body_ID$tss_BinID+(up_num+1-bin_id)
      ##     rep(bin_id==up_num+1, nrow(csID_mat)):
      ##         gene_body_ID$tss_BinID
      ##     rep(bin_id<up_num+body_num+2, nrow(csID_mat)):
      ##         "+": 
      ##             csID_mat$unit>=1: paste0(
      ##                 pos_strand_rounding((gene_body_ID$tss_BinID+1) + (bin_id-(up_num+1) -1) * csID_mat$unit), 
      ##                 "-", 
      ##                 pos_strand_rounding((gene_body_ID$tss_BinID+1) + (bin_id-(up_num+1)) * csID_mat$unit - 1)
      ##                 )
      ##             csID_mat$unit<1: paste0(
      ##                 floor((gene_body_ID$tss_BinID+1) + (bin_id-(up_num+1) -1) * csID_mat$unit + 1e-5), 
      ##                 "-", 
      ##                 floor((gene_body_ID$tss_BinID+1) + (bin_id-(up_num+1)) * csID_mat$unit - 1e-5)
      ##                 )
      ##         "-": 
      ##             csID_mat$unit>=1: paste0(
      ##                 neg_strand_rounding((gene_body_ID$tes_BinID+1) + (body_num+1-(bin_id-(up_num+1)) -1) * csID_mat$unit + 1), 
      ##                 "-", 
      ##                 neg_strand_rounding((gene_body_ID$tes_BinID+1) + (body_num+1-(bin_id-(up_num+1))) * csID_mat$unit)
      ##                 )
      ##             csID_mat$unit<1: paste0(
      ##                 floor((gene_body_ID$tes_BinID+1) + (body_num+1-(bin_id-(up_num+1)) -1) * csID_mat$unit + 1e-5), 
      ##                 "-", 
      ##                 floor((gene_body_ID$tes_BinID+1) + (body_num+1-(bin_id-(up_num+1))) * csID_mat$unit - 1e-5)
      ##                 )
      ##     rep(bin_id==up_num+body_num+2, nrow(csID_mat)):
      ##         gene_body_ID$tes_BinID
      ##     else
      ##         "+": gene_body_ID$tes_BinID+(bin_id-(up_num+body_num+2))
      ##         "-": gene_body_ID$tes_BinID-(bin_id-(up_num+body_num+2))
    }
    
    # Tx up down matrix
    if (T) {
      total_bin_num <- up_num+body_num+down_num
      
      head(gene_body_ID)
      csID_mat <- data.frame(gene_id = gene_body_ID$tx_id)
      csID_mat$strand <- gene_body_ID$strand
      csID_mat$unit <- ifelse(gene_body_ID$strand == "+", 
                              ((gene_body_ID$tes_BinID-1) - (gene_body_ID$tss_BinID+1) +1) / body_num, 
                              ((gene_body_ID$tss_BinID-1) - (gene_body_ID$tes_BinID+1) +1) / body_num)
      # define rounding function
      if (T) {
        pos_strand_rounding <- function(x) {
          x_nextL <- x*10
          remaining <- x_nextL %% 10
          
          res <- ifelse(remaining>=5, ceiling(x), floor(x))
          
          return(res)
        }
        neg_strand_rounding <- function(x) {
          x_nextL <- x*10
          remaining <- x_nextL %% 10
          
          res <- ifelse(remaining<=5, floor(x)-1, ceiling(x)-1)
          
          return(res)
        }
      }
      
      for (bin_id in 1:(total_bin_num+2)) {
        name <- ifelse(bin_id<up_num+1, paste0("U", up_num+1-bin_id), 
                       ifelse(bin_id==up_num+1, "TSS", 
                              ifelse(bin_id<up_num+body_num+2, paste0("B", bin_id-(up_num+1)), 
                                     ifelse(bin_id==up_num+body_num+2, "TES", paste0("D", bin_id-(up_num+body_num+2))))))
        
        if (bin_id < total_bin_num+2) {
          cat(paste0(name, " "))
        } else {
          cat(paste0(name, "\n"))
        }
        
        csID_mat[, name] <- ifelse(rep(bin_id<up_num+1, nrow(csID_mat)), 
                                   ifelse(gene_body_ID$strand == "+", 
                                          gene_body_ID$tss_BinID-(up_num+1-bin_id), 
                                          gene_body_ID$tss_BinID+(up_num+1-bin_id)), 
                                   
                                   ifelse(rep(bin_id==up_num+1, nrow(csID_mat)), 
                                          gene_body_ID$tss_BinID, 
                                          
                                          ifelse(rep(bin_id<up_num+body_num+2, nrow(csID_mat)), 
                                                 ifelse(gene_body_ID$strand == "+", 
                                                        ifelse(csID_mat$unit>=1, 
                                                               paste0(
                                                                 pos_strand_rounding((gene_body_ID$tss_BinID+1) + (bin_id-(up_num+1) -1) * csID_mat$unit), 
                                                                 "-", 
                                                                 pos_strand_rounding((gene_body_ID$tss_BinID+1) + (bin_id-(up_num+1)) * csID_mat$unit - 1)
                                                               ), 
                                                               paste0(
                                                                 floor((gene_body_ID$tss_BinID+1) + (bin_id-(up_num+1) -1) * csID_mat$unit + 1e-5), 
                                                                 "-", 
                                                                 floor((gene_body_ID$tss_BinID+1) + (bin_id-(up_num+1)) * csID_mat$unit - 1e-5)
                                                               )), 
                                                        ifelse(csID_mat$unit>=1, 
                                                               paste0(
                                                                 neg_strand_rounding((gene_body_ID$tes_BinID+1) + (body_num+1-(bin_id-(up_num+1)) -1) * csID_mat$unit + 1), 
                                                                 "-", 
                                                                 neg_strand_rounding((gene_body_ID$tes_BinID+1) + (body_num+1-(bin_id-(up_num+1))) * csID_mat$unit)
                                                               ), 
                                                               paste0(
                                                                 floor((gene_body_ID$tes_BinID+1) + (body_num+1-(bin_id-(up_num+1)) -1) * csID_mat$unit + 1e-5), 
                                                                 "-", 
                                                                 floor((gene_body_ID$tes_BinID+1) + (body_num+1-(bin_id-(up_num+1))) * csID_mat$unit - 1e-5)
                                                               ))),
                                                 
                                                 ifelse(rep(bin_id==up_num+body_num+2, nrow(csID_mat)), 
                                                        gene_body_ID$tes_BinID,
                                                        
                                                        ifelse(gene_body_ID$strand == "+", 
                                                               gene_body_ID$tes_BinID+(bin_id-(up_num+body_num+2)), 
                                                               gene_body_ID$tes_BinID-(bin_id-(up_num+body_num+2)))))))
      }
      
      rm(total_bin_num, bin_id, name, pos_strand_rounding, neg_strand_rounding)
    }
    
    # remove the end point
    if (T) {
      bin$Chr <- seqnames(bin)
      ends <- do.call(rbind, tapply(bin$ID, bin$Chr, range))
      ends_bins <- c(ends)
      
      # the ends locate in the tx
      torf <- apply(csID_mat, 1, function(x) {
        # x <- unlist(csID_mat[1, ])
        up <- as.numeric(x[paste0("U", up_num-1)])
        down <- as.numeric(x[paste0("D", down_num-1)])
        
        torf <- sum(up:down %in% ends_bins)>0
        
        return(torf)
      })
      
      if (sum(torf)>0) {
        mess <- paste0("There are ", sum(torf), " location in chromatin ends, these locations will be removed.\n")
        cat(mess)
        csID_mat <- csID_mat[!torf, ]
      }
    }
  }
  cat("###################################### Done #######################################\n")
}

# replace csID with CS
if (T) {
  cat("\n############################## Calculate cell specific CS matrix ##############################\n")
  ggdat <- lapply(sampleID, function(cell) {
    # cell <- sampleID[1]
    
    cat(paste0(cell, ":\n"))
    
    # TSS
    if (type == "TSS") {
      # cs distribution for each location
      if (T) {
        mat <- data.frame(
          t(apply(csID_mat, 1, function(x) {
            # x <- unlist(csID_mat[1, ])
            geneid <- x["gene_id"]
            
            x <- x[grep("^U|TSS|^D", names(x))]
            cell_specific_state <- state[as.numeric(x), cell]
            res <- c(geneid, cell_specific_state)
            
            return(res)
          }))
        )
        colnames(mat)[2:ncol(mat)] <- grep("^U|TSS|^D", colnames(csID_mat), value = T)
        colnames(mat)[1] <- "gene_id"
        
        mat[, -1] <- sapply(mat[, -1] , as.numeric)
      }
      
      # sum matrix
      if (T) {
        # all states
        state_order <- sort(as.numeric(unique(mat$TSS)))
        
        # get total number for each state in each position
        if (T) {
          state_profile <- lapply(state_order, function(s){
            # s <- 0
            cell_dat <- sapply(mat[, -1], function(c_s) {
              sum(s==c_s)
            })
            return(cell_dat)
          })
          
          state_profile <- data.frame(do.call(rbind, state_profile))
          state_profile$State <- paste0("S", state_order)
          state_profile$Cell <- cell
        }
      }
    }
    
    # Body
    if (type == "Body") {
      # cs distribution for each location
      if (T) {
        # prepare hello info
        if (T) {
          state_order <- sort(as.numeric(unique(state[, cell])))
          start_mess <- paste0("|", paste(rep("-", 100), collapse = ""), "|\n")
          cat(start_mess)
          
          csID_mat$num <- 1:nrow(csID_mat)
          
          csID_mat$thread <- cut(1:nrow(csID_mat), breaks = seq(1, nrow(csID_mat), length.out = nthreads+1), right = F, include.lowest = T, labels = paste0("P", 1:nthreads))
          
          breaks <- round(seq(min(csID_mat$num), max(csID_mat$num), length.out=100))
        }
        
        # prepare multicore environment
        if (T) {
          library(parallel)
          cl <- makeCluster(nthreads, type = "PSOCK", outfile = "")
          clusterExport(cl, c("csID_mat", "breaks", "state", "cell", "state_order", "up_num", "down_num", "body_num"), envir = environment())
        }
        
        # get cell specific body chromatin state matrix: absolute number
        if (T) {
          mat <- parLapply(cl, paste0("P", 1:nthreads), function(p) {
            # p <- "P1"
            subdat <- csID_mat[csID_mat$thread == p, -ncol(csID_mat)]
            submat <- data.frame(t(
              apply(subdat, 1, function(x) {
                # x <- unlist(subdat[1, ])
                # print process
                if (as.numeric(x[length(x)]) %in% breaks) {
                  if (which(as.numeric(x[length(x)]) == breaks) == 1) {
                    cat("|*")
                  }
                  if (which(as.numeric(x[length(x)]) == breaks) == 100) {
                    cat("*|\n")
                  }
                  if (! which(as.numeric(x[length(x)]) == breaks) %in% c(1, 100)) {
                    cat("*")
                  }
                }
                
                # nonbody
                if (T) {
                  nonbody <- x[grepl("^U|TSS|TES|^D", colnames(subdat))]
                  nonbody <- as.numeric(nonbody)
                  nonbody <- state[nonbody, cell]
                  names(nonbody) <- grep("^U|TSS|TES|^D", colnames(subdat), value = T)
                }
                
                # genebody
                if (T) {
                  genebody_bin <- x[grepl("^B", colnames(subdat))]
                  genebody <- data.frame(
                    sapply(genebody_bin, function(gb) {
                      # gb <- genebody_bin[1]
                      start <- as.numeric(strsplit(gb, "-")[[1]][1])
                      end <- as.numeric(strsplit(gb, "-")[[1]][2])
                      s_dat <- state[start:end, cell]
                      
                      s_p <- sapply(state_order, function(s) {
                        sum(s_dat==s)
                      })
                      names(s_p) <- paste0("S", state_order)
                      return(s_p)
                    })
                  )
                  genebody <- c(as.matrix(genebody))
                  
                  names(genebody) <- paste0(
                    rep(grep("^B", colnames(subdat), value = T), each=length(state_order)), 
                    "_", 
                    rep(paste0("S", state_order), body_num)
                  )
                }
                
                # merge the results
                if (T) {
                  order <- c(
                    paste0("U", up_num:1), 
                    "TSS", 
                    names(genebody), 
                    "TES", 
                    paste0("D", 1:down_num)
                  )
                  
                  res <- c(nonbody, genebody)
                  res <- res[order]
                }
                
                return(res)
              })
            ))
            
            submat$gene_id <- subdat$gene_id
            
            return(submat)
          })
        }
        
        # end multicore environment
        if (T) {
          stopCluster(cl)
        }
        
        # merge and format the data
        if (T) {
          mat <- data.frame(do.call(rbind, mat))
          
          mat <- mat[, c(which(grepl("gene_id", colnames(mat))), 
                         which(!grepl("gene_id", colnames(mat))))]
        }
      }
      
      # sum matrix
      if (T) {
        # all states
        state_order <- sort(as.numeric(unique(mat$TSS)))
        
        # get total number for each state: nonbody
        if (T) {
          colnames(mat)
          
          nonbody <- mat[, grep("^U|^D|TSS|TES", colnames(mat))]
          
          nonbody <- lapply(state_order, function(s){
            # s <- 0
            nonbody_dat <- sapply(nonbody, function(c_s) {
              sum(s==c_s)
            })
            return(nonbody_dat)
          })
          
          nonbody <- data.frame(do.call(rbind, nonbody))
          nonbody$State <- paste0("S", state_order)
        }
        
        # get total number for each state: body
        if (T) {
          body <- mat[, grep("^B", colnames(mat))]
          
          body <- reshape2::melt(body, id.vars = NULL, variable.name = "ID", value.name = "value")
          body$Loc <- str_split(body$ID, "_", simplify = T)[, 1]
          body$State <- str_split(body$ID, "_", simplify = T)[, 2]
          body <- dcast(body, State~Loc, value.var = "value", fun.aggregate = sum)
          body <- body[, c(paste0("B", 1:body_num), "State")]
        }
        
        # merge the info 
        if (T) {
          # make sure the order of body and nonbody are identical
          if (T) {
            body <- body[match(paste0("S", state_order), body$State), ]
            nonbody <- nonbody[match(paste0("S", state_order), nonbody$State), ]
          }
          
          # merge the state number data
          if (T) {
            order <- c(
              paste0("U", up_num:1), 
              "TSS", 
              paste0("B", 1:body_num), 
              "TES", 
              paste0("D", 1:down_num)
            )
            
            state_profile <- merge(body, nonbody, by="State")
            state_profile <- state_profile[, c(order, "State")]
            rownames(state_profile) <- 1:nrow(state_profile)
            
            state_profile$Cell <- cell
          }
        }
      }
    }
    
    # get ggdat
    if (T) {
      if (scale_type == "genomic") {
        dat_col <- data.frame(
          apply(state_profile[, grep("^U|^B|^D|TSS|TES", colnames(state_profile))], 2, function(x) {
            x/sum(x)*100
          })
        )
        dat_col$State <- state_profile$State
        dat_col$Cell <- state_profile$Cell
        
        dat_d <- dat_col
        
        ggdat <- melt(dat_d, id.vars = c("State", "Cell"), variable.name = "Loc", value.name = "Genomic_Percentage")
      }
      if (scale_type == "state") {
        bin_num <- sapply(state_profile[, grep("^U|^B|^D|TSS|TES", colnames(state_profile))], sum)
        
        dat_row <- data.frame(t(
          apply(state_profile[, grep("^U|^B|^D|TSS|TES", colnames(state_profile))], 1, function(x) {
            # x <- state_profile$TSS
            x <- as.numeric(x)
            
            # norm the bin number
            (x/sum(x)*100)/(bin_num/bin_num["TSS"])
          })
        ))
        dat_row$State <- state_profile$State
        dat_row$Cell <- state_profile$Cell
        
        dat_d <- dat_row
        
        ggdat <- melt(dat_d, id.vars = c("State", "Cell"), variable.name = "Loc", value.name = "State_Percentage")
      }
      
      # format the data
      if (T) {
        if ("TES" %in% unique(ggdat$Loc)) {
          ggdat$Loc <- factor(ggdat$Loc, levels = c(
            paste0("U", up_num:1), 
            "TSS", 
            paste0("B", 1:body_num), 
            "TES", 
            paste0("D", 1:down_num)
          ), labels = c(
            paste0("U", up_num:1), 
            startLabel, 
            paste0("B", 1:body_num), 
            endLabel, 
            paste0("D", 1:down_num)
          ))
        } else {
          ggdat$Loc <- factor(ggdat$Loc, levels = c(
            paste0("U", up_num:1), 
            "TSS", 
            paste0("D", 1:down_num)
          ), labels = c(
            paste0("U", up_num:1), 
            refPointLabel, 
            paste0("D", 1:down_num)
          ))
        }
      }
      
      return(list(ggdat, dat_d))
    }
  })
  
  # output the raw matrix
  if (output_matrix != "F") {
    dat <- lapply(ggdat, function(x) {
      x[[2]]
    })
    dat <- data.frame(do.call(rbind, dat))
    dat <- dat[order(dat$Cell, dat$State), ]
    rownames(dat) <- 1:nrow(dat)
    
    write.table(dat, file = output_matrix, quote = F, sep = "\t", col.names = T, row.names = F)
  }
  
  # format the data
  if (T) {
    ggdat <- lapply(ggdat, function(x) {
      x[[1]]
    })
    ggdat <- data.frame(do.call(rbind, ggdat))
    colnames(ggdat)[4] <- "Value"
    
    # order of cs
    if (T) {
      if (order_of_CS == "cs") {
        ord <- paste0("S", sort(as.numeric(gsub("S", "", unique(ggdat$State)))))
      } else if (order_of_CS == "csgp") {
        ggdat$merged <- paste0(ggdat$Cell, "@", ggdat$State)
        auc <- dcast(ggdat, merged~Loc, value.var="Value")
        auc$cell <- str_split(auc$merged, "@", simplify = T)[, 1]
        auc$state <- str_split(auc$merged, "@", simplify = T)[, 2]
        
        if (type == "TSS") {
          ord <- c(
            paste0("U", up_num:1), 
            "TSS", 
            paste0("D", 1:down_num)
          )
        }
        if (type == "Body") {
          ord <- c(
            paste0("U", up_num:1), 
            "TSS", 
            paste0("B", 1:body_num), 
            "TES", 
            paste0("D", 1:down_num)
          )
        }
        
        auc$auc <- apply(auc[, ord], 1, function(x) {
          # x <- auc[1, ord]
          value <- as.numeric(x)
          
          a <- value[-1]
          b <- value[-length(value)]
          
          sum((a+b)*1/2)
        })
        
        ord <- tapply(auc$auc, auc$state, sum)
        ord <- sort(ord, decreasing = T)
        ord <- names(ord)
      } else if (grepl(",", order_of_CS)) {
        ord <- strsplit(order_of_CS, ",")[[1]]
        ord <- paste0("S", ord)
      }
      
      if (reverse_order) {
        ord <- rev(ord)
      }
      ggdat$State <- factor(ggdat$State, levels = ord)
    }
    
    # order of cell
    if (T) {
      ggdat$Cell <- factor(ggdat$Cell, levels = sampleID)
    }
  }
  cat("############################################ Done #############################################\n")
}

# ggplot2
if (T) {
  cat("\n############################## Plot cell specific CS distribution ##############################\n")
  if (T) {
    ggdat$group <- paste0(ggdat$Cell, ggdat$State)
    
    # indicator line
    if (T) {
      if (type == "TSS") {
        vline <- c(refPointLabel)
      }
      if (type == "Body") {
        vline <- c(startLabel, endLabel)
      }
    }
    
    # colors
    if (colors != "Auto") {
      colors <- strsplit(colors, ",")[[1]]
      names(colors) <- sampleID
      col <- scale_color_manual(values = colors)
    } else {
      col <- NULL
    }
    
    p <- ggplot(ggdat) +
      geom_vline(xintercept = vline, linewidth=0.6, linetype=2, alpha=0.8, color="#cbcbcb") +
      geom_line(aes(x=Loc, y=Value, group=group, color=Cell), linewidth=1, alpha=0.7) +
      scale_x_discrete(name = NULL, breaks=c(paste0("U", up_num), startLabel, endLabel, refPointLabel, paste0("D", down_num))) +
      ylab(ifelse(scale_type=="genomic", "Genomic Percentage", "State Percentage")) +
      col +
      facet_wrap(~State, scales = "free", ncol = num_per_row) +
      theme_classic() +
      theme(axis.title = element_text(size = rel(1.2), color = "black"), 
            axis.text = element_text(size = rel(1.1), color = "black"), 
            strip.text = element_text(size = rel(1.2), color = "black"), 
            legend.text = element_text(size = rel(1.1), color = "black"), 
            panel.border = element_rect(color="black", fill = NA), 
            strip.background = element_rect(color=NA, fill=NA))
    
    ggsave(plot = p, filename = output_figure, width = width, height = height, units = "in")
  }
  cat("############################################# Done #############################################\n")
}
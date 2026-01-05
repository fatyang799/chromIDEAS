# load the environment
if (T) {
  rm(list = ls())
  options(stringAsFactors = F)
  set.seed(799)
  suppressPackageStartupMessages(library(parallel))
  suppressPackageStartupMessages(library(qs))
  suppressPackageStartupMessages(library(GenomicFeatures))
}

# get options
if (T) {
  args <- commandArgs(trailingOnly = T)
  
  # test dat
  if (F) {
    input_CS <- "chromIDEAS.state"
    CS_cluster <- "data/saved_data/merge.cluster.csv"
    region_file <- "data/raw_data/gencode.v40.annotation.gtf.gz"
    dist_mat <- "data/saved_data/2.csc.merge.CS_Distance.qs"
    out_prefix <- "data/saved_data/dcscg"
    
    file_type <- "gtf"
    up_bin_num <- 3
    down_bin_num <- 3
    nthreads <- 4
  }
  
  input_CS <- args[1]
  CS_cluster <- args[2]
  region_file <- args[3]
  dist_mat <- args[4]
  out_prefix <- args[5]
  file_type <- args[6]
  up_bin_num <- as.numeric(args[7])
  down_bin_num <- as.numeric(args[8])
  nthreads <- as.numeric(args[9])
}

# read clustering dat
if (T) {
  clusters <- read.table(CS_cluster, header = T, sep = ",", fill = T, comment.char = "")
}

# read distance dat
if (T) {
  dists <- qread(dist_mat, nthreads = 6)
  
  rownames(dists) <- dists$state
  dists <- dists[, dists$state]
  dists <- dists[clusters$state, ]
}

# normalization: max-min-normalization
if (T) {
  values <- c(as.matrix(dists))
  max <- max(values)
  min <- min(values)
  
  dists <- (dists-min)/(max-min)
  dists <- as.matrix(dists)
  
  rm(values, max, min)
}

# read the states data
if (T) {
  state <- data.table::fread(input_CS, sep = " ", header = T, data.table = F)
  
  bin <- GRanges(seqnames = state[,2],
                 ranges = IRanges(start = state[,3]+1,
                                  end = state[,4]),
                 ID = state[,1])
  chrs <- unique(state[, 2])
  
  state <- state[, -c(2:4)]
  colnames(state)[1] <- "ID"
}

# read the location info: genebody_stat
if (T) {
  # read the gtf
  if (file_type == "gtf") {
    txdb <- makeTxDbFromGFF(region_file)
    # txdb <- loadDb("data/saved_data/gencode.v40.annotation.sqlite")
    
    # only focus on the record regions
    seqlevels(txdb) <- chrs
  }
  
  # read the bed
  if (file_type == "bed") {
    gtf <- data.table::fread(region_file, header = F, sep = "\t", data.table = F)
    
    cat(ifelse(all(grepl("chr", gtf[, 1])), "", "Wrong bed file format, please check. 1st column should be the chromID, with 'chr' prefix\n"))
    cat(ifelse(all(as.numeric(gtf[, 2])>=0), "", "Wrong bed file format, please check. 2st column should be non-negative integer\n"))
    cat(ifelse(all(as.numeric(gtf[, 3])>=0), "", "Wrong bed file format, please check. 3st column should be non-negative integer\n"))
    cat(ifelse(all(unique(gtf[, 4]) %in% c("+", "-", "*")), "", "Wrong bed file format, please check. 4st column should be the strand, '+', '-' or '*'\n"))
    cat(ifelse(length(unique(gtf[, 5])) != nrow(gtf), "", "Wrong bed file format, please check. 5st column should be the unique chromID with no duplicate\n"))
    
    gtf <- gtf[gtf[, 1] %in% chrs, ]
    
    colnames(gtf)[5] <- "gene_id"
  }
  
  rm(chrs)
  
  # calculate the regions
  if (T) {
    # get the region info
    if (T) {
      if (file_type == "gtf") {
        gtf <- genes(txdb, columns="gene_id")
        
        chr <- seqnames(gtf)
        start <- start(gtf)
        end <- end(gtf)
        strand <- as.vector(strand(gtf))
      }
      if (file_type == "bed") {
        chr <- gtf[, 1]
        start <- gtf[, 2]
        end <- gtf[, 3]
        strand <- gtf[, 4]
      }
    }
    
    # TSS bin ID
    if (T) {
      tss <- GRanges(seqnames = chr, 
                     ranges = IRanges(start = ifelse(strand == "+", start, end),
                                      end = ifelse(strand == "+", start, end)))
      
      # find overlap
      overlapTSS <- findOverlaps(tss, bin, type="any")
      
      # summary the results
      tssID <- data.frame(TSS_ID = gtf$gene_id[queryHits(overlapTSS)], 
                          Bin_ID = (bin$ID)[subjectHits(overlapTSS)], 
                          Strand = strand[queryHits(overlapTSS)])
      
      rm(overlapTSS, tss)
    }
    
    # TES bin ID
    if (T) {
      tes <- GRanges(seqnames = chr, 
                     ranges = IRanges(start = ifelse(strand == "+", end, start),
                                      end = ifelse(strand == "+", end, start)))
      
      # find overlap
      overlapTES <- findOverlaps(tes, bin, type="any")
      
      # summary the results
      tesID <- data.frame(TES_ID = gtf$gene_id[queryHits(overlapTES)], 
                          Bin_ID = (bin$ID)[subjectHits(overlapTES)], 
                          Strand = strand[queryHits(overlapTES)])
      
      rm(overlapTES, tes, chr, start, end, strand)
    }
    
    # get tx with tes and tss at same time
    if (T) {
      over <- intersect(tesID$TES_ID, tssID$TSS_ID)
      tssID <- tssID[match(over, tssID$TSS_ID), ]
      tesID <- tesID[match(over, tesID$TES_ID), ]
      genebody_stat <- data.frame(tx_id = over, 
                                  tss_BinID = tssID$Bin_ID, 
                                  tes_BinID = tesID$Bin_ID, 
                                  strand = tssID$Strand)
    }
  }
}

# get tss ID
if (T) {
  if (file_type == "gtf") {
    # get tx id
    if (T) {
      gtf <- transcripts(txdb, columns=c("TXNAME", "GENEID"))
      gtf$GENEID <- sapply(gtf$GENEID, c)
      rm(txdb)
    }
    
    # get region info
    if (T) {
      chr <- seqnames(gtf)
      start <- start(gtf)
      end <- end(gtf)
      strand <- as.vector(strand(gtf))
    }
    
    # TSS bin ID
    if (T) {
      tss <- GRanges(seqnames = chr, 
                     ranges = IRanges(start = ifelse(strand == "+", start, end),
                                      end = ifelse(strand == "+", start, end)))
      
      # find overlap
      overlapTSS <- findOverlaps(tss, bin, type="any")
      
      # summary the results
      tssID <- data.frame(TSS_ID = gtf$TXNAME[queryHits(overlapTSS)], 
                          Gene_ID = gtf$GENEID[queryHits(overlapTSS)], 
                          Bin_ID = (bin$ID)[subjectHits(overlapTSS)], 
                          Strand = strand[queryHits(overlapTSS)])
      
      tssID <- lapply(split(tssID$Bin_ID, tssID$Gene_ID), function(x) {
        sort(as.numeric(unique(x)))
      })
      
      rm(overlapTSS, tss, chr, start, end, strand)
    }
  } else if (file_type == "bed") {
    tssID <- lapply(genebody_stat$tx_id, function(x) {
      return(0)
    })
    names(tssID) <- genebody_stat$tx_id
  }
}

# calculate the gene CS/CSC sequence
if (T) {
  cat("(1) calculate the gene CS sequence for two cells ...\n")
  cell_geneCS <- function(genebody_stat, cell_state, clusters, up_bin_num, down_bin_num, nthreads) {
    # test dat
    if (F) {
      cell_state <- state[, c("ID", "thp1")]
    }
    
    # prepare hello info
    if (T) {
      start_mess <- paste0("|", paste(rep("-", 100), collapse = ""), "|\n")
      cat(start_mess)
      IDs <- genebody_stat$tx_id
      breaks <- round(seq(1, length(IDs), length.out=98))
      breaks <- IDs[breaks]
      
      cat("|*")
    }
    
    # prepare multicore environment
    if (T) {
      cl <- makeCluster(nthreads, outfile = "")
      clusterExport(cl, ls(), envir = environment())
    }
    
    # get gene specific state pattern
    if (T) {
      dat <- parLapply(cl, IDs, function(gene_id) {
        # gene_id <- IDs[1]
        
        # print process
        if (gene_id %in% breaks) {
          cat("*")
        }
        
        # get subdat
        if (T) {
          gene_dat <- unlist(genebody_stat[genebody_stat$tx_id == gene_id, ])
        }
        
        # state
        if (T) {
          strand <- gene_dat["strand"]
          tss <- as.numeric(gene_dat["tss_BinID"])
          tes <- as.numeric(gene_dat["tes_BinID"])
          
          tss_up <- ifelse(strand == "-", tss + up_bin_num, tss - up_bin_num)
          tes_down <- ifelse(strand == "-", tes - down_bin_num, tes + down_bin_num)
          
          ids <- (tss_up:tes_down)
          states <- cell_state[ids, 2]
          states <- as.numeric(states)
        }
        
        # csc
        if (T) {
          csc <- clusters$cluster[match(paste0("S", states), clusters$state)]
        }
        
        # return result
        res <- list(cs = states, csc = csc)
        return(res)
      })
      cat("*|\n")
    }
    
    # get IDs info
    if (T) {
      names(dat) <- IDs
    }
    
    # end multicore environment
    if (T) {
      stopCluster(cl)
      
      rm(cl)
    }
    
    return(dat)
  }
  
  cat(paste0("    ", colnames(state)[2], " dat ... \n"))
  cell1_geneCS <- cell_geneCS(genebody_stat, state[, c(1, 2)], clusters, up_bin_num, down_bin_num, nthreads)
  
  cat(paste0("    ", colnames(state)[3], " dat ... \n"))
  cell2_geneCS <- cell_geneCS(genebody_stat, state[, c(1, 3)], clusters, up_bin_num, down_bin_num, nthreads)
  cat("(1) Done\n")
}

# DCSCG analysis
if (T) {
  DCSCG <- function(cell1_geneCS, cell2_geneCS, dists, nthreads) {
    # prepare hello info
    if (T) {
      start_mess <- paste0("|", paste(rep("-", 100), collapse = ""), "|\n")
      cat(start_mess)
      IDs <- names(cell1_geneCS)
      breaks <- round(seq(1, length(IDs), length.out=98))
      breaks <- IDs[breaks]
      
      cat("|*")
    }
    
    # prepare multicore environment
    if (T) {
      cl <- makeCluster(nthreads, outfile = "")
      clusterExport(cl, ls(), envir = environment())
    }
    
    # DCSSCG analysis
    if (T) {
      dat <- parLapply(cl, IDs, function(gene_id) {
        # gene_id <- IDs[1]
        
        # print process
        if (gene_id %in% breaks) {
          cat("*")
        }
        
        # get subdat
        if (T) {
          cell1_dat <- cell1_geneCS[[gene_id]]
          cell2_dat <- cell2_geneCS[[gene_id]]
        }
        
        # summary the res
        if (T) {
          res <- data.frame(
            id = gene_id, 
            location_id = 1:length(cell1_dat$cs), 
            location_p = (1:length(cell1_dat$cs)) / length(cell1_dat$cs), 
            cell1_CS = cell1_dat$cs,
            cell2_CS = cell2_dat$cs,
            cell1_CSC = cell1_dat$csc,
            cell2_CSC = cell2_dat$csc
          )
        }
        
        # distance
        if (T) {
          res$distance <- apply(res, 1, function(x) {
            dists[paste0("S", as.numeric(x[4])), paste0("S", as.numeric(x[5]))]
          })
        }
        
        return(res)
      })
      cat("*|\n")
    }
    
    # merge the info
    if (T) {
      dat <- data.frame(do.call(rbind, dat))
    }
    
    # end multicore environment
    if (T) {
      stopCluster(cl)
      
      rm(cl)
    }
    
    return(dat)
  }
  
  cat("(2) Differential Chromatin State Cluster Genes Analysis ...\n")
  dcscg <- DCSCG(cell1_geneCS, cell2_geneCS, dists, nthreads)
  cat("(2) Done\n")
}

# filter the data
if (T) {
  dcscg <- dcscg[dcscg$cell1_CSC != dcscg$cell2_CSC, ]
}

# determine the final transition label
if (T) {
  gene_cluster_conversion <- function(dcscg, tssID, genebody_stat, up_bin_num, down_bin_num) {
    # prepare hello info
    if (T) {
      start_mess <- paste0("|", paste(rep("-", 100), collapse = ""), "|\n")
      cat(start_mess)
      IDs <- unique(dcscg$id)
      breaks <- round(seq(1, length(IDs), length.out=98))
      breaks <- IDs[breaks]
      
      cat("|*")
    }
    
    # prepare the data
    if (T) {
      dcscg$cs_trans <- paste0(dcscg$cell1_CSC, "to", dcscg$cell2_CSC)
      all_conversion <- sort(unique(dcscg$cs_trans))
    }
    
    # prepare multicore environment
    if (T) {
      cl <- makeCluster(nthreads, outfile = "")
      clusterExport(cl, ls(), envir = environment())
    }
    
    # summary the cs conversion situation
    if (T) {
      dat <- parLapply(cl, IDs, function(gene_id) {
        # gene_id <- IDs[1]
        
        # print process
        if (gene_id %in% breaks) {
          cat("*")
        }
        
        # get subdat
        if (T) {
          subdat <- dcscg[dcscg$id == gene_id, ]
        }
        
        # stat distance
        if (T) {
          convers_dist <- tapply(subdat$distance, subdat$cs_trans, sum)
          convers_dist <- ifelse(all_conversion %in% names(convers_dist), convers_dist[all_conversion], 0)
          names(convers_dist) <- all_conversion
        }
        
        # stat loction
        if (T) {
          tss <- genebody_stat$tss_BinID[genebody_stat$tx_id == gene_id]
          tes <- genebody_stat$tes_BinID[genebody_stat$tx_id == gene_id]
          strand <- genebody_stat$strand[genebody_stat$tx_id == gene_id]
          
          tss_up <- ifelse(strand == "-", tss + up_bin_num, tss - up_bin_num)
          tes_down <- ifelse(strand == "-", tes - down_bin_num, tes + down_bin_num)
          
          gene_bin_id <- (tss_up:tes_down)
          dcsg_bin_id <- gene_bin_id[subdat$location_id]
          
          loc_type <- ifelse(dcsg_bin_id %in% tssID[[gene_id]], "TSS", "Body")
          convers_tss <- tapply(loc_type, subdat$cs_trans, function(x) {
            sum(x == "TSS")
          })
          convers_tss <- ifelse(all_conversion %in% names(convers_tss), convers_tss[all_conversion], 0)
          names(convers_tss) <- all_conversion
        }
        
        # summary the res
        if (T) {
          max_dist <- max(convers_dist)
          max_dist_type <- names(convers_dist)[convers_dist == max_dist]
          max_dist_N <- length(max_dist_type)
          max_dist_conversion = paste(max_dist_type, collapse = "@")
          
          max_tss <- max(convers_tss)
          max_tss_type <- names(convers_tss)[convers_tss == max_tss]
          max_tss_N <- length(max_tss_type)
          max_tss_conversion = paste(max_tss_type, collapse = "@")
          
          stat <- data.frame(
            id = gene_id, 
            max_dist = max_dist, 
            max_dist_N = max_dist_N, 
            max_dist_conversion = max_dist_conversion, 
            max_tss = max_tss, 
            max_tss_N = max_tss_N, 
            max_tss_conversion = max_tss_conversion)
        }
        
        return(stat)
      })
      cat("*|\n")
    }
    
    # merge the info
    if (T) {
      dat <- data.frame(do.call(rbind, dat))
    }
    
    # end multicore environment
    if (T) {
      stopCluster(cl)
      
      rm(cl)
    }
    
    return(dat)
  }
  
  mess <- ifelse(file_type == "gtf", 
                 "(3) Gene classification integrates both cumulative Euclidean distances and TSS proximity to determine dominant transition patterns ...\n", 
                 "(3) Gene classification based solely on cumulative Euclidean distances, without TSS consideration ...\n")
  cat(mess)
  dcscg_label <- gene_cluster_conversion(dcscg, tssID, genebody_stat, up_bin_num, down_bin_num)
  
  # assign the CS cluster conversion label
  dcscg_label$label <- ifelse(dcscg_label$max_dist_N == 1, dcscg_label$max_dist_conversion, 
                                ifelse(dcscg_label$max_tss_N == 1, dcscg_label$max_tss_conversion, "confused"))
  
  if (file_type == "bed") {
    dcscg_label <- dcscg_label[, !grepl("tss", colnames(dcscg_label))]
  }
  
  cat("(3) Done\n")
}

# output the results
if (T) {
  data.table::fwrite(dcscg_label, quote = F, sep = ",", col.names = T, row.names = F, 
                     file = paste0(out_prefix, ".DCSCG_Label.csv"))
  data.table::fwrite(dcscg, quote = F, sep = ",", col.names = T, row.names = F, 
                     file = paste0(out_prefix, ".DCSCG.csv"))
}


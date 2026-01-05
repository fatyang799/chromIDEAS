# load the environment
if (T) {
  rm(list = ls())
  options(stringAsFactors = F)
  suppressPackageStartupMessages(library(qs))
  suppressPackageStartupMessages(library(parallel))
  suppressPackageStartupMessages(library(reshape2))
  suppressPackageStartupMessages(library(data.table))
  suppressPackageStartupMessages(library(GenomicFeatures))
}

# get options
if (T) {
  args <- commandArgs(trailingOnly = T)
  
  # test dat
  if (F) {
    input_CS <- "chromIDEAS.state"
    body_bin_num <- 10
    length_leveles <- 10
    nthreads <- 4
    n_HITs <- 2000
    out_prefix <- "data/saved_data/1.chrom"
    
    # tx
    if (T) {
      region_file <- "data/raw_data/gencode.v40.annotation.gtf.gz"
      
      file_type <- "gtf"
      location_type <- "tx"
      location_type <- "gene"
      overlap_cutoff <- 0.1
    }
    
    # bed
    if (T) {
      region_file <- "data/raw_data/1.test.bed"
      
      file_type <- "bed"
      location_type <- ifelse(file_type == "bed", "gene", location_type)
    }
  }
  
  input_CS <- args[1]
  out_prefix <- args[2]
  
  body_bin_num <- as.numeric(args[3])
  length_leveles <- as.numeric(args[4])
  nthreads <- as.numeric(args[5])
  n_HITs <- as.numeric(args[6])
  
  region_file <- args[7]
  file_type <- args[8]
  location_type <- args[9]
  overlap_cutoff <- as.numeric(args[10])
  
  location_type <- ifelse(file_type == "bed", "gene", location_type)
}

# prepare the region files
if (T) {
  # get state file
  if (T) {
    state <- data.table::fread(input_CS, sep = " ", header = T, data.table = F)
    bin <- GRanges(seqnames = state[,2],
                   ranges = IRanges(start = state[,3]+1,
                                    end = state[,4]),
                   ID = state[,1])
    chrs <- unique(state[, 2])
  }
  
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
    
    cat(ifelse(all(grepl("chr", gtf[, 1])), "", "Wrong bed file format, please check. 1st column should be the chromID, with chr prefix\n"))
    cat(ifelse(all(as.numeric(gtf[, 2])>=0), "", "Wrong bed file format, please check. 2st column should be non-negative integer\n"))
    cat(ifelse(all(as.numeric(gtf[, 3])>=0), "", "Wrong bed file format, please check. 3st column should be non-negative integer\n"))
    cat(ifelse(all(unique(gtf[, 4]) %in% c("+", "-", "*")), "", "Wrong bed file format, please check. 4st column should be the strand, '+', '-' or '*'\n"))
    
    gtf <- gtf[gtf[, 1] %in% chrs, ]
    gtf$gene_id <- paste0("Row", 1:nrow(gtf))
  }
  
  rm(chrs)
  
  # calculate the regions (filter length and get non-overlapping txs)
  if (T) {
    # get the region info
    if (T) {
      if (file_type == "gtf") {
        # get gtf info
        if (T) {
          if (location_type == "tx") {
            gtf <- transcripts(txdb, columns=c("TXNAME", "GENEID"))
            gtf$GENEID <- sapply(gtf$GENEID, c)
          } else if (location_type == "gene") {
            gtf <- genes(txdb, columns="gene_id")
          }
          
          rm(txdb)
        }
        
        # get region info
        if (T) {
          chr <- seqnames(gtf)
          start <- start(gtf)
          end <- end(gtf)
          strand <- as.vector(strand(gtf))
        }
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
      if (location_type == "tx") {
        tssID <- data.frame(TSS_ID = gtf$TXNAME[queryHits(overlapTSS)], 
                            Bin_ID = (bin$ID)[subjectHits(overlapTSS)], 
                            Strand = strand[queryHits(overlapTSS)])
        tssID$Gene_ID <- gtf$GENEID[queryHits(overlapTSS)]
      } else if (location_type == "gene") {
        tssID <- data.frame(TSS_ID = gtf$gene_id[queryHits(overlapTSS)], 
                            Bin_ID = (bin$ID)[subjectHits(overlapTSS)], 
                            Strand = strand[queryHits(overlapTSS)])
      }
      
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
      if (location_type == "tx") {
        tesID <- data.frame(TES_ID = gtf$TXNAME[queryHits(overlapTES)], 
                            Bin_ID = (bin$ID)[subjectHits(overlapTES)], 
                            Strand = strand[queryHits(overlapTES)])
        tesID$Gene_ID <- gtf$GENEID[queryHits(overlapTES)]
      } else if (location_type == "gene") {
        tesID <- data.frame(TES_ID = gtf$gene_id[queryHits(overlapTES)], 
                            Bin_ID = (bin$ID)[subjectHits(overlapTES)], 
                            Strand = strand[queryHits(overlapTES)])
      }
      
      rm(overlapTES, tes, chr, start, end, strand)
    }
    
    # get tx with tes and tss at same time
    if (T) {
      over <- intersect(tesID$TES_ID, tssID$TSS_ID)
      tssID <- tssID[match(over, tssID$TSS_ID), ]
      tesID <- tesID[match(over, tesID$TES_ID), ]
      gene_body_ID <- data.frame(tx_id = over, 
                                 tss_BinID = tssID$Bin_ID, 
                                 tes_BinID = tesID$Bin_ID, 
                                 strand = tssID$Strand)
      if (location_type == "tx") {
        gene_body_ID$gene_id <- tesID$Gene_ID
      }
      
      gene_body_ID$Len <- abs(gene_body_ID$tes_BinID - gene_body_ID$tss_BinID) + 1
      rm(over, tssID, tesID, gtf)
    }
    
    # get non-overlap tx for each gene: only tx
    if (location_type == "tx") {
      cat(paste0("Now we are going to find the non-overlapping transcriptions for downstream analysis.\n"))
      
      # prepare hello info
      if (T) {
        start_mess <- paste0("|", paste(rep("-", 100), collapse = ""), "|\n")
        cat(start_mess)
        IDs <- unique(gene_body_ID$gene_id)
        breaks <- round(seq(1, length(IDs), length.out=98))
        breaks <- IDs[breaks]
        
        cat("|*")
      }
      
      # prepare multicore environment
      if (T) {
        cl <- makeCluster(nthreads, outfile = "")
        clusterExport(cl, ls(), envir = environment())
      }
      
      # calculate the non-overlapping txs
      if (T) {
        non_overlap_txs <- parLapply(cl, IDs, function(gene_id) {
          # gene_id <- IDs[1]
          
          # print process
          if (gene_id %in% breaks) {
            cat("*")
          }
          
          # get subdat
          if (T) {
            gene_dat <- gene_body_ID[gene_body_ID$gene_id == gene_id, ]
          }
          
          tx_bins <- lapply(1:nrow(gene_dat), function(x) {
            gene_dat$tss_BinID[x] : gene_dat$tes_BinID[x]
          })
          
          gene_bins_ids <- do.call(c, tx_bins)
          bins_num_stat <- table(gene_bins_ids)
          over_bins <- as.numeric(names(bins_num_stat[bins_num_stat>1]))
          
          target_txs <- sapply(tx_bins, function(txid) {
            # txid <- tx_bins[[2]]
            tx_len <- length(txid)
            over_len <- sum(txid %in% over_bins)
            over_p <- over_len/tx_len
            
            if (over_p > overlap_cutoff) {
              return(F)
            } else {
              return(T)
            }
          })
          
          return(gene_dat$tx_id[target_txs])
        })
        cat("*|\n")
      }
      
      # end multicore environment
      if (T) {
        stopCluster(cl)
        
        rm(cl, overlap_cutoff)
      }
      
      # merge and format the data
      if (T) {
        non_overlap_txs <- do.call(c, non_overlap_txs)
      }
      
      # summary info
      if (T) {
        cat(paste0("There are ", length(non_overlap_txs), " non-overlapping transcripts for downstream analysis\n"))
        
        gene_body_ID <- gene_body_ID[gene_body_ID$tx_id %in% non_overlap_txs, ]
      }
    }
    
    # filter the gene/tx/bed based on the length
    if (T) {
      len_filter <- gene_body_ID$Len>=body_bin_num
      
      gene_body_ID <- gene_body_ID[len_filter, ]
    }
    
    # summary the info
    if (T) {
      tmp <- ifelse(location_type == "tx", "transcription", 
                    ifelse(file_type == "gtf", "gene", "genomic region"))
      
      cat(paste0("To ensure that after being divided into ", body_bin_num, 
                 " segments, each segment contains at least a independent CS label, we filter out ", tmp, "s with length <= ", 
                 body_bin_num, " bins\n"))
      cat(paste0("Removing ", sum(! len_filter), " ", tmp, "s, there are total ", sum(len_filter), " ", tmp, "s for downstream analysis\n"))
      rm(len_filter, tmp)
    }
  }
}

# change ID name 
if (T) {
  gene_body_ID$tx_id <- gsub("[_.]", "-", gene_body_ID$tx_id)
  colnames(state)[1] <- "ID"
}

# manual
if (F) {
  ## gene_body_mat[, name]:
  ##     gene_body_ID$strand == "+": 
  ##         gene_body_mat$unit>=1: 
  ##             paste0(
  ##                 pos_strand_rounding(gene_body_ID$tss_BinID + (bin_id -1) * gene_body_mat$unit), 
  ##                 "-", 
  ##                 pos_strand_rounding(gene_body_ID$tss_BinID + (bin_id) * gene_body_mat$unit - 1)
  ##             )
  ##         else: 
  ##             paste0(
  ##                 floor(gene_body_ID$tss_BinID + (bin_id -1) * gene_body_mat$unit + 1e-5), 
  ##                 "-", 
  ##                 floor(gene_body_ID$tss_BinID + (bin_id) * gene_body_mat$unit - 1e-5)
  ##             )
  ##     else: 
  ##         gene_body_mat$unit>=1: 
  ##             paste0(
  ##                 neg_strand_rounding(gene_body_ID$tes_BinID + (body_bin_num+1-(bin_id) -1) * gene_body_mat$unit + 1), 
  ##                 "-", 
  ##                 neg_strand_rounding(gene_body_ID$tes_BinID + (body_bin_num+1-(bin_id)) * gene_body_mat$unit)
  ##             )
  ##         else: 
  ##             paste0(
  ##                 floor(gene_body_ID$tes_BinID + (body_bin_num+1-(bin_id) -1) * gene_body_mat$unit + 1e-5), 
  ##                 "-", 
  ##                 floor(gene_body_ID$tes_BinID + (body_bin_num+1-(bin_id)) * gene_body_mat$unit - 1e-5)
  ##             )
}

# Tx up down matrix
if (T) {
  head(gene_body_ID)
  gene_body_mat <- data.frame(gene_id = gene_body_ID$tx_id)
  gene_body_mat$strand <- gene_body_ID$strand
  gene_body_mat$unit <- ifelse(gene_body_ID$strand %in% c("+", "*"), 
                               (gene_body_ID$tes_BinID - gene_body_ID$tss_BinID +1) / body_bin_num, 
                               (gene_body_ID$tss_BinID - gene_body_ID$tes_BinID +1) / body_bin_num)
  
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
  
  for (bin_id in 1:body_bin_num) {
    # bin_id <- 1
    name <- paste0("G", bin_id)
    print(name)
    
    gene_body_mat[, name] <- ifelse(gene_body_ID$strand == "+", 
                                    ifelse(gene_body_mat$unit>=1, 
                                           paste0(
                                             pos_strand_rounding(gene_body_ID$tss_BinID + (bin_id -1) * gene_body_mat$unit), 
                                             "-", 
                                             pos_strand_rounding(gene_body_ID$tss_BinID + (bin_id) * gene_body_mat$unit - 1)
                                           ), 
                                           paste0(
                                             floor(gene_body_ID$tss_BinID + (bin_id -1) * gene_body_mat$unit + 1e-5), 
                                             "-", 
                                             floor(gene_body_ID$tss_BinID + (bin_id) * gene_body_mat$unit - 1e-5)
                                           )), 
                                    ifelse(gene_body_mat$unit>=1, 
                                           paste0(
                                             neg_strand_rounding(gene_body_ID$tes_BinID + (body_bin_num+1-(bin_id) -1) * gene_body_mat$unit + 1), 
                                             "-", 
                                             neg_strand_rounding(gene_body_ID$tes_BinID + (body_bin_num+1-(bin_id)) * gene_body_mat$unit)
                                           ), 
                                           paste0(
                                             floor(gene_body_ID$tes_BinID + (body_bin_num+1-(bin_id) -1) * gene_body_mat$unit + 1e-5), 
                                             "-", 
                                             floor(gene_body_ID$tes_BinID + (body_bin_num+1-(bin_id)) * gene_body_mat$unit - 1e-5)
                                           )))
  }
  
  rm(bin_id, name, pos_strand_rounding, neg_strand_rounding)
}

# get state percentage matrix
if (T) {
  state_profile <- function(gene_body_mat, state, col, nthreads) {
    # prepare hello info
    if (T) {
      start_mess <- paste0("|", paste(rep("-", 100), collapse = ""), "|\n")
      cat(start_mess)
      IDs <- gene_body_mat$gene_id
      breaks <- round(seq(1, length(IDs), length.out=98))
      breaks <- IDs[breaks]
      
      cat("|*")
    }
    
    # prepare for calculation
    if (T) {
      state_order <- sort(as.numeric(unique(state[, col])))
    }
    
    # prepare multicore environment
    if (T) {
      cl <- makeCluster(nthreads, outfile = "")
      clusterExport(cl, ls(), envir = environment())
    }
    
    # calculate the non-overlapping txs
    if (T) {
      dat <- parLapply(cl, IDs, function(gene_id) {
        # gene_id <- IDs[1]
        
        # print process
        if (gene_id %in% breaks) {
          cat("*")
        }
        
        # get subdat
        if (T) {
          gene_dat <- unlist(gene_body_mat[gene_body_mat$gene_id == gene_id, ])
        }
        
        # genebody
        if (T) {
          genebody_bin <- gene_dat[grepl("^G[0-9]{1,2}$", names(gene_dat))]
          genebody <- data.frame(t(
            sapply(genebody_bin, function(gb) {
              # gb <- genebody_bin[1]
              start <- as.numeric(strsplit(gb, "-")[[1]][1])
              end <- as.numeric(strsplit(gb, "-")[[1]][2])
              s_dat <- state[start:end, col]
              
              s_p <- sapply(state_order, function(s) {
                # norm the number of bins
                sum(s_dat==s) / length(s_dat)
              })
              names(s_p) <- paste0("S", state_order)
              return(s_p)
            })
          ))
          rownames(genebody) <- paste0(gene_dat[1], "@", rownames(genebody))
        }
        
        # return result
        return(genebody)
      })
      cat("*|\n")
    }
    
    # get info for each region: percentage of each state
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
  
  for (cell in 5:ncol(state)) {
    # cell <- 5
    cellname <- colnames(state)[cell]
    tmp <- ifelse(location_type == "tx", "tx", 
                  ifelse(file_type == "bed", "bed", "gene"))
    
    file <- paste0(out_prefix, ".", tmp, "_Body_", body_bin_num, "segments_based_on_CSPercentage.", cellname, ".qs")
    rm(tmp)
    if (! file.exists(file)) {
      dat <- state_profile(gene_body_mat, state, cell, nthreads)
      qsave(dat, file, nthreads = 6)
      
      rm(dat)
    }
  }
  
  rm(gene_body_mat, bin, cell, cellname)
}

# get HITs
if (T) {
  # gene body length statistics
  if (T) {
    head(gene_body_ID)
    
    gene_body_ID$Len_type <- NA
    for (q in 1:length_leveles) {
      # q <- 1
      cutoff1 <- quantile(gene_body_ID$Len, (q-1)/10)
      cutoff2 <- quantile(gene_body_ID$Len, q/10)
      
      if (q<length_leveles) {
        gene_body_ID$Len_type <- ifelse(gene_body_ID$Len>=cutoff1 & gene_body_ID$Len<cutoff2, 
                                        paste0("Q", q), 
                                        gene_body_ID$Len_type)
      } else {
        gene_body_ID$Len_type <- ifelse(gene_body_ID$Len>=cutoff1 & gene_body_ID$Len<=cutoff2, 
                                        paste0("Q", q), 
                                        gene_body_ID$Len_type)
      }
    }
    
    rm(cutoff1, cutoff2, q)
  }
  
  # stratified random sampling based on the length: target_tx
  if (T) {
    target_tx <- data.frame()
    
    for (cell in 5:ncol(state)) {
      # cell <- 6
      cellname <- colnames(state)[cell]
      tmp <- ifelse(location_type == "tx", "tx", 
                    ifelse(file_type == "bed", "bed", "gene"))
      
      cat(paste0("Now calclulate the HITs for ", cellname, " dat:\n"))
      
      # get gene body part chromatin state percentage mat
      if (T) {
        gene_body_mat <- qread(paste0(out_prefix, ".", tmp, "_Body_", body_bin_num, "segments_based_on_CSPercentage.", cellname, ".qs"), 
                               nthreads = 6)
        rm(tmp)
      }
      
      # common value
      if (T) {
        target_tx_type <- paste0("Q", 1:length_leveles)
        all_states <- colnames(gene_body_mat)
        
        # default select 2000 genes
        n_length_state <- ceiling(
          (n_HITs/length(all_states)) / length_leveles
        )
        if (n_length_state < 1) {
          warning(paste0("The calculation setting of ", n_HITs, " HITs is too low. Under ", all_states, 
                         " chromatin states (CSs) and ", length_leveles, 
                         " body length levels, each combination averages less than 1 HIT. The calculation will proceed using 1 HIT per CS per length level."))
          
          n_length_state <- 1
        }
      }
      
      # get group specific target txs
      if (T) {
        # prepare hello info
        if (T) {
          start_mess <- paste0("|", paste(rep("-", length_leveles+2), collapse = ""), "|\n")
          cat(start_mess)
          
          cat("|*")
        }
        
        # prepare multicore environment
        if (T) {
          cl <- makeCluster(nthreads, outfile = "")
          clusterExport(cl, ls(), envir = environment())
        }
        
        # calculate the non-overlapping txs
        if (T) {
          target_tx_tmp <- parLapply(cl, target_tx_type, function(type) {
            # type <- target_tx_type[1]
            
            # print process
            if (T) {
              cat("*")
            }
            
            # filter data
            if (T) {
              subid <- gene_body_ID$tx_id[gene_body_ID$Len_type == type]
              submat <- gene_body_mat[sapply(strsplit(rownames(gene_body_mat), "@"), function(x) {x[1]}) %in% subid, ]
            }
            
            # get statistics value for all genes
            if (T) {
              stat_ids <- data.frame(t(
                sapply(subid, function(id) {
                  # id <- subid[1]
                  
                  id_mat <- submat[sapply(strsplit(rownames(submat), "@"), function(x) {x[1]}) == id, ]
                  sapply(id_mat, sum)
                })
              ))
              stat_ids$geneid <- rownames(stat_ids)
            }
            
            # for each state, get genes with most specific state percentage
            if (T) {
              target_gene <- sapply(all_states, function(stat) {
                # stat <- all_states[1]
                
                # get state specific genes
                if (T) {
                  stat_ids <- stat_ids[order(stat_ids[, stat], decreasing = T), ]
                  state_specific <- stat_ids$geneid
                }
                
                res <- head(state_specific, n_length_state)
                
                return(res)
              })
              
              if (n_length_state>1) {
                target_gene <- as.data.frame(target_gene)
              } else if (n_length_state == 1) {
                target_gene <- data.frame(matrix(target_gene, nrow = 1, dimnames = list("1", names(target_gene))))
              }
            }
            
            # format the res
            if (T) {
              target_gene <- reshape2::melt(target_gene, id.vars = NULL, measure.vars = all_states, variable.name = "State", value.name = "target_genes")
              target_gene$Cell <- cellname
              target_gene$Len <- type
            }
            
            return(target_gene)
          })
          cat("*|\n")
        }
        
        # end multicore environment
        if (T) {
          stopCluster(cl)
          
          rm(cl)
        }
        
        # format the data
        if (T) {
          target_tx_tmp <- data.frame(do.call(rbind, target_tx_tmp))
        }
      }
      
      target_tx <- rbind(target_tx, target_tx_tmp)
    }
    
    rm(target_tx_tmp, cell, cellname, gene_body_mat, target_tx_type, all_states, n_length_state, start_mess)
  }
  
  # get sampled txs and merge info
  if (T) {
    gene_body_ID <- gene_body_ID[gene_body_ID$tx %in% target_tx$target_genes, ]
    
    for (cell in unique(target_tx$Cell)) {
      genes <- target_tx[target_tx$Cell == cell, ]
      gene_body_ID[match(genes$target_genes, gene_body_ID$tx), cell] <- genes$Len
    }
    rm(cell, genes)
  }
}

# save the data
if (T) {
  to_title <- function(characters) {
    n <- nchar(characters)
    splits <- strsplit(characters, "")[[1]]
    U <- toupper(splits[1])
    L <- tolower(splits[2:n])
    L <- paste(L, collapse = "")
    title <- paste(U, L, sep = "")
    
    return(title)
  }
  
  tmp <- ifelse(location_type == "tx", "tx", 
                ifelse(file_type == "bed", "bed", "gene"))
  tmp <- to_title(tmp)
  
  file <- paste0(out_prefix, ".", n_HITs, "_Highly_Informative_", tmp, "s.qs")
  qsave(gene_body_ID, file = file, nthreads = 6)
}

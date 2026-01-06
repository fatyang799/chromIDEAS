# load the environment
if (T) {
  rm(list = ls())
  options(stringAsFactors = F)
  set.seed(799)
  suppressPackageStartupMessages(library(qs))
  suppressPackageStartupMessages(library(ggplot2))
  suppressPackageStartupMessages(library(Seurat))
  suppressPackageStartupMessages(library(clustree))
}

# get options
if (T) {
  args <- commandArgs(trailingOnly = T)
  
  # test dat 
  if (F) {
    emission <- "chromIDEAS.emission.txt"
    cell1_cs_gene <- "data/saved_data/1.chrom.tx_Body_10segments_based_on_CSPercentage.cd34.qs"
    cell2_cs_gene <- "data/saved_data/1.chrom.tx_Body_10segments_based_on_CSPercentage.thp1.qs"
    hits <- "data/saved_data/1.chrom.2000_Highly_Informative_Txs.qs"
    output_prefix <- "data/saved_data/2.csc_cluster"
    
    # 1 = cell1,
    # 2 = cell2,
    # 3 = merged,
    # 4 = all
    mode <- 3
    
    resolutions <- "0.1-0.9-0.1,1-5-0.2"
    plot_clustertree <- "T"
    
    excludeCS <- "7,15,18,19,24,25,28,30,31,36"
  }
  
  emission <- args[1]
  cell1_cs_gene <- args[2]
  cell2_cs_gene <- args[3]
  hits <- args[4]
  output_prefix <- args[5]
  
  mode <- as.numeric(args[6])
  
  resolutions <- args[7]
  plot_clustertree <- args[8]
  excludeCS <- args[9]
}

# get resolution
if (T) {
  resolutions <- as.vector(do.call(c, sapply(strsplit(resolutions, ",")[[1]], function(pat) {
    if (grepl("-", pat)) {
      x <- strsplit(pat, "-")[[1]]
      seq(as.numeric(x[1]), as.numeric(x[2]), as.numeric(x[3]))
    } else {
      as.numeric(pat)
    }
  })))
}

# get exclude states
if (excludeCS != "none") {
  excludeCS <- as.numeric(strsplit(excludeCS, ",")[[1]])
  excludeCS <- paste0("S", excludeCS)
}

# prepare the gene CS data
if (T) {
  cell_gene_dat <- function(gene_file, hit_file) {
    # gene_file <- cell1_cs_gene
    # hit_file <- hits
    
    cell <- strsplit(gene_file, "[.]")[[1]]
    cell <- cell[(length(cell)-1)]
    
    gene_body_ID <- qread(hit_file, nthreads = 6)
    target_gene_pat <- gene_body_ID$tx_id[! is.na(gene_body_ID[,cell])]
    
    # CS percentage input matrix
    gene <- qread(gene_file, nthreads = 6)
    rowname <- rownames(gene)
    rowname <- sapply(strsplit(rowname, "@"), function(x) {x[1]})
    
    torf <- rowname %in% target_gene_pat
    sum(torf)
    gene <- gene[torf, ]
    
    return(gene)
  }
  
  if (mode < 3) {
    file <- ifelse(mode == 1, cell1_cs_gene, cell2_cs_gene)
    gene <- cell_gene_dat(file, hits)
    
    cell <- strsplit(file, "[.]")[[1]]
    cell <- cell[(length(cell)-1)]
    
    rm(file)
  } else if (mode >= 3) {
    gene1 <- cell_gene_dat(cell1_cs_gene, hits)
    gene2 <- cell_gene_dat(cell2_cs_gene, hits)
    
    cell1 <- strsplit(cell1_cs_gene, "[.]")[[1]]
    cell1 <- cell1[(length(cell1)-1)]
    
    cell2 <- strsplit(cell2_cs_gene, "[.]")[[1]]
    cell2 <- cell2[(length(cell2)-1)]
    
    rownames(gene1) <- paste0(cell1, "@", rownames(gene1))
    rownames(gene2) <- paste0(cell2, "@", rownames(gene2))
    
    gene <- rbind(gene1, gene2)
  }
}

# clustering
if (T) {
  chrom_clustering <- function(gene, emission, resolutions, excludeCS, plot_clustertree, prefix) {
    # Create Seurat Object
    if (T) {
      # gene parts' percentage
      if (T) {
        # get the sorted matrix
        gene <- gene[, paste0("S", seq(min(as.numeric(gsub("S", "", colnames(gene)))), max(as.numeric(gsub("S", "", colnames(gene))))))]
        gene <- gene*1e4
        gene <- round(gene)
        gene <- log2(gene+1)
        
        if (length(excludeCS)>1 & (! "none" %in% excludeCS)) {
          gene <- gene[, !(colnames(gene) %in% excludeCS)]
        }
        
        gene <- CreateSeuratObject(counts = gene,
                                   assay = "gene",
                                   names.delim = "+",
                                   min.cells = 0, min.features = 0)
        gene@meta.data$orig.ident <- colnames(gene)
      }
      
      # emission
      if (T) {
        # read the raw data
        emission <- read.table(emission, header = T, sep = "\t")
        
        rownames(emission) <- emission[, 1]
        emission <- emission[, -c(1:2)]
        emission <- data.frame(t(emission))
        emission <- emission[, colnames(gene)]
        
        emission <- emission*1e2
        emission <- round(emission)
        emission <- log2(emission+1)
        
        emission <- CreateSeuratObject(counts = emission,
                                       assay = "emission",
                                       names.delim = "+",
                                       min.cells = 0, min.features = 0)
      }
      
      # merge the data
      if (T) {
        dat <- gene
        dat@assays$emission <- emission@assays$emission
        
        Assays(dat)
      }
    }
    
    # pre-qc for gene
    if (T) {
      DefaultAssay(dat) <- 'gene'
      
      dat[["gene"]]$data <- dat[["gene"]]$counts
      VariableFeatures(dat) <- rownames(dat[["gene"]])
      dat <- ScaleData(dat, features = rownames(dat))
      dat <- RunPCA(dat, features = VariableFeatures(dat), npcs = ncol(dat), verbose=F, approx=F)
      
      n_pc_gene <- min(dim(dat@reductions$pca))
    }
    
    # pre-qc for emission
    if (T) {
      DefaultAssay(dat) <- 'emission'
      
      dat[["emission"]]$data <- dat[["emission"]]$counts
      VariableFeatures(dat) <- rownames(dat[["emission"]])
      dat <- ScaleData(dat, features = rownames(dat))
      dat <- RunPCA(dat, features = VariableFeatures(dat), npcs = nrow(dat), reduction.name = 'apca', verbose=F, approx=F)
      
      n_pc_emission <- min(dim(dat@reductions$apca))
    }
    
    # WNN
    if (T) {
      dat <- FindMultiModalNeighbors(
        dat, 
        reduction.list = list("pca", "apca"), 
        dims.list = list(1:n_pc_gene, 1:n_pc_emission),
        k.nn = round(ncol(dat)*0.1),
        knn.range = round(ncol(dat)*0.3),
      )
    }
    
    # calculate the distance matrix
    if (T) {
      wsnn <- as.matrix(dat@graphs$wsnn)
      dists <- as.matrix(dist(wsnn, method = "euclidean"))
      dists <- as.data.frame(dists)
      dists$state <- rownames(dists)
      
      file <- paste0(prefix, ".CS_Distance.qs")
      qsave(dists, file = file, nthreads = 6)
    }
    
    # find cluster
    if (T) {
      dat <- FindClusters(dat, graph.name = "wsnn", algorithm = 3, resolution = resolutions, verbose = FALSE)
      if (plot_clustertree) {
        p <- clustree(dat@meta.data, prefix = "wsnn_res.", show_axis = T)
        ggsave(paste0(prefix, ".clustree.pdf"), width = 7, height = 10)
      }
    }
    
    # umap
    if (T) {
      dat <- RunUMAP(dat, nn.name = "weighted.nn", 
                     reduction.name = "wnn.umap", reduction.key = "wnnUMAP_")
      
      data <- data.frame(dat@reductions$wnn.umap@cell.embeddings)
    }
    
    # merge the data
    if (T) {
      dat <- dat@meta.data
      
      data <- data[dat$orig.ident, ]
      data <- cbind(dat, data)
      
      data <- data[, c("orig.ident", "gene.weight", "emission.weight", "wnnUMAP_1", "wnnUMAP_2", paste0("wsnn_res.", resolutions))]
    }
    
    return(data)
  }
  
  if (mode < 3) {
    dat <- chrom_clustering(gene, emission, resolutions, excludeCS, plot_clustertree=plot_clustertree, prefix=paste0(output_prefix, ".", cell))
    write.table(dat, file = paste0(output_prefix, ".", cell, ".cluster.csv"), quote = F, sep = ",", col.names = T, row.names = F)
  } else if (mode == 3) {
    dat <- chrom_clustering(gene, emission, resolutions, excludeCS, plot_clustertree=plot_clustertree, prefix=paste0(output_prefix, ".", "merge"))
    write.table(dat, file = paste0(output_prefix, ".", "merge", ".cluster.csv"), quote = F, sep = ",", col.names = T, row.names = F)
  } else if (mode == 4) {
    dat1 <- chrom_clustering(gene1, emission, resolutions, excludeCS, plot_clustertree=plot_clustertree, prefix=paste0(output_prefix, ".", cell1))
    write.table(dat1, file = paste0(output_prefix, ".", cell1, ".cluster.csv"), quote = F, sep = ",", col.names = T, row.names = F)
    
    dat2 <- chrom_clustering(gene2, emission, resolutions, excludeCS, plot_clustertree=plot_clustertree, prefix=paste0(output_prefix, ".", cell2))
    write.table(dat2, file = paste0(output_prefix, ".", cell2, ".cluster.csv"), quote = F, sep = ",", col.names = T, row.names = F)
    
    dat3 <- chrom_clustering(gene, emission, resolutions, excludeCS, plot_clustertree=plot_clustertree, prefix=paste0(output_prefix, ".", "merge"))
    write.table(dat3, file = paste0(output_prefix, ".", "merge", ".cluster.csv"), quote = F, sep = ",", col.names = T, row.names = F)
  }
}

# change from runme.R by fatyang

# load the environment
if (T) {
  rm(list = ls())
  options(stringAsFactors = F)
  options(scipen=1000)
}

# define some functions
if (T) {
  mystop<-function(ms, logfile){
    if(!is.null(logfile)){
      write(ms, file=logfile, append=T)
    }
    stop(ms)
  }
}

# get arguments
if (T) {
  args <-commandArgs(trailingOnly=TRUE)
  
  # default setting
  if (T) {
    # default in bash script
    if (T) {
      cap = 16
      prepmat = 0
      prenorm = 0
      signal = 5
      ideas = 1
      train = 100
      trainsz = 500000
      log2val = 0
      norm = 0
      minerr = 0.5
      smooth = 0
      burnin = 20
      mcmc = 5
      maketrack = 1
      targetURL = NULL
    }
    
    # default in R
    if (T) {
      email = NULL
      maxerr = 0
      splitstateflag = 0
      statefiles = NULL
      split = NULL
      prevstate = NULL
      mycol = NULL
      sc = NULL
      statename = NULL
      cellinfo = NULL
      matrix = NULL
    }
  }
  
  # user setting
  if (T) {
    # user related
    metadata <- args[1]
    out_dir <- args[2]
    id <- args[3]
    bed <- args[4]
    
    otherpara <- args[5]
    thread <- as.numeric(args[6])
    impute <- args[7]
    train <- as.numeric(args[8])
    trainsz <- as.numeric(args[9])
    C <- as.numeric(args[10])
    G <- as.numeric(args[11])
    minerr <- as.numeric(args[12])
    burnin <- as.numeric(args[13])
    mcmc <- as.numeric(args[14])
    track <- args[15]
    bin_root <- args[16]
  }
  
  # auto match
  if (T) {
    if (otherpara == "F") {
      otherpara = NULL
    }
    if (tolower(impute) == "none") {
      impute <- "none"
    } else if (tolower(impute) == "all") {
      impute <- "All"
    } else {
      impute <- unlist(strsplit(impute,","))
    }
    maketrack <- ifelse(track == "T", 1, 0)
  }
  
  # log file
  if (T) {
    logfile=paste0(out_dir, "/log.txt")
  }
  
  if(substring(out_dir, nchar(out_dir)) != "/") {
    out_dir = paste0(out_dir, "/",sep="")
  }
}

#add ideas to PATH
if (T) {
  path=Sys.getenv("PATH")
  ideas_path <- paste0(bin_root, "/IDEAS_2018/bin")
  path=paste(path, ideas_path, sep=":")
  Sys.setenv("PATH"=path)
  
  gsl_lib <- paste0("export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:", bin_root, "/../gsl/lib/")
  system(gsl_lib)
}

# run ideas
if(ideas){
  # info header
  if (T) {
    write("------[ IDEAS Analysis ]------", file=logfile, append=FALSE)
    write(date(), file=logfile, append=TRUE)  
  }
  
  #build the command
  if (T) {
    runideas = paste("Rscript", paste0(ideas_path, "/ideaspipe.R"), metadata, bed, "-o", paste0(out_dir, id), "-sample", burnin, mcmc, "-thread", thread)
    
    if(train>0 & trainsz>0) {
      runideas = paste(runideas, "-randstart", train, trainsz)
    }
    if(length(split)==1) {
      runideas = paste(runideas, "-split", split)
    }
    if(impute != "All") {
      runideas = paste(runideas, "-impute", impute)
    }
    if(log2val > 0) {
      runideas = paste(runideas, "-log2", log2val)
    }
    if(norm) {
      runideas = paste(runideas, "-norm")
    }
    if(smooth > 0) {
      runideas = paste(runideas, "-hp")
    }
    if(G > 0) {
      runideas = paste(runideas, "-G", G)
    }
    if(C > 0) {
      runideas = paste(runideas, "-C", C)
    }
    if(minerr > 0) {
      runideas = paste(runideas, "-minerr", minerr)
    }
    if(maxerr > 0) {
      runideas = paste(runideas, "-maxerr", maxerr)
    }
    if(cap < 100000000) {
      runideas = paste(runideas, "-cap", cap)
    }
    if(length(otherpara)>0) {
      runideas = paste(runideas, "-otherpara", otherpara)
    }
    if(length(prevstate)>0) {
      runideas = paste(runideas, "-prevrun", prevstate)
    }
    if(splitstateflag==1) {
      runideas = paste(runideas, "-splitstate")
    }
    
    runideas = paste(runideas, "-bin_root", bin_root)
    
    paste(runideas, "-logfile", logfile)
    
    #write command used to logfile
    write(runideas, file=logfile, append=TRUE)
  }
  
  #run the command
  if (T) {
    system(runideas)
  }
  
  #verify .para file exists in results
  if (T) {
    p <- paste0(out_dir, "/", id, ".para")
    if(file.exists(p)) {
      write("Done running ideas", file=logfile, append=TRUE)
    }
    if(! file.exists(p)) {
      write("Failed to generate .para file\n", file=logfile, append=TRUE)
      quit("no", 1, FALSE)
    }
  }
}

#-------------------(3) create tracks
if(maketrack){
  # info header
  if (T) {
    write("------[ Create Custom Tracks ]------", file=logfile, append=TRUE)
    write(date(), file=logfile, append=TRUE)  
  }
  
  source("bin/createGenomeTracks.R")
  if(length(statefiles)==0){
    if(length(split)==1){
      targetfile=paste(out_dir, id, '.', as.matrix(read.table(split))[,1],sep="")
    }
    if(length(split)!=1){
      targetfile=paste(out_dir, id, sep="")
    }
  }
  if(length(statefiles)!=0){
    targetfile=gsub(".state","",statefiles)
  }
  
  statefiles=paste(targetfile, ".state",sep="")
  
  #generate heatmap and get sc (state colors) for tracks
  pdf(paste(targetfile[1],".pdf",sep=""))
  sc=createHeatmap(paste(targetfile[1],".para",sep=""), scale=F, logfile=logfile, markcolor=mycol)
  dev.off()
  
  hubid=id
  genomeid=build
  genomefile=paste("./data/", build, ".genome", sep="")
  trackfolder=paste(out_dir, "Tracks/", sep="")
  
  #run defined in createGenomeTracks.R
  rt=run(statefiles, hubid, genomeid, genomefile, sc, targetURL, trackfolder,cellinfo=cellinfo, statename=statename, email=email, logfile=logfile)
  if(rt==0){
    mystop("Creation of custom tracks failed.", logfile)
  } else {
    write(paste("Tracks created successfully in ", out_dir, "Tracks/", "\n", sep=""), file=logfile, append=TRUE)
  }
  
  write(date(), file=logfile, append=TRUE)
  hubUrl=paste(out_dir, "Tracks/hub_", hubid, ".txt", sep="")
  write(paste("The hub url is ", hubUrl), file=logfile, append=TRUE)
  write(paste("A direct link to the VISION browser is http://main.genome-browser.bx.psu.edu/cgi-bin/hgTracks?db=", build, "&hubUrl=", hubUrl, "\n", sep=""), file=logfile, append=TRUE)
  write(paste("A direct link to the UCSC Genome Browser is http://genome.ucsc.edu/cgi-bin/hgTracks?db=", build, "&hubUrl=", hubUrl, "\n", sep=""), file=logfile, append=TRUE)
  donemsg=paste("IDEAS execution was successful.  Results are available with the hub URL", hubUrl)
} else{
  donemsg=paste("IDEAS execution was successful.")
}

write("Done!\n", file=logfile, append=TRUE)

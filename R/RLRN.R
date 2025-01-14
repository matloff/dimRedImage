
# RLRN routines 

# somewhat different from standard, in that we count number of
# consecutive pixels about the given threshold, rather than equal to it

######################  RLRNOneImg()  ##############################

# inputs an image in the form of a vector storing the image in row-major
# order, WITHOUT labels; does horizontal and vertical sweeps (but not
# diagonals), outputting a vector of component counts for that image

# nr and nc are the numbers of rows and cols in the image 

# arguments:

#    img: img in vector form (see above); if color, then this is the
#       concatenation of the R, G and B vectors
#    nr:  number of rows in image
#    nc:  number of cols in image
#    thresh: vector of threshold values; if negative, then [0,255] is
#       divided in equal subinternvals; see TDAsweep()
#    intervalWidth:  number of consecutive rows and columns to consolidate

# value:
#
#    vector of component counts
#
#      format:
#
#          nThresh sets of row counts, then nThresh sets of col counts
#          (nThresh = length(thresh))
#
#          finally, rowCountsEnd, colCountsEnd tacked on at the end; 
#          used by the caller, and later removed

RLRNOneImg <- function(img,nr,nc,thresh) 
{

   if (thresh[1] < 0) {
      thresh <- -thresh
      increm <- 256 / (thresh+1)
      thresh <- increm * (1:thresh)
      thresh <- thresh
   }

   rlrn <- NULL
   m <- max(nr,nc) + 1  # +1 for the 0 case

   for (threshi in thresh) {

      # replace each pixel by 1 or 0, according to whether >= 1, and
      # convert to matrix rep
      img10 <- as.integer(img >= threshi)
      img10vec <- img10
      img10 <- matrix(img10,ncol=nc,byrow=TRUE)

      eps <- findEndpointsOneImg(img10)
      # need to make sure we get a 0 count
      zeroRows <- (eps[,1] == 0 & eps[,2] == 0)
      if (sum(zeroRows) == 0) 
         eps <- rbind(eps,data.frame(start=0,end=0,rcnum=1,rc='rpw'))
      compLengths <- rep(0,nrow(eps))
      nonZero <- which(eps[,1] != 0)
      compLengths[nonZero] <- eps[nonZero,2] - eps[nonZero,1] + 1
      counts <- table(compLengths)
      rlrni <- rep(0,m)
      names(rlrni) <- 1:m
      rlrni[names(counts)] <- counts
   
      rlrn <- c(rlrn,rlrni)
      
   }

   rlrn

}

#######################  RLRNImgSet()  ############################

# imgSet is a matrix, one image stored per row

RLRNImgSet <- function(imgSet,nr,nc,thresh) 
{
   oneimg <- function(img) RLRNOneImg(img,nr,nc,thresh)
   t(apply(imgSet,1,oneimg))
}

######################  helper functions  ##############################

# getNWSEdiags(), getSWNEdiags():  these find the numbers of component
# counts in all NW-to-SE and SW-to-NE diagonals

# v is a vector of nr and nc rows and cols, stored in row-major order;
# return value is a vector with all the NW-to-SE diagonals

getNWSEdiags <- function(v,nr,nc) 
{
   m <- matrix(v,ncol=nc,byrow=TRUE)
   res <- list()
   # go through all possible starting points, first along column 1 and
   # then along row 1
   rowm <- row(m)
   colm <- col(m)
   # get ray starting at Row nr-k
   getOneNWSEdiag <- function(k) m[rowm - colm == nr-k]
   lout <- lapply(1:(nr+nc-1),getOneNWSEdiag)
   sapply(lout,findNumComps)
}

# v is a vector of nr and nc rows and cols, stored in row-major order;
# return value is a list with all the SW-to-NE diagonals
getSWNEdiags <- function(v,nr,nc) 
{
   m <- matrix(v,ncol=nc,byrow=TRUE)
   res <- list()
   # go through all possible starting points, first at row 1, col 1
   rowm <- row(m)
   colm <- col(m)
   # get ray with row + col = k
   getOneNWSEdiag <- function(k) m[rowm + colm == k]
   lout <- lapply(2:(nr+nc),getOneNWSEdiag)
   sapply(lout,findNumComps)
}

# toIntervalMeans():  if intervalWidth > 1, finds interval means

# args:

#    countVec: vector of counts from one or more rows, columns or diagonals
#    intervalWidth: as the name implies

# value:

#    vector of counts replaced by mean

toIntervalMeans <- function(countVec,intervalWidth) 
{
   # add padding if needed; 
   lcv <- length(countVec)
   extra <- intervalWidth - lcv %% intervalWidth
   if (extra > 0) countVec <- c(countVec,rep(countVec[lcv],extra))

   mat <- matrix(countVec,byrow=TRUE,ncol=intervalWidth)
   apply(mat,1,mean)
}


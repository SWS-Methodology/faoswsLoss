#' Part of the FAO Loss Module
#' 
#' @author Alicia English
#' @export MultiExp

MultiExp<- function(X, degree,depVar){
  # Allows the interaction of the varaible terms (X) to the specified degree, 
  # The function also sorts the data by the type of the variable, so that only the 
  # Numerical data (and not factors) are interacted.Necessary for the Random Forest
  # to test the specification against non-linearities in the data, though to expansive 
  # datawise for the general data set. Use for the top variables. 
  #
  # e.g. # X1^1*X2^0, X1^2*X2^1 etc. 
  # Args:
  #   X: Matrix of variables 
  #   Degree: the degree in power terms of the interaction
  # Returns: 
  #   allData
  
  keep     <- list()
  descript <- list()
  Y <- X[,depVar,with=F]
  X <- X[,!colnames(X) %in% c(depVar),with=F]
  
  # sort through the input data and take out the factors
  numsX <- sapply(X, is.numeric)
  explanatory <- names(numsX)[numsX == TRUE]
  
  NonNumer <- X[, !names(X) %in% explanatory,with=F]
  Numerical <- X[, explanatory,with=F]
  # computes the single and higher interaction of variables  
  n <- dim(Numerical)[1]
  m <- dim(Numerical)[2] 
  # out <- matrix(0, n, 1)
  interaction <- matrix(0, n, 1)
  # option for cross interactions
  for (j in 1:degree){
    if(j == 1){
      for (mm in 1:m){
        new <-Numerical[1:n,names(Numerical)[mm],with=F]*Numerical[1:n,names(Numerical)[mm],with=F]
        if(mm!= m){
          colnames(new) <- paste(colnames(Numerical)[mm], colnames(Numerical)[mm:m], sep = ".")[mm]
        }
        interaction <- cbind(interaction, new)
        if(mm == m){
          colnames(interaction)[dim(interaction)[2]] <- paste(colnames(Numerical)[m], colnames(Numerical)[m], sep = ".")
        }
      }}
    interaction <- interaction[, 2:dim(interaction)[2]]
    out <- interaction 
    if(j>= 2){
      for (mm in 1:m){
        new <- mapply(`*`,Numerical[, mm,with=FALSE],interaction)
        colnames(new) <- paste(colnames(Numerical)[mm], colnames(interaction), sep = ".")
        out <- cbind(out, new)
        #if(mm == 1){
        #  out <- out[, 1:dim(out)[2]]
        #}
        
      }
    }
  }      
  # drops duplicates 
  for (DD in 1:length(colnames(out))){
    # if(nchar(colnames(out)[DD])>3){
    # tryCatch({
    colnames(out)[DD] <- paste(sort(strsplit(colnames(out)[DD], "[.]")[[1]]), collapse = '.')
    # }, error = function(e){})}
  }
  
  drops <- out[, duplicated(colnames(out)) == FALSE,with=F]
  factorized <- cbind(Numerical, drops)
  
  allData <- cbind(Y,NonNumer, factorized) 
  return(allData)
}

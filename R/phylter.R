# Detect and filter outliers in a list of trees or distance matrices. 

#' phylter
#' 
#' Detection and filtering out of outliers in a list of trees 
#' or distance matrices.
#' 
#' @param X A list of phylogenetic trees (phylo object) or a list 
#' of distance matrices. Trees can have different number of leaves and matrices
#' can have different dimensions. If this is the case, missing values are imputed. 
#' @param bvalue If X is a list of trees, nodes with a support below 'bvalue' will be collapsed
#' prior to the outlier detection.
#' @param distance If X is a list of trees, type of distance used to compute the 
#' pairwise matrices for each tree. Can be "patristic" (sum of branch lengths separating tips, the default)
#' or nodal (number of nodes separating tips).
#' @param k Strength of outlier detection. The higher this value the less outliers
#' detected (see details).
#' @param thres For the detection of complete outliert. Threshold above which genes or species
#' are considered as complete outliers. 0.3 means that a gene (resp. species) is a
#' complete outlier if it is detected as outlier for more than 30\% of 
#' its species (resp. genes).
#' @param Norm Should the matrices be normalized. If TRUE (the default), 
#' each matrix is normalized such that its first eigenvalie is equal to one.
#' @param keep.species If TRUE, species are protected from being detected 
#' as complete outliers and filtered out. 
#' @param gene.names List of gene names used to rename elements in X. If NULL (the default), 
#' elements are named 1,2,..,length(X). 
#' @param test.island This should not be modified. If TRUE (the default), only the highest value in
#' an 'island' of outliers is considered an outlier. This prevents non-outliers hitchhiked by outliers
#' to be considered outliers themselves. 
#' @param verbose If TRUE (the default), messages are written dugont the filtering process to get information
#' of what is happening
#' @param stop.criteria The optimisation stops when the gain between round n and round n+1 is smaller
#' than this value. Default to 1e-5.
#' 
#' @return A list with the 'Initial' (before filtering) and 'Final' (after filtering) states/
phylter<-function(X, bvalue=0, distance="patristic", k=3, thres=0.3, Norm=TRUE, keep.species=TRUE, gene.names=NULL, test.island=TRUE, verbose=TRUE, stop.criteria=1e-5) {
	ReplaceValueWithCompromise<-function(allmat, what, compro) {
		for (i in 1:length(allmat)) {
			whatsp<-what[what[,1]==i,2]
			if (length(whatsp)>0) {
				allmat[[i]][whatsp,]<-compro[whatsp,]
				allmat[[i]][,whatsp]<-compro[,whatsp]
			}
		}
		return(allmat)
	}
	ReoderBackTheCells<-function(DetectedCells, OrderUsed) {
		DetectedCells$cells[,2]<-OrderUsed[DetectedCells$cells[,2]]
		if (!is.null(DetectedCells$outsp)) DetectedCells$outsp<-OrderUsed[DetectedCells$outsp]
		return(DetectedCells)
	}
	FindNewCells<-function(DetectedCells, KnownCells) {
		NewCells<-NULL
		if (is.null(KnownCells)&!is.null(DetectedCells)) NewCells<-DetectedCells
		if (!is.null(KnownCells)&is.null(DetectedCells)) NewCells<-NULL
		if (!is.null(KnownCells)&!is.null(DetectedCells)) {
			#we paste the DetectedCells at the end of KnownCells, reusing KnownCells to save memory
			KnownCells<-rbind(KnownCells, DetectedCells)
			test<-tail(duplicated(KnownCells), nrow(DetectedCells))
			NewCells<-DetectedCells[test==FALSE,,drop=FALSE]
			if (nrow(NewCells)==0) NewCells<-NULL
		}
		return(NewCells)
	}
	CompareBeforeAfter<-function(InitialMatrices, AllOutliers, sp.order) {
		cell.exists<-apply(AllOutliers, 1, function(x, sp) is.element(sp.order[x[2]],colnames(matrices[[x[1]]])), sp=sp.order)
		AllOutliers<-AllOutliers[cell.exists,]
		Out<-cbind(names(InitialMatrices[AllOutliers[,1]]), sp.order[AllOutliers[,2]])
		return(Out)
	}
	if (is.null(names(X))) X<-rename.genes(X, gene.names=gene.names)
	if (class(trees[[1]])=="phylo") {
		matrices <- trees2matrices(X, distance = distance, bvalue = bvalue)
		Xsave<-matrices
	}
	else Xsave<-X #Xsave containe the original matrices
	matrices <- impMean(matrices) ##impute missing values, if any. This also sorts rows and columns
	if (verbose) {
		print(paste("Number of Genes:    ", length(matrices), sep=""))
		print(paste("Number of Species:  ", nrow(matrices[[1]]), sep=""))
	}
	RES<-DistatisFast(matrices, Norm)
	WR<-Dist2WR(RES)
	##Store Initial State
	Initial<-NULL
	Initial$mat.data<-Xsave
	Initial$WR<-WR
	Initial$RV<-RES$RVmat
	Initial$weights<-RES$alpha
	Initial$compromise<-RES$compromise
	Initial$F<-RES$F
	Initial$PartialF<-RES$PartialF
	maxWR<-max(WR) ##for plotting purpose
	if (verbose) print(RES$quality)
	VAL<-RES$quality #First Quality value
	CELLSREMOVED<-NULL
	continue<-TRUE
	##OPTIMIZATION
	while(continue) {
		# cluster rows to be able to detect 'islands'
		OrderWRrow<-hclust(as.dist(RES$compromise))$order
		# reorder rows according to row clustering
		WR.reordered<-WR[OrderWRrow,]
		# detct outliers (complete and cell by cell)
		CellsToRemove<-detect.outliers(WR.reordered, k=k,thres=thres,test.island=test.island,keep.species=keep.species)
		# reorder to previous order
		CellsToRemove<-ReoderBackTheCells(CellsToRemove, OrderWRrow)
		NewCellsToRemove<-FindNewCells(CellsToRemove$cells, CELLSREMOVED)
		if (verbose) print(paste("   ",nrow(NewCellsToRemove)," new cells removed."))
		if (!is.null(NewCellsToRemove)) {
			CELLSREMOVED.new<-rbind(CELLSREMOVED, NewCellsToRemove) 
			matrices.new<-ReplaceValueWithCompromise(matrices, CELLSREMOVED.new, RES$compromise)
			RES.new<-DistatisFast(matrices.new, Norm)
			VAL.new<-c(VAL, RES.new$quality)
			if (verbose) print(RES.new$quality)
			if (verbose) plot(VAL, type="o")				
			gain<-VAL.new[length(VAL.new)]-VAL.new[length(VAL.new)-1]
			if (gain<0) {
				print("Gain too small (< 0). Quiting")
				continue<-FALSE #we do worse than before. We break without updating WR and RES
			}
			else {
				RES<-RES.new
				matrices<-matrices.new
				CELLSREMOVED<-CELLSREMOVED.new
				VAL<-VAL.new
				WR<-Dist2WR(RES)
				if(gain<stop.criteria) {
					print("Gain too small. Quiting")
					continue<-FALSE
				}
			}
		}
		else {
			print ("No more outlier detected")
			break
			continue<-FALSE
		}

	}
	# Prepare return object
	Final<-NULL
	Final$WR<-WR
	Final$RV<-RES$RVmat
	Final$weights<-RES$alpha
	Final$compromise<-RES$compromise
	Final$F<-RES$F
	Final$PartialF<-RES$PartialF
	Final$species.order<-colnames(RES$compromise)
	Final$AllOptiScores<-VAL
	Final$CELLSREMOVED<-CELLSREMOVED
	Final$Outliers<-CompareBeforeAfter(Xsave, CELLSREMOVED, Final$species.order)

	Result<-list(Initial=Initial, Final=Final)
	class(Result)<-"phylter"
	return(Result)
}
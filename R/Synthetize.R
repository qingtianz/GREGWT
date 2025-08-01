# Created by Esteban Munoz (emunozh@gmail.com).
#
# 04.02.2015
# last edit:
# Do  13 Aug 2015 14:17:42    AEST
# Wed 30 Mar 2016 07:22:41 PM CEST
#

#TODO: document Synthetize

#' @title Synthetize
#'
#' @description
#' Create a synthetic population based on survey weights.
#'
#' @param data_in (default = FALSE) an object of class gregwt, compute with the
#' function gregwt
#' @param X (default = FALSE) original survey, must be define if data_in is not
#' data_in object will overwrite this parameter
#' @param w (default = FALSE) output weights used to sample the survey.
#' data_in object will overwrite this parameter. If data_in = FALSE and w =
#' FALSE all weight will be set to 1.
#' @param benchmarks (default = NULL) use extra benchmarks for the creation of
#' synthetic individuals.
#' @param pop_size_input (default = FALSE) total population size. This
#' parameter will overwrite the parameter on data_in object.
#' @param method (default = c('random', 1)) define the method for creating the
#' synthetic population. (1) c('random', n) will output an array of size
#' [pop,x,n] where pop is the population size, x are the number of parameters on
#' the original survey and n are the number of random samples; (2) c('best', n)
#' will output an array of size [pop,x], this array is the 'best' fit to
#' benchmarks; (3) c('bestpop', n) similar to best bust gives more attention
#' to population totals, important if running an integrated reweight.
#' @param errormetric (default = "TAE") metric used for the computation of the
#' error term. (a) 'TAE' total absolut error (default), (b) 'Z' modified Z-Statistic
#' @param distribution (default = FALSE) FALSE = use weight as probability;
#' ones = use a vector of ones as selection probability;
#' uniform = use a random uniform distribution as selection probability.
#' @param HHsize_mean_fit (default = 1.8) mean household size.
#' @param max_iter (default = 100) maximal iterations
#' @param fit_tolerance (default = 0.1) tolerance to achieve a fit
#' @param random_seed (default = 12345) seed for random number generator,
#' needed to reproduce results.
#' @param output (default = FALSE) file to attached to the input survey.
#' @param output_log (default = FALSE) create en output log of the simulation.
#' This will create a file called Synthetic.out on the current working
#' directory.  This option will suppress the output to the command line. You
#' can process the output by calling the function logtocsv() provided by this
#' package.
#' @param weights_col (default = NULL) column name in data_in$final_weights to
#' use as sampling weights when \\code{data_in} is supplied. If \\code{NULL},
#' the first non-'id' column is used.
#' @param verbose (default = FALSE) be verbose.
#' @return result matrix of synthetic population.
#' @author M. Esteban Munoz H.
#TODO: make example Synthetize
Synthetize <- function(x, ...) UseMethod("Synthetize")

Synthetize.default <- function(
        data_in         = FALSE,
        X               = FALSE,
        w               = FALSE,
        pop_size_input  = FALSE,
        benchmarks      = NULL,
        method          = c("random", 1),
        errormetric     = "TAE",
        distribution    = FALSE,
        group           = FALSE,
        HHsize_mean_fit = 1.8,
        max_iter        = 100,
        fit_tolerance   = 0.1,
        random_seed     = 12345,
        verbose         = FALSE,
        output_log      = FALSE,
        output          = FALSE,
        weights_col     = NULL){

    if (verbose) cat("Initiated\n")
    # set the random seed to ensure reproducibility
    set.seed(random_seed)

    if (output_log){
        log_con <- file("Snthetic.log", open="a")
        sink(log_con, append=TRUE)
        sink(log_con, append=TRUE, type="message")
    }

    # which data to use
    if (is.logical(data_in)){
        if (is.logical(X)){
            survey <- X
            original_survey <- X
        }
        if (is.logical(w)){
            if (is.logical(pop_size_input)){
                pop_size_input <- dim(X)[1]
                w <- vector(length=dim(X)[1])
                w <- w + 1
            }
        } else {
            if (is.logical(pop_size_input)){
                pop_size_input <- sum(w)
            }
        }
    } else {
        #survey <- data_in$X_complete
        survey <- data_in$X
        original_survey <- data_in$survey
        nW <- dim(survey)[1]
        if (distribution == "uniform"){
            w <- runif(nW)
        }else if (distribution == "ones"){
            w <- rep(1, nW)
        } else {
            if (is.null(weights_col)) {
                weights_col <- setdiff(colnames(data_in$final_weights), "id")[1]
            }
            w <- data_in$final_weights[[weights_col]]
            if (is.nan(mean(w))) {
                w[is.nan(w)] <- 1
            } else {
                w[is.nan(w)] <- mean(w)
            }
        }
    }

    # prepare array for synthetic population
    if (!(is.logical(output))){ survey <- cbind(survey, output) }
    survey <- as.data.frame(survey)

    if (!(is.logical(pop_size_input))){
        pop_size_input <- pop_size_input
    } else if (!(is.logical(data_in$pop))){
        pop_size_input <- data_in$pop
    }

    if (pop_size_input == 0){
        cat("WARNING! no population\n")
    }

    if (is.null(benchmarks) & !(is.logical(data_in))){
        #benchmarks <- data_in$Tx_complete
        benchmarks <- data_in$Tx
        #names(benchmarks) <- data_in$constrains_complete
        names(benchmarks) <- data_in$constrains
    }

    # test method
    if ((method[1] == "best" | method[1] == "bestpop") & is.null(benchmarks)){
        stop("benchmarks have to be define to use method 'best' or methoth 'bestpop'")
    }

    # define number of samples to take from the survey
    if (length(method) == 2){
        n_samples = as.numeric(method[2])
        method_input <- method[1]
    } else {
        n_samples <- 1
        method_input <- method
    }

    # assign gloval variables
    assign("verbose",         verbose,         envir = .GlobalEnv)
    assign("survey",          survey,          envir = .GlobalEnv)
    assign("original_survey", original_survey, envir = .GlobalEnv)
    assign("w",               w,               envir = .GlobalEnv)
    assign("n_samples",       n_samples,       envir = .GlobalEnv)
    assign("pop_size_input",  pop_size_input,  envir = .GlobalEnv)
    assign("benchmarks",      benchmarks,      envir = .GlobalEnv)
    assign("method",          method_input,    envir = .GlobalEnv)
    assign("errormetric",     errormetric,     envir = .GlobalEnv)
    assign("group",           group,           envir = .GlobalEnv)
    assign("HHsize_mean_fit", HHsize_mean_fit, envir = .GlobalEnv)
    assign("max_iter",        max_iter,        envir = .GlobalEnv)
    assign("fit_tolerance",   fit_tolerance,   envir = .GlobalEnv)
    assign("output",          output,          envir = .GlobalEnv)

    if (verbose){
        cat("\n===================================="  )
        cat("\nrandom seed      = ", random_seed      )
        cat("\nn samples        = ", n_samples        )
        cat("\nsurvey size      = ", dim(survey)      )
        cat("\nweights l        = ", length(w)        )
        cat("\ntotal pop        = ", pop_size_input   )
        cat("\nmethod           = ", method           )
        cat("\nerror metric     = ", errormetric      )
        cat("\nHHsize_mean_fit  = ", HHsize_mean_fit  )
        cat("\n====================================\n")
    }

    result = FALSE
    switch(method_input,
        "random"  = {model = randomSample() },
        "fbs"     = {model = fbs()          },
        "best"    = {model = findBest()     },
        "bestpop" = {model = findBest()     }
        )

    result <- model$result
    sampled_survey <- model$sampled_survey

    if (is.logical(result)) stop("Method: <",
                                 method_input,
                                 "> not implemented")

    # set weights to 1, each record represents one unit (w_i = 1 \forall i)
    weight_index <- unlist(
        lapply(colnames(result), function(x) grepl("weight", tolower(x))))
    if (sum(weight_index) > 0){
        if (verbose) print(weight_index)
        if (verbose) cat("\n dim(mode)", dim(result), "\n")
        result[, weight_index, ] <- 1
    }
    switch(errormetric,
           "TAE" = {TAE_m <- getTAE_synth(result)},
           "Z"   = {TAE_m <- getZ_synth(result)}
           )
    cat("\t\t\t\t\t\tmethod:", format(method_input, width=10),
        "\t| itr: ", format(itr, digits=0, width=4) ,
        "| Synth. pop --> | TAE:",
        format((TAE), digits=2, scientific=T), " |\n")
    if (output_log){
        sink()
        sink(type="message")
    }
    return(list("result"=result, "sampled_survey"=sampled_survey))
}


getF <- function(x, R, substract=FALSE){
    if (substract){
        f = sum(R^2 - (R - x)^2)
    } else {
        f = sum(R^2 - (R + x)^2)
    }
    return(f)
}


fbs <- function(){
    if (verbose) cat("Using fbs method...\t")
    result <- survey
    sampled_survey <- original_survey
    # (1) make integer weights
    X <- getX()
    wo <- rep(0, length(w))
    inx <- sample(length(w), pop_size_input, replace=TRUE, prob=w)
    for (i in inx) wo[i] = wo[i] + 1
    Tx <- benchmarks

    l_FI <- Inf; l_FII <- Inf
    # Start while loop
    j <- 0
    while (l_FI > 0 | l_FII > 0){
        j <- j+1
        # (2) compute hTx with integer weights
        hTx <- colSums(X * wo, na.rm=TRUE)
        TAE_sq = sum(abs(Tx - hTx))
        # (3) compute R
        R <- Tx - hTx
        if (verbose) cat("\n|--> fbp loop ", j,
                         "\tR:", sum(R^2),
                         "\tTAE: ", TAE_sq)
        # (4) compute FI and FII
        FII <- apply(X, 1, getF, R=R)
        #X_sim <- X[inx,]
        FI <- apply(X, 1, getF, R=R, substract=TRUE)
        l_FI  <- sum(FI > 0)
        l_FII <- sum(FII > 0)
        if (verbose) cat("\n\t|--> length(FI): ", l_FI,
                         "\tlength(FII): ", l_FII)
        # (5) swap individuals on w
        wo_temp <- wo
        if (l_FI  > 0 & l_FII  > 0){
            if (verbose) cat("\n\t\t|--> swap")
            wo_temp[which(FI  == max(FI) )] <- wo_temp[which(FI  == max(FI) )] - 1
            wo_temp[which(FII == max(FII))] <- wo_temp[which(FII == max(FII))] + 1
            TAE_temp <- sum(abs(Tx - colSums(X * wo_temp, na.rm=TRUE)))
            R_temp <- Tx - colSums(X * wo_temp, na.rm=TRUE)
            if (verbose) cat("\tR: ", sum(R_temp^2), "\tTAE: ", TAE_temp)
        } else if (l_FI <= 0 & l_FII  > 0){
            if (verbose) cat("\n\t\t|--> random swap")
            random_inx <- sampleW(FI)
            wo_temp[random_inx] <- wo_temp[random_inx] - 1
            wo_temp[which(FII == max(FII))] <- wo_temp[which(FII == max(FII))] + 1
            TAE_temp <- sum(abs(Tx - colSums(X * wo_temp, na.rm=TRUE)))
            R_temp <- Tx - colSums(X * wo_temp, na.rm=TRUE)
            if (verbose) cat("\tR: ", sum(R_temp^2), "\tTAE: ", TAE_temp)
        } else if (l_FII <= 0){
            if (verbose) cat("\n\t\t|--> no swap END")
            TAE_temp <- sum(abs(Tx - colSums(X * wo_temp, na.rm=TRUE)))
            R_temp <- Tx - colSums(X * wo_temp, na.rm=TRUE)
            if (verbose) cat("\tR: ", sum(R_temp^2), "\tTAE: ", TAE_temp)
            break
        }
        # (6) accept of reject change
        if (TAE_temp < TAE_sq | sum(R_temp^2) < sum(R^2)){
            wo <- wo_temp
            TAE_sq <- TAE_temp
            R <- R_temp
        } else {
            break
        }
    } # end while loop
    result <- cbind(result, wo)
    sampled_survey <- cbind(sampled_survey, wo)
    result <- result[which(wo >= 1), ]
    sampled_survey <- sampled_survey[which(wo >= 1), ]
    assign("itr", j, envir = .GlobalEnv)
    if (verbose) cat("OK\n")
    return(list("result"=result, "sampled_survey"=sampled_survey))
}


sampleW <- function(x) {
  if (length(x) == 1) {
    return(x)
  } else {
    return(sample(x,1))
  }
}


getFittValues <- function(Tx, X, w){
    hTx <- colSums(X * w, na.rm=TRUE)
    R <- Tx - hTx
    FI <- R^2 - (R - X)^2
}


randomSample <- function(){
    if (verbose) cat("\nMake random sample...")
    result <- prepareResult()
    original_sur <- array(NaN, dim=c(pop_size_input, ncol(original_survey), n_samples))
    for (i in seq(1, n_samples)) {
        if (verbose) cat("\n\t|--> sample ", i, "/", n_samples)
        index_survey <- sample(nrow(survey), pop_size_input, replace=TRUE, prob=w)
        original_sur[,,i] <- as.matrix(original_survey[index_survey, ])
        synthetic_pop <- survey[index_survey, ]
        result[,,i] <- as.matrix(synthetic_pop)
        if (verbose) cat("\tOK")
    }
    assign("itr", n_samples, envir = .GlobalEnv)
    return(list("result"=result, "sampled_survey"=original_sur))
}


prepareResult <- function(){
    # create the result array
    if (verbose) cat("\n\t|--> Prepare result...\t")
    result=array(NaN, dim=c(pop_size_input, dim(survey)[2], n_samples))
    dimnames(result) <- list(NULL,colnames(survey),NULL)

    # if grouped
    if (class(group) == "character"){
        if (verbose) cat("\ngrouped data\n")
        result <- unGroupData(result)
    }
    if (verbose) cat("OK\t")
    return(result)
}


#TODO: fix grouped data
unGroupData <- function(result){
    X_g    <- data.frame(HHid  =survey[, group],
                         HHsize=(vector(length=dim(survey)[1])+1))
    X_g    <- aggregate(X_g, by=list(survey[, group]), FUN=sum)
    X_g    <- X_g[names(X_g) != group]

    wx_g   <- aggregate(w, by=list(survey[, group]), FUN=mean)
    wx_g   <- as.matrix(wx_g)
    wx_g   <- as.numeric(wx_g[, "x"])
    mean_w <- mean(wx_g)

    pop_size_sel = pop_size_input / HHsize_mean_fit

    for (i in seq(1, n_samples)){
        HHsize_mean_sel = 0
        HHsize_sum_sel  = 0
        HHsize_delta    = Inf
        Popsize_delta   = Inf
        iter.num        = 0
        while(!(HHsize_mean_fit < HHsize_mean_sel + fit_tolerance  &
                HHsize_mean_fit > HHsize_mean_sel - fit_tolerance) |
                pop_size_input != HHsize_sum_sel
                ){
            if (iter.num == max_iter) break
            iter.num = iter.num + 1
            pop_index <- sample(
                nrow(X_g), pop_size_sel, replace=TRUE, prob=wx_g)
            pop_sel_temp <- X_g[pop_index, ]
            HHsize_mean_sel_temp <- mean(pop_sel_temp$HHsize, nan.rm=TRUE)
            if (verbose) cat("household size: ", HHsize_mean_sel_temp, "\n")
            HHsize_sum_sel_temp <- sum(pop_sel_temp$HHsize)
            if ((abs(HHsize_mean_sel_temp - HHsize_mean_fit) < HHsize_delta) &&
                (abs(HHsize_sum_sel_temp  - pop_size_input)  < Popsize_delta)){
                 HHsize_mean_sel <- HHsize_mean_sel_temp
                 HHsize_delta <- abs(HHsize_mean_sel - HHsize_mean_fit)
                 HHsize_sum_sel <- HHsize_sum_sel_temp
                 Popsize_delta <- abs(HHsize_sum_sel - pop_size_input)
                 pop_sel <- pop_sel_temp
            } else {
                if (HHsize_mean_sel > HHsize_mean_fit){
                    this_index = X_g$HHsize <= HHsize_mean_fit
                } else {
                    this_index = X_g$HHsize >= HHsize_mean_fit
                }
                wx_g[this_index] <- wx_g[this_index] + mean_w
            }
        }

        synthetic_pop <- data.frame(matrix(NA, nrow=0, ncol=dim(survey)[2]))
        names(synthetic_pop) <- names(survey)

        p <- pop_sel$Group.1
        for(j in seq(length(p))){
            spp <- survey[which(survey[,group] == p[j]), ]
            spp[group] <- j
            synthetic_pop <- rbind(synthetic_pop, spp)}

        if(dim(result)[1] != dim(synthetic_pop)[1]){
            cat("WARNING!! expected pop = ", dim(result)[1],
                "\tsynthetic pop = ", dim(synthetic_pop)[1])
            if (verbose) cat("people!\t got:", dim(synthetic_pop)[1])
            if (verbose) cat(" want:", dim(result)[1],"\n")
            synthetic_pop <- fillPop(synthetic_pop, dim(result)[1])
        }

        result[,,i] <- as.matrix(synthetic_pop)
    }
    if (verbose) cat("OK\n")
    return(result)
}


fillPop <- function(synthetic.pop, expected.dim){
    gap <- expected.dim - dim(synthetic.pop)[1]
    #cat("I have a gap of:", gap)
    if (gap>=1) {
        #cat(" adding",gap,"individuals\n")
        fill <- vector(length=(dim(synthetic.pop)[2]))
        fill[] <- NaN
        for(i in seq(1,abs(gap))){
            synthetic.pop <- rbind(synthetic.pop, fill)
        }
    } else {
        to.index <- dim(synthetic.pop)[1]+gap
        #cat(" to index:", to.index,"\n")
        synthetic.pop <- synthetic.pop[1:to.index,]
    }
    return(synthetic.pop)
}


findBest <- function(){
    model <- randomSample()
    result <- model$result
    sampled_survey <- model$sampled_survey
    switch(errormetric,
           "TAE" = {TAE_m <- getTAE_synth(result)},
           "Z"   = {TAE_m <- getZ_synth(result)}
           )
    # get the min TAE index
    TAE_index <- which(TAE_m == min(TAE_m))

    if (pop_size_input){
        # Resulting sample, count people
        if (dim(result)[1]==1){
            # If there is a single person in the sample
            rs = sum(!is.nan(result[,1,1]))
        } else {
            rs <- rowSums(!is.nan(aperm(result[,1,])))
        }
        # population difference
        diff_pop <- abs(rs - pop_size_input)
        # select the best sample based on TAE difference and total population
        # difference
        diff_both <- TAE_m + diff_pop
        result_index <- which(diff_both == min(diff_both))
    } else {
        result_index <- TAE_index
    }
    return(list("result"=result[,,result_index[1]],
                "sampled_survey"=sampled_survey[,,result_index[1]]))
}


getX <- function(){
    if (verbose) cat("\nPrepare survey data...")
    bench_names <- names(benchmarks)
    survey_names <- dimnames(survey)[[2]]
    index <- sapply(survey_names, "%in%", bench_names)
    X <- survey[, index]
}


getTx <- function(result){
    # select only columns to benchmarks to
    if (verbose) cat(" getTh")
    bench_names <- names(benchmarks)
    result_name <- dimnames(result)[[2]]
    index <- sapply(result_name, "%in%", bench_names)
    if (length(dim(result)) == 3){
        c_sums <- result[, index, ]
    } else {
        c_sums <- result[, index]
    }

    # get the sample marginal totals for the computation of TAE
    if (length(dim(result)) == 3){
        if (dim(result)[3] > 1) single_iter <- FALSE
        else single_iter <- TRUE
    } else single_iter <- TRUE
    if (dim(result)[1]==1 | single_iter==TRUE){
        # If there is a single person in the sample
        # or a single iteration
        TAE_sample <- sum(colSums(c_sums, na.rm=TRUE))
    } else {
        TAE_sample <- colSums(colSums(c_sums, na.rm=TRUE))
    }
    return(TAE_sample)
}


getTAE_synth <- function(result){
    TAE_sample <- getTx(result)
    # get the marginal totals from the benchmarks for the computation of the
    # TAE
    TAE_benchm <- sum(benchmarks)
    # compute the TAE
    TAE_m <- abs(TAE_sample - TAE_benchm)

    assign("TAE", min(TAE_m), envir = .GlobalEnv)
    return(TAE_m)
}


getZ_synth <- function(result){
    Tx <- getTx(result)
    hTx <- sum(benchmarks)
    z <- Z(Tx, hTx)
    return(z)
}


Z <- function(Tx, hTx){
    r <- hTx/sum(hTx)
    p <- Tx/sum(Tx)
    Z <- (r-p)/sqrt(p*(1-p)/sum(Tx))
    return(Z)
}

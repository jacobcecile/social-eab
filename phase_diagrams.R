# Libraries ####

library(plyr)


# Determining phase ####

# Determining phase of EAB models
phase_eab <- function(state, infection_threshold=1e-5){
  
  # Extract info on the infection at the end of the simulation
  last_state <- state[nrow(state), ]
  
  infected_id <- substr(names(state), 1, 1)=="I"
  infected_list <- last_state[infected_id] 
    
  # Count how many patches are infested
  num_infected <- sum(infected_list>=infection_threshold)
    
  if (num_infected==1){
    return ("Contained")
  } else if (num_infected==2){
    return ("Spread")
  } else {
    return (num_infected)
  }  
  
}


# Setting up search space ####

# Generate a grid of points to examine within the search space
search_p_grid <- function (search_space, nlevels=10){
  
  # The grid lines are evenly spaced along the range (inclusive)
  grid_lines <- as.data.frame(mapply(seq, from=search_space[1,], to=search_space[2,], length.out=nlevels))
  
  # Select a point of the search space at each intersection of these lines
  search_points <- expand.grid(grid_lines)
  
  return (search_points)
}

# Generate points to examine within the search space at random
search_p_runif <- function(search_space, npoints=100){
  search_points <- mapply(runif, min=search_space[1,], max=search_space[2,], n=npoints)
  
  return (search_points)
}

# Select points to examine within the search space
search_p <- function (search_space, npoints=100, method="grid"){
  if (method=="grid"){
    nlevels <- round (npoints^(1/ncol(search_space)))
    search_points <- search_p_grid(search_space, nlevels)
  }
  if (method=="runif"){
    search_points <- search_p_runif(search_space, npoints)
  }
  return (search_points)
}

# Pointwise searching ####

# Pointwise search of phase-space
phase_search_points <- function (search_points, phase_func, static_parm, initial_df, times=seq(from=0, to=10, by=0.1), factory, min_rates="auto", max_tries=1){
 
  param_df <- merge(search_points, static_parm)
  
  # data.frame for storing phase results
  phase_df <- param_df
  phase_df$phase <- NA
  
  for (i in 1:nrow(param_df)){
    
    print (paste0("Run number ", i, " of ", nrow(param_df)))
    
    # Extract the relevant parameter settings
    param <- param_df [i, ]
    
    # Run the model with the unique parameter setting
    args <- c(list(initial_df=initial_df, times=times, factory=factory, min_rates=min_rates, max_tries=max_tries), unlist(param))
    
    # Using do.call
    # state <-  do.call(sim, args)$state
    
    # Alternate approach using splat
    state <- splat(sim)(args)$state
    
    # Check the phase
    phase <- phase_func(state)
    
    # Updata the phase data.frame
    phase_df[i, "phase"] <- phase
  }
  
  return (phase_df)
  
}


# Plotting ####

# Simple geom_point plots of phase

plot_phase_points <- function (phase_df, xval=1, yval=2){
  ggplot(phase_df, aes(x=phase_df[[xval]], y=phase_df[[xval]], colour=phase))+geom_point()+theme_bw()
}

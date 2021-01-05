# Kate Schneider
# kate.schneider@tufts.edu
# Replication files for Kate Schneider 2021 PhD Thesis
# Last modified: 5 Jan 2020
# Purpose: Linear programming to calculate shared household least-cost diets and shadow prices
          # with revised nutrient requirements (only members 4 and above define shared nutrient requirements)

# Clear
rm(list=ls())

# Set working directory
setwd("yourfilepath")
getwd()
.libPaths("yourfilepath")

# Install relevant packages
install.packages("lpSolve", lib = ("yourlibrary"))
install.packages("foreign", lib = ("yourlibrary"))
install.packages("haven", lib = ("yourlibrary")) 
library(foreign)
library(haven)
library(lpSolve)

#### PART A #### LINEAR PROGRAMMING FOR SHARING SCENARIO CONSTRAINTS
# Import dataset
mydataHH <- read_dta("HH+CPI_LPInput_sharing_r.dta")

# Create a result matrix
result <- matrix(0,572516,51)

  # Run linear programming for CoNA
  for (i in 1:572516){
    temp <- mydataHH[(36*i-35):(36*i),12:64]
    f.obj <- t(temp[1,1:51])
    f.con <- temp[2:36,1:51]
    f.dir <- t(temp[2:36,52])
    f.rhs <- t(temp[2:36,53]) 
    temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
    result[i,] <- temp_out
  }
  
  # Export back to Stata
  write.csv(result,file="HH_LPResults_sharing_r.csv")

  #### PART B #### LINEAR PROGRAMMING FOR SHARING SCENARIO SHADOW PRICES
  
  # Import dataset
  mydataHH <- read_dta("HH+CPI_LPInput_sharing_r.dta")
  
  # Recover the shadow prices through the dual solution
  # The dual solution solves the corrollary maximization problem to the objective function
  # There are duals for each of the 34 constraints (not the price, which is the objective function) 
  # These are the first 34 columns returned in the duals results 
  # There are also duals for the 51 variables (food items)
  # We do not have any interest in these variable duals so we get rid of them
  results_duals <- matrix(0,572516,86)
  
  for (i in 1:572516){
    temp <- mydataHH[(36*i-35):(36*i),12:64]
    f.obj <- t(temp[1,1:51])
    f.con <- temp[2:36,1:51]
    f.dir <- t(temp[2:36,52])
    f.rhs <- t(temp[2:36,53]) 
    temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs, compute.sens=TRUE)$duals # Duals option will return the dual solution
    # print(length(temp_out)) # To understand the size of the matrix = 86 = 35 constraints + 51 foods
    results_duals[i,] <- temp_out 
  }
  
  results_SP <- results_duals[, 1:35] # Take only the shadow prices from the constraints (first 35 columns)
  # Export the data
  write.csv(results_SP,file="HH_Shadowprices_sharing_r.csv")
  

# Kate Schneider
# kate.schneider@tufts.edu
# Replication files for Kate Schneider 2021 PhD Thesis
# Last modified: 5 Jan 2020
# Purpose: Linear programming to calculate shared household least-cost diets and shadow prices

# THIS DO FILE IS FOR ARCHIVE PURPOSES ONLY #
  # THIS DO FILE WAS NOT USED TO CALCULATE LEAST COST DIETS IN MY PHD THESIS #
  # ONLY THE REVISED NUTRIENT REQUIREMENTS WERE USED IN MY THESIS FOR THE 
  #     PAPERS INCORPORATING LEAST-COST DIETS #
  
#  NOTE: This analysis requires substantial computing power. It will need days to
    # run on a standard desktop. Use of a supercomputer (e.g. high powered cluster)
    # is necessary.


# Clear
rm(list=ls())

# Set working directory
setwd("yourfilepath")
getwd()
.libPaths("/cluster/tufts/masterslab/kschne02/myR")

# Install relevant packages
install.packages("lpSolve", lib = ("yourlibrary"))
install.packages("foreign", lib = ("yourlibrary"))
install.packages("haven", lib = ("yourlibrary")) 
library(foreign)
library(haven)
library(lpSolve)

#### PART 1 #### LINEAR PROGRAMMING FOR SHARING SCENARIO CONSTRAINTS
# Import dataset
mydataHH <- read_dta("HH+CPI_LPInput_sharing.dta")

# Create a result matrix
result <- matrix(0,572516,51)

  # Run linear programming for CoNA
  for (i in 1:572516){
    temp <- mydataHH[(35*i-34):(35*i),11:63]
    f.obj <- t(temp[1,1:51])
    f.con <- temp[2:35,1:51]
    f.dir <- t(temp[2:35,52])
    f.rhs <- t(temp[2:35,53]) 
    temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
    result[i,] <- temp_out
  }
  
  # Export back to Stata
  write.csv(result,file="HH_LPResults_sharing.csv")

  # Recover the shadow prices through the dual solution
  # The dual solution solves the corrollary maximization problem to the objective function
  # There are duals for each of the 34 constraints (not the price, which is the objective function) 
  # These are the first 34 columns returned in the duals results 
  # There are also duals for the 51 variables (food items)
  # We do not have any interest in these variable duals so we get rid of them
  results_duals <- matrix(0,572516,85)
  
  for (i in 1:572516){
    temp <- mydataHH[(35*i-34):(35*i),11:63]
    f.obj <- t(temp[1,1:51])
    f.con <- temp[2:35,1:51]
    f.dir <- t(temp[2:35,52])
    f.rhs <- t(temp[2:35,53]) 
    temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs, compute.sens=TRUE)$duals # Duals option will return the dual solution
    # print(length(temp_out)) # To understand the size of the matrix = 85 = 34 constraints + 51 foods
    results_duals[i,] <- temp_out 
  }
  
  results_SP <- results_duals[, 1:34] # Take only the shadow prices from the constraints (first 34 columns)
  colnames(results_SP) <- c("energy_eer", "carbohydrates_amdr_lower", "carbohydrates_amdr_upper", "protein_ear", "protein_amdr_lower", "protein_amdr_upper","lipid_amdr_lower","lipid_amdr_upper","vitA_ear","retinol_ul","vitC_ear","vitC_ul","vitE","thiamin","riboflavin", "niacin", "b6_ear", "b6_ul", "folate", "b12", "calcium_ear", "calcium_ul", "copper_ear", "copper_ul", "iron_ear", "iron_ul", "magnesium", "phosphorus_ear", "phosphorus_ul", "selenium_ear", "selenium_ul", "zinc_ear", "zinc_ul", "sodium_ul")
  # Export the data
  write.csv(results_SP,file="HH_Shadowprices_sharing.csv")
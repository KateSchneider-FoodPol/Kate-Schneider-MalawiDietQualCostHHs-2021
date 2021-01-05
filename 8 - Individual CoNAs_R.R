# Kate Schneider
# kate.schneider@tufts.edu
# Replication files for Kate Schneider 2021 PhD Thesis
# Last modified: 3 Jan 2020
# Purpose: Linear programming to calculate individual least-cost diets

# Clear
rm(list=ls())

# Set working directory
setwd("yourfilepath")

# Install relevant packages
install.packages("lpSolve")
install.packages("foreign")
install.packages("haven")

library(foreign)
library(haven)
library(lpSolve)

# Groups with 36 line nutrient requirements (all but infants 6-12 months)
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult.csv")

# Infants 6-12 months who have a 10 line loop (age-sex group 2)
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput2.dta")
# Create a result matrix
result <- matrix(0,3683,51)

# Run linear programming by a loop
for (i in 1:3048){
  temp <- mydata[(10*i-9):(10*i),7:59]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:9,1:51]
  f.dir <- t(temp[2:9,52])
  f.rhs <- t(temp[2:9,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult2.csv")

###########Sensitivity testing for group 3
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_g3_test.dta")
# Create a result matrix
result <- matrix(0,3683,51)

# Run linear programming by a loop
for (i in 1:3683){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNA_LPResult_g3.csv")

###########Sensitivity testing for all groups, per nutrient with an upper bound
# Nutrient 3
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax325pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax325pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax350pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax350pct.csv")

# Nutrient 4
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax425pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax425pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax450pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax450pct.csv")

# Nutrient 5
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax525pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax525pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax550pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax550pct.csv")

# Nutrient 7
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax725pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax725pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax750pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax750pct.csv")

# Nutrient 8
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax825pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax825pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax850pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax850pct.csv")

# Nutrient 13
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax1325pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax1325pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax1350pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax1350pct.csv")

# Nutrient 16
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax1625pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax1625pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax1650pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax1650pct.csv")

# Nutrient 17
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax1725pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax1725pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax1750pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax1750pct.csv")

# Nutrient 20
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax2025pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax2025pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax2050pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax2050pct.csv")


# Nutrient 21
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax2125pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax2125pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax2150pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax2150pct.csv")


# Nutrient 22
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax2225pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax2225pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax2250pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax2250pct.csv")


# Nutrient 23
rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax2325pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax2325pct.csv")

rm(list=ls())
# Import dataset
mydata <- read_dta("iCoNA_LPInput_relax2350pct.dta")
# Create a result matrix
result <- matrix(0,88392,51)

# Run linear programming by a loop
for (i in 1:88392){
  temp <- mydata[(36*i-35):(36*i),8:60]
  f.obj <- t(temp[1,1:51])
  f.con <- temp[2:36,1:51]
  f.dir <- t(temp[2:36,52])
  f.rhs <- t(temp[2:36,53]) 
  temp_out <- lp ("min", f.obj, f.con, f.dir, f.rhs)$solution
  result[i,] <- temp_out
}
write.csv(result,file="iCoNALPResult_relax2350pct.csv")




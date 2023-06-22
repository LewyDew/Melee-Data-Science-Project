library(feather)
library(tidyverse)
library(ggplot2)
library(rpart.plot)
library(dplyr)
library(randomForest)
library(h2o)

localH2O <- h2o.init(nthreads = -1)
h2o.removeAll()

set.seed(1234)
df <- read_feather("game10.feather")
#Remove all the na only columns
Filter(function(x)!all(is.na(x)), df)


#Set button, character and state based fields as factors.
df$stage <- droplevels(as.factor(df$stage))
df$p1_character <- droplevels(as.factor(df$p1_character))
df$p1_buttons <- droplevels(as.factor(df$p1_buttons))
df$p1_state <- droplevels(as.factor(df$p1_state))
df$p1_last_hit_by <- droplevels(as.factor(df$p1_last_hit_by))
df$p1_last_landed <- droplevels(as.factor(df$p1_last_landed))
df$p1_direction <- droplevels(as.factor(df$p1_direction))
df$p2_character <- droplevels(as.factor(df$p2_character))
#df$p2_buttons <- droplevels(as.factor(df$p2_buttons))
df$p2_state <- droplevels(as.factor(df$p2_state))
df$p2_last_hit_by <- droplevels(as.factor(df$p2_last_hit_by))
df$p2_last_landed <- droplevels(as.factor(df$p2_last_landed))
df$p2_direction <- droplevels(as.factor(df$p2_direction))

#discretize contiunuous values of anolog inputs
#may need to do some more precise cuts into the zones that cause turnarounds, smashes, shielddrops, and other techniques. Ask kadano or practicalTas?
#Until I hear back from them I'm splitting by .05
df$p1_cstick_x <- cut(df$p1_cstick_x, breaks = 40)
df$p1_cstick_y <- cut(df$p1_cstick_y, breaks = 40)
df$p1_joystick_x <- cut(df$p1_joystick_x, breaks = 40)
df$p1_joystick_y <- cut(df$p1_joystick_y, breaks = 40)
df$p1_triggers <- cut(df$p1_triggers, breaks = 40)


#round to nearest whole value for position on stage and damage/shield
df$p1_position_x <- round(df$p1_position_x, digits = 0)
df$p1_position_y <- round(df$p1_position_y, digits = 0)

df$p1_damage <- round(df$p1_damage, digits = 0)
df$p1_shield <- round(df$p1_shield, digits = 0)


#Dropping seed for now because it is hard to discretize and only affects peach and ?fod?. Fod data is accounted for through x y player positions while on plats?
#will loose important data for playing around rare turnips
df$p1_seed <- NULL
df$p2_seed <- NULL
col.nums <- c(4, 5, 7, 8, 9, 12, 21, 22, 24, 25, 27, 28, 29, 32)
df[col.nums] <- sapply(df[col.nums], as.integer)

#creating n for a couple of operations that recquire number of rows
n <- nrow(df)
#adding collumns for checking next inputs
df["next_button_p1"] <- lead(df$p1_buttons)
df["next_joystick_y"] <- lead(df$p1_joystick_y)
df["next_joystick_x"] <- lead(df$p1_joystick_x)
df["next_cstick_y"] <- lead(df$p1_cstick_y)
df["next_cstick_x"] <- lead(df$p1_cstick_x)
df["next_triggers"] <- lead(df$p1_triggers)

#Decided I'll drop all the second players inputs as I'm only training one player at once and players don't normally look at eachothers controllers
#Also droping p2 direction as it was the lowest importancy
df$p2_cstick_x <- NULL #29th column
df$p2_cstick_y <- NULL
df$p2_joystick_x <- NULL
df$p2_joystick_y <- NULL
df$p2_triggers <- NULL
df$p2_buttons <- NULL
df$p2_direction <- NULL

#create sample and training set

df <- as.h2o(df)
splits <- h2o.splitFrame(
  df, ##  splitting the H2O frame we read above
  c(0.6, 0.2), ##  create splits of 60% and 20%; 
##  H2O will create one more split of 1-(sum of these parameters)
##  so we will get 0.6 / 0.2 / 1 - (0.6+0.2) = 0.6/0.2/0.2
  seed = 1234) ##  setting a seed will ensure reproducible results (not R's seed)

train <- h2o.assign(splits[[1]], "train.hex")
## assign the first result the R variable train
## and the H2O name train.hex
valid <- h2o.assign(splits[[2]], "valid.hex") ## R valid, H2O valid.hex
test <- h2o.assign(splits[[3]], "test.hex") ## R test, H2O test.hex
#Create models (target indexes 12 , 13 14 15 16 17 , 36 , 27

rf1 <- h2o.randomForest(## h2o.randomForest function
  training_frame = train, ## the H2O frame for training
  validation_frame = valid, ## the H2O frame for validation (not required)
  x = 1:28, ## the predictor columns, by column index
  y = 29, ## the target index (what we are predicting)
  model_id = "rf_covType_v1", ## name the model in H2O
##   not required, but helps use Flow
  ntrees = 200, ## use a maximum of 200 trees to create the
##  random forest model. The default is 50.
##  I have increased it because I will let 
##  the early stopping criteria decide when
##  the random forest is sufficiently accurate
  stopping_rounds = 2, ## Stop fitting new trees when the 2-tree
##  average is within 0.001 (default) of 
##  the prior two 2-tree averages.
##  Can be thought of as a convergence setting
  score_each_iteration = T, ## Predict against training and validation for
##  each tree. Default will skip several.
  seed = 1000000) ## Set the random seed so that this can be
##  reproduced.
###############################################################################
summary(rf1) ## View information about the model.
## Keys to look for are validation performance
##  and variable importance

rf1@model$validation_metrics ## A more direct way to access the validation 
##  metrics. Performance metrics depend on 
##  the type of model being built. With a
##  multinomial classification, we will primarily
##  look at the confusion matrix, and overall
##  accuracy via hit_ratio @ k=1.
h2o.hit_ratio_table(rf1, valid = T)[1, 2]
## Even more directly, the hit_ratio @ k=1
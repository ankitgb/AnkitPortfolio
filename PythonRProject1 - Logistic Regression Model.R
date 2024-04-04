data <- read.csv("C:/covid_dataset_final_3_6_24.csv", header=TRUE, stringsAsFactors=TRUE)

data <- subset(data, select = -c(cases, month, year, Year))

encoded_data <- cbind(data, model.matrix(~0 + region, data = data))
data <- encoded_data
# Remove the original 'region' column
encoded_data <- subset(encoded_data, select = -c(region, state))


data$time <- data$num_months+1
Survival <- survfit(Surv(time,death_event)~1,data=data)
Survival.Region <- survfit(Surv(time,death_event)~region,data=data)




##############################################################################
##############################################################################
##############################################################################
##############################################################################
########################### Logistic Regression ###############################
##############################################################################
##############################################################################
##############################################################################
##############################################################################

{r}
# Assuming df_modeling is your data frame
library(randomForest)

# Separate predictors (X) and response variable (y)
X <- encoded_data[, !names(encoded_data) %in% c('death_event')]
y <- encoded_data$death_event

# Define the method
rf_model <- randomForest(x = X, y = as.factor(y), ntree = 12, importance = TRUE)

# Get feature importance
importance <- importance(rf_model)

# Get the indices of the top 10 features
selected_features_indices <- order(importance[, 1], decreasing = TRUE)[1:10]

# Get the names of the selected features
selected_features <- names(importance[selected_features_indices, 1])

# Create a table with the selected features
table <- data.frame(Selected_Features = selected_features)

# Displaying the table with kable
kable(table, format = "markdown", col.names = c("Selected Features"), align = "c")




{r}
# Assuming df_modeling is your data frame
library(corrplot)
# Assuming 'data' is your dataset
# Check correlation matrix
corr <- cor(encoded_data)

# Sort correlation with 'death_event' in descending order
corr_death_event <- sort(corr[,'death_event'], decreasing = TRUE)

# Select the top 10 correlated variables
top_10_corr_vars <- names(corr_death_event[2:11])

# Create a table with the top 10 correlated variables
table_top_10_corr <- data.frame(Variable = top_10_corr_vars, Correlation = corr_death_event[top_10_corr_vars])

# Display the table
knitr::kable(table_top_10_corr, format = "markdown", row.names = FALSE)



{r}

# Set a random seed for reproducibility
set.seed(123)

# Split the data into training and test sets
split_index <- createDataPartition(encoded_data$death_event, p = 0.8, list = FALSE)
train_data <- encoded_data[split_index, ]
test_data <- encoded_data[-split_index, ]

# Select the relevant columns from the datasets
train_selected <- train_data[, c("death_event", top_10_corr_vars)]
test_selected <- test_data[, c("death_event", top_10_corr_vars)]

# Fit a logistic regression model on the training set
logistic_model <- glm(death_event ~ ., data = train_selected, family = binomial)

# Get coefficients and standard errors
coefficients <- coef(logistic_model)
standard_errors <- summary(logistic_model)$coefficients[, "Std. Error"]
interpretation <- exp(coefficients)

# Display the interpretation
cat("Interpretation of Coefficients:\n")
for (i in seq_along(interpretation)) {
  cat(paste("   - The odds of death_event increase by a factor of", round(interpretation[i], 4), 
            "for each unit increase in", names(interpretation)[i], "\n"))
}


# Create a table of coefficients with standard errors
coeff_table <- data.frame(
  Feature = names(coefficients),
  ExpCoefficient = exp(coefficients),
  `Standard Error` = standard_errors
)

# Print the table without row names
kable(coeff_table, format = "html", row.names = FALSE) %>%
  kable_styling(full_width = FALSE)



install.packages("pdp")
library(pdp)


variables <- c("doses_distributed_cumulative", "num_months", "X", 
               "doses_administered_cumulative", "V2A_Vaccine.Availability..summary.",
               "V1_Vaccine.Prioritisation..summary.", "regionNortheast", 
               "X85..years", "H7_Vaccination.policy", "X80.84.years")

pdp_plots <- lapply(variables, function(var) {
  partial(logistic_model, pred.var = var, train_selected, grid.resolution = 50, progress = FALSE)
})

# Plot the partial dependency plots
par(mfrow=c(ceiling(length(variables)/2), 2)) 
for (i in 1:length(variables)) {
  plot(pdp_plots[[i]], main = variables[i])
}



{r}
# Assuming your logistic regression model is stored in 'logreg_model'
# and your test set is stored in 'test_data'

# Make predictions on the test set
predicted_probs <- predict(logistic_model, newdata = test_data, type = "response")

# Create a data frame with actual outcomes and predicted probabilities
prediction_data <- data.frame(
  Actual = test_data$death_event,
  Predicted_Probability = predicted_probs
)

# ROC curve
library(pROC)
roc_curve <- roc(prediction_data$Actual, prediction_data$Predicted_Probability)

# Plot ROC curve
plot(roc_curve, col = "blue", main = "ROC Curve", col.main = "darkblue", lwd = 2)

# Add diagonal reference line (random classifier)
abline(a = 0, b = 1, col = "gray", lty = 2, lwd = 2)

# Add AUC value to the plot
auc_value <- auc(roc_curve)
legend("bottomright", legend = paste("AUC =", round(auc_value, 3)), col = "blue", lty = 1, cex = 0.8)





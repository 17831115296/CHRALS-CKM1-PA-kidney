libs <- c("tidyverse","haven","lcmm","mice","rms","tableone","gtsummary",
          "ggplot2","segmented","randomForest","vip")
invisible(lapply(libs, require, character.only = TRUE))

raw_dir <- "/Users/wxidong/Desktop/code/R/CHARLS/原始数据及说明/rawdata"
out_dir <- "/Users/wxidong/Desktop/code/R/CHARLS"
dir.create(out_dir, showWarnings = FALSE)

imp <- mice(data_final, m = 5, maxit = 20, method = "pmm", seed = 1234)
data_imp <- complete(imp, action = 1)
dd <- datadist(data_imp); options(datadist = "dd")

data_long <- data_imp %>% 
  select(ID, r3_met, r4_met, r5_met) %>% 
  pivot_longer(-ID, names_to = "wave", values_to = "met") %>% 
  mutate(wave = parse_number(wave))

best_mod <- hlme(met ~ wave + I(wave^2),
                 random = ~ 1, subject = "ID",
                 mixture = ~ wave + I(wave^2), ng = 2,
                 data = data_long, B = hlme(met ~ wave, ng = 1))

pred_class <- as_tibble(best_mod$pprob, rownames = "ID") %>% 
  mutate(class = factor(class, labels = c("LCDPA","HPPA")))
data_imp <- left_join(data_imp, pred_class, by = "ID")


vars_tbl1 <- c("age","male","r3_education","sbp","dbp",
               "fbg","hba1c","tg","egfr","bmi","qm002",
               "r3_smoke","r3_drink","shengzang")
data_imp <- data_imp %>% 
  rename(r3_age = age, r3_gender = male, r3_bmi = bmi, r3_qm002 = qm002,
         r3_sbp = sbp, r3_dbp = dbp, r3_fbg = fbg, r3_hba1c = hba1c,
         r3_tg = tg, r3_egfr = egfr, r3_smoke = r3_smoke, r3_drink = r3_drink,
         r3_shengzang = shengzang)

tbl1 <- CreateTableOne(vars = vars_tbl1,
                       strata = "class",
                       data   = data_imp,
                       factorVars = c("r3_gender","r3_education","r3_smoke","r3_drink","r3_shengzang"))
write_csv(print(tbl1, smd = TRUE, quote = FALSE), file.path(out_dir,"Table1.csv"))


for (i in c(2015,2018,2020)){
  y  <- paste0("r", substr(i,3,4), "_shengzang")
  x  <- paste0("r", substr(i,3,4), "_met")
  data_imp <- data_imp %>% mutate(!!sym(paste0("ckd_",i)) := as.numeric(get(y) == 1))
  fit_rcs <- lrm(get(paste0("ckd_",i)) ~ rcs(get(x),4) + r3_gender + r3_age + r3_education +
                   r3_bmi + r3_qm002 + r3_sbp + r3_dbp +
                   r3_fbg + r3_hba1c + r3_tg + r3_egfr, data = data_imp)
  OR <- Predict(fit_rcs, get(x), fun = exp)
  p  <- ggplot(OR, aes_string(x, "yhat")) +
    geom_line(color = "red") +
    geom_ribbon(aes_string(ymin = "lower", ymax = "upper"), alpha = .2) +
    theme_classic() +
    labs(x = paste0("MET (",i,")"), y = "OR (95% CI)")
  ggsave(p, filename = file.path(out_dir, paste0("RCS_",i,".png")), width = 5, height = 4)
  lm_base <- glm(get(paste0("ckd_",i)) ~ get(x), family = binomial, data = data_imp)
  lm_seg  <- segmented(lm_base, seg.Z = ~get(x), npsi = 1)
  write_csv(tibble(Year = i, Threshold = lm_seg$psi[2,2]),
            file.path(out_dir, paste0("Threshold_",i,".csv")))
}

data_imp <- data_imp %>% mutate(ckd_any = pmax(ckd_2015, ckd_2018, ckd_2020))
mod1 <- glm(ckd_any ~ class,                family = binomial, data = data_imp)
mod2 <- glm(ckd_any ~ class + r3_gender + r3_age + r3_education + r3_smoke + r3_drink,
            family = binomial, data = data_imp)
mod3 <- glm(ckd_any ~ class + r3_gender + r3_age + r3_education + r3_smoke + r3_drink +
              r3_bmi + r3_qm002 + r3_sbp + r3_dbp + r3_fbg + r3_hba1c + r3_tg + r3_egfr,
            family = binomial, data = data_imp)

tbl_main <- tbl_merge(list(mod1 %>% tbl_regression(exponentiate = TRUE),
                           mod2 %>% tbl_regression(exponentiate = TRUE),
                           mod3 %>% tbl_regression(exponentiate = TRUE)),
                      tab_spanner = c("Model 1","Model 2","Model 3"))
write_csv(as.data.frame(tbl_main), file.path(out_dir,"Table2_main.csv"))

data_imp <- data_imp %>% 
  mutate(
    age_45_60 = as.numeric(r3_age >= 45 & r3_age < 60),
    age_60    = as.numeric(r3_age >= 60),
    female    = as.numeric(r3_gender == 2),
    male      = as.numeric(r3_gender == 1),
    smoker_no = as.numeric(r3_smoke != 1),
    smoker_y  = as.numeric(r3_smoke == 1),
    drink_no  = as.numeric(r3_drink == 1),
    drink_lt1 = as.numeric(r3_drink == 2),
    drink_ge1 = as.numeric(r3_drink == 3),
    bmi_23_28 = as.numeric(r3_bmi >= 23 & r3_bmi < 28),
    bmi_ge28  = as.numeric(r3_bmi >= 28)
  )

sub_vec <- c("age_45_60","age_60","female","male","smoker_no","smoker_y",
             "drink_no","drink_lt1","drink_ge1","bmi_23_28","bmi_ge28")
sub_lab <- c("Age 45–60","Age ≥60","Female","Male","Non-smoker","Current smoker",
             "No alcohol","<1/month","≥1/month","BMI 23–28","BMI ≥28")

sub_tbl <- map2_dfr(sub_vec, sub_lab, function(v, l){
  glm(ckd_any ~ class + r3_gender + r3_age + r3_education + r3_smoke + r3_drink +
        r3_bmi + r3_qm002 + r3_sbp + r3_dbp + r3_fbg + r3_hba1c + r3_tg + r3_egfr,
      family = binomial, data = data_imp %>% filter(!!sym(v) == 1)) %>% 
    tidy(exponentiate = TRUE, conf.int = TRUE) %>% 
    filter(term == "classHPPA") %>% 
    mutate(subgroup = l)
})
write_csv(sub_tbl, file.path(out_dir,"Table3_subgroup.csv"))

library(randomForest)
set.seed(1234)
rf_data <- data_imp %>% 
  mutate(class_num = as.numeric(class)) %>% 
  select(ckd_any, class_num, r3_gender, r3_age, r3_education,
         r3_smoke, r3_drink, r3_bmi, r3_qm002, r3_sbp, r3_dbp,
         r3_fbg, r3_hba1c, r3_tg, r3_egfr)
rf_fit <- randomForest(ckd_any ~ ., data = rf_data, importance = TRUE, ntree = 2000)
rf_imp <- as_tibble(importance(rf_fit), rownames = "Variable") %>% 
  arrange(desc(MeanDecreaseGini))
write_csv(rf_imp, file.path(out_dir,"RF_importance.csv"))

ggplot(rf_imp, aes(reorder(Variable, MeanDecreaseGini), MeanDecreaseGini)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  theme_classic() +
  labs(title = "Random Forest Variable Importance") -> p_rf
ggsave(p_rf, filename = file.path(out_dir,"Fig5_RF.png"), width = 6, height = 4)

write_csv(data_imp, file.path(out_dir,"final_all_complete.csv"))
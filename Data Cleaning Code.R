
library(haven)
library(dplyr)
library(tidyr)

bio15  <- read_dta("rawdata/CHARLS2015r/Biomarker.dta")
blood  <- read_dta("rawdata/CHARLS2015r/Blood.dta")
demo15 <- read_dta("rawdata/CHARLS2015r/demographic_background.dta")
hs15   <- read_dta("rawdata/CHARLS2015r/health_status_and_functioning.dta")

base15 <- demo15 %>% 
  transmute(
    ID   = ID,                      
    age  = 2015 - ba004_w3_1,        
    male = if_else(ba000_w2_3 == 1, 1, 0)
  ) %>% 
  left_join(bio15  %>% transmute(ID, qa003, qa007, qa011,
                                 qa004, qa008, qa012,
                                 ql002, qi002, qm002), by = "ID") %>% 
  left_join(blood  %>% transmute(ID, bl_glu, bl_hbalc, bl_tg, bl_crea), by = "ID") %>% 
  left_join(hs15   %>% transmute(ID,
                                 gaoxueya = da007_w2_2_1_,
                                 xzyc     = da007_w2_2_2_,
                                 diabetes = da007_w2_2_3_,
                                 shengzang= da007_w2_2_9_), by = "ID")

base15 <- base15 %>% 
  mutate(
    bmi  = ql002 / (qi002/100)^2,
    sbp  = (qa003 + qa007 + qa011) / 3,
    dbp  = (qa004 + qa008 + qa012) / 3,
    tg   = bl_tg / 88.6,
    fbg  = bl_glu,
    hba1c= bl_hbalc,
    # CKD-EPI eGFR
    kappa = if_else(male == 1, 0.9, 0.7),
    alpha = if_else(male == 1, -0.411, -0.329),
    egfr  = 141 * pmin(bl_crea/kappa, 1)^alpha * pmax(bl_crea/kappa, 1)^(-1.209) * 0.993^age
  )

data_final <- base15 %>% 
  filter(age >= 45) %>%                                   
  filter(bmi >= 23) %>%                                   
  filter( (male == 1 & qm002 >= 90) |                     
            (male == 0 & qm002 >= 80) ) %>% 
  filter(between(fbg, 100, 124)) %>%                      
  filter(between(hba1c, 5.7, 6.4)) %>%                   
  filter(gaoxueya != 1) %>%                               
  filter(diabetes != 1) %>%                              
  filter(tg < 2.3) %>%                                   
  filter(egfr >= 60) %>%                                
  filter(shengzang != 1)                                 

id18 <- read_dta("rawdata/CHARLS2018r/health_status_and_functioning.dta") %>% 
  select(ID) %>% distinct()
id20 <- read_dta("rawdata/CHARLS2020r/health_status_and_functioning.dta") %>% 
  select(ID) %>% distinct()

data_final <- data_final %>% 
  inner_join(id18, by = "ID") %>% 
  inner_join(id20, by = "ID")
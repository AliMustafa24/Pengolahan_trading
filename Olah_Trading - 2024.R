### Pengolahan Data Trading Seksi AH SBSN #####
## by Elva - Ali -- Seksi AH SBSN @2023 ##

# sebelum di impor sesuaikan format tanggal di file dari SIBISSS dan DB Data Olah --> UK: yyyy-mm-dd
# karena pake csv values nya berubah
# seri baru sesuaikan letaknya di line 63 dan 293

#########################################################
library(readxl) # karena csv valuesnya berubah - kita pake excel nya - package ini lebih mudah
library(openxlsx) # tuk print dalam bentu xlsx 
library(tidyr) # untuk pivot dan filter
library(dplyr) # tuk sort data
#########################################################

rm(list=ls()) #clear the environment

#trading<-"Z:/Market Update/Master Update Sie.2/2023/R_Trading"
#setinput<-"C:/Users/andy.mustafa/OneDrive - Kemenkeu/Master Update Sie.2/2024/TRADING/R_TRADING/03 MARET 2024/20240306/input" #sesuaikan nama folder (kelompok terakhir)
#setseries<-"C:/Users/andy.mustafa/OneDrive - Kemenkeu/Master Update Sie.2/2024/Daftar_Seri_Update" #sesuaikan nama folder daftar seri yang update
#setoutput<-"C:/Users/andy.mustafa/OneDrive - Kemenkeu/Master Update Sie.2/2024/TRADING/R_TRADING/03 MARET 2024/20240306/output" #sesuaikan nama folder (kelompok terakhir)

setinput<-"C:/Users/elva.novitasari/OneDrive - Kemenkeu/Master Update Sie.2/2024/TRADING/R_TRADING/03 MARET 2024/20240328/input" #sesuaikan nama folder (kelompok terakhir)
setseries<-"C:/Users/elva.novitasari/OneDrive - Kemenkeu/Master Update Sie.2/2024/Daftar_Seri_Update" #sesuaikan nama folder daftar seri yang update
setoutput<-"C:/Users/elva.novitasari/OneDrive - Kemenkeu/Master Update Sie.2/2024/TRADING/R_TRADING/03 MARET 2024/20240328/output" #sesuaikan nama folder (kelompok terakhir)

#setinput<-"C:/Users/bloomberg/OneDrive - Kemenkeu/Master Update Sie.2/2024/TRADING/R_TRADING/02 FEBRUARI 2024/20240221/input" #sesuaikan nama folder (kelompok terakhir)
#setseries<-"C:/Users/bloomberg/OneDrive - Kemenkeu/Master Update Sie.2/2024/Daftar_Seri_Update" #sesuaikan nama folder daftar seri yang update
#setoutput<-"C:/Users/bloomberg/OneDrive - Kemenkeu/Master Update Sie.2/2024/TRADING/R_TRADING/02 FEBRUARI 2024/20240221/output" #sesuaikan nama folder (kelompok terakhir)

#setinput<-"C:/Users/DJPPR/OneDrive - Kemenkeu/Master Update Sie.2/2023/R_Trading/11 NOVEMBER 2023/20231108/input"
#setoutput<-"C:/Users/DJPPR/OneDrive - Kemenkeu/Master Update Sie.2/2023/R_Trading/11 NOVEMBER 2023/20231108/output"


# 1st step - update database
# seting tanggal sesuai tanggal data (t-1)
tanggal<-"2024-03-28" #yyyymmdd - t-1 --> sesuaikan tangal data download terakhir

## Impor Data
################################################################################
#note: cek "kelompok pembeli"/kolom M, apabila ada yg masih blank diisi manual
#      biasanya bank syariah, jd perlu kontak BI tuk memperbaiki sistem mereka
################################################################################
setwd(setinput)

# input data
#MainData1 <- read.csv("Trading_SIBISS_colname.csv") #sementara utk diambil colname nya
MainData <- read_excel("01_Trading_SIBISS.xlsx") #sesuaikan tanggalnya
#colnames(MainData)<-colnames(MainData1)
DB_Trad_Olah <- read_excel("02_DB_Trading_Olah_03_28_2024.xlsx")#2. Data base SBSN tanggal2 sebelumnya
#Series<-read.csv("03_DataSeries.csv", header = TRUE, sep = ";") #3. Daftar seri SBN 
DB_Trad_Olah_SUN <- read_excel("03_DB_Trading_Olah_SUN_03_28_2024.xlsx")#3. Data base SUN tanggal2 sebelumny

# select - series --> tradable & IDR & SBSN
setwd(setseries)
DB_series<-read_excel("Daftar_Seri_Update_2024.xlsx")
SBSN_series<-DB_series %>% 
  filter(tradable_non == "Tradable", Curr == "IDR", SUN_SBSN %in% c("SBSN")) #pilih yg tradable saja dan currency nya IDR
SBSN_series<-SBSN_series$Seri
#SBSN_series<-Series[227:279,] # sesuaikan letak SBSN tradable ada di row sebelah mana dan nama SR

## Adjust bentuk data hasil input
#MainData<-MainData %>%
  #rename(TANGGAL.SETELMEN=?..TANGGAL.SETELMEN)
MainData$`TANGGAL SETELMEN`<-tanggal # menyesuaikan bentuk tanggal
MainData$`TANGGAL SETELMEN`<-as.Date(MainData$`TANGGAL SETELMEN`)
MainData$`TANGGAL TRANSAKSI`<-as.Date(MainData$`TANGGAL TRANSAKSI`)
str(MainData)

## Clean DB - remove yang tidak perlu
col_rem<-c("AGREEMENT CODE","JENIS SETELMEN","AID PENJUAL",
           "AID PEMBELI","TANGGAL 2nd LEG TRANSAKSI",
           "SUBREG PENJUAL","SUBREG PEMBELI")
DataClean<-MainData[,!(names(MainData) %in% col_rem)]
str(DataClean)

## select - transaction --> Sale, inhouse Sale, Repo, n Repo 2nd leg
tran_type<-c("SALE","INHOUSE SALE","REPO","REPO 2nd LEG")
DataClean_tran<-which(DataClean$`JENIS TRANSAKSI` %in% tran_type)
DataClean_tran<-DataClean[DataClean_tran,]


DataClean_Series<-which(DataClean_tran$SERI %in% SBSN_series)
DataClean_Series<-DataClean_tran[DataClean_Series,]
DataClean_Series<-DataClean_Series[,-c(16:27)] # Remove columns - after yield

## Create new columns with new category "Frekuensi" "Jenis Transaksi 1" "Jenis Transaksi 2" "jenis seri"
DataClean_Series$FREKUENSI<-1 #put additional column - freq. --> all values:1
DataClean_Series$JENIS.TRANSAKSI_1<-ifelse(DataClean_Series$`JENIS TRANSAKSI`=="SALE","OUTRIGHT",
                                           ifelse(DataClean_Series$`JENIS TRANSAKSI`=="INHOUSE SALE","OUTRIGHT","REPO"))
DataClean_Series$JENIS.TRANSAKSI_2 <- ifelse((DataClean_Series$JENIS.TRANSAKSI_1 == "REPO" & DataClean_Series$'KELOMPOK PENJUAL' == "BANK INDONESIA") | 
                                               (DataClean_Series$JENIS.TRANSAKSI_1 == "REPO" & DataClean_Series$'KELOMPOK PEMBELI' == "BANK INDONESIA"), "REPO BI", 
                                             ifelse(DataClean_Series$JENIS.TRANSAKSI_1 == "REPO", "REPO", "-"))
DataClean_Series$jenis.seri<-substring(DataClean_Series$SERI,1,2) # pilih 2 huruf awal dari masing2 seri

## penyesuaian bentuk DataClean_Series
DataClean_Series$HARGA<-as.numeric(DataClean_Series$HARGA)
DataClean_Series$NOMINAL<-as.numeric(DataClean_Series$NOMINAL)
DataClean_Series$`NILAI TRANSAKSI`<-as.numeric(DataClean_Series$`NILAI TRANSAKSI`)
DataClean_Series$YIELD<-as.numeric(DataClean_Series$YIELD)

################################################################################
# 2nd step - produce the output
################################################################################

setwd(setoutput) #arahkan working directory nya ke tempat output

#####################################
## Output 1 --> Combine ke DB Trading Olah - update DB trading
#####################################

## waktu impor DB_TradingOlah - pastikan format date nya sesuai "yyyy-mm-dd" UK

DB_Trad_Olah$TANGGAL.SETELMEN<-as.Date(DB_Trad_Olah$TANGGAL.SETELMEN) # adjust format tanggal setelmen
colnames(DB_Trad_Olah)<-colnames(DataClean_Series) #samakan nama kolom biar bisa digabung
DB_Trad_Olah_all<-rbind(DB_Trad_Olah,DataClean_Series) #merge ke DB from prev. data
write.xlsx(DB_Trad_Olah_all, paste0("01_DB_Trad_Olah_",tanggal,".xlsx"), sheetName = "Trading_Olah")


######################
## Trading per tanggal
######################

DB_Pivot_Date <- DB_Trad_Olah_all[, c("TANGGAL SETELMEN", "NOMINAL", "FREKUENSI")] # Select only required columns
colnames(DB_Pivot_Date)[colnames(DB_Pivot_Date) == "TANGGAL SETELMEN"] <- "TANGGAL.SETELMEN" #ganti column name krn spasi g bisa di rumus pivot
# Aggregate the data by date
trade_by_date <- aggregate(cbind(NOMINAL, FREKUENSI) ~ TANGGAL.SETELMEN,
                           data = DB_Pivot_Date, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_by_date_df <- data.frame(
  date = trade_by_date$TANGGAL.SETELMEN,
  nominal_sum = trade_by_date$NOMINAL[, "sum"],
  frekuensi_sum = trade_by_date$FREKUENSI[, "sum"]
  )
write.xlsx(trade_by_date_df, paste0("02_trade_by_date_",tanggal,".xlsx")) #print to excel

######################
## Trading per seri
######################

## create trading per seri harian
DB_trade_series_harian <- DataClean_Series[, c("SERI", "FREKUENSI", "NOMINAL")] # Select only required columns
trade_series_harian <- aggregate(cbind(NOMINAL, FREKUENSI) ~ SERI,
                             data = DB_trade_series_harian, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_series_harian_df <- data.frame(
  seri = trade_series_harian$SERI,
  frekuensi_sum = trade_series_harian$FREKUENSI[, "sum"],
  nominal_sum = trade_series_harian$NOMINAL[, "sum"]
)
trade_series_harian_df <- trade_series_harian_df %>% arrange(desc(nominal_sum)) #sorted by nominal
write.xlsx(trade_series_harian_df, paste0("03_trade_series_harian_",tanggal,".xlsx")) #print to excel

## create trading per seri bulanan
DB_Pivot_Series_bulanan <- DB_Trad_Olah_all[, c("SERI", "FREKUENSI", "NOMINAL")] # Select only required columns
trade_series_bulanan <- aggregate(cbind(NOMINAL, FREKUENSI) ~ SERI,
                           data = DB_Pivot_Series_bulanan, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_series_bulanan_df <- data.frame(
  seri = trade_series_bulanan$SERI,
  frekuensi_sum = trade_series_bulanan$FREKUENSI[, "sum"],
  nominal_sum = trade_series_bulanan$NOMINAL[, "sum"]
)
trade_series_bulanan_df <- trade_series_bulanan_df %>% arrange(desc(nominal_sum)) #sorted by nominal
write.xlsx(trade_series_bulanan_df, paste0("04_trade_series_bulanan_",tanggal,".xlsx")) #print to excel

######################
## Data Jual
######################

## Per Kelompok Penjual
DB_Pivot_Jual <- DB_Trad_Olah_all[, c("KELOMPOK PENJUAL","TIPE INV PENJUAL","NOMINAL")] # Select only required columns
trade_by_Jual <- aggregate(cbind(NOMINAL) ~ `KELOMPOK PENJUAL`,
                             data = DB_Pivot_Jual, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_by_Jual_df <- data.frame(
  KELOMPOK = trade_by_Jual$`KELOMPOK PENJUAL`,
  nominal_sum = trade_by_Jual$NOMINAL[, "sum"]
)
#write.xlsx(trade_by_Jual_df, paste0("trade_by_Jual_",tanggal,".xlsx")) #print to excel

## Per jenis investor penjual filter Kelompok Penjual Resident
filter_resident_Jual <- DB_Pivot_Jual %>% 
  filter(`KELOMPOK PENJUAL` == "RESIDEN")
trade_by_tipe_Jual <- aggregate(cbind(NOMINAL) ~ `TIPE INV PENJUAL`,
                           data = filter_resident_Jual, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_by_tipe_Jual_df <- data.frame(
  KELOMPOK = trade_by_tipe_Jual$`TIPE INV PENJUAL`,
  nominal_sum = trade_by_tipe_Jual$NOMINAL[, "sum"]
)
#write.xlsx(trade_by_tipe_Jual_df, paste0("trade_by_tipe_Jual_",tanggal,".xlsx")) #print to excel

######################
## Data Beli
######################

## Per Kelompok Pembeli
DB_Pivot_Beli <- DB_Trad_Olah_all[, c("KELOMPOK PEMBELI","TIPE INV PEMBELI","NOMINAL")] # Select only required columns
colnames(DB_Pivot_Beli)[colnames(DB_Pivot_Beli) == "KELOMPOK PEMBELI"] <- "KELOMPOK.PEMBELI" #ganti column name krn spasi g bisa di rumus pivot
colnames(DB_Pivot_Beli)[colnames(DB_Pivot_Beli) == "TIPE INV PEMBELI"] <- "TIPE.INV.PEMBELI" #ganti column name krn spasi g bisa di rumus pivot

trade_by_Beli <- aggregate(cbind(NOMINAL) ~ KELOMPOK.PEMBELI,
                           data = DB_Pivot_Beli, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_by_Beli_df <- data.frame(
  KELOMPOK = trade_by_Beli$KELOMPOK.PEMBELI,
  nominal_sum = trade_by_Beli$NOMINAL[, "sum"]
)
#write.xlsx(trade_by_Beli_df, paste0("trade_by_Beli_",tanggal,".xlsx")) #print to excel

## Per jenis investor pembeli filter Kelompok Pembeli Resident
filter_resident_Beli <- DB_Pivot_Beli %>% 
  filter(KELOMPOK.PEMBELI == "RESIDEN") # filter Residen Pembeli
trade_by_tipe_Beli <- aggregate(cbind(NOMINAL) ~ TIPE.INV.PEMBELI,
                                data = filter_resident_Beli, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_by_tipe_Beli_df <- data.frame(
  KELOMPOK = trade_by_tipe_Beli$TIPE.INV.PEMBELI,
  nominal_sum = trade_by_tipe_Beli$NOMINAL[, "sum"]
)
#write.xlsx(trade_by_tipe_Beli_df, paste0("trade_by_tipe_Beli_",tanggal,".xlsx")) #print to excel

######################
## Net Buy (Sell)
######################

# combine trade by inv type - tuk jual dan beli
merged_Kelompok <- merge(trade_by_Jual_df, trade_by_Beli_df, by = "KELOMPOK", all = TRUE)
merged_InvType <- merge(trade_by_tipe_Jual_df, trade_by_tipe_Beli_df, by = "KELOMPOK", all = TRUE)

DB_net_trading <-rbind(merged_Kelompok,merged_InvType) #gabungan dari kelompok dan tipe (rincian resident)


# Sum rows with specific names
db_bank_Konven <- DB_net_trading %>% 
  mutate(KELOMPOK = ifelse(KELOMPOK %in% c("BANK ASING", "BANK CAMPURAN",
                                           "BANK PEMERINTAH","BANK SWASTA NASIONAL", "BPD"),
                           "BANK KONVENSIONAL", KELOMPOK)) %>% 
  group_by(KELOMPOK) %>% 
  summarise(nominal_sum.x = sum(nominal_sum.x, na.rm=TRUE),
            nominal_sum.y = sum(nominal_sum.y, na.rm=TRUE)) %>% 
  filter(KELOMPOK != "RESIDEN") # remove Resident

# only "sum" for some specific rows with similar names
#df_sum <- df %>%
#  group_by(Name) %>%
#  summarize(Value = sum(Value))

# Replace NA value with 0
db_bank_Konven <- db_bank_Konven %>% mutate_at(vars(nominal_sum.x, nominal_sum.y), ~ifelse(is.na(.), 0, .))

# Calculate net buy/sell
net_buy_sell <- db_bank_Konven %>%
  mutate(net_buySell = nominal_sum.y - nominal_sum.x) %>%
  mutate(net_buySell_billion = net_buySell / 1000000000) %>%
  arrange(net_buySell_billion)
write.xlsx(net_buy_sell, paste0("05_net_buy_sell_",tanggal,".xlsx")) #print to excel


######################
## Repo dan Outright
######################

# strategi: pivot dulu yg repo dan outright serta repo BI dan antar bank
# sehabis itu, di combine row antar dua file tersebut - terus delete: repo dan NA yg di kolom jenis transaksi

# Pivot repo dan outright (jenis transaksi 1)
DB_Pivot_Tran1 <- DB_Trad_Olah_all[, c("JENIS.TRANSAKSI_1","FREKUENSI","NOMINAL")] # Select only required columns
trade_Tran1 <- aggregate(cbind(NOMINAL, FREKUENSI) ~ JENIS.TRANSAKSI_1,
                           data = DB_Pivot_Tran1, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_Tran1_df <- data.frame(
  Jenis = trade_Tran1$JENIS.TRANSAKSI_1,
  nominal = trade_Tran1$NOMINAL[, "sum"],
  frekuensi = trade_Tran1$FREKUENSI[, "sum"]
)
#write.xlsx(trade_Tran1_df, paste0("trade_Tran1_",tanggal,".xlsx")) #print to excel

# Pivot repo BI dan antar bank (jenis transaksi 2)
DB_Pivot_Tran2 <- DB_Trad_Olah_all[, c("JENIS.TRANSAKSI_2","FREKUENSI","NOMINAL")] # Select only required columns
trade_Tran2 <- aggregate(cbind(NOMINAL, FREKUENSI) ~ JENIS.TRANSAKSI_2,
                         data = DB_Pivot_Tran2, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_Tran2_df <- data.frame(
  Jenis = trade_Tran2$JENIS.TRANSAKSI_2,
 nominal = trade_Tran2$NOMINAL[, "sum"],
  frekuensi = trade_Tran2$FREKUENSI[, "sum"]
)

#write.xlsx(trade_Tran2_df, paste0("trade_Tran2_",tanggal,".xlsx")) #print to excel

# combine jenis transaksi 1 dan 2 --> hilangkan row Repo dan NA
trade_Tran1_df_clean <- trade_Tran1_df [1,] #clean dalam rangka menghilangkan repo total
DB_jenis_trans<-rbind(trade_Tran1_df_clean,trade_Tran2_df) # combine jenis transaksi 1 dan 2
jenis_trans <- DB_jenis_trans %>%
  filter(Jenis %in% c("OUTRIGHT", "REPO BI", "REPO")) #select outright sama REPO BI
write.xlsx(jenis_trans, paste0("06_jenis_trans_",tanggal,".xlsx")) #print to excel

#############################################################################################
## Update Data Trading SUN
#############################################################################################

## Impor Data
##############################
#pake data yg sama - Main Data
##############################

MainData$'TANGGAL SETELMEN'<-as.Date(MainData$'TANGGAL SETELMEN')
str(MainData)

## Clean DB - remove yang tidak perlu
col_rem<-c("AGREEMENT CODE","JENIS SETELMEN","AID PENJUAL",
           "AID PEMBELI","TANGGAL 2nd LEG TRANSAKSI",
           "SUBREG PENJUAL","SUBREG PEMBELI")
DataClean<-MainData[,!(names(MainData) %in% col_rem)]
str(DataClean)

## select - transaction --> Sale, inhouse Sale, Repo, n Repo 2nd leg
tran_type<-c("SALE","INHOUSE SALE","REPO","REPO 2nd LEG")
DataClean_tran<-which(DataClean$'JENIS TRANSAKSI' %in% tran_type)
DataClean_tran<-DataClean[DataClean_tran,]

## select - series --> SUN
#SBSN_series<-Series[227:279,] # sesuaikan letak SBSN tradable ada di row sebelah mana dan nama SR
SUN_series<-DB_series %>% 
  filter(tradable_non == "Tradable", Curr == "IDR", SUN_SBSN %in% c("SUN")) #pilih yg tradable saja dan currency nya IDR

SUN_series<-SUN_series$Seri

#SUN_series<-Series[1:226,] # sesuaikan letak SUN tradable ada di row sebelah mana dan nama SR
#SUN_series<-SUN_series$Series

DataClean_SUN_Series<-which(DataClean_tran$SERI %in% SUN_series)
DataClean_SUN_Series<-DataClean_tran[DataClean_SUN_Series,]
DataClean_SUN_Series<-DataClean_SUN_Series[,-c(16:27)] # Remove columns - after yield

## Create new columns with new category "Frekuensi" "Jenis Transaksi 1" "Jenis Transaksi 2" "jenis seri"
DataClean_SUN_Series$FREKUENSI<-1 #put additional column - freq. --> all values:1
DataClean_SUN_Series$JENIS.TRANSAKSI_1<-ifelse(DataClean_SUN_Series$`JENIS TRANSAKSI`=="SALE","OUTRIGHT",
                                           ifelse(DataClean_SUN_Series$`JENIS TRANSAKSI`=="INHOUSE SALE","OUTRIGHT","REPO"))
DataClean_SUN_Series$JENIS.TRANSAKSI_2 <- ifelse((DataClean_SUN_Series$`JENIS TRANSAKSI` == "REPO" & DataClean_SUN_Series$`KELOMPOK PEMBELI` == "BANK INDONESIA") | 
                                               (DataClean_SUN_Series$`JENIS TRANSAKSI` == "REPO" & DataClean_SUN_Series$`KELOMPOK PEMBELI` == "BANK INDONESIA"), "REPO BI", "-")
#DataClean_SUN_Series$jenis.seri<-substring(DataClean_SUN_Series$SERI,1,2) # pilih 2 huruf awal dari masing2 seri

## penyesuaian bentuk DataClean_Series
DataClean_SUN_Series$HARGA<-as.numeric(DataClean_SUN_Series$HARGA)
DataClean_SUN_Series$NOMINAL<-as.numeric(DataClean_SUN_Series$NOMINAL)
DataClean_SUN_Series$`NILAI TRANSAKSI`<-as.numeric(DataClean_SUN_Series$`NILAI TRANSAKSI`)
DataClean_SUN_Series$YIELD<-as.numeric(DataClean_SUN_Series$YIELD)

## Combine ke DB Trading Olah - update DB trading
## waktu impor DB_TradingOlah - pastikan format date nya sesuai "yyyy-mm-dd" UK

#####################################
## impor db dari tanggal2 sebelumnya
#####################################

DB_Trad_Olah_SUN$TANGGAL.SETELMEN<-as.Date(DB_Trad_Olah_SUN$TANGGAL.SETELMEN) # adjust format tanggal setelmen
colnames(DB_Trad_Olah_SUN)<-colnames(DataClean_SUN_Series) #samakan nama kolom biar bisa digabung
DB_Trad_Olah_all_SUN<-rbind(DB_Trad_Olah_SUN,DataClean_SUN_Series) #merge ke DB from prev. data
write.xlsx(DB_Trad_Olah_all_SUN, paste0("08_DB_Trad_Olah_SUN",tanggal,".xlsx"), sheetName = "Trading_Olah")

################################################################################
# produce the SUN output
################################################################################
######################
## Trading per tanggal
######################
DB_Pivot_Date_SUN <- DB_Trad_Olah_all_SUN[, c("TANGGAL SETELMEN", "NOMINAL", "FREKUENSI")] # Select only required columns
# Aggregate the data by date
trade_by_date_SUN <- aggregate(cbind(NOMINAL, FREKUENSI) ~ `TANGGAL SETELMEN`,
                           data = DB_Pivot_Date_SUN, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_by_date_SUN_df <- data.frame(
  date = trade_by_date_SUN$`TANGGAL SETELMEN`,
  nominal_sum = trade_by_date_SUN$NOMINAL[, "sum"],
  frekuensi_sum = trade_by_date_SUN$FREKUENSI[, "sum"]
)
#write.xlsx(trade_by_date_SUN_df, paste0("02_trade_by_date_SUN_",tanggal,".xlsx")) #print to excel

######################
## Trading per seri
######################

## create trading per seri harian
DB_trade_series_harian_SUN <- DataClean_SUN_Series[, c("SERI", "NOMINAL", "FREKUENSI")] # Select only required columns
trade_series_harian_SUN <- aggregate(cbind(NOMINAL, FREKUENSI) ~ SERI,
                                 data = DB_trade_series_harian_SUN, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_series_harian_SUN_df <- data.frame(
  seri = trade_series_harian_SUN$SERI,
  nominal_sum = trade_series_harian_SUN$NOMINAL[, "sum"],
  frekuensi_sum = trade_series_harian_SUN$FREKUENSI[, "sum"]
)
trade_series_harian_SUN_df <- trade_series_harian_SUN_df %>% arrange(desc(nominal_sum)) #sorted by nominal
#write.xlsx(trade_series_harian_SUN_df, paste0("03_trade_series_harian_SUN",tanggal,".xlsx")) #print to excel

## create trading per seri bulanan
DB_Pivot_Series_bulanan_SUN <- DB_Trad_Olah_all_SUN[, c("SERI", "NOMINAL", "FREKUENSI")] # Select only required columns
trade_series_bulanan_SUN <- aggregate(cbind(NOMINAL, FREKUENSI) ~ SERI,
                                  data = DB_Pivot_Series_bulanan_SUN, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_series_bulanan_SUN_df <- data.frame(
  seri = trade_series_bulanan_SUN$SERI,
  nominal_sum = trade_series_bulanan_SUN$NOMINAL[, "sum"],
  frekuensi_sum = trade_series_bulanan_SUN$FREKUENSI[, "sum"]
)
trade_series_bulanan_SUN_df <- trade_series_bulanan_SUN_df %>% arrange(desc(nominal_sum)) #sorted by nominal
#write.xlsx(trade_series_bulanan_SUN_df, paste0("04_trade_series_bulanan_SUN",tanggal,".xlsx")) #print to excel

######################
## Data Jual
######################

## Per Kelompok Penjual
DB_Pivot_Jual_SUN <- DB_Trad_Olah_all_SUN[, c("KELOMPOK PENJUAL","TIPE INV PENJUAL","NOMINAL")] # Select only required columns
trade_by_Jual_SUN <- aggregate(cbind(NOMINAL) ~ `KELOMPOK PENJUAL`,
                           data = DB_Pivot_Jual_SUN, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_by_Jual_SUN_df <- data.frame(
  KELOMPOK = trade_by_Jual_SUN$`KELOMPOK PENJUAL`,
  nominal_sum = trade_by_Jual_SUN$NOMINAL[, "sum"]
)
#write.xlsx(trade_by_Jual_SUN_df, paste0("trade_by_Jual_SUN",tanggal,".xlsx")) #print to excel

## Per jenis investor penjual filter Kelompok Penjual Resident
filter_resident_Jual_SUN <- DB_Pivot_Jual_SUN %>% 
  filter(`KELOMPOK PENJUAL` == "RESIDEN")
trade_by_tipe_Jual_SUN <- aggregate(cbind(NOMINAL) ~ `TIPE INV PENJUAL`,
                                data = filter_resident_Jual_SUN, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_by_tipe_Jual_SUN_df <- data.frame(
  KELOMPOK = trade_by_tipe_Jual_SUN$`TIPE INV PENJUAL`,
  nominal_sum = trade_by_tipe_Jual_SUN$NOMINAL[, "sum"]
)
#write.xlsx(trade_by_tipe_Jual_SUN_df, paste0("trade_by_tipe_Jual_SUN",tanggal,".xlsx")) #print to excel

######################
## Data Beli
######################

## Per Kelompok Pembeli
DB_Pivot_Beli_SUN <- DB_Trad_Olah_all_SUN[, c("KELOMPOK PEMBELI","TIPE INV PEMBELI","NOMINAL")] # Select only required columns
trade_by_Beli_SUN <- aggregate(cbind(NOMINAL) ~ `KELOMPOK PEMBELI`,
                           data = DB_Pivot_Beli_SUN, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_by_Beli_SUN_df <- data.frame(
  KELOMPOK = trade_by_Beli_SUN$`KELOMPOK PEMBELI`,
  nominal_sum = trade_by_Beli_SUN$NOMINAL[, "sum"]
)
#write.xlsx(trade_by_Beli_df, paste0("trade_by_Beli_",tanggal,".xlsx")) #print to excel

## Per jenis investor pembeli filter Kelompok Pembeli Resident
filter_resident_Beli_SUN <- DB_Pivot_Beli_SUN %>% 
  filter(`KELOMPOK PEMBELI` == "RESIDEN") # filter Residen Pembeli
trade_by_tipe_Beli_SUN <- aggregate(cbind(NOMINAL) ~ `TIPE INV PEMBELI`,
                                data = filter_resident_Beli_SUN, FUN = function(x) c(sum = sum(x), count = length(x)))
trade_by_tipe_Beli_SUN_df <- data.frame(
  KELOMPOK = trade_by_tipe_Beli_SUN$`TIPE INV PEMBELI`,
  nominal_sum = trade_by_tipe_Beli_SUN$NOMINAL[, "sum"]
)
#write.xlsx(trade_by_tipe_Beli_SUN_df, paste0("trade_by_tipe_Beli_SUN_",tanggal,".xlsx")) #print to excel

######################
## Net Buy (Sell)
######################

# combine trade by inv type - tuk jual dan beli
merged_Kelompok_SUN <- merge(trade_by_Jual_SUN_df, trade_by_Beli_SUN_df, by = "KELOMPOK", all = TRUE)
merged_InvType_SUN <- merge(trade_by_tipe_Jual_SUN_df, trade_by_tipe_Beli_SUN_df, by = "KELOMPOK", all = TRUE)

DB_net_trading_SUN <-rbind(merged_Kelompok_SUN,merged_InvType_SUN) #gabungan dari kelompok dan tipe (rincian resident)

# Sum rows with specific names
db_bank_Konven_SUN <- DB_net_trading_SUN %>% 
  mutate(KELOMPOK = ifelse(KELOMPOK %in% c("BANK ASING", "BANK CAMPURAN",
                                           "BANK PEMERINTAH","BANK SWASTA NASIONAL","BPD"),
                           "BANK KONVENSIONAL", KELOMPOK)) %>% 
  group_by(KELOMPOK) %>% 
  summarise(nominal_sum.x = sum(nominal_sum.x),
            nominal_sum.y = sum(nominal_sum.y)) %>% 
  filter(KELOMPOK != "RESIDEN") # remove Resident

# only "sum" for some specific rows with similar names
#df_sum <- df %>%
#  group_by(Name) %>%
#  summarize(Value = sum(Value))

# Replace NA value with 0
db_bank_Konven_SUN <- db_bank_Konven_SUN %>% mutate_at(vars(nominal_sum.x, nominal_sum.y), ~ifelse(is.na(.), 0, .))

# Calculate net buy/sell
net_buy_sell_SUN <- db_bank_Konven_SUN %>%
  mutate(net_buySell = nominal_sum.y - nominal_sum.x) %>%
  mutate(net_buySell_billion = net_buySell / 1000000000) %>%
  arrange(net_buySell_billion)
write.xlsx(net_buy_sell_SUN, paste0("07_net_buy_sell_SUN_",tanggal,".xlsx")) #print to excel

######## 
# list output:
# 1. DB_trad_Olah_xxxxxx
# 2. Trading by Date
# 3. Trading series harian
# 4. Trading series bulanan
# 5. Net buy (sell)
# 6. Jenis transaksi (Outright dan Repo BI)
# 7. Net buy (sell) SUN
# input ke file output excel daily trading



library(readr)
library(dplyr)
library(tidyr)


ddd <- read_csv("https://www.czso.cz/documents/62353418/188699115/sldb2021_deti_stav_vzdelani_vek_matky.csv")

count(ddd, uzemi_txt)
count(ddd, ukaz_txt)

ddd |>
  select(hodnota, ends_with("txt")) |>
  filter(uzemi_txt != "Česká republika") |>
  drop_na() |>
  relocate(hodnota, .after = 6) |>
  spread(uzemi_txt, hodnota) |>
  View()

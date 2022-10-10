library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)
library(ggiraph)
library(purrr)

kkk <- czso::czso_get_catalogue()

byty <- czso::czso_get_table("sldb2021_byty_obydlenost")
vzdel <- czso::czso_get_table("sldb2021_vzdelani")
obcekraje <- czso::czso_get_codelist("cis108vaz43")
obceorp <- czso::czso_get_codelist("cis65vaz43")
typobce <- czso::czso_get_codelist("cis67vaz43")
obyv <- czso::czso_get_table("130149") |>
  filter(rok == max(rok), is.na(pohlavi_txt)) |>
  select(uzemi_kod = vuzemi_kod, pocob = hodnota)

byty_podily <- byty |>
  filter(uzemi_cis == "43", !is.na(obydlenost_txt)) |>
  select(hodnota, obydlenost_txt, uzemi_txt, uzemi_kod) |>
  pivot_wider(names_from = obydlenost_txt, values_from = hodnota) |>
  mutate(celkem = `obvykle obydlen` + `obvykle neobydlen`,
         obydlenost_share = `obvykle obydlen`/celkem) |>
  left_join(obyv) |>
  mutate(pocob_kat = cut(pocob, breaks = c(0, 500, 1000, 10000, 100000, 1000000, 1e7))) |>
  left_join(obcekraje |>
              select(kraj_nazev = TEXT1,
                     kraj_kod = CHODNOTA1,
                     uzemi_kod = CHODNOTA2)) |>
  left_join(obceorp |>
              select(orp_nazev = TEXT1,
                     orp_kod = CHODNOTA1,
                     uzemi_kod = CHODNOTA2)) |>
  left_join(typobce |>
              select(typobce_nazev = TEXT1,
                     typobce_kod = CHODNOTA1,
                     uzemi_kod = CHODNOTA2))

vzdel_podily <- vzdel |>
  filter(uzemi_cis == "43", !is.na(vzdelani_txt)) |>
  select(hodnota, vzdelani_txt, uzemi_txt, uzemi_kod) |>
  group_by(uzemi_txt, uzemi_kod) |>
  mutate(podil = hodnota/sum(hodnota)) |>
  filter(vzdelani_txt == "Vysokoškolské") |>
  left_join(obyv) |>
  mutate(pocob_kat = cut(pocob, breaks = c(0, 500, 1000, 10000, 100000, 1000000, 1e7))) |>
  left_join(obcekraje |>
              select(kraj_nazev = TEXT1,
                     kraj_kod = CHODNOTA1,
                     uzemi_kod = CHODNOTA2)) |>
  left_join(obceorp |>
              select(orp_nazev = TEXT1,
                     orp_kod = CHODNOTA1,
                     uzemi_kod = CHODNOTA2)) |>
  left_join(typobce |>
              select(typobce_nazev = TEXT1,
                     typobce_kod = CHODNOTA1,
                     uzemi_kod = CHODNOTA2))

byty_podily |>
  # filter(kraj_kod %in% c("CZ020", "CZ054", "CZ080")) |>
  ggplot(aes(1 - obydlenost_share, log(pocob))) +
  geom_point(alpha = .2) +
  geom_smooth(aes(colour = pocob_kat), method = "lm",) +
  coord_flip()

byty_podily |>
  drop_na(pocob_kat) |>
  count(pocob_kat, wt = 1 - mean(obydlenost_share)) |>
  ggplot(aes(pocob_kat, n)) +
  geom_col()

byty_podily |>
  drop_na(pocob_kat) |>
  count(kraj_nazev, wt = 1 - mean(obydlenost_share)) |>
  ggplot(aes(n, kraj_nazev)) +
  geom_col()

byty_podily |>
  drop_na(pocob_kat) |>
  filter(pocob < 1e6) |>
  count(kraj_nazev, wt = pocob,name = "pocob_sum") |>
  left_join(byty_podily |>
              drop_na(pocob_kat) |>
              count(kraj_nazev,
                    wt = 1 - mean(obydlenost_share),
                    name = "neobydlenost_share")) |>
  ggplot(aes(pocob_sum, neobydlenost_share)) +
  geom_point() +
  geom_label(aes(label = str_sub(kraj_nazev, 1, 4)))

byty_podily |>
  filter(kraj_kod %in% c("CZ020", "CZ031")) |>
  count(kraj_kod, wt = mean(obydlenost_share))

byty_podily |>
  filter(kraj_kod %in% c("CZ020", "CZ031")) |>
  count(kraj_kod, wt = mean(`obvykle obydlen`)/mean(celkem))

byty_podily |>
  filter(kraj_kod %in% c("CZ020", "CZ031")) |>
  count(kraj_kod, wt = sum(`obvykle obydlen`)/sum(celkem))

byty_podily |>
  ggplot(aes(log(pocob), obydlenost_share)) +
    geom_point(alpha = .3) +
    geom_smooth(method = "lm") +
    facet_wrap(~orp_nazev)

vzdel_podily |>
  group_by(orp_nazev, orp_kod) |>
  summarise(across(c(podil, pocob), mean)) |>
  ggplot(aes(log(pocob), podil)) +
    geom_point(alpha = .3) +
    geom_label(aes(label = orp_kod))

vzdel_podily |>
  group_by(orp_nazev, orp_kod) |>
  summarise(across(c(podil, pocob), mean)) |>
  ungroup() |>
  mutate(dev_podil = podil/mean(podil),
         dev_pocob = pocob/mean(pocob),
         dev_all = dev_pocob + dev_podil) |>
  filter(orp_kod %in% orp_slope_up) |>
  arrange(dev_all) |>
  ggplot(aes(podil, pocob)) +
  geom_point() +
  geom_label(aes(label = orp_kod))

ggg <- vzdel_podily |>
  drop_na(pocob, podil) |>
  filter(orp_kod %in% orp_slope_up) |>
  ggplot(aes(log(pocob), 1 - podil)) +
  geom_point(alpha = .4, aes(colour = orp_nazev)) +
  geom_smooth_interactive(aes(colour = orp_nazev, tooltip = paste0(orp_kod, "\n", orp_nazev)), method = "lm", se = FALSE) +
  guides(colour = "none") +
  geom_smooth(method = "lm", colour = "black")

girafe(ggobj = ggg)


vzdel_podily |>
  filter(orp_kod %in% c("4215", "3103")) |>
  # filter(orp_nazev %in% c("Česká Lípa", "Český Krumlov")) |>
  ggplot(aes(log(pocob), 1 - podil,
             colour = orp_nazev)) +
  geom_point(alpha = .8) +
  geom_smooth(aes(colour = orp_nazev), method = "lm",) +
  geom_smooth(aes(), method = "lm", colour = "black")

mdl <- vzdel_podily |>
  drop_na(pocob, podil) |>
  filter(pocob > 0) |>
  group_by(orp_nazev, orp_kod) |>
  nest() |>
  mutate(mdl = map(data, ~lm(1 - podil ~ log(pocob), data = .))) |>
  mutate(mdl_tidy = map(mdl, broom::tidy)) |>
  unnest(mdl_tidy) |>
  filter(term != "(Intercept)", estimate > 0) |>
  arrange(desc(estimate))

orp_slope_up <- mdl |> pull(orp_kod)

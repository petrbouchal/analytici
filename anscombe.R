library(tidyr)
library(dplyr)
library(ggplot2)
library(datasauRus)

pivot_longer_spec()

anscombe

aw <- anscombe |>
  mutate(id = row_number()) |>
  pivot_longer(names_pattern = "(x|y)([1-4])", cols = matches("[xy]"),
               names_to = c("val", "grp")) |>
  pivot_wider(values_from = value, names_from = val)

aw |>
  ggplot(aes(x, y)) +
  geom_point() +
  geom_smooth(se = FALSE, method = "lm", fullrange=TRUE) +
  facet_wrap(~grp) +
  ptrr::theme_ptrr("scatter")

aw |>
  ggplot(aes(x, y)) +
  geom_point() +
  geom_smooth(se = FALSE, method = "lm", fullrange=TRUE) +
  facet_wrap(~grp) +
  ptrr::theme_ptrr("scatter")

ggplot(datasaurus_dozen |>
         filter(dataset %in% c("dino", "star", "wide_lines", "circle")),
       aes(x = x, y = y, colour = dataset))+
  geom_point()+
  geom_smooth(se = FALSE, method = "lm", fullrange=TRUE) +
  facet_wrap(~dataset, ncol = 2) +
  ptrr::theme_ptrr("scatter", legend.position = "none")

ggplot(datasaurus_dozen |>
         filter(dataset %in% c("dino", "star", "wide_lines", "circle")),
       aes(x = x, y = y, colour = dataset))+
  geom_point(colour = NA)+
  geom_smooth(se = FALSE, method = "lm", fullrange=TRUE) +
  ptrr::theme_ptrr("scatter", legend.position = "none",
                   strip.text = element_text(colour = NA)) +
  facet_wrap(~dataset, ncol = 2)

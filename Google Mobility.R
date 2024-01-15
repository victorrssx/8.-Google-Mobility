  
  ########################################################
  ################                        ################
  ################     Google Mobility    ################
  ################       06/12/2023       ################
  ################                        ################
  ########################################################
  
  extrafont::loadfonts(device = "win")
  
  pacman::p_load(tidyverse, rvest, xml2, # tidyverse e adjacentes 
                 janitor, lubridate, ggtext, ggrepel, extrafont, scales, ggalt, zoo,
                 countrycode, ggbrace, glue)
  pacman::p_loaded()
  
  options(timeout = max(1000, getOption("timeout")))
  
  
  ## Importando dados
  
  gmob = read.csv("https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv") %>% 
            select(-c(country_region_code, metro_area:place_id)) %>% 
            filter(country_region %in% c("Brazil", "Argentina", "Chile", "United States", "Portugal", "Germany")) %>%  
            relocate(date, .before = country_region) %>%
            set_names(c("Data", "country_region", "sub_region_1", "sub_region_2",
                        "Varejo e Lazer", "Farmácia e Mercado", "Parques", "Estações de Transporte", "Locais de Trabalho", "Residencial")) %>%
            mutate(Data = as.Date(Data),
                   across(c(2:7), ~ rollapply(.x,  7, mean, fill = NA, align = "right"), .names = "{.col}_mm7"), 
                   across(c(2:7), ~ rollapply(.x, 30, mean, fill = NA, align = "right"), .names = "{.col}_mm30"),
                   .by = c(country_region, sub_region_1, sub_region_2)) %>% 
            mutate(country_region = countrycode(.$country_region, "country.name", "cldr.name.pt"))
  
  
  
  
  
  ## Gráficos
  
  tema_base = theme(plot.title = element_markdown(size = 23, family = "Comic Sans MS"),
                    plot.subtitle = element_markdown(size = 15, lineheight = 1.2),
                    axis.text.x = element_markdown(size = 15, hjust = 1),
                    axis.text = element_markdown(size = 12, color = "black"),
                    axis.line = element_line(color = "black"),
                    panel.grid.minor.y = element_blank(),
                    panel.grid.major = element_blank(),
                    panel.grid.minor.x = element_blank(),
                    panel.background = element_rect(fill = "white", colour = "white"),
                    plot.background = element_rect(fill = "white", colour = "white"),
                    plot.caption = element_markdown(hjust = -0.06, margin = unit(c(-5,0,0,0), "mm")))
  
  ini_pancovid = as.Date("2020-03-11")
  fim_pancovid = as.Date("2023-05-05")
  
  verao_hn = tibble(inicio = paste0(c("2020", "2021", "2022"), "-06-20") %>% as.Date,
                    fim    = paste0(c("2020", "2021", "2022"), "-09-23") %>% as.Date)
  
  
  

   # Brasil mm7 
   
   gmob %>%
      filter(country_region == "Brasil" & sub_region_1 == "") %>%
      select(Data, contains("mm7")) %>%
      pivot_longer(contains("mm7"), names_to = "tipo", values_to = "MM") %>% 
      mutate(ano = year(Data),
             Data = case_when(year(Data) != 2020 ~ `year<-`(Data, 2020),
                              TRUE ~ Data),
             tipo = gsub("_mm7", "", tipo),
             .by = tipo) %>% 
      
   {ggplot(., aes(x = Data, y = MM, group = interaction(tipo, ano), color = as.factor(ano))) +
      geom_hline(yintercept = 0, color = "black", size = 0.4) +
      geom_line(size = 1) +
      #annotate("rect", xmin = ini_pancovid, xmax = fim_pancovid, ymin = -Inf, ymax = Inf, alpha = .1) +
      labs(title = "**A Volta da Atividade no Brasil?**",
           subtitle = paste("Apesar da divulgação ter sido encerrada no final de 2022, os dados de alta frequência do Google Mobility <br>",
                            "permitem uma *proxy* da volta à normalidade no país."),
           caption = " <br> Fonte: Elaboração própria a partir de dados do Google.",
           x = "",
           y = "") +
      scale_color_manual(values = RColorBrewer::brewer.pal(7, "RdBu")[c(1,5,7)], name = "") +
      scale_x_date(date_breaks = "2 months", date_labels = "%b") +
      theme_minimal(base_size = 15) +
      tema_base +
      theme(strip.text = element_markdown(size = 13, face = "bold"),
            legend.text = element_markdown(size = 13),
            legend.position = c(0.49, 0.55),
            legend.direction = "horizontal") + 
      facet_wrap(~ tipo, scales = "fixed")} %>% 
   ggsave("Imagem.png", ., width = 12, height = 7, units = "in", dpi = 300)
   
   
   

   # Estados da Federação
   
   gmob %>% 
      select(Data, country_region, estado = sub_region_1, sub_region_2, contains("mm7")) %>%
      pivot_longer(contains("mm7"), names_to = "tipo", values_to = "MM") %>% 
      filter(country_region == "Brasil" & estado != "" & sub_region_2 == "" & tipo %in% c("Varejo e Lazer_mm7")) %>% 
      mutate(estado = case_when(estado == "Federal District"             ~ "Distrito Federal",
                                estado == "State of Alagoas"             ~ "Alagoas",
                                estado == "State of Amazonas"            ~ "Amazonas",
                                estado == "State of Ceará"               ~ "Ceará",
                                estado == "State of Goiás"               ~ "Goiás", 
                                estado == "State of Mato Grosso"         ~ "Mato Grosso",
                                estado == "State of Minas Gerais"        ~ "Minas Gerais", 
                                estado == "State of Paraíba"             ~ "Paraíba",
                                estado == "State of Pernambuco"          ~ "Pernambuco", 
                                estado == "State of Rio de Janeiro"      ~ "Rio de Janeiro", 
                                estado == "State of Rio Grande do Sul"   ~ "Rio Grande do Sul", 
                                estado == "State of Roraima"             ~ "Roraima", 
                                estado == "State of São Paulo"           ~ "São Paulo",
                                estado == "State of Tocantins"           ~ "Tocantins",
                                estado == "State of Acre"                ~ "Acre", 
                                estado == "State of Amapá"               ~ "Amapá",
                                estado == "State of Bahia"               ~ "Bahia",
                                estado == "State of Espírito Santo"      ~ "Espírito Santo", 
                                estado == "State of Maranhão"            ~ "Maranhão",
                                estado == "State of Mato Grosso do Sul"  ~ "Mato Grosso do Sul", 
                                estado == "State of Pará"                ~ "Pará",
                                estado == "State of Paraná"              ~ "Paraná",
                                estado == "State of Piauí"               ~ "Piauí",
                                estado == "State of Rio Grande do Norte" ~ "Rio Grande do Norte",
                                estado == "State of Rondônia"            ~ "Rondônia", 
                                estado == "State of Santa Catarina"      ~ "Santa Catarina", 
                                estado == "State of Sergipe"             ~ "Sergipe",
                                T ~ as.character(estado))) %>%
      mutate(ano = year(Data),
             Data = case_when(year(Data) != 2020 ~ `year<-`(Data, 2020),
                              TRUE ~ Data)) %>% 
     
   {ggplot(., aes(x = Data, y = MM, group = ano, color = as.factor(ano))) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "black", size = 1) +
      geom_line(size = 0.9) +
      labs(title = "**E os estados?**",
           subtitle = "Varejo e Lazer, média móvel de 7 dias.",
           x = "", y = "",
           caption = "<br> Fonte: Elaboração própria a partir de dados do Google.") +
      scale_color_manual(values = RColorBrewer::brewer.pal(7, "RdBu")[c(1,5,7)], name = "") +
      scale_x_date(date_breaks = "3 months", date_labels = "%b") +
      scale_y_continuous(limits = c(-80, 100), breaks = c(-50, 0, 50, 100)) +
      theme_minimal(base_size = 15) +
      tema_base +
      theme(axis.line = element_line(color = "black"),
            strip.background = element_blank(),
            strip.text.x = element_text(face = "bold"),
            legend.position = c(0.8, 0.05),
            legend.text = element_text(face = "bold"),
            legend.title = element_blank()) +
      facet_wrap(~ estado)} %>% 
    ggsave("Imagem.png", ., width = 12, height = 7, units = "in", dpi = 300)
   
   
   

   # Locais de Trabalho, finais de semana 
   
   gmob %>%
     filter(sub_region_1 == "" & country_region == "Estados Unidos",
            Data <= "2020-06-30") %>% 
     select(Data, country_region, `Locais de Trabalho`) %>% 
     mutate(`Dia da Semana` = lubridate::wday(Data, label = T)) %>% 
     
     {ggplot(., aes(x = Data, y = `Locais de Trabalho`)) +
         geom_col(aes(fill = ifelse(grepl('sáb|dom', `Dia da Semana`), 'Final de Semana', 'Dia Útil'))) +
         scale_fill_manual(values = c('#f7a766', '#bc2b53')) +
         
         geom_hline(yintercept = 0, colour = "black") +
         
         geom_brace(aes(x = c(as.Date("2020-01-03"), as.Date("2020-02-06")), y = c(-2, -7)), inherit.data = F, rotate = 180) +
         annotate("richtext", x = as.Date("2020-01-20"), y = -12, size = 3.5, fill = "white", label.color = NA,
                  label = "período que o Google usou <br> para calcular as medianas de <br> cada dia da semana") +
         
         coord_cartesian(xlim = c(as.Date("2020-01-01"), max(.$Data)), clip = 'off') + 
         #geom_segment(aes(x = as.Date("2020-06-25"), xend = as.Date("2020-07-05"), y = -65, yend = -65),
         #arrow = arrow(length = unit(0.1, "inches"))) +
         #annotate("richtext", x = as.Date("2020-06-30"), y = -62, size = 3.5, fill = "white", label.color = NA,
         #label = "próximo gráfico") + 
         
         scale_x_date(breaks = c(as.Date("2020-01-01"), seq.Date(as.Date("2020-03-01"), as.Date("2020-07-01"), "1 month")),
                      date_labels = ifelse(c(as.Date("2020-01-01"), seq.Date(as.Date("2020-03-01"), as.Date("2020-07-01"), "1 month")) %in% as.Date("2020-01-01"), '%b/%y', '%b')) +
         labs(title = "**Nem tudo parece o que é...** (1\\/2)",
              subtitle = glue(paste("{ unique(.[2]) }, { colnames(.[3]) }, janela amostral entre março e junho de 2020. <br>")),
              caption = " <br> Fonte: Elaboração própria a partir de dados do Google Mobility Report.",
              x = "", y = "%", fill = "") +
         theme_minimal(base_size = 15) +
         tema_base +
         theme(panel.grid.major.x = element_line(linetype = "dotdash", colour = "grey"),
               axis.text.y = element_text(size = 15),
               axis.title.y = element_text(angle = 180, vjust = 0.5, hjust = 1, margin = margin(0, 10, 0, 0)),
               legend.position = c(.25, .2))
     } %>%   
    ggsave("Imagem.png", ., width = 12, height = 7, units = "in", dpi = 300) 
   
   
   

   # Comparação Hemisfério Norte e Sul
   
   gmob %>%
     filter(sub_region_1 == "") %>% 
     select(Data, country_region, `Varejo e Lazer` = `Varejo e Lazer_mm30`, Parques = Parques_mm30) %>% 
     pivot_longer(3:4, names_to = "tipo", values_to = "valor") %>% 
     mutate(hemisferio = ifelse(country_region %in% c("Brasil", "Argentina", "Chile"), "Sul", "Norte")) %>% 
     
   {ggplot(data = .) +
       geom_rect(data = verao_hn, aes(xmin = inicio, xmax = fim, ymin = -Inf, ymax = Inf), alpha = 0.1) +
       
       geom_line(data = ~ filter(., hemisferio ==  "Norte" & tipo == "Parques"), aes(x = Data, y = valor, color = country_region), size = 0.8) +
       scale_color_manual(values = RColorBrewer::brewer.pal(9, "Blues")[c(5,7,9)], name = "Hemisfério Norte", guide = guide_legend(order = 1)) +
       ggnewscale::new_scale_color() +
       geom_line(data = ~ filter(., hemisferio == "Sul" & tipo == "Parques"), aes(x = Data, y = valor, color = country_region), size = 0.8) +
       scale_color_manual(values = RColorBrewer::brewer.pal(9, "Reds")[c(5,7,9)], name = "Hemisfério Sul", guide = guide_legend(order = 2)) +
       
       geom_hline(yintercept = 0, colour = "black") +
       geom_vline(xintercept = as.Date("2022-10-15"), colour = "grey", linetype = 4, size = .8) +
       geom_curve(aes(x = as.Date("2022-10-15"), y = -45, xend = as.Date("2022-12-15"), yend = -70),
                  arrow = arrow(length = unit(0.02, "npc"))) +
       
       coord_cartesian(xlim = c(min(.$Data), max(.$Data)), clip = 'off') +
       annotate("richtext", x = as.Date("2023-03-01"), y = -75, size = 3.5, fill = "white", label.color = NA,
                 label = "As séries foram <br> encerradas em <br> 15/10/2022") + 
       annotate("richtext", x = as.Date("2020-08-07"), y = 160, size = 3.5, fill = "transparent", label.color = NA,
                label = "Verão no <br> Hemisf. Norte") + 
       
       scale_y_continuous(breaks = seq(-90, 150, 30)) +
       scale_x_date(breaks = "3 months", labels = label_date_short(sep = "<br>")) +
       labs(title = "**...e nem tudo é o que parece** (2\\/2)",
            subtitle = "Parques, média móvel de 30 dias. <br>",
            caption = " <br> Fonte: Elaboração própria a partir de dados do Google Mobility Report.",
            x = "", y = "%") +
       theme_minimal(base_size = 15) +
       tema_base +
       theme(axis.text = element_markdown(size = 15),
             axis.title.y = element_text(angle = 180, vjust = 0.5, hjust = 1, margin = margin(0, 10, 0, 0)))} %>%   
     ggsave("Imagem.png", ., width = 12, height = 7, units = "in", dpi = 300)
   
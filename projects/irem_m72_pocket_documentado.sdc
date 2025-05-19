# ============================================
# Relojes principales derivados del PLL (core_pll)
# ============================================

# clk_dram: Salida directa del PLL (Salida 1) - Frecuencia base ≈ 104.687 MHz
create_clock -name clk_dram -period 9.552 \
    [get_nets {ic|core_pll|core_pll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}]

# clk_sys: Derivado como clk_dram / 3 ≈ 34.895 MHz (Salida 2 del PLL)
create_clock -name clk_sys -period 28.658 \
    [get_nets {ic|core_pll|core_pll_inst|altera_pll_i|cyclonev_pll|counter[1].output_counter|divclk}]

# clk_video: Derivado como clk_dram / 12 ≈ 8.724 MHz (Salida 3 del PLL)
create_clock -name clk_video -period 114.635 \
    [get_nets {ic|core_pll|core_pll_inst|altera_pll_i|cyclonev_pll|counter[2].output_counter|divclk}]

# ============================================
# Multicycle path entre dominios sincronizados manualmente (SDRAM -> SYS)
# ============================================
set_multicycle_path -from [get_clocks clk_dram] -to [get_clocks clk_sys] -setup 3
set_multicycle_path -from [get_clocks clk_dram] -to [get_clocks clk_sys] -hold 2

# ============================================
# Agrupación de relojes asincrónicos
# ============================================
set_clock_groups -asynchronous \
  -group [get_clocks clk_sys] \
  -group [get_clocks {bridge_spiclk clk_74a clk_74b clk_video}]
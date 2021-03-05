# ip

source ./generate_ip.tcl

ip_create ADC344x_Top

ip_files ADC344x_Top [list \
  "../rtl/Serdes_1x14_DDR.v" \
  "../rtl/AdcFrame.v" \
  "../rtl/AdcData.v" \
  "../rtl/AdcClock.vhd" \
  "../rtl/Adc344x_Top.v" \
  "../lib/axis_adapter.v" \
  "../lib/axis_async_fifo.v" \
  "../lib/axis_async_fifo_adapter.v" \
  "../syn/axis_async_fifo.tcl"]
  # "../lib/axis_async_fifo.tcl"]

ip_properties_lite ADC344x_Top

ipx::save_core [ipx::current_core]


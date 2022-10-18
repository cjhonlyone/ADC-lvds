# ip

source ./generate_ip.tcl

ip_create adc_lvds

add_files -fileset sources_1 ../rtl/Serdes_1x10_DDR.v
add_files -fileset sources_1 ../rtl/Serdes_1x12_DDR.v
add_files -fileset sources_1 ../rtl/Serdes_1x14_DDR.v
add_files -fileset sources_1 ../rtl/Serdes_1x8_DDR.v
add_files -fileset sources_1 ../rtl/AdcClock.v
add_files -fileset sources_1 ../rtl/AdcFrame.v
add_files -fileset sources_1 ../rtl/AdcLane.v
add_files -fileset sources_1 ../rtl/AdcSwap.v
add_files -fileset sources_1 ../rtl/AdcLVDS.v
add_files -fileset sources_1 ../lib/axis_adapter.v
add_files -fileset sources_1 ../lib/axis_async_fifo.v
add_files -fileset sources_1 ../lib/axis_async_fifo_adapter.v

# add_files -fileset constrs_1 ../syn/axis_async_fifo.tcl

ip_properties_lite adc_lvds

# ipx::infer_bus_interface AdcSampClk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface AdcFrmClk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface AdcFrmClk2x xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]

ipx::save_core [ipx::current_core]


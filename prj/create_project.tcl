create_project -force -part xc7z020clg400-2 fpga
add_files -fileset sources_1 ../rtl/AdcFrame.v
add_files -fileset sources_1 ../rtl/AdcLane.v
add_files -fileset sources_1 ../rtl/AdcLVDS.v
add_files -fileset sources_1 ../rtl/AdcSwap.v
add_files -fileset sources_1 ../rtl/AdcClock.v
add_files -fileset sources_1 ../rtl/Serdes_1x10_DDR.v
add_files -fileset sources_1 ../rtl/Serdes_1x12_DDR.v
add_files -fileset sources_1 ../rtl/Serdes_1x14_DDR.v
add_files -fileset sources_1 ../rtl/Serdes_1x8_DDR.v
add_files -fileset sources_1 ../rtl/top.v

add_files -fileset sources_1 ../lib/axis_adapter.v
add_files -fileset sources_1 ../lib/axis_async_fifo.v
add_files -fileset sources_1 ../lib/axis_async_fifo_adapter.v

add_files -fileset constrs_1 ../syn/axis_async_fifo.tcl
add_files -fileset constrs_1 ../syn/top.xdc

set_property top top [get_filesets sources_1]

start_gui
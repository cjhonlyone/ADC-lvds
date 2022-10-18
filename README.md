# ADC General LVDS Interface

## Generate IP

```vivado
(vivado) cd ./ip
(vivado) source adc_lvds_ip.tcl
```

```bash
(bash) vivado -mode tcl -source ./ip/adc_lvds_ip.tcl
```

### 2 wire mode
- ADC3441/ADC3442/ADC3443/ADC3444
- 1:14 Serdes has been tested

### 1 wire mode
- AD9252, 8 Channel
- 1:14 Serdes has been tested
- 1:12 Serdes has been tested

### 1 wire mode
- LTC2263, 2 Channel
- 1:14 Serdes has been tested


point_num = 8192;
fs_MHz = 100;
rx_t_us = 0:(1/fs_MHz):(point_num-1)*(1/fs_MHz);
Adc_data = sin(10*rx_t_us)*(2^13-1);

fp=fopen('Adc_data.txt','w');%'A.txt'为文件名；'a'为打开方式：在打开的文件末端添加数据，若文件不存在则创建。
for ii = 1:length(Adc_data)
    fprintf(fp,'%04x\n',typecast(int16(Adc_data(ii)),'uint16'));%fp为文件句柄，指定要写入数据的文件。注意：%d后有空格。
end
fclose(fp);%关闭文件。
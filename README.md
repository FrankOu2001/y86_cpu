# y86_cpu

A simple implement of Y86-64 pipeline cpu written in verilog.

+ `pipe`是仅添加五级流水线的版本

+ `pipe-predictor`是在五级流水线基础上添加GShare分支预测器的版本

+ `pipe-predictor-cache`是五级流水线+GShare+数据Cache
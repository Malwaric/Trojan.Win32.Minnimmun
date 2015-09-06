JMP FAR PTR Duh ; Takes four bytes
Duh DW V2_Start ; Takes two bytes

DB 1101001B ; Code for JMP(2 Byte-Displacement)
Duh DW V2_Start - OFFSET Duh ; 2 byte displacement

Duh V2_Start - $

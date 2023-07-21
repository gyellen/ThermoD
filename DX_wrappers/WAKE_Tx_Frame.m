function dframe = WAKE_Tx_Frame(ADDR, CMD, N, Data)
% returns a full transmission frame given address, command, data
% eliminated special handling for ADDR==0

dframe = uint8([]);

Pc_Tx_Crc = uint8(hex2dec('DE'));   %init CRC
FEND  = uint8(hex2dec('C0'));
FESC  = uint8(hex2dec('DB'));
TFEND = uint8(hex2dec('DC'));
TFESC = uint8(hex2dec('DD'));

for i=-4:N
    switch i
        case -4
            d = FEND;
        case -3
            d = uint8(ADDR);
        case -2
            d = uint8(hex2dec(CMD));
        case -1
            d = uint8(N);
        case N
            d = Pc_Tx_Crc;  % last xfer is CRC
        otherwise
            d = uint8(Data(i+1));
    end
    
    % update the CRC using the current d value
    Pc_Tx_Crc = crc(d,Pc_Tx_Crc);
    
    % set the address MSB
    if i==-3, d = bitor(d,uint8(128)); end
    
    if i~=-4 && (d==FEND || d==FESC)
        dframe = [dframe FESC];
        if d==FEND
            dframe = [dframe TFEND];
        else
            dframe = [dframe TFESC];
        end
    else
        dframe = [dframe d];
    end
end

function newcrc = crc(d,oldcrc)
persistent crc_table
if isempty(crc_table)
    crc_table = uint8(hex2dec({ ...
        '00','5E','BC','E2','61','3F','DD','83','C2','9C','7E','20','A3','FD','1F','41', ...
        '9D','C3','21','7F','FC','A2','40','1E','5F','01','E3','BD','3E','60','82','DC', ...
        '23','7D','9F','C1','42','1C','FE','A0','E1','BF','5D','03','80','DE','3C','62', ...
        'BE','E0','02','5C','DF','81','63','3D','7C','22','C0','9E','1D','43','A1','FF', ...
        '46','18','FA','A4','27','79','9B','C5','84','DA','38','66','E5','BB','59','07', ...
        'DB','85','67','39','BA','E4','06','58','19','47','A5','FB','78','26','C4','9A', ...
        '65','3B','D9','87','04','5A','B8','E6','A7','F9','1B','45','C6','98','7A','24', ...
        'F8','A6','44','1A','99','C7','25','7B','3A','64','86','D8','5B','05','E7','B9', ...
        '8C','D2','30','6E','ED','B3','51','0F','4E','10','F2','AC','2F','71','93','CD', ...
        '11','4F','AD','F3','70','2E','CC','92','D3','8D','6F','31','B2','EC','0E','50', ...
        'AF','F1','13','4D','CE','90','72','2C','6D','33','D1','8F','0C','52','B0','EE', ...
        '32','6C','8E','D0','53','0D','EF','B1','F0','AE','4C','12','91','CF','2D','73', ...
        'CA','94','76','28','AB','F5','17','49','08','56','B4','EA','69','37','D5','8B', ...
        '57','09','EB','B5','36','68','8A','D4','95','CB','29','77','F4','AA','48','16', ...
        'E9','B7','55','0B','88','D6','34','6A','2B','75','97','C9','4A','14','F6','A8', ...
        '74','2A','C8','96','15','4B','A9','F7','B6','E8','0A','54','D7','89','6B','35'}));
end
newcrc = crc_table(1+bitxor(d,oldcrc,'uint8'));

% //----------------------------------------------------------------------------
% //----------------------------------------------------------------------------
% 
% #define WAKE_GLOBALS
% #include "Wake.h"	
% #include "Frame.h"	 
% #include "main\DX5100.h"
% #include "main\DX5100_var.h"
% 
% #include "UART1\UART1.h"	
% #include "UART0\UART0.h"	
% 
% 
% 
% #define FEND  0xC0    //Frame END
% #define FESC  0xDB    //Frame ESCape
% #define TFEND 0xDC    //Transposed Frame END
% #define TFESC 0xDD    //Transposed Frame ESCape
% 
% #define CRC_INIT 0xDE //Innitial CRC value
% 
% unsigned char Pc_Tx_Crc; //CRC
% 
% //Structure WAKE frame
% //FEND-ADDR-CMD-N-Data1-...-DataN-CRC
% 
% //                   FESC   TFEND
% //FEND  0xC0	-->  0xDB + 0xDC
% //                   FESC   TFESC
% //FESC  0xC0	-->  0xDB + 0xDD
% 
% /*------------------------------------------------------------------------------*/
% //      calculate CRC  WAKE frame: 
% /*------------------------------------------------------------------------------*/

% unsigned char code crc_table[256] = {
% 0x00,0x5E,0xBC,0xE2,0x61,0x3F,0xDD,0x83,0xC2,0x9C,0x7E,0x20,0xA3,0xFD,0x1F,0x41,
% 0x9D,0xC3,0x21,0x7F,0xFC,0xA2,0x40,0x1E,0x5F,0x01,0xE3,0xBD,0x3E,0x60,0x82,0xDC,
% 0x23,0x7D,0x9F,0xC1,0x42,0x1C,0xFE,0xA0,0xE1,0xBF,0x5D,0x03,0x80,0xDE,0x3C,0x62,
% 0xBE,0xE0,0x02,0x5C,0xDF,0x81,0x63,0x3D,0x7C,0x22,0xC0,0x9E,0x1D,0x43,0xA1,0xFF,
% 0x46,0x18,0xFA,0xA4,0x27,0x79,0x9B,0xC5,0x84,0xDA,0x38,0x66,0xE5,0xBB,0x59,0x07,
% 0xDB,0x85,0x67,0x39,0xBA,0xE4,0x06,0x58,0x19,0x47,0xA5,0xFB,0x78,0x26,0xC4,0x9A,
% 0x65,0x3B,0xD9,0x87,0x04,0x5A,0xB8,0xE6,0xA7,0xF9,0x1B,0x45,0xC6,0x98,0x7A,0x24,
% 0xF8,0xA6,0x44,0x1A,0x99,0xC7,0x25,0x7B,0x3A,0x64,0x86,0xD8,0x5B,0x05,0xE7,0xB9,
% 0x8C,0xD2,0x30,0x6E,0xED,0xB3,0x51,0x0F,0x4E,0x10,0xF2,0xAC,0x2F,0x71,0x93,0xCD,
% 0x11,0x4F,0xAD,0xF3,0x70,0x2E,0xCC,0x92,0xD3,0x8D,0x6F,0x31,0xB2,0xEC,0x0E,0x50,
% 0xAF,0xF1,0x13,0x4D,0xCE,0x90,0x72,0x2C,0x6D,0x33,0xD1,0x8F,0x0C,0x52,0xB0,0xEE,
% 0x32,0x6C,0x8E,0xD0,0x53,0x0D,0xEF,0xB1,0xF0,0xAE,0x4C,0x12,0x91,0xCF,0x2D,0x73,
% 0xCA,0x94,0x76,0x28,0xAB,0xF5,0x17,0x49,0x08,0x56,0xB4,0xEA,0x69,0x37,0xD5,0x8B,
% 0x57,0x09,0xEB,0xB5,0x36,0x68,0x8A,0xD4,0x95,0xCB,0x29,0x77,0xF4,0xAA,0x48,0x16,
% 0xE9,0xB7,0x55,0x0B,0x88,0xD6,0x34,0x6A,0x2B,0x75,0x97,0xC9,0x4A,0x14,0xF6,0xA8,
% 0x74,0x2A,0xC8,0x96,0x15,0x4B,0xA9,0xF7,0xB6,0xE8,0x0A,0x54,0xD7,0x89,0x6B,0x35};
 
% //--------------------- calculate CRC -------------------------
% void Do_Crc8_TX(unsigned char b, unsigned char *crc)
% {
%   *crc=crc_table[(*crc^b)];
% }

% /*------------------------------------------------------------------------------*/
% //      Transmit frame WAKE: 
% /*------------------------------------------------------------------------------*/
% void WAKE_Tx_Frame(unsigned char ADDR, unsigned char CMD, unsigned char N, unsigned char *Data)
   
%    
% { 
%   char idata i;
%   unsigned char idata d;            
%   Pc_Tx_Crc = uint8(hex2dec('DE'));   %init CRC
%                       
%   
%   for (i = -4; i <= N; i++)
%   {
%     if ((i == -3) && (!ADDR)) i++;
%     if (i == -4) d = FEND; else        //FEND
%     if (i == -3) d = ADDR; else        //address
%     if (i == -2) d = CMD;  else        //command
%     if (i == -1) d = N;    else        //N
%     if (i ==  N) d = Pc_Tx_Crc;  else  //CRC
%                  d = Data[i];          //data
%     Do_Crc8_TX(d, &Pc_Tx_Crc);         //new CRC
%     if (i == -3) d |= 0x80;
%     if ((i != -4) && ((d == FEND) || (d == FESC)))
%     { 
%       CharInTxBuf(FESC);
%       if (d == FEND) d = TFEND;
%       else d = TFESC;
%     }
%     CharInTxBuf(d);
%   }
% }
% /********************************************************************************/
% 



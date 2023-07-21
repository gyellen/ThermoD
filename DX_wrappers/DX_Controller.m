function dframe = DX_Controller(ch,cmd,val)
switch cmd
    case 'idle'
        c = 0; val = 0;
    case 'program'
        c = 1;
    case 'pid'
        c = 3;
    case 'constV'
        c = 4;
    otherwise
        dframe = [];
        disp('DX_Controller: no legal cmd');
        return
end

% NOTE THAT DEVICE considers channels 1 and 2 to be ch=0,1
dframe = WAKE_Tx_Frame(1,'35',8,[2 0 ch-1 c Wake_Encode_Float(val)]);

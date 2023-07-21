function [resp,cmd,msg] = DX_Receive(flag)
% doesn't account for possible byte-stuffing!
global DX5100 DX_Verbose
FESC = hex2dec('DB'); FEND = hex2dec('C0');
if nargin>=1 || DX5100.Port.BytesAvailable>6
    frameStart = 0; skip = -1;
    while frameStart ~= FEND  % looking for start of frame
        frameStart = fread(DX5100.Port,1);
        skip = skip+1;
    end
    if skip>0 && DX_Verbose, disp(['DX_Receive: skipped ' num2str(skip) ' bytes']); end
    
    hdr = fread(DX5100.Port,3);  % get the start of the frame: FEND addr cmd N
    if numel(hdr)==3
        frameStart(2:4) = hdr; 
    else
        frameStart(2) = 999; 
    end
    if frameStart(1) ~= FEND || frameStart(2) ~= 129
        rhex = dec2hex(frameStart,2)';
        disp(['DX_Receive got invalid response: ' rhex(:)']);
        resp = []; cmd = 0; msg = '';
        return
    end
    cmd = frameStart(3);
    [resp,~,msg] = fread(DX5100.Port,frameStart(4)+1);
    %% handle any byte stuffing
    % find any escape codes 
    stuff = find(resp==FESC);
    nExtra = numel(stuff);
    % read the extra bytes needed, until we have them all
    t0 = now;
    while nExtra>0 && (now-t0)<2e-5 % (about 1.7 s) 
        [rExtra,~,msg] = fread(DX5100.Port,nExtra);
        resp = [resp; rExtra];
        stuff = find(resp==FESC);
        nExtra = numel(stuff)-nExtra;  % more to get
    end
    if ~isempty(stuff)
        % replace the escape codes with the correct values
        for k=1:numel(stuff)
            pos = stuff(k)+1;
            if resp(pos)==hex2dec('DC')
                resp(pos) = hex2dec('C0');
            elseif resp(pos)==hex2dec('DD')
                resp(pos) = hex2dec('DB');
            else
                disp(['DX_Receive got invalid ESC seq: ' compose('%0X',resp)])
            end
        end
        % delete the escape codes
        resp(stuff)=[];
    end
    %% return the response
    resp = resp(1:end-1)';
    DX_ValidateResponse(resp,flag);
else
    cmd=0;
    resp = [];
end


function lineUpCamData(Thermo,fh,ff)
% lining up MATLAB and PIX Connect data

% MATLAB data
mSrc  = Thermo; % usually Thermo or savedThermo
mTime = mSrc.camTimes(:)*60; %  times in seconds, from start of expt
mTemp = round(mSrc.camTemps(1,:),2);  %  values in deg C

% imported time/temp data - increment assumed to be 0.02 sec (50 Hz)
chTemp = round(fh(:),2);  % sequence of temps for flash heat
chTime = (1:numel(chTemp))*0.02;
cfTemp = round(ff(:),2);  % sequence of temps for flash freeze
cfTime = (1:numel(cfTemp))*0.02;

% for heating - find the mTemp values in heating range
mhTVals = unique(mTemp( mTemp>40 ),'stable');
% keep track of their earliest occurrence in the MATLAB data
for k=1:numel(mhTVals)
    mhtVals(k) = mTime(find(mTemp==mhTVals(k),1,'first'));
end
% now find their earliest occurrence in the camera data,
%   but only for those that are unique
for k=1:numel(mhTVals)
    T = mhTVals(k);
    selH(k) = sum(chTemp==T)==1;
    if selH(k) 
        hTimeMatch(k) = chTime(find(chTemp==T));
    else
        hTimeMatch(k) = nan;
    end
end
offH = min(mhtVals(selH)-hTimeMatch(selH));
% for freezing - find the mTemp values in heating range
mfTVals = unique(mTemp( mTemp<0 ),'stable');
% keep track of their earliest occurrence in the MATLAB data
for k=1:numel(mfTVals)
    mftVals(k) = mTime(find(mTemp==mfTVals(k),1,'first'));
end
for k=1:numel(mfTVals)
    selF(k) = sum(cfTemp==mfTVals(k))==1;
    if selF(k) 
        fTimeMatch(k) = cfTime(find(cfTemp==mfTVals(k)));
    else
        fTimeMatch(k) = nan;
    end
end
offF = min(mftVals(selF)-fTimeMatch(selF));
pltH = (mTime>=offH) & (mTime<=(offH+chTime(end)));
pltF = (mTime>=offF) & (mTime<=(offF+cfTime(end)));

figure(100); clf; plot(mTime(pltH)-offH,mTemp(pltH),'-o',chTime,chTemp,'-x');

figure(101); clf; plot(mTime(pltF)-offF,mTemp(pltF),'-o',cfTime,cfTemp,'-x');
a=1;



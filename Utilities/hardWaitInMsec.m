function hardWaitInMsec(ms)
tTarget = now + ms/86400000;
while (now<tTarget); end

function f = Wake_Decode_Float(byts)
f = flipud(typecast(uint8(flipud(byts(:))),'single'));

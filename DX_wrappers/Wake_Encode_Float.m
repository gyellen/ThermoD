function byts = Wake_Encode_Float(f)
byts = fliplr(typecast(single(fliplr(f(:)')),'uint8'));
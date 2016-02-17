function data = prepBMP(BMP)
%prepBMP Adds a header to the matrix BMP
%

bitDepth = 1;
signature = ['53'; '70'; '6C'; '64'];
imageWidth = dec2hex(typecast(uint16(size(BMP,2)),'uint8'));
imageHeight = dec2hex(typecast(uint16(size(BMP,1)),'uint8'));
numOfBytes = dec2hex(typecast(uint32(size(BMP,1)*size(BMP,2)*...
    bitDepth),'uint8'));
backgroundColor = ['00'; '00'; '00'; '00'];
compression = '00';

header = [signature; imageWidth; imageHeight; numOfBytes; ...
    'FF'; 'FF'; 'FF'; 'FF'; 'FF'; 'FF'; 'FF'; 'FF'; backgroundColor; ...
    '00'; compression; '01'; '00'; '00'; '00'; '00'; '00'; '00'; '00';...
    '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00';...
    '00'; '00'; '00'];

BMP = BMP';

if strcmp(compression, '01')
    data = [header; dec2hex(typecast(rle(BMP(:))','uint8'),2)];
else
    % add two more colors
    BMP3c = [BMP(:), zeros(size(BMP(:),1),2)];
    data = [header; dec2hex(BMP3c(:),2);];
end
data = dec2bin(hex2dec(data),8);
end
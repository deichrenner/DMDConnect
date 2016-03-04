function data = prepBMP(BMP1)
%prepBMP Adds a header to the matrix BMP and applies RLE to the input matrix
%
% The RLE algorithm is based on http://stackoverflow.com/questions/
% 12059744/run-length-encoding-in-matlab
% 
% Author: Klaus Hueck (e-mail: khueck (at) physik (dot) uni-hamburg (dot) de)
% Version: 0.0.1alpha
% Changes tracker:  28.01.2016  - First version
% License: GPL v3

bitDepth = 1;
signature = ['53'; '70'; '6C'; '64'];
imageWidth = dec2hex(typecast(uint16(size(BMP1,2)),'uint8'),2);
imageHeight = dec2hex(typecast(uint16(size(BMP1,1)),'uint8'),2);
numOfBytes = dec2hex(typecast(uint32(size(BMP1,1)*size(BMP1,2)*...
    bitDepth),'uint8'));
backgroundColor = ['00'; '00'; '00'; '00'];
compression = '01';

header = [signature; imageWidth; imageHeight; numOfBytes; ...
    'FF'; 'FF'; 'FF'; 'FF'; 'FF'; 'FF'; 'FF'; 'FF'; backgroundColor; ...
    '00'; compression; '01'; '00'; '00'; '00'; '00'; '00'; '00'; '00';...
    '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00';...
    '00'; '00'; '00'];

BMP1 = BMP1';

% expand to 24bit in hex notation
BMP24 = zeros(size(BMP1)); 
BMP24(BMP1(:) == 1) = 800000;

data = '';

% compress if whished
if strcmp(compression, '01')
    for i = 1:size(BMP24,1)
        ind = find(diff([BMP24(i,1)-1, BMP24(i,:)]));
        relMat = [dec2hex(diff([ind, numel(BMP24(i,:))+1]),2), num2str(BMP24(i,ind)','%06d')];
        for j = 1:size(relMat,1)
            data = [data relMat(j,:)];
        end
        data = [data '0000']; % add the end of line command
    end
    data = [data '0001']; % add the end of file command
    data = [header; char(regexp(data, sprintf('\\w{1,%d}', 2), 'match')')];
else
    % merge header and data
    data = [header; char(regexp(num2str(BMP24(:)','%d'), ...
        sprintf('\\w{1,%d}', 2), 'match')')];
end

end
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
    bitDepth),'uint8'),2);
backgroundColor = ['00'; '00'; '00'; '00'];
compression = '00';

header = [signature; imageWidth; imageHeight; numOfBytes; ...
    'FF'; 'FF'; 'FF'; 'FF'; 'FF'; 'FF'; 'FF'; 'FF'; backgroundColor; ...
    '00'; compression; '01'; '00'; '00'; '00'; '00'; '00'; '00'; '00';...
    '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00'; '00';...
    '00'; '00'; '00'];

% convert input matrix to decimal and transpose for later handling
BMP1 = BMP1'*1; 

% expand to 24bit in 3x8bit decimal notation
BMP24 = cellstr(dec2hex(BMP1(:),6));

% clear return variable
data = '';

% % compress if whished
if strcmp(compression, '02')
    % reshape in order to get 24bit pixel information line by line
    BMP24 = reshape(BMP24, size(BMP1,1), [])';
    for i = 1:size(BMP24,1)
        [~, ~, ic] = unique(BMP24(i,:));
        ind = find(diff([ic(1)-1, ic(:)']));
        relMat = [formatRep(diff([ind, numel(BMP24(i,:))+1])), cell2mat(BMP24(i,ind)')];
        data = [data sprintf(relMat(:,:)')];
    end
    % put together header, compressed data and end of image padding
    data = [header; char(regexp(data, sprintf('\\w{1,%d}', 2), 'match')'); '00'; '01'; '00'];
else
    % merge header and data
    data = [header; BMP24;];
end

end
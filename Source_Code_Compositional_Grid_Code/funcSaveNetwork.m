function funcSaveNetwork(filename)
% Save current global netY to ./data&figure/<filename>.mat
    global netY;

    if nargin < 1 || isempty(filename)
        error('funcSaveNetwork:InvalidInput', 'filename is required.');
    end

    if isempty(netY)
        error('funcSaveNetwork:EmptyNetY', 'global netY is empty.');
    end

    if size(netY, 1) ~= size(netY, 2)
        error('funcSaveNetwork:InvalidNetY', 'global netY must be a square matrix.');
    end

    outFile = ['./data&figure/', filename, '.mat'];
    save(outFile, 'netY');
end
